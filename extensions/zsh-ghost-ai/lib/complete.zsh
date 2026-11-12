# One completion: ask the provider, clean the reply.
#
# A provider is a function _zga_provider_<name> that takes the buffer and
# prints the model's raw reply (stdout). It may print anything; _zga_sanitize
# turns that into safe ghost text.

# _zga_complete <buffer>  → REPLY = ghost text (may be empty); status 1 on error
_zga_complete() {
  local buffer=$1 provider raw
  _zga_get provider; provider=$REPLY
  if (( ! $+functions[_zga_provider_$provider] )); then
    _zga_error "unknown provider '$provider'"
    REPLY=""
    return 1
  fi
  raw=$(_zga_provider_$provider "$buffer") || { REPLY=""; return 1; }
  _zga_sanitize "$buffer" "$raw"
  return 0
}

# _zga_sanitize <buffer> <raw reply>  → REPLY = ghost text
# Keeps only what can safely follow the cursor: the first line, no escape or
# control characters, no code fences, never a repeat of what's already typed.
_zga_sanitize() {
  emulate -L zsh
  setopt extendedglob
  local buffer=$1 s=$2

  s=${s//$'\r'/}
  # Drop a leading code fence line (```sh) and keep the first real line.
  s=${s##[[:space:]]#\`\`\`[[:alnum:]]#$'\n'}
  s=${s%%$'\n'*}
  # ANSI CSI / OSC sequences, then any remaining control characters.
  s=${s//$'\e'\[[0-9;?]#[@-~]/}
  s=${s//$'\e'\][^$'\a']#$'\a'/}
  s=${s//[[:cntrl:]]/}
  # A chat model may echo the prompt sign: "$ ls -la".
  [[ $s == '$ '* ]] && s=${s#'$ '}
  # Stray inline-code backticks around the whole reply.
  [[ $s == \`*\` ]] && s=${s#\`} s=${s%\`}
  s=${s%%\`\`\`*}

  # The model repeated the whole line: keep what comes after it.
  if [[ -n $buffer && ${s[1,$#buffer]} == "$buffer" ]]; then
    s=${s[$#buffer+1,-1]}
  else
    # The model restarted the last, unfinished word ("git che" → "checkout").
    local last=${buffer##*[[:space:]]}
    if [[ -n $last && $buffer != *[[:space:]] && ${s[1,$#last]} == "$last" ]]; then
      s=${s[$#last+1,-1]}
    fi
  fi

  # A completion of a finished word needs its leading space; one of an
  # unfinished word must not get one. Models often get this wrong.
  if [[ $buffer == *[[:space:]] ]]; then
    s=${s##[[:space:]]#}
  fi

  _zga_get max-length
  (( $#s > REPLY )) && s=${s[1,REPLY]}
  # Ghost text that is only whitespace helps nobody.
  [[ $s == [[:space:]]# ]] && s=""
  REPLY=$s
}

# Remember the last provider error for `ghost-ai status` and `doctor`.
_zga_error() {
  _zga_state_dir
  print -r -- "$(date '+%F %T') $*" >| "$REPLY/last-error" 2>/dev/null
}

# _zga_http <method> <url> <timeout-seconds> <json-body> [header lines...]
#   → REPLY = response body (status 0), or a short error (status 1)
# Header lines go to curl through a file descriptor, never as arguments, so
# API keys don't show up in `ps`.
_zga_http() {
  local method=$1 url=$2 timeout=$3 body=$4 out errf rc
  shift 4
  _zga_state_dir
  errf="$REPLY/curl.${sysparams[pid]:-$$}.err"
  if (( $# )); then
    out=$(print -r -- "$body" | curl -sS -X "$method" --max-time "$timeout" \
      -H 'Content-Type: application/json' -H @<(print -rl -- "$@") \
      --data-binary @- -- "$url" 2>"$errf")
  else
    out=$(print -r -- "$body" | curl -sS -X "$method" --max-time "$timeout" \
      -H 'Content-Type: application/json' \
      --data-binary @- -- "$url" 2>"$errf")
  fi
  rc=$?
  if (( rc == 0 )); then
    REPLY=$out
  elif (( rc == 28 )); then
    REPLY="timed out after ${timeout}s"
  else
    REPLY=$(<"$errf")
    REPLY=${${REPLY#curl: }:-curl exited $rc}
  fi
  rm -f -- "$errf"
  (( rc == 0 ))
}

