# Ghost text display, keys and ZLE hooks.
#
# State
#   _ZGA_SUGGESTION   the full suggested line (BUFFER + ghost text), or empty
#   _ZGA_LAST_BUFFER  BUFFER at the previous redraw, to detect edits
#   _ZGA_QUIET_FOR    a buffer the user dismissed or just accepted: no new
#                     request until the line changes again
#
# Display: POSTDISPLAY holds the ghost text, dimmed by one region_highlight
# entry (the technique zsh-autosuggestions uses). It's only shown while the
# cursor is at the end of the line.

typeset -g _ZGA_SUGGESTION="" _ZGA_LAST_BUFFER="" _ZGA_QUIET_FOR="" _ZGA_LAST_HL=""
typeset -gi _ZGA_ENABLED=1 _ZGA_LAST_STATUS=0
# standalone: we draw the ghost text. strategy: zsh-autosuggestions draws it
# and asks us through _zsh_autosuggest_strategy_ghost_ai (lib/strategy.zsh).
# Empty until decided (mode auto decides at the first prompt).
typeset -g _ZGA_MODE=""
typeset -gA _ZGA_FALLBACK   # "<keymap><keys>" -> widget the key had before us

# Widgets whose edits may start a request. History moves, completion menus,
# pastes and the like never send anything.
typeset -g _ZGA_TRIGGER_WIDGETS='(self-insert|self-insert-unmeta|magic-space|backward-delete-char|vi-backward-delete-char|backward-kill-word|vi-backward-kill-word|delete-char|ghost-ai-accept-word)'

_zga_hl_remove() {
  if [[ -n $_ZGA_LAST_HL ]]; then
    region_highlight=("${(@)region_highlight:#$_ZGA_LAST_HL}")
    _ZGA_LAST_HL=""
  fi
}

# Draw the current suggestion if it extends the buffer and the cursor is at
# the end; otherwise draw nothing.
_zga_show() {
  _zga_hl_remove
  local s=$_ZGA_SUGGESTION
  if (( _ZGA_ENABLED && CURSOR == $#BUFFER && $#s > $#BUFFER )) && [[ ${s[1,$#BUFFER]} == "$BUFFER" ]]; then
    POSTDISPLAY=${s[$#BUFFER+1,-1]}
    _zga_get highlight
    _ZGA_LAST_HL="$#BUFFER $(( $#BUFFER + $#POSTDISPLAY )) $REPLY"
    region_highlight+=("$_ZGA_LAST_HL")
  else
    POSTDISPLAY=""
  fi
}

_zga_hide() {
  _zga_hl_remove
  POSTDISPLAY=""
}

# Forget the suggestion and any request in flight.
_zga_reset() {
  _ZGA_SUGGESTION=""
  _zga_cancel
  _zga_hide
}

# Should this buffer be completed at all?
_zga_wants_request() {
  emulate -L zsh
  setopt extendedglob
  (( _ZGA_ENABLED )) || return 1
  (( CURSOR == $#BUFFER )) || return 1
  [[ $BUFFER == *$'\n'* ]] && return 1          # multi-line edits
  [[ $BUFFER == [[:space:]]# ]] && return 1     # blank
  [[ $BUFFER == "$_ZGA_QUIET_FOR" ]] && return 1
  _zga_get min-chars
  (( $#BUFFER >= REPLY )) || return 1
  _zga_ignored "$BUFFER" && return 1
  [[ $LASTWIDGET == ${~_ZGA_TRIGGER_WIDGETS} ]] || return 1
  return 0
}

# Called on every redraw (zle-line-pre-redraw).
_zga_pre_redraw() {
  [[ $_ZGA_MODE == strategy ]] && return 0   # zsh-autosuggestions draws
  (( _ZGA_ENABLED )) || { [[ -n $POSTDISPLAY ]] && _zga_hide; return 0; }

  if [[ $BUFFER == "$_ZGA_LAST_BUFFER" ]]; then
    _zga_show        # same line: just follow the cursor
    return 0
  fi
  _ZGA_LAST_BUFFER=$BUFFER

  # Typing along the suggestion keeps it, with no new request.
  local s=$_ZGA_SUGGESTION
  if (( $#s > $#BUFFER )) && [[ ${s[1,$#BUFFER]} == "$BUFFER" ]]; then
    _zga_show
    return 0
  fi

  _zga_reset
  _zga_wants_request || return 0

  if _zga_cache_get "$BUFFER"; then
    _ZGA_SUGGESTION="$BUFFER$REPLY"
    _zga_show
    return 0
  fi
  _zga_request
}

# A reply arrived for the line it was asked about.
#   _zga_apply <buffer-it-was-for> <ghost text>
_zga_apply() {
  local for=$1 ghost=$2
  [[ $for == "$BUFFER" && -n $ghost ]] || return 0
  _zga_cache_put "$for" "$ghost"
  _ZGA_SUGGESTION="$for$ghost"
  _zga_show
}

# --- widgets ---------------------------------------------------------------

_zga_fallback() {
  local w=${_ZGA_FALLBACK[$KEYMAP$KEYS]:-$1}
  zle "$w"
}

# → / End: take the whole suggestion, else do what the key did before.
_zga_widget_accept() {
  [[ $_ZGA_MODE == strategy ]] && { _zga_fallback "$1"; return; }
  if [[ -n $POSTDISPLAY ]] && (( CURSOR == $#BUFFER )); then
    BUFFER+=$POSTDISPLAY
    CURSOR=$#BUFFER
    _ZGA_QUIET_FOR=$BUFFER
    _ZGA_SUGGESTION=""
    _zga_hide
  else
    _zga_fallback "$1"
  fi
}
# Fallbacks use the plain widget names (not .forward-char), so another plugin's
# wrapper around them still runs: zsh-autosuggestions accepts through it.
ghost-ai-accept()             { _zga_widget_accept forward-char; }
ghost-ai-accept-end-of-line() { _zga_widget_accept end-of-line; }

# Alt+→ / Alt+f: take the next word of the suggestion.
ghost-ai-accept-word() {
  emulate -L zsh
  setopt extendedglob
  [[ $_ZGA_MODE == strategy ]] && { _zga_fallback forward-word; return; }
  if [[ -n $POSTDISPLAY ]] && (( CURSOR == $#BUFFER )); then
    local word=${(M)POSTDISPLAY##[[:space:]]#[^[:space:]]#}
    [[ -n $word ]] || word=$POSTDISPLAY
    BUFFER+=$word
    CURSOR=$#BUFFER
    _ZGA_LAST_BUFFER=$BUFFER   # the rest stays on screen, no new request
    _zga_show
  else
    _zga_fallback forward-word
  fi
}

# Esc: hide the suggestion for this line.
ghost-ai-dismiss() {
  [[ $_ZGA_MODE == strategy ]] && { _zga_fallback undefined-key; return; }
  if [[ -n $POSTDISPLAY ]]; then
    _ZGA_QUIET_FOR=$BUFFER
    _zga_reset
  else
    _zga_fallback undefined-key
  fi
}

# Alt+g: turn suggestions on or off for this shell.
ghost-ai-toggle() {
  if (( _ZGA_ENABLED )); then
    _ZGA_ENABLED=0
    _zga_reset
    zle -M "ghost-ai: off"
  else
    _ZGA_ENABLED=1
    _ZGA_LAST_BUFFER=""
    zle -M "ghost-ai: on"
  fi
}

# --- hooks -----------------------------------------------------------------

_zga_line_init() {
  if [[ -z $_ZGA_MODE ]]; then
    _zga_resolve_mode
    # Run our redraw hook after any added since we loaded:
    # zsh-syntax-highlighting 0.7 rebuilds region_highlight in its own hook
    # and would wipe the dim highlight if it ran after us.
    add-zle-hook-widget -d line-pre-redraw _zga_pre_redraw
    add-zle-hook-widget line-pre-redraw _zga_pre_redraw
  fi
  _ZGA_LAST_BUFFER=$BUFFER
  _ZGA_QUIET_FOR=""
  _ZGA_SUGGESTION=""
}

# Leave no ghost text in the scrollback when a line is run.
_zga_line_finish() {
  _zga_reset
}

_zga_precmd() {
  _ZGA_LAST_STATUS=$?
}

# _zga_bind <keymap> <keys> <widget>: bind, remembering what the key did.
_zga_bind() {
  local km=$1 keys=$2 widget=$3 prev
  prev=$(bindkey -M "$km" -- "$keys" 2>/dev/null)
  prev=${prev##* }
  if [[ -n $prev && $prev != (undefined-key|ghost-ai-*) ]]; then
    _ZGA_FALLBACK[$km$keys]=$prev
  fi
  bindkey -M "$km" -- "$keys" "$widget"
}

_zga_bind_defaults() {
  local km
  for km in emacs viins; do
    _zga_bind $km '^[[C'    ghost-ai-accept               # →
    _zga_bind $km '^[OC'    ghost-ai-accept               # → (application mode)
    _zga_bind $km '^[[F'    ghost-ai-accept-end-of-line   # End
    _zga_bind $km '^[OF'    ghost-ai-accept-end-of-line
    _zga_bind $km '^E'      ghost-ai-accept-end-of-line
    _zga_bind $km '^[[1;3C' ghost-ai-accept-word          # Alt+→
    _zga_bind $km '^[f'     ghost-ai-accept-word          # Alt+f
    _zga_bind $km '^[g'     ghost-ai-toggle               # Alt+g
  done
  # Esc alone is vi's command mode, so dismiss is only bound for emacs.
  _zga_bind emacs '^[' ghost-ai-dismiss
}

_zga_init() {
  zmodload zsh/system 2>/dev/null
  zmodload zsh/zselect 2>/dev/null
  _zga_is enabled || _ZGA_ENABLED=0

  local w
  for w in ghost-ai-accept ghost-ai-accept-end-of-line ghost-ai-accept-word \
           ghost-ai-dismiss ghost-ai-toggle; do
    zle -N $w
  done
  zle -N _zga-apply _zga_apply_widget

  autoload -Uz add-zle-hook-widget add-zsh-hook
  add-zle-hook-widget line-pre-redraw _zga_pre_redraw
  add-zle-hook-widget line-init _zga_line_init
  add-zle-hook-widget line-finish _zga_line_finish
  add-zsh-hook precmd _zga_precmd

  _zga_is bindkeys && _zga_bind_defaults

  _zga_get provider
  if [[ $REPLY == ollama ]] && (( _ZGA_ENABLED )) && _zga_is warm-up; then
    _zga_ollama_warm
  fi
  return 0
}
