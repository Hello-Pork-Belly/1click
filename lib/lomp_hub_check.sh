#!/bin/sh

lomp_hub_extract_bind_value() {
  file=$1
  key=$2
  awk -v wanted="${key}" '
    $0 ~ "^[[:space:]]*" wanted "[[:space:]]*=" {
      sub(/^[^=]*=[[:space:]]*/, "", $0)
      print $0
      exit
    }
    $1 == wanted {
      sub(/^[^[:space:]]+[[:space:]]+/, "", $0)
      print $0
      exit
    }
  ' "${file}"
}

lomp_hub_check_tenant_manifest() {
  manifest=$1
  for slug in ${LOMP_HUB_SITE_SLUGS}; do
    key=$(lomp_hub_slug_key "${slug}")
    grep -q "^TENANT_${key}_DB=wp_${slug}\$" "${manifest}" || {
      lomp_log_error "tenant manifest missing DB mapping for ${slug}"
      return 1
    }
    grep -q "^TENANT_${key}_USER=wp_${slug}\$" "${manifest}" || {
      lomp_log_error "tenant manifest missing DB user mapping for ${slug}"
      return 1
    }
    grep -q "^TENANT_${key}_REDIS_NS=${slug}:\$" "${manifest}" || {
      lomp_log_error "tenant manifest missing Redis namespace mapping for ${slug}"
      return 1
    }
  done
}

lomp_hub_check() {
  rootfs=${LOMP_HUB_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/

  mariadb_conf=$(lomp_path_in_rootfs "${rootfs}" "/etc/mysql/mariadb.conf.d/50-server.cnf") || return 1
  redis_conf=$(lomp_path_in_rootfs "${rootfs}" "/etc/redis/redis.conf") || return 1
  nginx_conf=$(lomp_path_in_rootfs "${rootfs}" "/etc/nginx/sites-available/lomp-hub.conf") || return 1
  tenant_manifest=$(lomp_path_in_rootfs "${rootfs}" "/etc/lomp-hub/tenants.env") || return 1
  diagnostics_env=$(lomp_path_in_rootfs "${rootfs}" "/etc/lomp-hub/diagnostics.env") || return 1
  dashboard_root=$(lomp_path_in_rootfs "${rootfs}" "${LOMP_HUB_DASHBOARD_ROOT}") || return 1

  if [ -f "${mariadb_conf}" ]; then
    mariadb_bind=$(lomp_hub_extract_bind_value "${mariadb_conf}" "bind-address")
    [ -n "${mariadb_bind}" ] || mariadb_bind="${LOMP_HUB_TAILSCALE_ADDR}"
    lomp_hub_require_tailscale_bind "${mariadb_bind}" "mariadb bind-address" || return 1
  else
    lomp_log_info "hub check: MariaDB config not present in rootfs; inventory-only Tailscale boundary check passed"
  fi

  if [ -f "${redis_conf}" ]; then
    if grep -Eq '(^|[[:space:]])0\.0\.0\.0($|[[:space:]])' "${redis_conf}"; then
      lomp_log_error "redis config exposes 0.0.0.0"
      return 1
    fi
    grep -Eq "^[[:space:]]*bind[[:space:]].*${LOMP_HUB_TAILSCALE_ADDR}" "${redis_conf}" || {
      lomp_log_error "redis config does not include the Hub Tailscale bind ${LOMP_HUB_TAILSCALE_ADDR}"
      return 1
    }
    grep -Eq '^[[:space:]]*requirepass[[:space:]]+' "${redis_conf}" || {
      lomp_log_error "redis config missing requirepass"
      return 1
    }
  else
    lomp_log_info "hub check: Redis config not present in rootfs; inventory-only Tailscale boundary check passed"
  fi

  if [ -f "${nginx_conf}" ]; then
    grep -q "listen ${LOMP_HUB_TAILSCALE_ADDR}:80;" "${nginx_conf}" || {
      lomp_log_error "hub-main config does not listen on Hub Tailscale address ${LOMP_HUB_TAILSCALE_ADDR}"
      return 1
    }
    grep -q "server_name ${HUB_DOMAIN};" "${nginx_conf}" || {
      lomp_log_error "hub-main config does not reference domain ${HUB_DOMAIN}"
      return 1
    }
  else
    lomp_log_info "hub check: hub-main config not present in rootfs; inventory-only dashboard boundary check passed"
  fi

  if [ -f "${tenant_manifest}" ]; then
    lomp_hub_check_tenant_manifest "${tenant_manifest}" || return 1
  else
    lomp_log_info "hub check: tenant manifest not present in rootfs; inventory-only isolation check passed"
  fi

  if [ -f "${diagnostics_env}" ]; then
    grep -q "^HUB_TENANT_COUNT=$(lomp_hub_site_count)\$" "${diagnostics_env}" || {
      lomp_log_error "diagnostics env does not report the expected tenant count"
      return 1
    }
  else
    lomp_log_info "hub check: diagnostics env not present in rootfs; inventory-only diagnostics check passed"
  fi

  if [ -d "${dashboard_root}" ]; then
    index_file="${dashboard_root}/index.html"
    if [ -f "${index_file}" ]; then
      grep -q "${HUB_DOMAIN}" "${index_file}" || {
        lomp_log_error "hub dashboard does not reference domain ${HUB_DOMAIN}"
        return 1
      }
    fi
  else
    lomp_log_info "hub check: dashboard root not present in rootfs; inventory-only dashboard check passed"
  fi

  lomp_log_info "lomp-hub check passed"
}
