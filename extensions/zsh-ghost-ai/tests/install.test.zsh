# install.sh / uninstall.sh against a release tarball built from this tree,
# in a throwaway HOME.

typeset -g I_TMP=$(mktemp -d "${TMPDIR:-/tmp}/zga-inst.XXXXXX")
local rel=$I_TMP/rel ver=v0.0.0-test
mkdir -p $rel $I_TMP/src/zsh-ghost-ai-$ver
# The tree as a release would ship it (no .git, no tests' temp files).
( cd $ZGA_ROOT && tar --exclude=.git --exclude=dist -cf - . ) | tar -xf - -C $I_TMP/src/zsh-ghost-ai-$ver
tar -czf $rel/zsh-ghost-ai-$ver.tar.gz -C $I_TMP/src zsh-ghost-ai-$ver
( cd $rel && sha256sum zsh-ghost-ai-$ver.tar.gz > SHA256SUMS )

# _inst <home> [args...]: run the installer non-interactively in that HOME.
_inst() {
  local home=$1; shift
  env -i HOME=$home PATH=$PATH TERM=dumb TMPDIR=$I_TMP \
    sh $ZGA_ROOT/install.sh --yes --from $rel/zsh-ghost-ai-$ver.tar.gz "$@" </dev/null >$I_TMP/out 2>&1
}
_count_blocks() { grep -cxF '# >>> zsh-ghost-ai >>>' $1/.zshrc; }

t_case "install"
local home=$I_TMP/h1
mkdir -p $home
print -r -- 'export EDITOR=nvim  # my setting' > $home/.zshrc
_inst $home
t_eq "$?" "0" "installer succeeds"
[[ -f $home/.local/share/zsh-ghost-ai/zsh-ghost-ai.plugin.zsh ]] && t_ok "files installed under ~/.local/share" || t_fail "files missing"
grep -q 'Checksum verified' $I_TMP/out && t_ok "checksum verified" || t_fail "checksum not verified: $(<$I_TMP/out)"
t_eq "$(_count_blocks $home)" "1" "one block in .zshrc"
t_eq "$(head -n1 $home/.zshrc)" "export EDITOR=nvim  # my setting" "existing .zshrc content kept"
grep -q "source \"$home/.local/share/zsh-ghost-ai/zsh-ghost-ai.plugin.zsh\"" $home/.zshrc && t_ok "block sources the plugin" || t_fail "no source line"
local v=$(env -i HOME=$home PATH=$PATH TERM=dumb zsh -ic 'ghost-ai version' 2>/dev/null </dev/null)
t_eq "$v" "zsh-ghost-ai 0.1.0" "a new interactive shell loads it"

t_case "rerun"
_inst $home --provider anthropic
t_eq "$(_count_blocks $home)" "1" "rerunning replaces the block, never duplicates it"
grep -qxF "zstyle ':ghost-ai:*' provider anthropic" $home/.zshrc && t_ok "provider choice written to the block" || t_fail "provider line missing"

t_case "syntax highlighting order"
home=$I_TMP/h2; mkdir -p $home
print -rl -- 'export A=1' 'source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' 'export B=2' > $home/.zshrc
_inst $home
local begin=$(grep -nxF '# >>> zsh-ghost-ai >>>' $home/.zshrc | cut -d: -f1)
local zsh_hl=$(grep -n 'zsh-syntax-highlighting.zsh' $home/.zshrc | cut -d: -f1)
t_eq "$(( begin < zsh_hl ))" "1" "block goes before zsh-syntax-highlighting (line $begin < $zsh_hl)"
t_eq "$(tail -n1 $home/.zshrc)" "export B=2" "the rest of .zshrc is untouched"

t_case "no-rc"
home=$I_TMP/h3; mkdir -p $home
_inst $home --no-rc
[[ ! -e $home/.zshrc ]] && t_ok "--no-rc leaves .zshrc alone" || t_fail ".zshrc created"
grep -qF 'source "' $I_TMP/out && t_ok "prints the line to add" || t_fail "no line printed"

t_case "bad checksum"
home=$I_TMP/h4; mkdir -p $home
cp $rel/SHA256SUMS $rel/SHA256SUMS.good
print -r -- "0000000000000000000000000000000000000000000000000000000000000000  zsh-ghost-ai-$ver.tar.gz" > $rel/SHA256SUMS
_inst $home
local rc=$?
mv $rel/SHA256SUMS.good $rel/SHA256SUMS
t_eq "$(( rc != 0 ))" "1" "installer refuses a tarball that doesn't match"
grep -q 'checksum mismatch' $I_TMP/out && t_ok "says why" || t_fail "no mismatch message: $(<$I_TMP/out)"
[[ ! -e $home/.local/share/zsh-ghost-ai && ! -e $home/.zshrc ]] && t_ok "nothing installed" || t_fail "partial install left behind"

t_case "uninstall"
home=$I_TMP/h1
mkdir -p $home/.local/state/zsh-ghost-ai && : > $home/.local/state/zsh-ghost-ai/last-error
env -i HOME=$home PATH=$PATH TERM=dumb sh $home/.local/share/zsh-ghost-ai/uninstall.sh --yes </dev/null >$I_TMP/out 2>&1
t_eq "$?" "0" "uninstaller succeeds"
t_eq "$(grep -c 'zsh-ghost-ai' $home/.zshrc)" "0" "block removed from .zshrc"
t_eq "$(<$home/.zshrc)" "export EDITOR=nvim  # my setting" ".zshrc is back to what it was"
[[ ! -e $home/.local/share/zsh-ghost-ai ]] && t_ok "files removed" || t_fail "files left"
[[ ! -e $home/.local/state/zsh-ghost-ai ]] && t_ok "state removed" || t_fail "state left"

t_case "uninstall safety"
mkdir -p $I_TMP/notours && : > $I_TMP/notours/precious
env -i HOME=$I_TMP/h3 PATH=$PATH TERM=dumb sh $ZGA_ROOT/uninstall.sh --yes --dir $I_TMP/notours </dev/null >/dev/null 2>&1
[[ -f $I_TMP/notours/precious ]] && t_ok "won't delete a directory that isn't a zsh-ghost-ai install" || t_fail "deleted a foreign directory"

rm -rf -- $I_TMP
