TOOL_READ_MAX_LINES="${TOOL_READ_MAX_LINES:-2000}"

read_file_spec='
{
  "name": "read_file",
  "description": "Read file contents. Always read before editing. Supports offset/limit for large files.",
  "input_schema": {
    "type": "object",
    "properties": {
      "path":   {"type": "string", "description": "File path (absolute or relative to cwd)"},
      "offset": {"type": "integer", "description": "Start line (1-indexed, default 1)"},
      "limit":  {"type": "integer", "description": "Max lines to read (default 2000)"}
    },
    "required": ["path"]
  }
}'

_tool_read_file() {
  local input="$1"
  local path offset limit
  path="$(printf '%s' "$input" | jq -r '.path // empty')"
  offset="$(printf '%s' "$input" | jq -r '.offset // 1')"
  limit="$(printf '%s' "$input" | jq -r '.limit // empty')"
  limit="${limit:-$TOOL_READ_MAX_LINES}"

  [[ -z "$path" ]] && { printf '{"error":"path required"}'; return; }
  [[ ! -f "$path" ]] && { jq -nc --arg p "$path" '{error:"file not found",path:$p}'; return; }

  (( offset < 1 )) && offset=1
  (( limit > TOOL_READ_MAX_LINES )) && limit=$TOOL_READ_MAX_LINES

  local total
  total="$(wc -l < "$path" | tr -d '[:space:]')"
  local content
  content="$(tail -n "+$offset" "$path" | head -n "$limit")"
  local end_line=$((offset + limit - 1))
  local truncated="false"
  (( end_line < total )) && truncated="true"

  jq -nc --arg p "$path" --arg c "$content" --argjson o "$offset" \
    --argjson l "$limit" --argjson t "$total" --arg tr "$truncated" \
    '{path:$p,content:$c,offset:$o,limit:$l,totalLines:$t,truncated:($tr=="true")}'
}
