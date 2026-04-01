_sessions_dir() {
  local d="$OCTCLAW_STATE/sessions"
  mkdir -p "$d"
  printf '%s' "$d"
}

session_file() {
  local sid="${1:-default}"
  sid="$(printf '%s' "$sid" | tr -cd 'A-Za-z0-9_-')"
  [[ -z "$sid" ]] && sid="default"
  printf '%s/%s.jsonl' "$(_sessions_dir)" "$sid"
}

# --- Metadata support ---

_session_meta_file() {
  local sid="${1:-default}"
  sid="$(printf '%s' "$sid" | tr -cd 'A-Za-z0-9_-')"
  printf '%s/%s.meta.json' "$(_sessions_dir)" "$sid"
}

session_meta_init() {
  local sid="${1:-default}"
  local meta_file
  meta_file="$(_session_meta_file "$sid")"
  [[ -f "$meta_file" ]] && return 0
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -nc \
    --arg id "$sid" \
    --arg created "$now" \
    --arg updated "$now" \
    '{id:$id, created:$created, updated:$updated, parent:null, branch_of:null, tags:[], description:""}' \
    > "$meta_file"
}

session_meta_get() {
  local sid="${1:-default}" key="${2:-.}"
  local meta_file
  meta_file="$(_session_meta_file "$sid")"
  [[ -f "$meta_file" ]] || { printf ''; return; }
  jq -r "$key // empty" < "$meta_file" 2>/dev/null
}

session_meta_update() {
  local sid="${1:-default}"
  local meta_file
  meta_file="$(_session_meta_file "$sid")"
  [[ -f "$meta_file" ]] || session_meta_init "$sid"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local tmp
  tmp="$(jq --arg t "$now" '.updated = $t' < "$meta_file")"
  printf '%s\n' "$tmp" > "$meta_file"
}

# --- Branch support ---

session_branch() {
  local src_sid="${1:-default}" new_sid="$2"
  [[ -z "$new_sid" ]] && die "Usage: oct session branch <name>"

  local src_file new_file
  src_file="$(session_file "$src_sid")"
  new_file="$(session_file "$new_sid")"

  [[ -f "$new_file" ]] && die "Session '$new_sid' already exists"

  # Copy conversation history
  if [[ -f "$src_file" ]]; then
    cp "$src_file" "$new_file"
  fi

  # Create metadata linking to parent
  session_meta_init "$new_sid"
  local meta_file
  meta_file="$(_session_meta_file "$new_sid")"
  local tmp
  tmp="$(jq --arg p "$src_sid" '.parent = $p | .branch_of = $p' < "$meta_file")"
  printf '%s\n' "$tmp" > "$meta_file"

  info "Branched '$src_sid' → '$new_sid'"
}

session_merge() {
  local src_sid="$1" dst_sid="${2:-default}"
  [[ -z "$src_sid" ]] && die "Usage: oct session merge <source> [target]"

  local src_file dst_file
  src_file="$(session_file "$src_sid")"
  dst_file="$(session_file "$dst_sid")"

  [[ -f "$src_file" ]] || die "Source session '$src_sid' not found"

  # Append source messages to destination
  if [[ -f "$dst_file" ]]; then
    cat "$src_file" >> "$dst_file"
  else
    cp "$src_file" "$dst_file"
  fi

  session_meta_update "$dst_sid"
  info "Merged '$src_sid' → '$dst_sid'"
}

# --- Core operations ---

session_append() {
  local file="$1" role="$2" content="$3"
  jq -nc --arg r "$role" --arg c "$content" '{role:$r, content:$c}' >> "$file"
  # Update metadata
  local sid
  sid="$(basename "$file" .jsonl)"
  session_meta_update "$sid" 2>/dev/null || true
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
    [.[] | select(.type == "tool_result") | .tool_id] as $result_ids |
    [.[] |
      if .type == "tool_call" then
        if (.tool_id | IN($result_ids[])) then
          {role:"assistant", content:null,
           tool_calls:[{
             id:.tool_id, type:"function",
             function:{name:.tool_name,
               arguments:(if (.tool_input|type)=="string" then .tool_input else (.tool_input|tostring) end)}
           }]}
        else empty end
      elif .type == "tool_result" then
        {role:"tool", tool_call_id:.tool_id, content:(.content // "")}
      else
        {role:.role, content:.content}
      end
    ]'
}

session_clear() {
  local sid="${1:-default}"
  local f
  f="$(session_file "$sid")"
  rm -f "$f"
  rm -f "$(_session_meta_file "$sid")"
}

session_list() {
  local dir
  dir="$(_sessions_dir)"
  printf '%-20s %-8s %-20s %s\n' "SESSION" "MSGS" "UPDATED" "PARENT"
  printf '%-20s %-8s %-20s %s\n' "-------" "----" "-------" "------"
  local f
  for f in "$dir"/*.jsonl; do
    [[ -f "$f" ]] || continue
    local name
    name="$(basename "$f" .jsonl)"
    local lines
    lines="$(wc -l < "$f" | tr -d '[:space:]')"
    local updated="" parent=""
    if [[ -f "$(_session_meta_file "$name")" ]]; then
      updated="$(session_meta_get "$name" '.updated')"
      parent="$(session_meta_get "$name" '.parent')"
    fi
    printf '%-20s %-8s %-20s %s\n' "$name" "$lines" "${updated:--}" "${parent:--}"
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
