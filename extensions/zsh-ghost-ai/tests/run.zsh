#!/usr/bin/env zsh
# Run every tests/*.test.zsh (or the files given) and report.
#   zsh tests/run.zsh
#   zsh tests/run.zsh tests/ghost.test.zsh

emulate -L zsh
setopt extendedglob

typeset -g ZGA_ROOT=${0:A:h:h}
source $ZGA_ROOT/tests/lib.zsh

local -a files=("$@")
(( $#files )) || files=($ZGA_ROOT/tests/*.test.zsh(N))

print -r -- "zsh $ZSH_VERSION"
local f
for f in $files; do
  print -r -- "${f:t}"
  source $f
  t_stop
done

print -r -- ""
print -r -- "$T_PASS passed, $T_FAIL failed"
(( T_FAIL == 0 ))
