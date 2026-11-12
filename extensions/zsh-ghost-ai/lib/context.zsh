# What the model is told, as a short shell transcript:
#
#   # zsh on Arch Linux
#   # cwd: ~/proj
#   # git: main, uncommitted changes
#   # files: Cargo.toml README.md src
#   # last command exited with status 1
#   $ cargo build            <- recent history (when send-history is on)
#   $ git status
#   $ <the line being typed>  <- added by the provider
#
# Everything here runs in the background worker, never while typing. History
# lines that match the ignore pattern are left out, and every line is
# redacted before it's sent.

typeset -g _ZGA_OS=""

_zga_os() {
  if [[ -z $_ZGA_OS ]]; then
    local line
    if [[ -r /etc/os-release ]]; then
      for line in "${(@f)$(</etc/os-release)}"; do
        [[ $line == PRETTY_NAME=* ]] && { _ZGA_OS=${${line#PRETTY_NAME=}//\"/}; break; }
      done
    fi
    : ${_ZGA_OS:=$(uname -s)}
  fi
  REPLY=$_ZGA_OS
}

# _zga_git → REPLY = "branch" or "branch, uncommitted changes"; 1 outside a repo
_zga_git() {
  (( $+commands[git] )) || return 1
  local branch
  branch=$(git symbolic-ref --short -q HEAD 2>/dev/null) ||
    branch=$(git rev-parse --short -q HEAD 2>/dev/null) || return 1
  [[ -n $branch ]] || return 1
  REPLY=$branch
  local changed
  changed=$(GIT_OPTIONAL_LOCKS=0 git status --porcelain --untracked-files=no 2>/dev/null)
  [[ -n $changed ]] && REPLY+=", uncommitted changes"
  return 0
}

# _zga_history → reply=(redacted recent commands, oldest first)
_zga_history() {
  emulate -L zsh
  setopt extendedglob
  reply=()
  _zga_get history-lines
  local n=$REPLY line
  (( n > 0 )) || return 0
  # fc fails outright if asked to start before the first event, so a new
  # shell with fewer than n entries would send nothing: clamp the start.
  local first=$(( HISTCMD - n ))
  (( first < 1 )) && first=1
  for line in "${(@f)$(fc -ln $first 2>/dev/null)}"; do
    [[ -n $line ]] || continue
    _zga_ignored "$line" && continue
    _zga_redact "$line"
    reply+=("$REPLY")
  done
}

# _zga_context → REPLY = the transcript above the current line
_zga_context() {
  emulate -L zsh
  setopt extendedglob
  local -a lines
  _zga_os
  lines+=("# zsh on $REPLY")
  lines+=("# cwd: ${(D)PWD}")
  _zga_git && lines+=("# git: $REPLY")

  _zga_get max-files
  local max=$REPLY
  if (( max > 0 )); then
    local -a files=(*(N[1,$max]))
    files=(${(q-)files})   # quote each name; joining inside "..." would quote the lot
    (( $#files )) && lines+=("# files: ${(j: :)files}")
  fi

  (( _ZGA_LAST_STATUS )) && lines+=("# last command exited with status $_ZGA_LAST_STATUS")

  if _zga_is send-history; then
    _zga_history
    local h
    for h in "${reply[@]}"; do lines+=("\$ $h"); done
  fi

  _zga_redact "${(F)lines}"
}
