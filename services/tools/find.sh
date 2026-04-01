find_spec='
{
  "name": "find",
  "description": "Find files by name pattern. Excludes .git, node_modules, __pycache__ automatically.",
  "input_schema": {
    "type": "object",
    "properties": {
      "pattern": {"type": "string", "description": "File name glob, e.g. *.sh or README*"},
      "path":    {"type": "string", "description": "Directory to search (default: .)"},
      "type":    {"type": "string", "description": "f=files, d=directories (default: f)"}
    },
    "required": ["pattern"]
  }
}'

_tool_find() {
  local input="$1"
  local pattern path type
  pattern="$(printf '%s' "$input" | jq -r '.pattern // empty')"
  path="$(printf '%s' "$input" | jq -r '.path // "."')"
  type="$(printf '%s' "$input" | jq -r '.type // "f"')"

  [[ -z "$pattern" ]] && { printf '{"error":"pattern required"}'; return; }

  local output
  output="$(find "$path" \
    -not -path '*/.git/*' \
    -not -path '*/node_modules/*' \
    -not -path '*/__pycache__/*' \
    -not -path '*/.venv/*' \
    -type "$type" \
    -name "$pattern" \
    2>/dev/null | sort | head -200)" || true

  local count
  count="$(printf '%s' "$output" | grep -c '.' || true)"
  jq -nc --arg o "$output" --argjson c "$count" '{count:$c,files:$o}'
}
