# Command dispatcher — routes subcommands to command files

dispatch() {
  local cmd="${1:-}"
  local cmd_file="$OCT_ROOT/commands/${cmd}.sh"

  if [[ -n "$cmd" && -f "$cmd_file" ]]; then
    shift
    source "$cmd_file"
    "cmd_${cmd}" "$@"
    return 0
  fi
  return 1
}
