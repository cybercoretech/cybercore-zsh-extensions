typeset -g CCAUDIT_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cybercore/command-auditor"
mkdir -p "$CCAUDIT_DIR"
typeset -g CCAUDIT_LOG="$CCAUDIT_DIR/session-$(date +%Y%m%d).log"
typeset -g CCAUDIT_PENDING=""
_ccaudit_preexec() {
  CCAUDIT_PENDING="$1"
  print -r -- "$(date -Iseconds) START cwd=$PWD command=$1" >> "$CCAUDIT_LOG"
}
_ccaudit_precmd() {
  local rc=$?
  if [[ -n "$CCAUDIT_PENDING" ]]; then
    print -r -- "$(date -Iseconds) END exit=$rc" >> "$CCAUDIT_LOG"
    CCAUDIT_PENDING=""
  fi
  return $rc
}
ccaudit() {
  case "$1" in
    show) tail -n "${2:-40}" "$CCAUDIT_LOG" 2>/dev/null ;;
    path) print "$CCAUDIT_LOG" ;;
    *) print "Usage: ccaudit show [lines] | path" ;;
  esac
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _ccaudit_preexec
add-zsh-hook precmd _ccaudit_precmd
