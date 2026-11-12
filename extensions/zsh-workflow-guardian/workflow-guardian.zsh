typeset -g CWG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cybercore/workflow-guardian"
mkdir -p "$CWG_DIR"
_cwg_preexec() {
  print -r -- "$1" >| "$CWG_DIR/last-command"
  if [[ "$1" =~ '(rm[[:space:]]+-[^[:space:]]*r|git[[:space:]]+(reset|clean|push[[:space:]]+--force)|mkfs|dd[[:space:]]+if=)' ]]; then
    print -P "%F{yellow}[Workflow Guardian]%f Potentially destructive command. Review its target and consider a checkpoint."
  fi
  git rev-parse --show-toplevel >/dev/null 2>&1 && print -P "%F{cyan}[Workflow Guardian]%f Git project: $(basename "$(git rev-parse --show-toplevel)")"
}
cwg() {
  case "$1" in
    task) shift; if (( $# )); then print -r -- "$*" >| "$CWG_DIR/task"; else cat "$CWG_DIR/task" 2>/dev/null || print "No task set."; fi ;;
    last) cat "$CWG_DIR/last-command" 2>/dev/null || print "No command recorded." ;;
    checkpoint) git status --short --branch 2>/dev/null || { print "Not in a Git repository."; return 1; }; print "Review status and create a checkpoint manually. No Git operation was executed." ;;
    *) print "Usage: cwg task <text> | cwg last | cwg checkpoint" ;;
  esac
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _cwg_preexec
