_tg_api() {
  local method="$1" data="${2:-}"
  local token="${TELEGRAM_BOT_TOKEN:-${TELEGRAM_TOKEN:-${OCTCLAW_TELEGRAM_TOKEN:-}}}"
  local url="https://api.telegram.org/bot${token}/${method}"
  if [[ -n "$data" ]]; then
    curl -sS --max-time 60 -H "Content-Type: application/json" -d "$data" "$url" 2>/dev/null || true
  else
    curl -sS --max-time 60 "$url" 2>/dev/null || true
  fi
}

_tg_send() {
  local chat_id="$1" text="$2"
  (( ${#text} > 4096 )) && text="${text:0:4093}..."
  local data
  data="$(jq -nc --arg c "$chat_id" --arg t "$text" '{chat_id:$c,text:$t}')"
  _tg_api "sendMessage" "$data" >/dev/null
}

_telegram_poll() {
  local token="${TELEGRAM_BOT_TOKEN:-${TELEGRAM_TOKEN:-${OCTCLAW_TELEGRAM_TOKEN:-}}}"
  [[ -z "$token" ]] && { die "TELEGRAM_BOT_TOKEN not set"; return; }

  local me
  me="$(_tg_api "getMe")"
  local bot
  bot="$(printf '%s' "$me" | jq -r '.result.username // "unknown"')"
  info "Telegram bot: @${bot}"

  local offset=0
  while true; do
    local params
    params="$(jq -nc --argjson o "$offset" '{timeout:30,offset:$o,allowed_updates:["message"]}')"
    local res
    res="$(_tg_api "getUpdates" "$params")"

    [[ "$(printf '%s' "$res" | jq -r '.ok // false')" != "true" ]] && { sleep 5; continue; }

    local count
    count="$(printf '%s' "$res" | jq '.result | length')"
    (( count == 0 )) && continue

    local i=0
    while (( i < count )); do
      local update
      update="$(printf '%s' "$res" | jq -c ".result[$i]")"
      local uid
      uid="$(printf '%s' "$update" | jq -r '.update_id // 0')"
      offset=$(( uid + 1 ))

      local chat_id text
      chat_id="$(printf '%s' "$update" | jq -r '.message.chat.id // empty')"
      text="$(printf '%s' "$update" | jq -r '.message.text // empty')"

      if [[ -n "$chat_id" && -n "$text" ]]; then
        debug "Telegram msg from $chat_id: ${text:0:80}"
        local reply
        reply="$(agent_run "tg_${chat_id}" "$text" 2>&1)" || reply="Error: $reply"
        _tg_send "$chat_id" "$reply"
      fi

      (( i++ )) || true
    done
  done
}

