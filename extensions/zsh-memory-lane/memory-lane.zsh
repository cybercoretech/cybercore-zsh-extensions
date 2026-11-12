typeset -g CML_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cybercore/memory-lane"
mkdir -p "$CML_DIR/recipes"
cml() {
  local action="$1"; shift
  case "$action" in
    search) [[ -n "$*" ]] || { print "Usage: cml search <term>"; return 2; }; fc -l 1 2>/dev/null | grep -i -- "$*" | tail -n 40 ;;
    project)
      local root="$(git rev-parse --show-toplevel 2>/dev/null)"
      [[ -n "$root" ]] || { print "Not in a Git repository."; return 1; }
      print "Project: $root"
      fc -l 1 2>/dev/null | grep -F -- "$root" | tail -n 30 ;;
    save)
      local name="$1"; shift
      [[ "$name" == [A-Za-z0-9_-]## && -n "$*" ]] || { print "Usage: cml save <name> <recipe text>"; return 2; }
      print -r -- "$*" >| "$CML_DIR/recipes/$name"; print "Recipe saved." ;;
    show) cat "$CML_DIR/recipes/$1" 2>/dev/null || { print "Recipe not found."; return 1; } ;;
    recipes) command ls -1 "$CML_DIR/recipes" ;;
    *) print "Usage: cml search <term> | project | save <name> <text> | show <name> | recipes" ;;
  esac
}
