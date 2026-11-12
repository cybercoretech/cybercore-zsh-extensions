cib() {
  local request="$*"
  [[ -n "$request" ]] || { print "Usage: cib <describe your goal>"; return 2; }
  print "Request: $request"
  case "$request" in
    *"Rust files"*) print "Proposal: find . -type f -name '*.rs' -print" ;;
    *"modified in the last two days"*) print "Proposal: find . -type f -mtime -2 -print" ;;
    *"largest files"*) print "Proposal: find . -type f -printf '%s %p\\n' | sort -nr | head -20" ;;
    *"search for "*) print "Proposal: grep -RIn -- 'SEARCH_TERM' . (replace SEARCH_TERM after review)" ;;
    *) print "No local template matches. Ask your AI assistant to draft a command for review."; return 1 ;;
  esac
  print "Review and run manually if approved. Nothing was executed."
}
