# Strategy mode: run inside zsh-autosuggestions instead of beside it.
#
# zsh-autosuggestions and zsh-ghost-ai both draw with POSTDISPLAY, so they
# can't both draw. In strategy mode zsh-autosuggestions keeps drawing and
# accepting, and asks us for a suggestion only when its earlier strategies
# (history by default) have none: ZSH_AUTOSUGGEST_STRATEGY=(history ghost_ai).
#
#   zstyle ':ghost-ai:*' mode auto        # default: strategy if zsh-autosuggestions is loaded
#   zstyle ':ghost-ai:*' mode strategy    # always
#   zstyle ':ghost-ai:*' mode standalone  # never (both will draw)

# Decide the mode at the first prompt, when every plugin has loaded, so the
# order of the plugins in .zshrc doesn't matter.
_zga_resolve_mode() {
  _zga_get mode
  case $REPLY in
    strategy)   _ZGA_MODE=strategy ;;
    standalone) _ZGA_MODE=standalone ;;
    *) if (( $+functions[_zsh_autosuggest_start] )); then _ZGA_MODE=strategy
       else _ZGA_MODE=standalone; fi ;;
  esac
  if [[ $_ZGA_MODE == strategy ]]; then
    _zga_reset 2>/dev/null
    # Ask us after whatever the user already has (history by default).
    local -a strategies=(${=ZSH_AUTOSUGGEST_STRATEGY:-history})
    (( ${strategies[(Ie)ghost_ai]} )) || strategies+=(ghost_ai)
    # zsh-autosuggestions declares this as an array (users may set a string);
    # a plain array assignment works for both and keeps it global.
    ZSH_AUTOSUGGEST_STRATEGY=($strategies)
  fi
}

# Called by zsh-autosuggestions with the line; sets `suggestion` to the full
# suggested line. In async mode (zsh-autosuggestions' default) this runs in a
# background process that is killed on the next keystroke, so the debounce
# wait below costs nothing and a slow model never blocks typing.
_zsh_autosuggest_strategy_ghost_ai() {
  emulate -L zsh
  setopt extendedglob
  typeset -g suggestion=""
  local buffer=$1
  [[ $_ZGA_MODE == strategy ]] || return 0
  (( _ZGA_ENABLED )) || return 0
  # Synchronous mode would freeze typing while the model answers: refuse.
  (( ${+ZSH_AUTOSUGGEST_USE_ASYNC} )) || return 0
  [[ $buffer == *$'\n'* || $buffer == [[:space:]]# ]] && return 0
  _zga_get min-chars
  (( $#buffer >= REPLY )) || return 0
  _zga_ignored "$buffer" && return 0
  if _zga_cache_get "$buffer"; then
    suggestion="$buffer$REPLY"
    return 0
  fi
  _zga_get debounce
  (( REPLY > 0 )) && zselect -t $(( (REPLY + 9) / 10 ))
  _zga_complete "$buffer" && [[ -n $REPLY ]] && suggestion="$buffer$REPLY"
  return 0
}
