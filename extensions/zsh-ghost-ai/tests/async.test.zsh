# Background requests: debounce, cancel, stale replies, never blocking.

local -a slow_rc=(
  "zstyle ':ghost-ai:*' provider fake"
  "zstyle ':ghost-ai:*' debounce 200"
  '_zga_provider_fake() {
    print -r -- "$1" >> $HOME/calls.log
    case $1 in
      ("git che")      sleep 1;   print -r -- "checkout main" ;;
      ("docker ps")    print -r -- " -a" ;;
      ("sleepy "*)     sleep 2;   print -r -- "zzz" ;;
    esac
  }'
)

t_case "debounce"
t_start "${slow_rc[@]}"
local c
for c in d o c k e r ' ' p s; do t_type "$c"; done
t_wait_post " -a" 3
t_eq "$D_POST" " -a" "ghost text arrives after typing stops"
local calls=$(<$T_DIR/calls.log)
t_eq "$calls" "docker ps" "keystrokes 50 ms apart send one request, for the final line"

t_case "never blocks"
t_type $'\C-u'
t_type 'sleepy '
t_settle 0.3            # past the debounce: the slow request is in flight
local start=$EPOCHREALTIME
t_type 'abc'
t_dump
local took=$(( EPOCHREALTIME - start ))
t_eq "$D_BUFFER" "sleepy abc" "keys typed during a slow request land at once"
t_eq "$(( took < 0.5 ))" "1" "the line editor answered in under 0.5 s (took ${took[1,4]} s)"

t_case "stale reply dropped"
t_type $'\C-u'
t_type 'git che'
t_settle 0.4            # request sent, reply due in 1 s
t_type 'x'              # the line changed: that reply must never show
t_settle 1.5
t_dump
t_eq "$D_BUFFER|$D_POST" "git chex|" "a reply for an older line is ignored"
t_stop

# Reliability: many cancel-and-restart cycles in a row must each end with
# the reply. (A race in this area, a leftover notification from a killed
# worker closing the next request, showed up in about 1 in 10 runs of
# ghost.test.zsh before _zga_on_reply learned to wait for a live worker.)
t_case "rapid restarts"
t_start "zstyle ':ghost-ai:*' provider fake" "zstyle ':ghost-ai:*' debounce 0" \
  '_zga_provider_fake() { [[ $1 == "git che" ]] && print -r -- "checkout main"; }'
local i got=0
for i in {1..20}; do
  t_type $'\C-u'
  t_type 'git che'
  t_wait_post "ckout main" 2 && (( ++got ))
done
t_eq "$got" "20" "every one of 20 rapid requests got its reply"
t_stop

t_case "cache"
t_start "zstyle ':ghost-ai:*' provider fake" "zstyle ':ghost-ai:*' debounce 0" \
  '_zga_provider_fake() { print -r -- "$1" >> $HOME/calls.log; [[ $1 == "git che" ]] && print -r -- "checkout main"; }'
t_type 'git che'
t_wait_post "ckout main"
t_type $'\C-u'
t_type 'git che'
t_dump
t_eq "$D_POST" "ckout main" "retyping shows the cached ghost text at once"
t_type $'\C-u'
t_type 'git chex'
t_type $'\C-?'
t_dump
t_eq "$D_BUFFER|$D_POST" "git che|ckout main" "backspacing to an answered line shows it again"
local n=${#${(f)"$(<$T_DIR/calls.log)"}[(R)git che]}
t_eq "$(grep -cx 'git che' $T_DIR/calls.log)" "1" "the provider was asked about 'git che' once"
t_stop
