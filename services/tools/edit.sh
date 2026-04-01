edit_spec='
{
  "name": "edit",
  "description": "Edit a file by replacing exact text. old_text must match exactly (including whitespace/indentation). For multiple changes, call edit multiple times.",
  "input_schema": {
    "type": "object",
    "properties": {
      "path":     {"type": "string", "description": "File path to edit"},
      "old_text": {"type": "string", "description": "Exact text to find (must match precisely)"},
      "new_text": {"type": "string", "description": "Replacement text"}
    },
    "required": ["path", "old_text", "new_text"]
  }
}'

_tool_edit() {
  local input="$1"
  local path old_text new_text
  path="$(printf '%s' "$input" | jq -r '.path // empty')"
  old_text="$(printf '%s' "$input" | jq -r '.old_text // empty')"
  new_text="$(printf '%s' "$input" | jq -r '.new_text // empty')"

  [[ -z "$path" ]] && { printf '{"error":"path required"}'; return; }
  [[ ! -f "$path" ]] && { jq -nc --arg p "$path" '{error:"file not found",path:$p}'; return; }
  [[ -z "$old_text" ]] && { printf '{"error":"old_text required"}'; return; }

  local file_content
  file_content="$(cat "$path")"

  if [[ "$file_content" != *"$old_text"* ]]; then
    local first_line
    first_line="$(printf '%s' "$old_text" | head -1)"
    local nearby
    nearby="$(grep -n -F "$first_line" "$path" 2>/dev/null | head -3)"
    if [[ -n "$nearby" ]]; then
      jq -nc --arg p "$path" --arg h "$nearby" \
        '{error:"old_text not found (partial match exists)",path:$p,hint:$h}'
    else
      jq -nc --arg p "$path" '{error:"old_text not found in file",path:$p}'
    fi
    return
  fi

  local count
  count="$(awk -v pat="$old_text" 'BEGIN{c=0} {buf=buf $0 "\n"} END{
    while((i=index(buf,pat))>0){c++;buf=substr(buf,i+length(pat))}; print c
  }' "$path")"
  if (( count > 1 )); then
    jq -nc --arg p "$path" --argjson c "$count" \
      '{error:"old_text matches multiple locations, be more specific",path:$p,matches:$c}'
    return
  fi

  local new_content
  new_content="$(awk -v old="$old_text" -v new="$new_text" '
    BEGIN { buf="" }
    { buf = buf (NR>1 ? "\n" : "") $0 }
    END {
      i = index(buf, old)
      if (i > 0) {
        printf "%s%s%s", substr(buf, 1, i-1), new, substr(buf, i+length(old))
      } else {
        printf "%s", buf
      }
    }
  ' "$path")"

  printf '%s' "$new_content" > "$path"
  jq -nc --arg p "$path" '{ok:true,path:$p}'
}
