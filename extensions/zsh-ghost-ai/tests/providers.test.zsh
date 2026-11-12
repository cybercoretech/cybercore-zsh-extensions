# Chat providers (Claude, OpenAI-compatible) against a local mock server:
# request shape, reply parsing, errors, and keys kept out of `ps`.

(( $+commands[python3] )) || { print -r -- "  skip  providers: python3 not available"; return 0; }

typeset -g M_DIR M_PID M_PORT
m_start() { # m_start <replies-json> [delay]
  M_DIR=$(mktemp -d "${TMPDIR:-/tmp}/zga-mock.XXXXXX")
  print -r -- "$1" > $M_DIR/replies.json
  python3 -I $ZGA_ROOT/tests/mock_server.py $M_DIR/port $M_DIR/log $M_DIR/replies.json ${2:-0} &!
  M_PID=$!
  local i
  for i in {1..50}; do [[ -s $M_DIR/port ]] && break; zselect -t 5; done
  M_PORT=$(<$M_DIR/port)
}
m_stop() { kill $M_PID 2>/dev/null; rm -rf -- $M_DIR; }
# m_field <jq filter>: from the first logged request
m_field() { head -n1 $M_DIR/log | jq -r "$1"; }

# Run one completion in a fresh shell: _c <rc lines...>; prints the ghost text.
_c() {
  zsh -fic "
    $1
    source ${(q)ZGA_ROOT}/zsh-ghost-ai.plugin.zsh
    _zga_complete ${(q)2}; print -rn -- \"\$REPLY\"
  " 2>/dev/null
}

# --- Claude -----------------------------------------------------------------
t_case "anthropic request"
m_start '{"/v1/messages": {"body": {"type": "message", "stop_reason": "end_turn",
  "content": [{"type": "text", "text": "git checkout main"}]}}}'
local rc="export XDG_STATE_HOME=$M_DIR ANTHROPIC_API_KEY=sk-ant-test-0123456789abcdef
zstyle ':ghost-ai:*' provider anthropic
zstyle ':ghost-ai:*' endpoint http://127.0.0.1:$M_PORT"
local ghost=$(_c "$rc" 'git che')
t_eq "$ghost" "ckout main" "reply parsed; the repeated line is trimmed"
t_eq "$(m_field .path)" "/v1/messages" "Messages API path"
t_eq "$(m_field '.headers["anthropic-version"]')" "2026-10-21" "anthropic-version header"
t_eq "$(m_field '.headers["x-api-key"]')" "sk-ant-test-0123456789abcdef" "API key in x-api-key"
t_eq "$(m_field .body.model)" "claude-haiku-5-5" "default model"
t_eq "$(m_field '.body | has("temperature")')" "false" "no temperature (rejected by this API version)"
t_eq "$(m_field .body.thinking.type)" "disabled" "thinking off for latency"
t_eq "$(m_field '.body.messages | length')" "1" "one user message, no prefill"
t_eq "$(m_field '.body.messages[0].content | endswith("$ git che")')" "true" "the line ends the user message"
t_eq "$(m_field '.body.messages[0].content | contains("$ ")')" "true" "context transcript included"
m_stop

t_case "anthropic errors and refusals"
m_start '{"/v1/messages": {"status": 400, "body": {"type": "error",
  "error": {"type": "invalid_request_error", "message": "model: not found"}}}}'
rc="export XDG_STATE_HOME=$M_DIR ANTHROPIC_API_KEY=sk-ant-test-0123456789abcdef
zstyle ':ghost-ai:*' provider anthropic
zstyle ':ghost-ai:*' endpoint http://127.0.0.1:$M_PORT"
ghost=$(_c "$rc" 'git che')
t_eq "$ghost" "" "an API error gives no ghost text"
t_eq "$(cut -d' ' -f3- $M_DIR/zsh-ghost-ai/last-error)" "anthropic: model: not found" "the API's message is recorded"
m_stop
m_start '{"/v1/messages": {"body": {"type": "message", "stop_reason": "refusal",
  "content": [{"type": "text", "text": "rm -rf"}]}}}'
rc="export XDG_STATE_HOME=$M_DIR ANTHROPIC_API_KEY=sk-ant-test-0123456789abcdef
zstyle ':ghost-ai:*' provider anthropic
zstyle ':ghost-ai:*' endpoint http://127.0.0.1:$M_PORT"
t_eq "$(_c "$rc" 'git che')" "" "a refusal gives no ghost text"
m_stop

t_case "anthropic without a key"
rc="export XDG_STATE_HOME=$(mktemp -d) PATH=/usr/bin:/bin; unset ANTHROPIC_API_KEY
zstyle ':ghost-ai:*' provider anthropic"
t_eq "$(_c "$rc" 'git che')" "" "no key, no request"

t_case "key kept out of ps"
m_start '{"/v1/messages": {"body": {"type": "message", "stop_reason": "end_turn",
  "content": [{"type": "text", "text": "x"}]}}}' 1.5
# The key comes from the environment (as it would for a user), so the only
# place it could show up in ps is curl's own arguments.
rc="export XDG_STATE_HOME=$M_DIR
zstyle ':ghost-ai:*' provider anthropic
zstyle ':ghost-ai:*' endpoint http://127.0.0.1:$M_PORT"
ANTHROPIC_API_KEY=sk-ant-SECRET-visible-check-42 _c "$rc" 'git che' >/dev/null &
local bg=$!
zselect -t 70                       # the request is now in flight (server waits 1.5 s)
local curls=$(ps -eo args | grep '^curl ' | grep -c "127.0.0.1:$M_PORT")
local leaks=$(ps -eo args | grep '^curl ' | grep -c 'SECRET-visible-check')
wait $bg
t_eq "$curls" "1" "the request was in flight while ps was checked"
t_eq "$leaks" "0" "the API key never appears in curl's arguments"
m_stop

# --- OpenAI-compatible --------------------------------------------------------
t_case "openai request"
m_start '{"/v1/chat/completions": {"body": {"choices": [{"message": {"role": "assistant", "content": "$ ls -la"}}]}}}'
rc="export XDG_STATE_HOME=$M_DIR OPENAI_API_KEY=sk-test-openai-0123456789
zstyle ':ghost-ai:*' provider openai
zstyle ':ghost-ai:*' model some-model
zstyle ':ghost-ai:*' endpoint http://127.0.0.1:$M_PORT"
t_eq "$(_c "$rc" 'ls -')" "la" "reply parsed; echoed prompt sign and line trimmed"
t_eq "$(m_field '.headers.authorization')" "Bearer sk-test-openai-0123456789" "Bearer key when set"
t_eq "$(m_field .body.model)" "some-model" "model from zstyle"
t_eq "$(m_field '.body.messages[0].role + "," + .body.messages[1].role')" "system,user" "system + user messages"
t_eq "$(m_field '.body.stop[0] == "\n"')" "true" "stops at the end of the line"
m_stop

t_case "openai without a key"
m_start '{"/v1/chat/completions": {"body": {"choices": [{"message": {"content": "la"}}]}}}'
rc="export XDG_STATE_HOME=$M_DIR; unset OPENAI_API_KEY
zstyle ':ghost-ai:*' provider openai
zstyle ':ghost-ai:*' model local
zstyle ':ghost-ai:*' endpoint http://127.0.0.1:$M_PORT"
t_eq "$(_c "$rc" 'ls -')" "la" "local servers work without a key"
t_eq "$(m_field '.headers | has("authorization")')" "false" "no Authorization header without a key"
m_stop

t_case "key-cmd"
m_start '{"/v1/chat/completions": {"body": {"choices": [{"message": {"content": "la"}}]}}}'
rc="export XDG_STATE_HOME=$M_DIR; unset OPENAI_API_KEY
zstyle ':ghost-ai:*' provider openai
zstyle ':ghost-ai:*' model local
zstyle ':ghost-ai:*' key-cmd 'print from-key-cmd'
zstyle ':ghost-ai:*' endpoint http://127.0.0.1:$M_PORT"
_c "$rc" 'ls -' >/dev/null
t_eq "$(m_field '.headers.authorization')" "Bearer from-key-cmd" "key-cmd output is used as the key"
m_stop
