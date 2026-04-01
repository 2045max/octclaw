TOOL_SHELL_TIMEOUT="${TOOL_SHELL_TIMEOUT:-30}"

shell_spec='
{
  "name": "shell",
  "description": "Execute a shell command. Use for running code, tests, git, installing packages, etc.",
  "input_schema": {
    "type": "object",
    "properties": {
      "command": {"type": "string", "description": "Shell command to execute"}
    },
    "required": ["command"]
  }
}'

_tool_shell() {
  local input="$1"
  local cmd
  cmd="$(printf '%s' "$input" | jq -r '.command // empty')"
  [[ -z "$cmd" ]] && { printf '{"error":"command required"}'; return; }

  case "$cmd" in
    *"rm -rf /"*|*"mkfs"*|*":(){:|:&};:"*)
      printf '{"error":"blocked: dangerous command pattern"}'
      return ;;
  esac

  local output=""
  if command -v timeout &>/dev/null; then
    output="$(timeout "$TOOL_SHELL_TIMEOUT" bash -c "$cmd" 2>&1)" || true
  elif command -v gtimeout &>/dev/null; then
    output="$(gtimeout "$TOOL_SHELL_TIMEOUT" bash -c "$cmd" 2>&1)" || true
  else
    output="$(bash -c "$cmd" 2>&1)" || true
  fi

  (( ${#output} > 102400 )) && output="${output:0:102400}... [truncated]"
  jq -nc --arg out "$output" '{output:$out}'
}
