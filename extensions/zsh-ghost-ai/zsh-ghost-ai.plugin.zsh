# zsh-ghost-ai: inline LLM ghost-text completions for zsh.
# https://github.com/cybercoretech/zsh-ghost-ai
#
# Load with any plugin manager, or: source /path/to/zsh-ghost-ai.plugin.zsh

# Standard plugin path discovery (works when sourced or loaded by a manager).
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

typeset -g ZGA_ROOT="${0:A:h}"
typeset -g ZGA_VERSION="0.1.0"

# Only interactive shells have a line editor to draw on.
[[ -o interactive ]] || return 0

autoload -Uz is-at-least
if ! is-at-least 5.8; then
  print -u2 "zsh-ghost-ai: needs zsh 5.8 or newer (this is $ZSH_VERSION)"
  return 1
fi

() {
  local f
  for f in config redact context cache complete providers async ghost strategy; do
    if [[ $f == providers ]]; then
      for f in "$ZGA_ROOT"/lib/providers/*.zsh(N); do source "$f"; done
    else
      source "$ZGA_ROOT/lib/$f.zsh"
    fi
  done
}

fpath=("$ZGA_ROOT/functions" $fpath)
autoload -Uz ghost-ai

_zga_init
