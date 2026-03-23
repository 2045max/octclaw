# ---- /commands (交互中) ----

_handle_slash_command() {
  local input="$1"
  case "$input" in
    /help)
      cat <<'EOF'
  /model <name>    切换模型
  /session <name>  切换会话
  /sessions        列出会话
  /clear           清空当前会话
  /compact         压缩历史
  /tools           列出工具
  /help            显示此帮助
  /exit            退出
EOF
      ;;
    /exit|/quit)    return 1 ;;
    /clear)         session_clear "$_OCT_SID"
                    printf '\033[90mSession cleared.\033[0m\n' ;;
    /sessions)      session_list ;;
    /session\ *)    _OCT_SID="${input#/session }"
                    _OCT_SID="$(printf '%s' "$_OCT_SID" | tr -cd 'A-Za-z0-9_-')"
                    printf '\033[90mSession: %s\033[0m\n' "$_OCT_SID" ;;
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

# ---- 交互模式 ----

_mode_interactive() {
  local sid="$1"
  _OCT_SID="$sid"
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

# ---- Print 模式 ----

_mode_print() {
  local sid="$1" msg="$2"
  local reply
  reply="$(agent_run "$sid" "$msg")"
  printf '%s\n' "$reply"
}

# ---- 子命令: doctor ----

_cmd_doctor() {
  printf '\033[36m🐙 OctClaw v%s\033[0m\n\n' "$OCTCLAW_VERSION"
  for cmd in bash jq curl socat; do
    printf '  %-12s' "$cmd"
    command -v "$cmd" &>/dev/null \
      && printf '\033[32m✓\033[0m %s\n' "$(command -v "$cmd")" \
      || printf '\033[31m✗\033[0m not found\n'
  done
  printf '\n'
  printf '  %-12s%s\n' "state_dir" "$OCTCLAW_STATE"
  printf '  %-12s%s\n' "config" "$OCTCLAW_CONFIG"
  printf '  %-12s%s\n' "model" "$(_resolve_model 2>/dev/null || echo 'gpt-4o')"
  printf '  %-12s%s\n' "api_base" "$(_resolve_api_base 2>/dev/null)"
  local has_key="false"
  for var in API_KEY OPENAI_API_KEY ANTHROPIC_API_KEY DEEPSEEK_API_KEY GROQ_API_KEY; do
    [[ -n "${!var:-}" ]] && has_key="true"
  done
  [[ "$(config_get '.api_key' '' 2>/dev/null)" != "" ]] && has_key="true"
  printf '  %-12s' "api_key"
  [[ "$has_key" == "true" ]] && printf '\033[32m✓\033[0m configured\n' || printf '\033[31m✗\033[0m not set\n'
}

# ---- 子命令: config ----

_cmd_config() {
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


_usage() {
  cat <<EOF
🐙 OctClaw v${OCTCLAW_VERSION} — AI coding assistant in pure Bash

Usage:
  oct [flags] [message]        Chat (interactive if no message)
  oct <subcommand> [args]      Management commands

Flags:
  -m, --model <name>           Model name (default: gpt-4o)
  -s, --session <id>           Session ID (default: default)
  -c, --continue               Continue most recent session
  -p, --print                  Force non-interactive output
      --debug                  Debug output
  -h, --help                   Show this help
  -v, --version                Show version

Subcommands:
  gateway [port]               Start HTTP server (default: 16869)
  doctor                       Check dependencies
  config [set k v | get k]     View or edit config
  sessions                     List sessions

Interactive /commands:
  /model /session /sessions /clear /compact /tools /help /exit

Examples:
  oct                          Interactive chat
  oct "list files in src/"     One-shot answer
  oct -m deepseek-chat "hi"    Use specific model
  oct -c "then what?"          Continue last session
  oct gateway 8080             Start web UI
EOF
}

# 找最近修改的 session 文件
_latest_session() {
  local dir
  dir="$(_sessions_dir)"
  local latest
  latest="$(ls -t "$dir"/*.jsonl 2>/dev/null | head -1)"
  if [[ -n "$latest" ]]; then
    basename "$latest" .jsonl
  else
    echo "default"
  fi
}

main() {
  # 1) 子命令拦截
  case "${1:-}" in
    gateway)          shift; config_init; _load_env; gateway_start "$@"; return ;;
    doctor)           _load_env 2>/dev/null || true; _cmd_doctor; return ;;
    config)           shift; _cmd_config "$@"; return ;;
    sessions)         config_init; _load_env; session_list; return ;;
    _gateway_handle)  _load_env; _gateway_handle; return ;;
  esac

  # 2) 解析 flags
  local flag_model="" flag_session="" flag_continue=0 flag_print=0
  local messages=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m|--model)     flag_model="$2"; shift 2 ;;
      -s|--session)   flag_session="$2"; shift 2 ;;
      -c|--continue)  flag_continue=1; shift ;;
      -p|--print)     flag_print=1; shift ;;
      --debug)        export OCTCLAW_DEBUG=1; shift ;;
      -h|--help)      _usage; return ;;
      -v|--version)   echo "$OCTCLAW_VERSION"; return ;;
      -*)             die "Unknown flag: $1 (try oct --help)" ;;
      *)              messages+=("$1"); shift ;;
    esac
  done

  # 3) 应用 flags
  config_init
  _load_env
  [[ -n "$flag_model" ]] && export MODEL="$flag_model"

  local sid="default"
  if [[ -n "$flag_session" ]]; then
    sid="$flag_session"
  elif (( flag_continue )); then
    sid="$(_latest_session)"
    info "Continuing session: $sid"
  fi

  # 4) 路由: 有消息=print, 无消息=交互
  if (( ${#messages[@]} > 0 )); then
    _mode_print "$sid" "${messages[*]}"
  elif (( flag_print )); then
    die "No message provided for print mode"
  else
    _mode_interactive "$sid"
  fi
}
