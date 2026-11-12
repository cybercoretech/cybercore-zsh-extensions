#!/bin/sh
# zsh-ghost-ai uninstaller: removes the ~/.zshrc block, the oh-my-zsh link,
# the installed files and the state directory (error log).
#
#   sh ~/.local/share/zsh-ghost-ai/uninstall.sh [--dir <path>] [--yes]
#   ghost-ai uninstall

set -u

MARK_BEGIN="# >>> zsh-ghost-ai >>>"
MARK_END="# <<< zsh-ghost-ai <<<"

info() { printf '\033[1m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

main() {
  DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh-ghost-ai"
  YES=0
  while [ $# -gt 0 ]; do
    case $1 in
      --dir) DIR=${2:?--dir needs a path}; shift ;;
      --yes|-y) YES=1 ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done

  if [ "$YES" != 1 ] && [ -r /dev/tty ] && (: </dev/tty) 2>/dev/null; then
    printf 'Remove zsh-ghost-ai from %s and your ~/.zshrc? [y/N] ' "$DIR" >/dev/tty
    read -r reply </dev/tty || reply=""
    case $reply in [Yy]*) ;; *) echo "Nothing removed."; exit 0 ;; esac
  fi

  rc="${ZDOTDIR:-$HOME}/.zshrc"
  if [ -f "$rc" ] && grep -qxF "$MARK_BEGIN" "$rc"; then
    awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
      $0 == begin { skip = 1; next }
      $0 == end   { skip = 0; next }
      !skip       { print }
    ' "$rc" >"$rc.zga.$$" && cat "$rc.zga.$$" >"$rc" && rm -f "$rc.zga.$$"
    info "Removed the block from $rc"
  fi

  link="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}/plugins/zsh-ghost-ai"
  if [ -L "$link" ]; then rm -f "$link" && info "Removed $link (also drop zsh-ghost-ai from plugins=(...))"; fi

  # Only remove a directory that really is a zsh-ghost-ai install.
  if [ -f "$DIR/zsh-ghost-ai.plugin.zsh" ]; then
    rm -rf "$DIR" && info "Removed $DIR"
  fi
  state="${XDG_STATE_HOME:-$HOME/.local/state}/zsh-ghost-ai"
  [ -d "$state" ] && rm -rf "$state" && info "Removed $state"

  echo "zsh-ghost-ai is uninstalled. Open a new shell to finish: exec zsh"
}

main "$@"
