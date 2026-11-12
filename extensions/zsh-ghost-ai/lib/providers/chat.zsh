# Shared by the chat-style providers (Claude, OpenAI-compatible): the
# instructions and the message that carries the line being typed.

typeset -g _ZGA_CHAT_SYSTEM='You are the inline autocomplete of an interactive zsh shell.
The user is typing a command. Reply with ONLY the characters that come after the
cursor to finish that command, on one line: no explanation, no quotes, no code
fences, no leading "$". If the command already looks complete or you are unsure,
reply with nothing.

Examples (line -> reply):
git che -> ckout main
ls - -> la
docker compose  -> up -d
tar -x -> vf archive.tar.gz'

# _zga_chat_user <buffer>  → REPLY = the user message: context + the line
_zga_chat_user() {
  _zga_context
  local ctx=$REPLY
  _zga_redact "$1"
  REPLY="$ctx"$'\n\n'"Complete this line (the cursor is at the end):"$'\n'"\$ $REPLY"
}

# _zga_api_key  → REPLY = the key from key-cmd, else from the env var named by
# api-key-env. Empty when there is none.
_zga_api_key() {
  local cmd var
  if zstyle -s ':ghost-ai:settings' key-cmd cmd && [[ -n $cmd ]]; then
    local -a out=("${(@f)$(eval "$cmd" 2>/dev/null)}")
    REPLY=${out[1]}
    return 0
  fi
  _zga_get api-key-env; var=$REPLY
  REPLY=${var:+${(P)var}}
}
