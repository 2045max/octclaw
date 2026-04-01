# Command: session — manage session branches

cmd_session() {
  config_init
  _load_env
  case "${1:-}" in
    branch)  session_branch "${2:-default}" "${3:-}" ;;
    switch)  [[ -z "${2:-}" ]] && die "Usage: oct session switch <name>"
             printf '\033[90mSession: %s\033[0m\n' "$2" ;;
    merge)   session_merge "${2:-}" "${3:-default}" ;;
    info)    local sid="${2:-default}"
             local meta_file
             meta_file="$(_session_meta_file "$sid")"
             [[ -f "$meta_file" ]] && jq '.' "$meta_file" || printf 'No metadata for session: %s\n' "$sid" ;;
    "")      session_list ;;
    *)       die "Unknown: oct session $1 (try: branch, switch, merge, info)" ;;
  esac
}
