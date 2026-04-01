# Plugin loader — auto-load plugins from plugins/ directory

plugins_load() {
  local pdir="$OCT_ROOT/plugins"
  [[ -d "$pdir" ]] || return 0

  local f
  for f in "$pdir"/*.sh; do
    [[ -f "$f" ]] || continue
    # Skip framework files
    local base
    base="$(basename "$f")"
    [[ "$base" == "base.sh" || "$base" == "loader.sh" ]] && continue

    debug "Loading plugin: $base"
    source "$f"

    # Call plugin_init if defined
    if declare -f plugin_init &>/dev/null; then
      plugin_init
      unset -f plugin_init 2>/dev/null || true
    fi
  done
}
