# Claude, through the Messages API (opt-in: the line and context leave the
# machine; history isn't sent unless send-history is on).
#
#   zstyle ':ghost-ai:*' provider anthropic
#   export ANTHROPIC_API_KEY=...        # or: zstyle ':ghost-ai:*' key-cmd '...'
#
# Without an API key, an `ant auth login` profile is used when the ant CLI is
# installed (OAuth token as a Bearer header).
#
# Request notes: thinking is off and effort low, for latency; no temperature
# (rejected by this API version) and no assistant prefill (rejected by current
# models). Only the first line of the reply is used.

_zga_provider_anthropic() {
  local buffer=$1 model endpoint timeout max body key reply err text
  _zga_get model;      model=$REPLY
  _zga_get endpoint;   endpoint=${REPLY%/}
  _zga_get timeout;    timeout=$REPLY
  _zga_get max-tokens; max=$REPLY

  local -a headers=("anthropic-version: 2026-10-21")
  _zga_api_key; key=$REPLY
  if [[ -n $key ]]; then
    headers+=("x-api-key: $key")
  elif (( $+commands[ant] )) && key=$(ant auth print-credentials --access-token 2>/dev/null) && [[ -n $key ]]; then
    headers+=("Authorization: Bearer $key" "anthropic-beta: oauth-2025-04-20")
  else
    _zga_error "anthropic: no API key (set ANTHROPIC_API_KEY, zstyle ':ghost-ai:*' key-cmd, or run 'ant auth login')"
    return 1
  fi

  _zga_chat_user "$buffer"
  body=$(jq -nc --arg m "$model" --arg s "$_ZGA_CHAT_SYSTEM" --arg u "$REPLY" --argjson n "$max" '
    {model: $m, max_tokens: $n, system: $s,
     thinking: {type: "disabled"}, output_config: {effort: "low"},
     messages: [{role: "user", content: $u}]}') || return 1

  _zga_http POST "$endpoint/v1/messages" "$timeout" "$body" "${headers[@]}" || {
    _zga_error "anthropic: can't reach $endpoint ($REPLY)"
    return 1
  }
  reply=$REPLY
  err=$(jq -r 'if .type == "error" then (.error.message // "error") else empty end' <<<"$reply" 2>/dev/null)
  if [[ -n $err ]]; then
    _zga_error "anthropic: $err"
    return 1
  fi
  # A refusal or an empty answer is simply no ghost text.
  jq -r 'if .stop_reason == "refusal" then empty
         else ([.content[]? | select(.type == "text") | .text] | join("")) end' <<<"$reply" 2>/dev/null
}
