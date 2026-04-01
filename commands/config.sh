# Command: config — view/set configuration

cmd_config() {
  config_init
  case "${1:-}" in
    set)  [[ -z "${2:-}" || -z "${3:-}" ]] && die "Usage: oct config set <key> <value>"
          config_set "$2" "$3"; printf 'Set %s = %s\n' "$2" "$3" ;;
    get)  [[ -z "${2:-}" ]] && die "Usage: oct config get <key>"
          config_get "$2" ""; printf '\n' ;;
    "")   [[ -f "$OCTCLAW_CONFIG" ]] && jq '.' "$OCTCLAW_CONFIG" || printf '{}\n' ;;
    *)    die "Unknown: oct config $1" ;;
  esac
}
