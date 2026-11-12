_cgs_status() {
  git rev-parse --show-toplevel >/dev/null 2>&1 || { print "Not in a Git repository."; return 1; }
  print "Repository: $(git rev-parse --show-toplevel)"
  print "Branch: $(git branch --show-current)"
  git status --short --branch
  local upstream
  upstream="$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)" && \
    git rev-list --left-right --count "HEAD...$upstream" | awk '{print "Ahead: "$1", behind: "$2}' || print "No upstream configured."
  [[ -n "$(git ls-files --others --exclude-standard)" ]] && print "Untracked files detected."
}
gits() {
  case "$1" in
    ""|status) _cgs_status ;;
    branches) git branch -vv ;;
    explain) _cgs_status; print "Inspect git diff, git diff --cached, and git reflog before selecting recovery. No changes made." ;;
    *) print "Usage: gits [status|branches|explain]" ;;
  esac
}
_cgs_precmd() {
  git rev-parse --show-toplevel >/dev/null 2>&1 &&
    [[ -n "$(git status --porcelain 2>/dev/null)" ]] &&
    print -P "%F{yellow}[Git Sentinel]%f Uncommitted or untracked changes — run gits."
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _cgs_precmd
