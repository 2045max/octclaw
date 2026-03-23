gateway_start() {
  local port="${1:-16869}"
  require_cmd socat

  config_init
  _load_env
  info "OctClaw v$OCTCLAW_VERSION"
  info "Listening on http://localhost:$port"
  info "Model: $(_resolve_model)  Base: $(_resolve_api_base)"

  # Telegram: 有 token 就自动启动
  if [[ -n "${TELEGRAM_TOKEN:-}" ]]; then
    _telegram_poll &
  fi

  local oct_bin
  oct_bin="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
  oct_bin="$(cd "$(dirname "$oct_bin")/.." && pwd)/oct"

  socat TCP-LISTEN:"$port",reuseaddr,fork EXEC:"'$oct_bin' _gateway_handle",stderr &
  local pid=$!
  trap "kill $pid 2>/dev/null; kill 0 2>/dev/null; exit" INT TERM
  wait "$pid"
}

_gateway_handle() {
  # Parse HTTP request
  local line
  IFS= read -r line; line="${line%%$'\r'}"
  local method path _
  IFS=' ' read -r method path _ <<< "$line"

  local content_length=0 origin=""
  while IFS= read -r line; do
    line="${line%%$'\r'}"
    [[ -z "$line" ]] && break
    local lower="${line,,}"
    [[ "$lower" == content-length:* ]] && content_length="${line#*: }" && content_length="${content_length%%$'\r'}"
    [[ "$lower" == origin:* ]] && origin="${line#*: }"
  done

  local body=""
  (( content_length > 0 )) && body="$(head -c "$content_length")"

  # Handle CORS preflight
  if [[ "$method" == "OPTIONS" ]]; then
    printf 'HTTP/1.1 204 No Content\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Methods: GET,POST,DELETE,OPTIONS\r\nAccess-Control-Allow-Headers: Content-Type,Authorization\r\n\r\n'
    return
  fi

  # Query string
  local query=""
  [[ "$path" == *"?"* ]] && { query="${path#*\?}"; path="${path%%\?*}"; }

  case "$method $path" in
    "POST /api/chat")
      local sid msg
      sid="$(printf '%s' "$body" | jq -r '.session // "default"' 2>/dev/null)"
      msg="$(printf '%s' "$body" | jq -r '.message // empty' 2>/dev/null)"
      [[ -z "$msg" ]] && { _gw_json 400 '{"error":"message required"}'; return; }
      local reply
      reply="$(agent_run "$sid" "$msg" 2>&1)" || true
      _gw_json 200 "$(jq -nc --arg r "$reply" --arg s "$sid" '{reply:$r, session:$s}')"
      ;;
    "GET /api/sessions")
      local list
      list="$(cd "$(_sessions_dir)" 2>/dev/null && ls *.jsonl 2>/dev/null | sed 's/\.jsonl$//' | jq -R . | jq -s '.' || echo '[]')"
      _gw_json 200 "$(jq -nc --argjson s "$list" '{sessions:$s}')"
      ;;
    "DELETE /api/session/"*)
      local sid="${path#/api/session/}"
      session_clear "$sid"
      _gw_json 200 '{"ok":true}'
      ;;
    "GET /api/config")
      _gw_json 200 "$(jq -nc --arg m "$(_resolve_model)" --arg b "$(_resolve_api_base)" \
        '{model:$m, api_base:$b, version:"'"$OCTCLAW_VERSION"'"}')"
      ;;
    "POST /api/config")
      printf '%s' "$body" > "$OCTCLAW_CONFIG"
      _gw_json 200 '{"ok":true}'
      ;;
    "GET /"|"GET /index.html")
      _gw_html "$(_embedded_ui)"
      ;;
    *)
      _gw_json 404 '{"error":"not found"}'
      ;;
  esac
}

_gw_json() {
  local code="$1" body="$2"
  local status_text="OK"
  (( code == 400 )) && status_text="Bad Request"
  (( code == 404 )) && status_text="Not Found"
  printf 'HTTP/1.1 %d %s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n%s' \
    "$code" "$status_text" "${#body}" "$body"
}

_gw_html() {
  local body="$1"
  printf 'HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
    "${#body}" "$body"
}

