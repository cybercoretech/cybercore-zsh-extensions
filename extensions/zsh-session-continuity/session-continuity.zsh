typeset -g CSC_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cybercore/session-continuity"
mkdir -p "$CSC_DIR"
_csc_file() {
  local root="$(git rev-parse --show-toplevel 2>/dev/null)"
  [[ -n "$root" ]] || root="$PWD"
  local key="$(print -r -- "$root" | tr '/' '_')"
  print -r -- "$CSC_DIR/$key.md"
}
csc() {
  local action="$1"; shift
  local file="$(_csc_file)"
  case "$action" in
    start) print -r -- "# Session: $PWD\n\n## Objective\n$*\n\n## Completed\n\n## Next\n\n## Decisions\n" >| "$file"; print "Session initialized: $file" ;;
    done) print -r -- "- $*" >> "$file"; print "Progress appended." ;;
    next) print -r -- "$*" >| "$CSC_DIR/next-step"; print "Next step saved." ;;
    decision) print -r -- "- $*" >> "$file"; print "Decision appended." ;;
    show) cat "$file" 2>/dev/null || print "No session. Use csc start <objective>." ;;
    handoff)
      cat "$file" 2>/dev/null || print "No session yet."
      [[ -f "$CSC_DIR/next-step" ]] && { print "Immediate next step:"; cat "$CSC_DIR/next-step"; }
      print "Git status:"
      git status --short --branch 2>/dev/null
      ;;
    path) print "$file" ;;
    *) print "Usage: csc start <objective> | done <note> | next <step> | decision <note> | show | handoff | path" ;;
  esac
}
