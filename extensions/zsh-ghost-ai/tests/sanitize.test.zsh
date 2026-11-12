# _zga_sanitize: unit tests, run directly in the test runner's shell.

source $ZGA_ROOT/lib/config.zsh
source $ZGA_ROOT/lib/complete.zsh

_s() { _zga_sanitize "$1" "$2"; print -rn -- "$REPLY"; }

t_case "sanitize"
t_eq "$(_s 'git che' 'ckout main')"             "ckout main"   "plain continuation"
t_eq "$(_s 'git che' 'checkout main')"          "ckout main"   "restarted last word"
t_eq "$(_s 'git che' 'git checkout main')"      "ckout main"   "whole line repeated"
t_eq "$(_s 'git ' ' status')"                   "status"       "no double space after a finished word"
t_eq "$(_s 'ls' ' -la')"                        " -la"         "keeps the space a new word needs"
t_eq "$(_s 'ls -' $'la\nrm -rf /')"             "la"           "first line only"
t_eq "$(_s 'ls -' $'```sh\nla\n```')"           "la"           "code fence stripped"
t_eq "$(_s 'ls -' '`la`')"                      "la"           "inline backticks stripped"
t_eq "$(_s 'echo ' $'\e[31mred\e[0m')"           "red"          "ANSI colour codes removed"
t_eq "$(_s 'echo ' $'hi\e]0;pwned\a')"           "hi"           "OSC title sequence removed"
t_eq "$(_s 'echo ' $'a\x07b\x08c')"              "abc"          "control characters removed"
t_eq "$(_s 'echo ' '   ')"                      ""             "whitespace-only reply is empty"
t_eq "$(_s 'echo ' '')"                         ""             "empty reply"
local long=${(l:300::x:)}
t_eq "$(_s 'echo ' "$long")"                    "${(l:200::x:)}" "cut to max-length"
t_eq "$(_s 'ls -' '$ ls -la')"                 "la"           "echoed prompt sign and line"
