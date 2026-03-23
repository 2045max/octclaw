# Tools index — load all tools, assemble spec, dispatch calls

_OCT_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools"

source "$_OCT_TOOLS_DIR/read.sh"
source "$_OCT_TOOLS_DIR/write.sh"
source "$_OCT_TOOLS_DIR/edit.sh"
source "$_OCT_TOOLS_DIR/shell.sh"
source "$_OCT_TOOLS_DIR/grep.sh"
source "$_OCT_TOOLS_DIR/find.sh"

tools_spec() {
  jq -s '.' <<EOF
$read_file_spec
$write_file_spec
$edit_spec
$shell_spec
$grep_spec
$find_spec
EOF
}

tool_execute() {
  local name="$1" input="$2"
  debug "Tool call: $name"
  case "$name" in
    read_file)  _tool_read_file "$input" ;;
    write_file) _tool_write_file "$input" ;;
    edit)       _tool_edit "$input" ;;
    shell)      _tool_shell "$input" ;;
    grep)       _tool_grep "$input" ;;
    find)       _tool_find "$input" ;;
    *)          printf '{"error":"unknown tool: %s"}' "$name" ;;
  esac
}
