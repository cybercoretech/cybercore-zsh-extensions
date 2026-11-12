# Background requests: typing never waits for the model.
#
#   _zga_request  starts a worker for the current BUFFER (the previous one is
#                 cancelled first) and registers a zle -F handler on its output
#   worker        a process substitution: waits out the debounce, asks the
#                 provider, prints one line of ghost text
#   handler       reads that line and applies it, but only if the line still
#                 reads as it did when the request was made
#
# Cancelling closes the worker's fd (its handler goes with it, so a stale
# reply can never land) and kills the worker.

typeset -gi _ZGA_FD=0 _ZGA_PID=0
typeset -g _ZGA_REQ_BUFFER=""

_zga_cancel() {
  if (( _ZGA_FD )); then
    zle -F $_ZGA_FD 2>/dev/null
    exec {_ZGA_FD}<&- 2>/dev/null
    _ZGA_FD=0
  fi
  if (( _ZGA_PID )); then
    kill -TERM $_ZGA_PID 2>/dev/null
    _ZGA_PID=0
  fi
}

_zga_request() {
  _zga_cancel
  _zga_get debounce
  local debounce=$REPLY
  _ZGA_REQ_BUFFER=$BUFFER
  exec {_ZGA_FD}< <(_zga_worker "$BUFFER" "$debounce")
  _ZGA_PID=${sysparams[procsubstpid]:-0}
  zle -F $_ZGA_FD _zga_on_reply
}

# Runs in the background process.
_zga_worker() {
  # Debounce: a keystroke within this time cancels us before we send.
  (( $2 > 0 )) && zselect -t $(( ($2 + 9) / 10 ))
  _zga_complete "$1"
  print -r -- "$REPLY"
}

# zle -F handler: <fd> [error]
_zga_on_reply() {
  local fd=$1 line=""
  if (( fd != _ZGA_FD )); then
    # Not the current request's fd: a leftover registration. Drop it.
    zle -F $fd 2>/dev/null
    return 0
  fi
  if ! IFS= read -r -t 0 -u $fd line; then
    # Nothing to read yet. fd numbers are reused, so a notification left over
    # from the cancelled worker can arrive for the new one while it's still
    # running: keep waiting. Only a worker that has exited ends the request.
    if (( _ZGA_PID )) && kill -0 $_ZGA_PID 2>/dev/null; then
      return 0
    fi
  fi
  zle -F $fd 2>/dev/null
  exec {fd}<&- 2>/dev/null
  _ZGA_FD=0 _ZGA_PID=0
  zle _zga-apply -- "$_ZGA_REQ_BUFFER" "$line"
}

# Widget wrapper: only widgets may change POSTDISPLAY from a handler.
_zga_apply_widget() {
  _zga_apply "$1" "$2"
}
