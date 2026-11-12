# Living with other plugins: zsh-autosuggestions (strategy mode) and
# zsh-syntax-highlighting. Uses the real plugins when they're installed
# (distro packages, or ZGA_TEST_PLUGINS=<dir> holding both clones); skips
# otherwise.

_find_plugin() { # _find_plugin <name> → path to <name>.zsh or empty
  local f
  for f in ${ZGA_TEST_PLUGINS:+$ZGA_TEST_PLUGINS/$1/$1.zsh} \
           /usr/share/zsh/plugins/$1/$1.zsh /usr/share/$1/$1.zsh \
           /opt/homebrew/share/$1/$1.zsh /usr/local/share/$1/$1.zsh; do
    [[ -r $f ]] && { print -r -- $f; return; }
  done
}
local as=$(_find_plugin zsh-autosuggestions) hl=$(_find_plugin zsh-syntax-highlighting)

local fake='_zga_provider_fake() { print -r -- "$1" >> $HOME/calls.log; [[ $1 == "git che" ]] && print -r -- "checkout main"; }'

if [[ -z $as ]]; then
  print -r -- "  skip  strategy mode: zsh-autosuggestions not installed"
else
  t_case "strategy mode"
  t_start "zstyle ':ghost-ai:*' provider fake" "zstyle ':ghost-ai:*' debounce 0" "$fake" \
          "source ${(q)as}"
  t_type 'git che'
  t_wait_post "ckout main" 3
  t_eq "$D_BUFFER|$D_POST" "git che|ckout main" "zsh-autosuggestions shows the AI suggestion"
  t_type $'\e[C'
  t_dump
  t_eq "$D_BUFFER|$D_POST" "git checkout main|" "→ accepts it (zsh-autosuggestions' accept)"
  t_type $'\C-u'
  t_type 'ls'
  t_dump
  local n=0
  [[ -f $T_DIR/calls.log ]] && n=$(grep -c '^ls$' $T_DIR/calls.log)
  t_eq "$n" "0" "min-chars still applies in strategy mode"
  t_stop

  t_case "history first"
  t_start "zstyle ':ghost-ai:*' provider fake" "zstyle ':ghost-ai:*' debounce 0" "$fake" \
          "source ${(q)as}" "print -s 'git cherry-pick abc123'"
  t_type 'git che'
  t_wait_post "rry-pick abc123" 3
  t_eq "$D_POST" "rry-pick abc123" "a history match wins"
  t_eq "$(cat $T_DIR/calls.log 2>/dev/null)" "" "the model isn't asked when history has an answer"
  t_stop

  t_case "load order"
  # zsh-ghost-ai is sourced by t_start after these lines, i.e. after
  # zsh-autosuggestions; here autosuggestions is sourced from a precmd-free
  # hook instead: load it AFTER the plugin via zshrc's last line.
  t_start "zstyle ':ghost-ai:*' provider fake" "zstyle ':ghost-ai:*' debounce 0" "$fake" \
          "_late() { source ${(q)as}; add-zsh-hook -d precmd _late; _zsh_autosuggest_start; }" \
          "autoload -Uz add-zsh-hook; add-zsh-hook precmd _late"
  t_type 'git che'
  t_wait_post "ckout main" 3
  t_eq "$D_POST" "ckout main" "works when zsh-autosuggestions loads after zsh-ghost-ai"
  t_stop

  t_case "synchronous autosuggestions"
  t_start "zstyle ':ghost-ai:*' provider fake" "zstyle ':ghost-ai:*' debounce 0" \
          '_zga_provider_fake() { sleep 2; print -r -- "checkout main"; }' \
          "source ${(q)as}" "unset ZSH_AUTOSUGGEST_USE_ASYNC"
  local start=$EPOCHREALTIME
  t_type 'git che'
  t_dump
  t_eq "$(( EPOCHREALTIME - start < 1 ))" "1" "typing isn't blocked by a slow model"
  t_eq "$D_POST" "" "no AI suggestion in synchronous mode (it would freeze typing)"
  t_stop
fi

if [[ -z $hl ]]; then
  print -r -- "  skip  syntax highlighting: zsh-syntax-highlighting not installed"
else
  t_case "syntax highlighting"
  # The recommended order: zsh-ghost-ai first, zsh-syntax-highlighting last.
  local hlrc=$T_DIR
  t_start "zstyle ':ghost-ai:*' provider fake" "zstyle ':ghost-ai:*' debounce 0" "$fake" \
          "_late() { source ${(q)hl}; add-zsh-hook -d precmd _late; }" \
          "autoload -Uz add-zsh-hook; add-zsh-hook precmd _late"
  t_type 'git che'
  t_wait_post "ckout main" 3
  t_eq "$D_POST" "ckout main" "ghost text with zsh-syntax-highlighting loaded"
  [[ $D_HL == *"7 17 fg=8"* ]] && t_ok "the ghost text stays dimmed (region 7-17 fg=8)" \
                               || t_fail "dim highlight lost: ${(qqq)D_HL}"
  t_type $'\e[C'
  t_dump
  t_eq "$D_BUFFER" "git checkout main" "→ accepts"
  [[ $D_HL != *"fg=8"* ]] && t_ok "no stale dim highlight after accepting" || t_fail "stale highlight: ${(qqq)D_HL}"
  t_stop
fi

# A stand-in for zsh-syntax-highlighting 0.7 (Ubuntu's version), which
# rebuilds region_highlight from scratch in its own redraw hook, loaded after
# zsh-ghost-ai. Runs everywhere, no external code.
t_case "highlight rebuilt by a later hook"
t_start "zstyle ':ghost-ai:*' provider fake" "zstyle ':ghost-ai:*' debounce 0" "$fake" \
        '_wiper() { region_highlight=("0 3 fg=green"); }' \
        "_late() { add-zle-hook-widget line-pre-redraw _wiper; add-zsh-hook -d precmd _late; }" \
        "autoload -Uz add-zsh-hook add-zle-hook-widget; add-zsh-hook precmd _late"
t_type 'git che'
t_wait_post "ckout main" 3
t_dump    # one more full redraw, so the other hook has had its turn
[[ $D_HL == *"7 17 fg=8"* ]] && t_ok "the ghost text stays dimmed" || t_fail "dim highlight lost: ${(qqq)D_HL}"
[[ $D_HL == *"0 3 fg=green"* ]] && t_ok "the other plugin's highlight is kept" || t_fail "other highlight lost: ${(qqq)D_HL}"
t_stop

