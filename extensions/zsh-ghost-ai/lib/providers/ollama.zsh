# Ollama (default): a local model, nothing leaves the machine.
#
# Uses fill-in-the-middle (/api/generate with a suffix), which completes the
# line much better than a plain prompt with code models such as
# qwen2.5-coder. Models without FIM support fall back to a plain prompt.

_zga_provider_ollama() {
  local buffer=$1 model endpoint timeout max prompt body reply err
  _zga_get model;      model=$REPLY
  _zga_get endpoint;   endpoint=${REPLY%/}
  _zga_get timeout;    timeout=$REPLY
  _zga_get max-tokens; max=$REPLY
  if [[ -z $model ]]; then
    _zga_error "ollama: no model set (zstyle ':ghost-ai:*' model <name>)"
    return 1
  fi

  _zga_context
  local ctx=$REPLY
  _zga_redact "$buffer"
  prompt="$ctx"$'\n'"\$ $REPLY"

  local fim=1
  while :; do
    body=$(jq -nc --arg m "$model" --arg p "$prompt" --argjson n "$max" --argjson fim $fim '
      {model: $m, prompt: $p, stream: false, keep_alive: "30m",
       options: {temperature: 0, num_predict: $n, stop: ["\n"]}}
      + (if $fim == 1 then {suffix: "\n"} else {raw: true} end)') || return 1

    _zga_http POST "$endpoint/api/generate" "$timeout" "$body" || {
      if [[ $REPLY == timed\ out* ]]; then
        _zga_error "ollama: no reply within ${timeout}s (the model may still be loading; the first request after a while idle can take several seconds)"
      else
        _zga_error "ollama: can't reach $endpoint ($REPLY)"
      fi
      return 1
    }
    reply=$REPLY
    err=$(jq -r '.error // empty' <<<"$reply" 2>/dev/null)
    if [[ -n $err ]]; then
      if (( fim )) && [[ $err == *(insert|suffix)* ]]; then
        fim=0   # the model has no FIM template: retry as a plain prompt
        continue
      fi
      _zga_error "ollama: $err"
      return 1
    fi
    jq -r '.response // empty' <<<"$reply" 2>/dev/null
    return 0
  done
}

# Load the model in the background so the first keystroke doesn't wait for
# it (Ollama unloads idle models). Never blocks the shell; errors are ignored.
_zga_ollama_warm() {
  local model endpoint
  _zga_get model;    model=$REPLY
  _zga_get endpoint; endpoint=${REPLY%/}
  [[ -n $model ]] || return 0
  {
    jq -nc --arg m "$model" '{model: $m, prompt: "", stream: false, keep_alive: "30m"}' |
      curl -s -m 120 -H 'Content-Type: application/json' --data-binary @- \
        "$endpoint/api/generate" >/dev/null 2>&1
  } &!
}

