grep_spec='
{
  "name": "grep",
  "description": "Search file contents with pattern matching. Returns matching lines with file path and line number.",
  "input_schema": {
    "type": "object",
    "properties": {
      "pattern": {"type": "string", "description": "Search pattern (regex supported)"},
      "path":    {"type": "string", "description": "File or directory to search (default: .)"},
      "include": {"type": "string", "description": "Glob filter, e.g. *.ts (optional)"}
    },
    "required": ["pattern"]
  }
}'

_tool_grep() {
  local input="$1"
  local pattern path include
  pattern="$(printf '%s' "$input" | jq -r '.pattern // empty')"
  path="$(printf '%s' "$input" | jq -r '.path // "."')"
  include="$(printf '%s' "$input" | jq -r '.include // empty')"

  [[ -z "$pattern" ]] && { printf '{"error":"pattern required"}'; return; }

  local args=(-rn --color=never -C 2)
  [[ -n "$include" ]] && args+=(--include="$include")
  args+=(--exclude-dir=.git --exclude-dir=node_modules --exclude-dir=__pycache__ --exclude-dir=.venv)

  local output
  output="$(grep "${args[@]}" -- "$pattern" "$path" 2>&1 | head -100)" || true

  if [[ -z "$output" ]]; then
    jq -nc --arg p "$pattern" '{matches:0,output:"no matches found",pattern:$p}'
  else
    local match_count
    match_count="$(printf '%s' "$output" | grep -v '^--$' | grep -c ':' || true)"
    jq -nc --arg o "$output" --argjson c "$match_count" '{matches:$c,output:$o}'
  fi
}
