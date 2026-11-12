# Ghost display and keys, driven through a real shell with a fake provider.

local -a fake_rc=(
  "zstyle ':ghost-ai:*' provider fake"
  "zstyle ':ghost-ai:*' debounce 0"
  '_zga_provider_fake() {
    case $1 in
      ("git che") print -r -- "checkout main" ;;
      ("ls -")    print -r -- "la" ;;
      ("gi")      print -r -- "t status" ;;
      ("pass sh") print -r -- "ow github" ;;
      ("echo "*)  print -r -- "world" ;;
    esac
  }'
)

t_case "shows ghost text"
t_start "${fake_rc[@]}"
t_type 'git che'
t_wait_post "ckout main"
t_eq "$D_BUFFER" "git che" "buffer is what was typed"
t_eq "$D_POST" "ckout main" "restarted word is trimmed to the rest"

t_case "typing along"
t_type 'c'
t_dump
t_eq "$D_BUFFER|$D_POST" "git chec|kout main" "matching keystroke keeps the suggestion"

t_case "accept all"
t_type $'\e[C'
t_dump
t_eq "$D_BUFFER|$D_POST" "git checkout main|" "→ inserts the suggestion"
t_eq "$D_CURSOR" "17" "cursor moves to the end"

t_case "accept word"
t_type $'\C-u'
t_type 'git che'
t_wait_post "ckout main"
t_type $'\ef'
t_dump
t_eq "$D_BUFFER|$D_POST" "git checkout| main" "Alt+f takes one word, the rest stays"
t_type $'\ef'
t_dump
t_eq "$D_BUFFER|$D_POST" "git checkout main|" "Alt+f again takes the last word"

t_case "cursor not at end"
t_type $'\C-u'
t_type 'git che'
t_wait_post "ckout main"
t_type $'\e[D'
t_dump
t_eq "$D_POST|$D_CURSOR" "|6" "← hides the ghost text"
t_type $'\e[C'
t_dump
t_eq "$D_BUFFER|$D_POST|$D_CURSOR" "git che|ckout main|7" "→ moves the cursor back and the ghost returns"

t_case "dismiss"
t_type $'\e'
t_settle 0.6
t_dump
t_eq "$D_BUFFER|$D_POST" "git che|" "Esc hides it"

t_case "min-chars"
t_type $'\C-u'
t_type 'gi'
t_settle 0.3
t_dump
t_eq "$D_POST" "" "2 characters ask for nothing"

t_case "ignore pattern"
t_type $'\C-u'
t_type 'pass sh'
t_settle 0.3
t_dump
t_eq "$D_POST" "" "lines matching the ignore pattern are never completed"

t_case "toggle"
t_type $'\C-u'
t_type $'\eg'
t_type 'ls -'
t_settle 0.3
t_dump
t_eq "$D_POST" "" "off: no ghost text"
t_type $'\C-u'
t_type $'\eg'
t_type 'ls -'
t_wait_post "la"
t_eq "$D_POST" "la" "on again"

t_case "run clears"
t_type $'\C-u'
t_type 'echo '
t_wait_post "world"
t_type $'\r'
t_settle 0.3
t_dump
t_eq "$D_BUFFER|$D_POST" "|" "Enter runs the line; the new prompt is clean"
t_stop
