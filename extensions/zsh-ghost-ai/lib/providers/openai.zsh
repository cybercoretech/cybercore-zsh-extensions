# Any OpenAI-compatible chat completions server: llama.cpp's server, LM Studio,
# vLLM, OpenRouter, or Ollama's /v1 endpoint.
#
#   zstyle ':ghost-ai:*' provider openai
#   zstyle ':ghost-ai:*' endpoint http://localhost:8080   # base URL, without /v1
#   zstyle ':ghost-ai:*' model <name>
#
# A key (OPENAI_API_KEY or key-cmd) is sent only if set: local servers need none.

_zga_provider_openai() {
  local buffer=$1 model endpoint timeout max body key reply err
  _zga_get model;      model=$REPLY
  _zga_get endpoint;   endpoint=${REPLY%/}
  _zga_get timeout;    timeout=$REPLY
  _zga_get max-tokens; max=$REPLY
  if [[ -z $model ]]; then
    _zga_error "openai: no model set (zstyle ':ghost-ai:*' model <name>)"
    return 1
  fi

  local -a headers=()
  _zga_api_key; key=$REPLY
  [[ -n $key ]] && headers+=("Authorization: Bearer $key")

  _zga_chat_user "$buffer"
  body=$(jq -nc --arg m "$model" --arg s "$_ZGA_CHAT_SYSTEM" --arg u "$REPLY" --argjson n "$max" '
    {model: $m, max_tokens: $n, temperature: 0, stop: ["\n"],
     messages: [{role: "system", content: $s}, {role: "user", content: $u}]}') || return 1

  _zga_http POST "$endpoint/v1/chat/completions" "$timeout" "$body" "${headers[@]}" || {
    _zga_error "openai: can't reach $endpoint ($REPLY)"
    return 1
  }
  reply=$REPLY
  err=$(jq -r '.error | if type == "object" then (.message // "error") elif type == "string" then . else empty end' <<<"$reply" 2>/dev/null)
  if [[ -n $err ]]; then
    _zga_error "openai: $err"
    return 1
  fi
  jq -r '.choices[0].message.content // empty' <<<"$reply" 2>/dev/null
}
