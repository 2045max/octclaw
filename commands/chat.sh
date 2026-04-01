# Command: chat — interactive and print mode

cmd_chat() {
  local sid="${1:-default}" msg="${2:-}"
  if [[ -n "$msg" ]]; then
    _mode_print "$sid" "$msg"
  else
    _mode_interactive "$sid"
  fi
}

_mode_interactive() {
  local sid="$1"
  _OCT_SID="$sid"
  session_meta_init "$sid"
  printf '\033[36m🐙 OctClaw v%s\033[0m  session: %s  model: %s\n' \
    "$OCTCLAW_VERSION" "$sid" "$(_resolve_model)"
  printf '\033[90mType /help for commands\033[0m\n\n'

  while true; do
    printf '\033[32m> \033[0m'
    local input
    IFS= read -r input || break
    [[ -z "$input" ]] && continue

    if [[ "$input" == /* ]]; then
      _handle_slash_command "$input" || break
      continue
    fi

    local reply
    reply="$(agent_run "$_OCT_SID" "$input" 2>&1)"
    printf '\n%s\n\n' "$reply"
  done
}

_mode_print() {
  local sid="$1" msg="$2"
  session_meta_init "$sid"
  local reply
  reply="$(agent_run "$sid" "$msg")"
  printf '%s\n' "$reply"
}

_handle_slash_command() {
  local input="$1"
  case "$input" in
    /help)
      cat <<'EOF'
  /model <name>    Switch model
  /session <name>  Switch session
  /sessions        List sessions
  /branch <name>   Branch current session
  /merge <name>    Merge session into current
  /clear           Clear current session
  /compact         Compact history
  /tools           List tools
  /help            Show this help
  /exit            Exit
EOF
      ;;
    /exit|/quit)    return 1 ;;
    /clear)         session_clear "$_OCT_SID"
                    printf '\033[90mSession cleared.\033[0m\n' ;;
    /sessions)      session_list ;;
    /session\ *)    _OCT_SID="${input#/session }"
                    _OCT_SID="$(printf '%s' "$_OCT_SID" | tr -cd 'A-Za-z0-9_-')"
                    session_meta_init "$_OCT_SID"
                    printf '\033[90mSession: %s\033[0m\n' "$_OCT_SID" ;;
    /branch\ *)     local name="${input#/branch }"
                    session_branch "$_OCT_SID" "$name" ;;
    /merge\ *)      local name="${input#/merge }"
                    session_merge "$name" "$_OCT_SID" ;;
    /model\ *)      export MODEL="${input#/model }"
                    printf '\033[90mModel: %s\033[0m\n' "$MODEL" ;;
    /compact)       local f; f="$(session_file "$_OCT_SID")"
                    if [[ -f "$f" ]]; then
                      session_prune "$f" 20
                      printf '\033[90mCompacted to last 20 messages.\033[0m\n'
                    else
                      printf '\033[90mNo session to compact.\033[0m\n'
                    fi ;;
    /tools)         tools_spec | jq -r '.[].name' ;;
    /*)             printf '\033[90mUnknown command. Type /help\033[0m\n' ;;
  esac
}
