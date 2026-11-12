# Settings: zstyles under ':ghost-ai:*', with defaults.
#
#   zstyle ':ghost-ai:*' provider ollama
#
# Every lookup goes through _zga_get so defaults live in one place.

typeset -gA _ZGA_DEFAULTS=(
  provider        ollama
  debounce        150        # ms to wait after the last keystroke
  min-chars       3          # don't ask for lines shorter than this
  highlight       'fg=8'     # how ghost text is drawn
  timeout         2          # seconds per request
  max-tokens      48
  max-length      200        # characters of ghost text, at most
  history-lines   20         # recent commands sent as context
  max-files       50         # file names from the current directory sent as context
  mode            auto       # auto | standalone | strategy (zsh-autosuggestions)
  bindkeys        yes        # bind the default keys
  warm-up         yes        # Ollama: load the model in the background at shell start
  enabled         yes
  # Lines matching this (case-insensitive zsh pattern) are never sent and
  # never completed.
  ignore          '*(pass |passwd|password|gpg|ssh-add|secret|token|api[-_]key|aws_secret)*'
)

# Per-provider defaults. send-history is off for remote providers.
typeset -gA _ZGA_PROVIDER_DEFAULTS=(
  ollama:model          qwen2.5-coder:1.5b
  ollama:endpoint       http://localhost:11434
  ollama:send-history   yes
  openai:model          ''
  openai:endpoint       http://localhost:8080
  openai:send-history   no
  openai:api-key-env    OPENAI_API_KEY
  anthropic:model       claude-haiku-5-5
  anthropic:endpoint    https://api.anthropic.com
  anthropic:send-history no
  anthropic:api-key-env ANTHROPIC_API_KEY
)

# _zga_get <key>  → REPLY
_zga_get() {
  # One-off checks (doctor, test) may wait longer than typing can.
  if [[ $1 == timeout && -n ${_ZGA_TIMEOUT_OVERRIDE-} ]]; then
    REPLY=$_ZGA_TIMEOUT_OVERRIDE
    return 0
  fi
  if zstyle -s ':ghost-ai:settings' "$1" REPLY; then
    return 0
  fi
  local provider
  zstyle -s ':ghost-ai:settings' provider provider || provider=${_ZGA_DEFAULTS[provider]}
  if (( ${+_ZGA_PROVIDER_DEFAULTS[$provider:$1]} )); then
    REPLY=${_ZGA_PROVIDER_DEFAULTS[$provider:$1]}
  else
    REPLY=${_ZGA_DEFAULTS[$1]-}
  fi
}

# _zga_is <key>  → true when the setting is yes/true/on/1
_zga_is() {
  _zga_get "$1"
  [[ ${REPLY:l} == (yes|true|on|1) ]]
}

# Where diagnostics (the last request error) are kept.
_zga_state_dir() {
  REPLY="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-ghost-ai"
  [[ -d $REPLY ]] || mkdir -p "$REPLY" 2>/dev/null
}
