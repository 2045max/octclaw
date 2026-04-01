# Plugin base — interface that plugins implement
#
# To create a plugin, add a .sh file in plugins/ that defines:
#   plugin_name()    — return plugin name
#   plugin_init()    — called on load (register commands, tools, etc.)
#
# Plugins can:
#   - Register new slash commands via plugin_register_command
#   - Add tools via plugin_register_tool
#   - Hook into events via plugin_on_event

declare -A _PLUGIN_COMMANDS 2>/dev/null || true
declare -A _PLUGIN_TOOLS 2>/dev/null || true

plugin_register_command() {
  local name="$1" handler="$2"
  _PLUGIN_COMMANDS["$name"]="$handler"
  debug "Plugin registered command: /$name"
}

plugin_register_tool() {
  local name="$1" spec_var="$2" handler="$3"
  _PLUGIN_TOOLS["$name"]="$handler"
  debug "Plugin registered tool: $name"
}

plugin_run_command() {
  local name="$1"
  shift
  local handler="${_PLUGIN_COMMANDS[$name]:-}"
  [[ -n "$handler" ]] && { "$handler" "$@"; return 0; }
  return 1
}

plugin_run_tool() {
  local name="$1" input="$2"
  local handler="${_PLUGIN_TOOLS[$name]:-}"
  [[ -n "$handler" ]] && { "$handler" "$input"; return 0; }
  return 1
}
