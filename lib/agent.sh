agent_run() {
  local session_id="${1:-default}"
  local user_message="$2"

  [[ -z "$user_message" ]] && die "message is required"

  local model
  model="$(_resolve_model)"
  local sess_file
  sess_file="$(session_file "$session_id")"

  # System prompt
  local system_prompt
  system_prompt="$(_build_system_prompt)"

  # Tools
  local tools
  tools="$(tools_spec)"

  # Append user message
  session_append "$sess_file" "user" "$user_message"

  local iteration=0 max_turns="${MAX_TURNS:-10}" final_text=""

  while (( iteration < max_turns )); do
    iteration=$((iteration + 1))
    debug "Iteration $iteration/$max_turns"

    local messages
    messages="$(session_build_messages "$sess_file")"

    local response
    response="$(call_api "$model" "$system_prompt" "$messages" "$tools")"

    local stop_reason
    stop_reason="$(printf '%s' "$response" | jq -r '.stop_reason // "end_turn"')"

    local text
    text="$(printf '%s' "$response" | jq -r '[.content[]? | select(.type=="text") | .text] | join("")')"
    [[ -n "$text" ]] && final_text="$text"

    if [[ "$stop_reason" == "tool_use" ]]; then
      [[ -n "$text" ]] && session_append "$sess_file" "assistant" "$text"

      local tool_calls
      tool_calls="$(printf '%s' "$response" | jq -c '[.content[]? | select(.type=="tool_use")]')"
      local n
      n="$(printf '%s' "$tool_calls" | jq 'length')"

      local i=0
      while (( i < n )); do
        local tc
        tc="$(printf '%s' "$tool_calls" | jq -c ".[$i]")"
        local tname tid tinput
        tname="$(printf '%s' "$tc" | jq -r '.name')"
        tid="$(printf '%s' "$tc" | jq -r '.id')"
        tinput="$(printf '%s' "$tc" | jq -c '.input')"

        info "Tool: $tname"
        session_append_tool_call "$sess_file" "$tname" "$tinput" "$tid"

        local result
        result="$(tool_execute "$tname" "$tinput" 2>&1)" || true

        local is_error="false"
        printf '%s' "$result" | jq -e '.error' &>/dev/null && is_error="true"

        session_append_tool_result "$sess_file" "$tid" "$result" "$is_error"
        debug "Tool result (${#result} chars)"

        i=$((i + 1))
      done
      continue
    fi

    # End turn — save and break
    [[ -n "$text" ]] && session_append "$sess_file" "assistant" "$text"
    break
  done

  (( iteration >= max_turns )) && warn "Reached max tool iterations ($max_turns)"

  # Prune history
  session_prune "$sess_file" 200

  printf '%s' "$final_text"
}

