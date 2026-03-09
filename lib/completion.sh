#!/bin/sh

hz_completion_print() {
  shell_name=${1:-bash}

  case "${shell_name}" in
    bash)
      cat <<'BASH_EOF'
# Bash completion for hz
# Usage:
#   source <(hz completion bash)

_hz_complete() {
  local cur prev cmd sub
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  cmd="${COMP_WORDS[1]:-}"
  sub="${COMP_WORDS[2]:-}"

  local top_level="check-env report secret completion install ping diagnose doctor inventory recipe module notify cron watch help version"

  if [[ "${COMP_CWORD}" -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "${top_level}" -- "${cur}") )
    return 0
  fi

  case "${cmd}" in
    report)
      if [[ "${COMP_CWORD}" -eq 2 ]]; then
        COMPREPLY=( $(compgen -W "html" -- "${cur}") )
        return 0
      fi
      if [[ "${sub}" == "html" ]]; then
        COMPREPLY=( $(compgen -W "--input --output --latest --out" -- "${cur}") )
        return 0
      fi
      ;;
    secret)
      if [[ "${COMP_CWORD}" -eq 2 ]]; then
        COMPREPLY=( $(compgen -W "gen-key encrypt decrypt" -- "${cur}") )
        return 0
      fi
      ;;
    completion)
      if [[ "${COMP_CWORD}" -eq 2 ]]; then
        COMPREPLY=( $(compgen -W "bash zsh" -- "${cur}") )
        return 0
      fi
      ;;
  esac

  COMPREPLY=( $(compgen -W "${top_level}" -- "${cur}") )
  return 0
}

complete -o bashdefault -o default -F _hz_complete hz
BASH_EOF
      ;;
    zsh)
      cat <<'ZSH_EOF'
#compdef hz
# Zsh completion for hz
# Usage:
#   source <(hz completion zsh)

_hz() {
  local -a top_level
  top_level=(check-env report secret completion install ping diagnose doctor inventory recipe module notify cron watch help version)

  if (( CURRENT == 2 )); then
    compadd -- "${top_level[@]}"
    return 0
  fi

  case "${words[2]:-}" in
    report)
      if (( CURRENT == 3 )); then
        compadd -- html
      else
        compadd -- --input --output --latest --out
      fi
      ;;
    secret)
      compadd -- gen-key encrypt decrypt
      ;;
    completion)
      compadd -- bash zsh
      ;;
    *)
      compadd -- "${top_level[@]}"
      ;;
  esac
}

compdef _hz hz
ZSH_EOF
      ;;
    *)
      printf 'ERROR: completion: unknown shell: %s\n' "${shell_name}" >&2
      return 1
      ;;
  esac
}
