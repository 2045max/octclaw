# Call OpenAI-compatible chat completions API with retry
call_api() {
  local model="$1" system="$2" messages="$3" tools="${4:-}"

  require_cmd curl
  require_cmd jq

  local api_key api_base
  api_key="$(_resolve_api_key)"
  api_base="$(_resolve_api_base)"

  local max_tokens temperature
  max_tokens="$(config_get '.max_tokens' '4096')"
  temperature="$(config_get '.temperature' '0.7')"

  # Build messages array: system + history
  local oai_messages
  oai_messages="$(printf '%s' "$messages" | jq --arg sys "$system" \
    '[{role:"system",content:$sys}] + .')"

  # Convert tool spec to OpenAI function format
  local oai_tools=""
  if [[ -n "$tools" && "$tools" != "[]" && "$tools" != "null" ]]; then
    oai_tools="$(printf '%s' "$tools" | jq '[.[] | {
      type:"function",
      function:{name:.name, description:.description, parameters:.input_schema}
    }]')"
  fi

  # Build request body
  local body
  if [[ -n "$oai_tools" && "$oai_tools" != "[]" ]]; then
    body="$(jq -nc \
      --arg model "$model" \
      --argjson msgs "$oai_messages" \
      --argjson mt "$max_tokens" \
      --argjson temp "$temperature" \
      --argjson tools "$oai_tools" \
      '{model:$model, messages:$msgs, max_tokens:$mt, temperature:$temp, tools:$tools}')"
  else
    body="$(jq -nc \
      --arg model "$model" \
      --argjson msgs "$oai_messages" \
      --argjson mt "$max_tokens" \
      --argjson temp "$temperature" \
      '{model:$model, messages:$msgs, max_tokens:$mt, temperature:$temp}')"
  fi

  debug "API call: model=$model base=$api_base"

  # Retry loop
  local attempt=0 max_retries=3 response="" http_code=""
  local tmp_file
  tmp_file="$(mktemp)"
  trap "rm -f '$tmp_file'" RETURN

  while (( attempt < max_retries )); do
    attempt=$((attempt + 1))
    http_code="$(curl -sS --max-time 120 \
      -o "$tmp_file" -w '%{http_code}' \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $api_key" \
      -d "$body" \
      "${api_base}/chat/completions" 2>/dev/null)" || http_code="000"

    case "$http_code" in
      200|201) break ;;
      429|500|502|503)
        if (( attempt < max_retries )); then
          local delay=$(( 2 ** attempt + RANDOM % 3 ))
          warn "HTTP $http_code, retry $attempt/$max_retries in ${delay}s"
          sleep "$delay"
          continue
        fi ;;
    esac
    break
  done

  response="$(cat "$tmp_file" 2>/dev/null)"

  if [[ "$http_code" != "200" && "$http_code" != "201" ]]; then
    local err_msg
    err_msg="$(printf '%s' "$response" | jq -r '.error.message // .error // "unknown error"' 2>/dev/null)"
    die "API error (HTTP $http_code): $err_msg"
  fi

  # Normalize to internal format (Anthropic-style)
  _normalize_openai_response "$response"
}

_normalize_openai_response() {
  local response="$1"

  local finish_reason
  finish_reason="$(printf '%s' "$response" | jq -r '.choices[0].finish_reason // "stop"')"

  local stop_reason="end_turn"
  case "$finish_reason" in
    tool_calls) stop_reason="tool_use" ;;
    length)     stop_reason="max_tokens" ;;
  esac

  local has_tools
  has_tools="$(printf '%s' "$response" | jq '.choices[0].message.tool_calls | length > 0' 2>/dev/null)"

  if [[ "$has_tools" == "true" ]]; then
    printf '%s' "$response" | jq --arg sr "$stop_reason" '{
      stop_reason: $sr,
      content: [
        (if .choices[0].message.content then {type:"text",text:.choices[0].message.content} else empty end),
        (.choices[0].message.tool_calls[]? | {
          type:"tool_use", id:.id, name:.function.name,
          input:(.function.arguments | fromjson? // {})
        })
      ],
      usage: .usage
    }'
  else
    local text
    text="$(printf '%s' "$response" | jq -r '.choices[0].message.content // ""')"
    # Strip <think> reasoning tags (DeepSeek, MiniMax, etc.)
    if [[ "$text" == *"<think>"* ]]; then
      text="$(printf '%s' "$text" | sed '/<think>/,/<\/think>/d' | sed '/^[[:space:]]*$/d')"
      text="${text#"${text%%[![:space:]]*}"}"
    fi
    printf '%s' "$response" | jq --arg sr "$stop_reason" --arg text "$text" '{
      stop_reason: $sr,
      content: [{type:"text", text:$text}],
      usage: .usage
    }'
  fi
}

