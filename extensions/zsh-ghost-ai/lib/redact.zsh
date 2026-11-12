# Ignore patterns and secret redaction.
#
# Two layers protect what's sent to a model:
#   1. Ignore: a line matching the `ignore` pattern is never sent and never
#      completed (the current line), or left out entirely (history).
#   2. Redact: everything that is sent first has secrets replaced with
#      <redacted>: token-shaped strings, secret-looking assignments and
#      flags, Authorization headers and passwords in URLs.

# _zga_ignored <line>: true when the line must never be sent or completed.
_zga_ignored() {
  emulate -L zsh
  setopt extendedglob
  _zga_get ignore
  [[ -n $REPLY && $1 == (#i)${~REPLY} ]]
}

# _zga_redact <text>  → REPLY = text with secrets replaced by <redacted>
_zga_redact() {
  emulate -L zsh
  setopt extendedglob
  local s=$1 r='<redacted>'

  # Token shapes: GitHub, GitLab, Slack, OpenAI/Anthropic-style keys, AWS
  # access keys, JWTs.
  s=${s//gh[pousr]_[[:alnum:]]##/$r}
  s=${s//github_pat_[[:alnum:]_]##/$r}
  s=${s//glpat-[[:alnum:]_-]##/$r}
  s=${s//xox[abposr]-[[:alnum:]-]##/$r}
  s=${s//sk-[[:alnum:]_-](#c16,)/$r}
  s=${s//(AKIA|ASIA)[[:upper:][:digit:]](#c16)/$r}
  s=${s//eyJ[[:alnum:]_-]##.[[:alnum:]_-]##.[[:alnum:]_-]#/$r}

  # Authorization headers: keep the scheme, drop the credential.
  s=${s//(#ib)(authorization:[[:space:]]#(bearer|basic|token)[[:space:]]##)[^[:space:]\"\']##/$match[1]$r}

  # Passwords in URLs: scheme://user:secret@host
  s=${s//(#b)(:\/\/[^\/:@[:space:]]##:)[^@\/[:space:]]##@/$match[1]$r@}

  # export NAME=value: the value of any exported variable.
  s=${s//(#b)(export[[:space:]]##[[:alpha:]_][[:alnum:]_]#=)(\"[^\"]#\"|\'[^\']#\'|[^[:space:]]##)/$match[1]$r}

  # NAME=value where the name sounds secret (TOKEN, SECRET, PASSWORD, API_KEY...).
  s=${s//(#ib)([[:alnum:]_]#(token|secret|passw(or)#d|pass|api_#key|apikey|auth|credential)[[:alnum:]_]#=)(\"[^\"]#\"|\'[^\']#\'|[^[:space:]]##)/$match[1]$r}

  # Secret-sounding flags: --password=x, --token x, ...
  s=${s//(#ib)(--(password|passwd|pass|token|api-key|apikey|secret|auth-token|access-token|client-secret)(=|[[:space:]]##))(\"[^\"]#\"|\'[^\']#\'|[^[:space:]]##)/$match[1]$r}

  REPLY=$s
}
