_sessions_dir() {
  local d="$OCTCLAW_STATE/sessions"
  mkdir -p "$d"
  printf '%s' "$d"
}

session_file() {
  local sid="${1:-default}"
  # Sanitize: only allow alnum, dash, underscore
  sid="$(printf '%s' "$sid" | tr -cd 'A-Za-z0-9_-')"
  [[ -z "$sid" ]] && sid="default"
  printf '%s/%s.jsonl' "$(_sessions_dir)" "$sid"
}

session_append() {
  local file="$1" role="$2" content="$3"
  jq -nc --arg r "$role" --arg c "$content" '{role:$r, content:$c}' >> "$file"
}

session_append_tool_call() {
  local file="$1" name="$2" input="$3" id="$4"
  jq -nc --arg n "$name" --arg id "$id" --argjson inp "$input" \
    '{type:"tool_call", tool_name:$n, tool_id:$id, tool_input:$inp}' >> "$file"
}

session_append_tool_result() {
  local file="$1" id="$2" result="$3" is_error="${4:-false}"
  jq -nc --arg id "$id" --arg r "$result" --arg e "$is_error" \
    '{type:"tool_result", tool_id:$id, content:$r, is_error:($e == "true")}' >> "$file"
}

session_load() {
  local file="$1" max="${2:-50}"
  [[ -f "$file" ]] || { printf '[]'; return; }
  tail -n "$max" "$file" | jq -s '.' 2>/dev/null || printf '[]'
}

session_build_messages() {
  local file="$1"
  local max="${2:-50}"
  local history
  history="$(session_load "$file" "$max")"
  printf '%s' "$history" | jq '
    [.[] |
      if .type == "tool_call" then
        {role:"assistant", content:null,
         tool_calls:[{
           id:.tool_id, type:"function",
           function:{name:.tool_name,
             arguments:(if (.tool_input|type)=="string" then .tool_input else (.tool_input|tostring) end)}
         }]}
      elif .type == "tool_result" then
        {role:"tool", tool_call_id:.tool_id, content:(.content // "")}
      else
        {role:.role, content:.content}
      end
    ]'
}

session_clear() {
  local f
  f="$(session_file "${1:-default}")"
  rm -f "$f"
}

session_list() {
  local dir
  dir="$(_sessions_dir)"
  local f
  for f in "$dir"/*.jsonl; do
    [[ -f "$f" ]] || continue
    local name
    name="$(basename "$f" .jsonl)"
    local lines
    lines="$(wc -l < "$f" | tr -d '[:space:]')"
    printf '%-20s %s messages\n' "$name" "$lines"
  done
}

session_prune() {
  local file="$1" max="${2:-200}"
  [[ -f "$file" ]] || return 0
  local lines
  lines="$(wc -l < "$file" | tr -d '[:space:]')"
  if (( lines > max )); then
    local tmp
    tmp="$(tail -n "$max" "$file")"
    printf '%s\n' "$tmp" > "$file"
    debug "Pruned session to $max lines"
  fi
}

