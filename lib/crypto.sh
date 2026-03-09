#!/bin/sh

crypto__log_error() {
  if command -v log_error >/dev/null 2>&1; then
    log_error "$*"
  else
    printf 'ERROR: %s\n' "$*" >&2
  fi
}

crypto__log_info() {
  if command -v log_info >/dev/null 2>&1; then
    log_info "$*"
  else
    printf 'INFO: %s\n' "$*"
  fi
}

crypto_require_openssl() {
  command -v openssl >/dev/null 2>&1 || {
    crypto__log_error "openssl not found"
    return 1
  }
}

crypto__set_passphrase_env() {
  if [ -n "${HZ_SECRET_PASSPHRASE:-}" ]; then
    HZ_CRYPTO_PASSPHRASE=${HZ_SECRET_PASSPHRASE}
  elif [ -n "${HZ_SECRET_KEY:-}" ]; then
    HZ_CRYPTO_PASSPHRASE=${HZ_SECRET_KEY}
  else
    crypto__log_error "HZ_SECRET_PASSPHRASE is not set"
    return 1
  fi
  export HZ_CRYPTO_PASSPHRASE
}

crypto_require_passphrase() {
  crypto__set_passphrase_env
}

crypto_require_pbkdf2() {
  crypto_require_openssl || return 1
  HZ_CRYPTO_PASSPHRASE=probe
  export HZ_CRYPTO_PASSPHRASE
  printf '' | openssl enc -aes-256-cbc -pbkdf2 -salt -a -A -pass env:HZ_CRYPTO_PASSPHRASE >/dev/null 2>&1 || {
    crypto__log_error "OpenSSL missing -pbkdf2 support"
    return 1
  }
}

crypto_is_encrypted_value() {
  case "${1:-}" in
    HZENC:*) return 0 ;;
    *) return 1 ;;
  esac
}

crypto_gen_key() {
  crypto_require_openssl || return 1
  openssl rand -base64 32
}

crypto_encrypt_stdin() {
  crypto_require_openssl || return 1
  crypto_require_passphrase || return 1
  crypto_require_pbkdf2 || return 1

  cipher=$(openssl enc -aes-256-cbc -pbkdf2 -salt -a -A -pass env:HZ_CRYPTO_PASSPHRASE 2>/dev/null) || {
    crypto__log_error "encryption failed"
    return 1
  }

  printf 'HZENC:%s\n' "${cipher}"
}

crypto_decrypt_stdin() {
  crypto_require_openssl || return 1
  crypto_require_passphrase || return 1
  crypto_require_pbkdf2 || return 1

  enc_value=$(cat)
  crypto_is_encrypted_value "${enc_value}" || {
    crypto__log_error "input is not HZENC:*"
    return 1
  }

  cipher_text=${enc_value#HZENC:}
  plain_text=$(printf '%s' "${cipher_text}" | openssl enc -d -aes-256-cbc -pbkdf2 -a -A -pass env:HZ_CRYPTO_PASSPHRASE 2>/dev/null) || {
    crypto__log_error "decryption failed (wrong passphrase or corrupted ciphertext)"
    return 1
  }

  printf '%s' "${plain_text}"
}

crypto_encrypt_string() {
  if [ "$#" -gt 0 ] && [ -n "${1:-}" ]; then
    printf '%s' "$1" | crypto_encrypt_stdin
    return $?
  fi
  crypto_encrypt_stdin
}

crypto_decrypt_string() {
  if [ "$#" -gt 0 ] && [ -n "${1:-}" ]; then
    printf '%s' "$1" | crypto_decrypt_stdin
    return $?
  fi
  crypto_decrypt_stdin
}
