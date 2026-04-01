# Command: doctor — check dependencies and config

cmd_doctor() {
  printf '\033[36m🐙 OctClaw v%s\033[0m\n\n' "$OCTCLAW_VERSION"
  for cmd in bash jq curl socat; do
    printf '  %-12s' "$cmd"
    command -v "$cmd" &>/dev/null \
      && printf '\033[32m✓\033[0m %s\n' "$(command -v "$cmd")" \
      || printf '\033[31m✗\033[0m not found\n'
  done
  printf '\n'
  printf '  %-12s%s\n' "state_dir" "$OCTCLAW_STATE"
  printf '  %-12s%s\n' "config" "$OCTCLAW_CONFIG"
  printf '  %-12s%s\n' "model" "$(_resolve_model 2>/dev/null || echo 'gpt-4o')"
  printf '  %-12s%s\n' "api_base" "$(_resolve_api_base 2>/dev/null)"
  local has_key="false"
  for var in API_KEY OPENAI_API_KEY ANTHROPIC_API_KEY DEEPSEEK_API_KEY GROQ_API_KEY; do
    [[ -n "${!var:-}" ]] && has_key="true"
  done
  [[ "$(config_get '.api_key' '' 2>/dev/null)" != "" ]] && has_key="true"
  printf '  %-12s' "api_key"
  [[ "$has_key" == "true" ]] && printf '\033[32m✓\033[0m configured\n' || printf '\033[31m✗\033[0m not set\n'
  printf '\n'

  # Plugin status
  local pdir="$OCT_ROOT/plugins"
  local pcount=0
  if [[ -d "$pdir" ]]; then
    pcount="$(find "$pdir" -name '*.sh' ! -name 'base.sh' ! -name 'loader.sh' 2>/dev/null | wc -l | tr -d '[:space:]')"
  fi
  printf '  %-12s%s\n' "plugins" "$pcount loaded"
}
