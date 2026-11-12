# Strategy mode's ZSH_AUTOSUGGEST_STRATEGY handling: unit tests with a
# stand-in for zsh-autosuggestions' own declaration.

t_case "strategy list"
local out
out=$(zsh -f -c "
  typeset -ga ZSH_AUTOSUGGEST_STRATEGY; ZSH_AUTOSUGGEST_STRATEGY=(history)
  _zga_get() { REPLY=strategy; }; _zga_reset() { :; }; typeset -g _ZGA_MODE=''
  source ${(q)ZGA_ROOT}/lib/strategy.zsh
  _zga_resolve_mode; _zga_resolve_mode
  print -r -- \"\$_ZGA_MODE|\${(t)ZSH_AUTOSUGGEST_STRATEGY}|\${ZSH_AUTOSUGGEST_STRATEGY[*]}\"")
t_eq "$out" "strategy|array|history ghost_ai" "appended after history once, still an array"

out=$(zsh -f -c "
  typeset -g ZSH_AUTOSUGGEST_STRATEGY='match_prev_cmd completion'
  _zga_get() { REPLY=strategy; }; _zga_reset() { :; }; typeset -g _ZGA_MODE=''
  source ${(q)ZGA_ROOT}/lib/strategy.zsh
  _zga_resolve_mode
  print -r -- \"\${ZSH_AUTOSUGGEST_STRATEGY[*]}\"")
t_eq "$out" "match_prev_cmd completion ghost_ai" "a user's own string list is kept, ghost_ai last"

out=$(zsh -f -c "
  _zga_get() { REPLY=auto; }; _zga_reset() { :; }; typeset -g _ZGA_MODE=''
  source ${(q)ZGA_ROOT}/lib/strategy.zsh
  _zga_resolve_mode
  print -r -- \"\$_ZGA_MODE|\${+ZSH_AUTOSUGGEST_STRATEGY}\"")
t_eq "$out" "standalone|0" "auto without zsh-autosuggestions: standalone, nothing touched"
