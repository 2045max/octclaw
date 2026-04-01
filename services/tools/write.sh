write_file_spec='
{
  "name": "write_file",
  "description": "Create or overwrite a file. Creates parent directories automatically. For partial changes use edit instead.",
  "input_schema": {
    "type": "object",
    "properties": {
      "path":    {"type": "string", "description": "File path"},
      "content": {"type": "string", "description": "Full file content to write"}
    },
    "required": ["path", "content"]
  }
}'

_tool_write_file() {
  local input="$1"
  local path content
  path="$(printf '%s' "$input" | jq -r '.path // empty')"
  content="$(printf '%s' "$input" | jq -r '.content // empty')"

  [[ -z "$path" ]] && { printf '{"error":"path required"}'; return; }

  mkdir -p "$(dirname "$path")"
  printf '%s' "$content" > "$path"
  local lines
  lines="$(wc -l < "$path" | tr -d '[:space:]')"
  jq -nc --arg p "$path" --argjson l "$lines" '{ok:true,path:$p,lines:$l}'
}
