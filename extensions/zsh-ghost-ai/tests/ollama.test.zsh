# Live test against a local Ollama with the default model. Skipped when
# Ollama isn't running or the model isn't pulled (as in CI).

t_case "ollama (live)"
local model=qwen2.5-coder:1.5b
# Check the output, not jq's exit code: jq 1.6 (Ubuntu 22.04) exits 0 with
# -e on empty input, so a missing server looked like a present model.
local found=$(curl -s -m 2 http://localhost:11434/api/tags 2>/dev/null |
  jq -r --arg m "$model" '.models[]? | select(.name == $m) | .name' 2>/dev/null)
if [[ $found != "$model" ]]; then
  print -r -- "  skip  $T_NAME: Ollama with $model not available"
  return 0
fi

t_start "zstyle ':ghost-ai:*' debounce 50"
t_type 'git che'
local end=$(( EPOCHREALTIME + 15 ))
while (( EPOCHREALTIME < end )); do
  t_dump
  [[ -n $D_POST ]] && break
  t_settle 0.2
done
t_eq "$D_BUFFER" "git che" "buffer untouched"
t_eq "${D_POST[1,4]}" "ckou" "the model completes 'git che' (got ${(qqq)D_POST})"
t_type $'\e[C'
t_dump
t_eq "${D_BUFFER[1,12]}" "git checkout" "→ accepts the model's completion"
t_stop
