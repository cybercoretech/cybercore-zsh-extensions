# Context: what the model is told. Run in an interactive zsh (for history)
# inside a throwaway git repo.

t_case "context"
local dir=$(mktemp -d "${TMPDIR:-/tmp}/zga-ctx.XXXXXX")
(
  cd $dir && git init -q -b main . && touch Cargo.toml README.md 'with space.txt' &&
  git add . && git -c user.name=t -c user.email=t@t commit -qm init && print change >> README.md
) || t_fail "could not set up the git repo"

local ctx
ctx=$(cd $dir && HOME=$dir zsh -fic "
  source ${(q)ZGA_ROOT}/zsh-ghost-ai.plugin.zsh
  print -s 'cargo build'
  print -s 'pass show github'
  print -s 'export GITHUB_TOKEN=ghp_abcdefghijklmnopqrstuvwxyz0123456789'
  print -s 'curl https://user:hunter2@example.com/x'
  print -s 'git status'
  _ZGA_LAST_STATUS=1
  _zga_context; print -r -- \$REPLY
" 2>&1)

local -a want=(
  "# git: main, uncommitted changes"
  "# files: Cargo.toml README.md 'with space.txt'"
  "# last command exited with status 1"
  "\$ cargo build"
  "\$ curl https://user:<redacted>@example.com/x"
  "\$ git status"
)
local w
for w in $want; do
  if [[ ${(f)ctx} == *"$w"* ]]; then t_ok "has: $w"
  else t_fail "missing ${(qqq)w} in:"$'\n'"$ctx"; fi
done
[[ $ctx == *"zsh on "* && $ctx == *"# cwd: "* ]] && t_ok "OS and directory lines" || t_fail "no OS/cwd line"
[[ $ctx != *pass\ show* ]] && t_ok "ignored history line left out" || t_fail "ignored line was sent"
[[ $ctx != *GITHUB_TOKEN* && $ctx != *ghp_* ]] && t_ok "a line matching the ignore pattern (token) is left out" || t_fail "token line was sent"
[[ $ctx != *hunter2* ]] && t_ok "password in a history line redacted" || t_fail "password leaked"

t_case "remote providers get no history by default"
ctx=$(cd $dir && HOME=$dir zsh -fic "
  zstyle ':ghost-ai:*' provider anthropic
  source ${(q)ZGA_ROOT}/zsh-ghost-ai.plugin.zsh
  print -s 'cargo build'
  _zga_context; print -r -- \$REPLY
" 2>&1)
[[ $ctx != *'$ cargo build'* ]] && t_ok "no history for anthropic" || t_fail "history sent to a remote provider"
ctx=$(cd $dir && HOME=$dir zsh -fic "
  zstyle ':ghost-ai:*' provider anthropic
  zstyle ':ghost-ai:*' send-history yes
  source ${(q)ZGA_ROOT}/zsh-ghost-ai.plugin.zsh
  print -s 'cargo build'
  _zga_context; print -r -- \$REPLY
" 2>&1)
[[ $ctx == *'$ cargo build'* ]] && t_ok "send-history yes opts in" || t_fail "send-history yes ignored"
rm -rf -- $dir
