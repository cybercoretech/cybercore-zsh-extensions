#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT/install.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/zea-tests.XXXXXX")"
PAYLOAD="$TEST_ROOT/payload"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

pass() {
    printf 'PASS: %s\n' "$1"
}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

make_archive() {
    local marker="$1"
    local archive_dir="$2"
    local archive="$archive_dir/test-extension.tar.gz"

    mkdir -p "$archive_dir" "$PAYLOAD/rules"
    rm -f "$PAYLOAD/explain-autofix.zsh"
    printf '# test payload %s\n' "$marker" > "$PAYLOAD/explain-autofix.zsh"
    printf '# test rule\n' > "$PAYLOAD/rules/test.conf"

    tar -czf "$archive" -C "$PAYLOAD" .
    printf '%s\n' "$archive"
}

mkdir -p "$TEST_ROOT/home"
export HOME="$TEST_ROOT/home"

# Help and argument validation.
if "$INSTALLER" --help > "$TEST_ROOT/help.out" 2>&1; then
    grep -q -- '--from' "$TEST_ROOT/help.out" ||
        fail "help output does not document --from"
    pass "help output"
else
    fail "--help returned a failure status"
fi

if "$INSTALLER" --definitely-invalid-option > "$TEST_ROOT/invalid.out" 2>&1; then
    fail "unknown option was accepted"
fi

grep -q 'unknown option' "$TEST_ROOT/invalid.out" ||
    fail "unknown option did not produce the expected error"
pass "unknown option rejected"

# Fresh installation from a local archive.
FRESH_ARCHIVE="$(make_archive fresh "$TEST_ROOT/fresh-archive")"
FRESH_TARGET="$TEST_ROOT/fresh-install"
FRESH_RC="$TEST_ROOT/fresh.zshrc"

if ! ZSHRC="$FRESH_RC" "$INSTALLER" \
    --from "$FRESH_ARCHIVE" \
    --dir "$FRESH_TARGET" \
    --no-rc > "$TEST_ROOT/fresh.out" 2>&1; then
    cat "$TEST_ROOT/fresh.out" >&2
    fail "fresh local-archive installation failed"
fi

grep -q 'test payload fresh' "$FRESH_TARGET/explain-autofix.zsh" ||
    fail "fresh installation has unexpected plugin contents"
test -f "$FRESH_TARGET/rules/test.conf" ||
    fail "fresh installation is missing its rules directory"
test ! -e "$FRESH_RC" ||
    fail "--no-rc unexpectedly created the zshrc file"
pass "fresh local-archive installation"

# Upgrade an existing installation.
UPGRADE_ARCHIVE="$(make_archive upgraded "$TEST_ROOT/upgrade-archive")"

if ! ZSHRC="$TEST_ROOT/upgrade.zshrc" "$INSTALLER" \
    --from "$UPGRADE_ARCHIVE" \
    --dir "$FRESH_TARGET" \
    --no-rc > "$TEST_ROOT/upgrade.out" 2>&1; then
    cat "$TEST_ROOT/upgrade.out" >&2
    fail "upgrade installation failed"
fi

grep -q 'test payload upgraded' "$FRESH_TARGET/explain-autofix.zsh" ||
    fail "upgrade did not replace the previous plugin contents"
pass "upgrade replaces existing installation"

# A checksum mismatch must reject the archive and preserve the old install.
BAD_ARCHIVE="$(make_archive tampered "$TEST_ROOT/checksum-archive")"
printf '%064d  %s\n' 0 "$(basename "$BAD_ARCHIVE")" \
    > "$(dirname "$BAD_ARCHIVE")/SHA256SUMS"

if ZSHRC="$TEST_ROOT/checksum.zshrc" "$INSTALLER" \
    --from "$BAD_ARCHIVE" \
    --dir "$FRESH_TARGET" \
    --no-rc > "$TEST_ROOT/checksum.out" 2>&1; then
    fail "archive with an invalid checksum was accepted"
fi

grep -q 'checksum mismatch' "$TEST_ROOT/checksum.out" ||
    fail "checksum failure did not produce the expected error"

grep -q 'test payload upgraded' "$FRESH_TARGET/explain-autofix.zsh" ||
    fail "previous installation was not preserved after checksum failure"
pass "checksum mismatch rejected; previous installation preserved"

# --no-rc must preserve an existing zshrc byte-for-byte.
NO_RC_ARCHIVE="$(make_archive no-rc "$TEST_ROOT/no-rc-archive")"
NO_RC_TARGET="$TEST_ROOT/no-rc-install"
NO_RC_FILE="$TEST_ROOT/no-rc.zshrc"

cat > "$NO_RC_FILE" <<'ZEA_RC'
# existing user configuration
source "$HOME/custom.zsh"
ZEA_RC
cp "$NO_RC_FILE" "$TEST_ROOT/no-rc.expected"

if ! ZSHRC="$NO_RC_FILE" "$INSTALLER" \
    --from "$NO_RC_ARCHIVE" \
    --dir "$NO_RC_TARGET" \
    --no-rc > "$TEST_ROOT/no-rc.out" 2>&1; then
    cat "$TEST_ROOT/no-rc.out" >&2
    fail "--no-rc installation failed"
fi

cmp -s "$NO_RC_FILE" "$TEST_ROOT/no-rc.expected" ||
    fail "--no-rc changed the existing zshrc"
pass "--no-rc preserves existing zshrc"

# --yes must write the marked block, preserve existing content, and avoid duplicates.
YES_ARCHIVE="$(make_archive yes-mode "$TEST_ROOT/yes-archive")"
YES_TARGET="$TEST_ROOT/yes-install"
YES_RC="$TEST_ROOT/yes.zshrc"

printf '# keep this configuration\nexport ZEA_TEST=1\n' > "$YES_RC"

if ! ZSHRC="$YES_RC" "$INSTALLER" \
    --from "$YES_ARCHIVE" \
    --dir "$YES_TARGET" \
    --yes > "$TEST_ROOT/yes.out" 2>&1; then
    cat "$TEST_ROOT/yes.out" >&2
    fail "--yes installation failed"
fi

MARK_BEGIN='# >>> zsh-explain-autofix >>>'
MARK_END='# <<< zsh-explain-autofix <<<'

grep -Fqx '# keep this configuration' "$YES_RC" ||
    fail "--yes did not preserve existing zshrc content"
grep -Fqx 'export ZEA_TEST=1' "$YES_RC" ||
    fail "--yes did not preserve existing environment configuration"
grep -Fqx "$MARK_BEGIN" "$YES_RC" ||
    fail "--yes did not write the beginning marker"
grep -Fqx "$MARK_END" "$YES_RC" ||
    fail "--yes did not write the ending marker"

EXPECTED_SOURCE="source \"$YES_TARGET/explain-autofix.zsh\""
grep -Fqx "$EXPECTED_SOURCE" "$YES_RC" ||
    fail "--yes wrote an incorrect source instruction"

# Running again must replace the managed block, not duplicate it.
if ! ZSHRC="$YES_RC" "$INSTALLER" \
    --from "$YES_ARCHIVE" \
    --dir "$YES_TARGET" \
    --yes > "$TEST_ROOT/yes-repeat.out" 2>&1; then
    cat "$TEST_ROOT/yes-repeat.out" >&2
    fail "repeated --yes installation failed"
fi

BEGIN_COUNT="$(grep -Fxc "$MARK_BEGIN" "$YES_RC" || true)"
END_COUNT="$(grep -Fxc "$MARK_END" "$YES_RC" || true)"

[[ "$BEGIN_COUNT" == 1 && "$END_COUNT" == 1 ]] ||
    fail "repeated --yes installation duplicated the managed block"

grep -Fqx '# keep this configuration' "$YES_RC" ||
    fail "repeated --yes installation removed existing configuration"
pass "--yes writes and updates one managed zshrc block"

printf '\nAll Explain Autofix installer tests passed.\n'
