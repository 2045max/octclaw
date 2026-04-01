config_init() {
  mkdir -p "$OCTCLAW_STATE"
  [[ -f "$OCTCLAW_CONFIG" ]] || printf '{}' > "$OCTCLAW_CONFIG"
}

config_get() {
  local key="$1" default="${2:-}"
  [[ -f "$OCTCLAW_CONFIG" ]] || { printf '%s' "$default"; return; }
  local val
  val="$(jq -r "$key // empty" < "$OCTCLAW_CONFIG" 2>/dev/null)"
  [[ -n "$val" ]] && printf '%s' "$val" || printf '%s' "$default"
}

config_set() {
  local key="$1" value="$2"
  config_init
  local tmp
  tmp="$(jq "$key = $value" < "$OCTCLAW_CONFIG")"
  printf '%s\n' "$tmp" > "$OCTCLAW_CONFIG"
}

# Load env vars from state dir .env file
_load_env() {
  local env_file="$OCTCLAW_STATE/.env"
  [[ -f "$env_file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" =~ ^[A-Za-z_][A-Za-z_0-9]*= ]] && export "$line"
  done < "$env_file"
}

# Resolve API key: explicit > env > config
_resolve_api_key() {
  local key="${API_KEY:-${OPENAI_API_KEY:-}}"
  [[ -n "$key" ]] && { printf '%s' "$key"; return; }
  key="$(config_get '.api_key' '')"
  [[ -n "$key" ]] && { printf '%s' "$key"; return; }
  # Try provider-specific keys
  for var in ANTHROPIC_API_KEY DEEPSEEK_API_KEY GROQ_API_KEY; do
    [[ -n "${!var:-}" ]] && { printf '%s' "${!var}"; return; }
  done
  die "No API key found. Set API_KEY, OPENAI_API_KEY, or run: oct config set .api_key '\"sk-...\"'"
}

_resolve_api_base() {
  local base="${API_BASE:-}"
  [[ -n "$base" ]] && { printf '%s' "$base"; return; }
  base="$(config_get '.api_base' '')"
  [[ -n "$base" ]] && { printf '%s' "$base"; return; }
  printf 'https://api.openai.com/v1'
}

_resolve_model() {
  local m="${MODEL:-}"
  [[ -n "$m" ]] && { printf '%s' "$m"; return; }
  m="$(config_get '.model' '')"
  [[ -n "$m" ]] && { printf '%s' "$m"; return; }
  printf 'gpt-4o'
}

