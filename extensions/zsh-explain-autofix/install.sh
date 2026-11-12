#!/usr/bin/env bash
#
# zsh-explain-autofix installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/cybercoretech/cybercore-zsh-extensions/main/extensions/zsh-explain-autofix/install.sh | bash
#
# Options:
#   --version <tag>   Install a shared monorepo release (default: latest);
#                     "main" installs the development branch, unverified.
#   --yes             Noninteractive mode.
#   --dir <path>      Installation directory.
#   --no-rc           Do not modify the zshrc; print the source instruction.
#   --from <file>     Install from a local extension archive.
#   -h, --help        Show this help.
#
# Release assets:
#   zsh-explain-autofix-<tag>.tar.gz
#   SHA256SUMS
#
# The extension is installed independently from the monorepo.

set -euo pipefail

REPO="cybercoretech/cybercore-zsh-extensions"
EXTENSION="zsh-explain-autofix"
MARK_BEGIN="# >>> zsh-explain-autofix >>>"
MARK_END="# <<< zsh-explain-autofix <<<"

VERSION="${ZEA_VERSION:-}"
YES="${ZEA_YES:-0}"
DIR="${ZEA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zsh-explain-autofix}"
ZSHRC="${ZSHRC:-${ZDOTDIR:-$HOME}/.zshrc}"
NO_RC=0
FROM=""

say()  { printf '%s\n' "$*"; }
info() { printf '\033[1m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
    sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'
}

while (($#)); do
    case "$1" in
        --version)
            (($# >= 2)) || die "--version requires a value"
            VERSION="$2"
            shift
            ;;
        --yes|-y)
            YES=1
            ;;
        --dir)
            (($# >= 2)) || die "--dir requires a path"
            DIR="$2"
            shift
            ;;
        --no-rc)
            NO_RC=1
            ;;
        --from)
            (($# >= 2)) || die "--from requires a file"
            FROM="$2"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown option: $1 (try --help)"
            ;;
    esac
    shift
done

[[ -n "$DIR" ]] || die "installation directory cannot be empty"

case "$VERSION" in
    ""|main) ;;
    -*|*/*|*[!A-Za-z0-9._-]*)
        die "invalid version/tag: $VERSION"
        ;;
esac

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar >/dev/null 2>&1 || die "tar is required"
command -v awk >/dev/null 2>&1 || die "awk is required"
command -v find >/dev/null 2>&1 || die "find is required"

if command -v sha256sum >/dev/null 2>&1; then
    SHA_TOOL="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    SHA_TOOL="shasum"
else
    die "sha256sum or shasum is required for release verification"
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/zea-install.XXXXXX")" ||
    die "could not create temporary directory"

cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT

verify_checksum() {
    local archive="$1"
    local sums="$2"
    local filename="${archive##*/}"
    local expected actual

    expected="$(
        awk -v f="$filename" '
            $2 == f || $2 == "*" f { print $1; exit }
        ' "$sums"
    )"

    [[ -n "$expected" ]] ||
        die "$filename is not listed in SHA256SUMS"

    if [[ "$SHA_TOOL" == "sha256sum" ]]; then
        actual="$(sha256sum "$archive" | awk '{print $1}')"
    else
        actual="$(shasum -a 256 "$archive" | awk '{print $1}')"
    fi

    [[ "$expected" == "$actual" ]] ||
        die "checksum mismatch for $filename"

    info "Checksum verified: $filename"
}

latest_version() {
    local tag

    tag="$(
        curl -fsSL \
            "https://api.github.com/repos/$REPO/releases/latest" |
        awk -F'"' '
            /"tag_name"[[:space:]]*:/ { print $4; exit }
        '
    )" || true

    printf '%s' "$tag"
}

fetch_archive() {
    local base

    if [[ -n "$FROM" ]]; then
        [[ -f "$FROM" ]] || die "archive not found: $FROM"

        ARCHIVE="$TMP/${FROM##*/}"
        cp "$FROM" "$ARCHIVE"

        local local_sums
        local_sums="$(dirname "$FROM")/SHA256SUMS"

        if [[ -f "$local_sums" ]]; then
            verify_checksum "$ARCHIVE" "$local_sums"
        else
            warn "No adjacent SHA256SUMS found; local archive is not verified."
        fi
        return
    fi

    if [[ -z "$VERSION" ]]; then
        VERSION="$(latest_version)"
        [[ -n "$VERSION" ]] ||
            die "could not determine the latest release; specify --version main to install the development branch"
    fi

    if [[ "$VERSION" == "main" ]]; then
        ARCHIVE="$TMP/$EXTENSION-main.tar.gz"
        info "Downloading $EXTENSION from the monorepo main branch"

        curl -fsSL -o "$ARCHIVE" \
            "https://codeload.github.com/$REPO/tar.gz/refs/heads/main" ||
            die "could not download the main branch archive"

        return
    fi

    base="https://github.com/$REPO/releases/download/$VERSION"
    ARCHIVE="$TMP/$EXTENSION-$VERSION.tar.gz"

    info "Downloading $EXTENSION $VERSION"

    curl -fsSL -o "$ARCHIVE" \
        "$base/$EXTENSION-$VERSION.tar.gz" ||
        die "could not download $EXTENSION-$VERSION.tar.gz"

    curl -fsSL -o "$TMP/SHA256SUMS" \
        "$base/SHA256SUMS" ||
        die "could not download SHA256SUMS for $VERSION"

    verify_checksum "$ARCHIVE" "$TMP/SHA256SUMS"
}

install_extension() {
    local unpack="$TMP/unpacked"
    local source_file source_dir parent staging previous

    mkdir -p "$unpack"

    tar -xzf "$ARCHIVE" -C "$unpack" ||
        die "could not unpack extension archive"

    source_file="$(
        find "$unpack" -type f -name explain-autofix.zsh -print -quit
    )"

    [[ -n "$source_file" ]] ||
        die "archive does not contain explain-autofix.zsh"

    source_dir="${source_file%/*}"

    [[ -d "$source_dir/rules" ]] ||
        die "archive is missing the extension rules directory"

    parent="$(dirname "$DIR")"
    mkdir -p "$parent"

    staging="$DIR.new.$$"
    previous="$DIR.old.$$"

    rm -rf "$staging" "$previous"
    mkdir -p "$staging"

    cp -R "$source_dir/." "$staging/" ||
        die "could not stage extension files"

    [[ -f "$staging/explain-autofix.zsh" ]] ||
        die "staged installation is incomplete"

    if [[ -e "$DIR" ]]; then
        mv "$DIR" "$previous" ||
            die "could not move existing installation aside"
    fi

    if ! mv "$staging" "$DIR"; then
        if [[ -e "$previous" ]]; then
            mv "$previous" "$DIR" || true
        fi
        die "could not activate new installation; previous installation restored if possible"
    fi

    rm -rf "$previous"
    info "Installed $EXTENSION to $DIR"
}

rc_block() {
    printf '%s\n' "$MARK_BEGIN"
    printf 'source "%s/explain-autofix.zsh"\n' "$DIR"
    printf '%s\n' "$MARK_END"
}

write_rc() {
    local parent clean updated

    parent="$(dirname "$ZSHRC")"
    mkdir -p "$parent"
    [[ -f "$ZSHRC" ]] || : > "$ZSHRC"

    clean="$TMP/zshrc.clean"
    updated="$TMP/zshrc.updated"

    awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
        $0 == begin { skip = 1; next }
        $0 == end   { skip = 0; next }
        !skip       { print }
    ' "$ZSHRC" > "$clean" ||
        die "could not read $ZSHRC"

    {
        cat "$clean"
        [[ ! -s "$clean" ]] || [[ -z "$(tail -c 1 "$clean")" ]] || printf '\n'
        rc_block
    } > "$updated"

    cat "$updated" > "$ZSHRC" ||
        die "could not update $ZSHRC"

    info "Updated $ZSHRC"
}

confirm_rc() {
    [[ "$NO_RC" == 0 ]] || return 1
    [[ "$YES" == 1 ]] && return 0

    if [[ ! -r /dev/tty ]] || ! (: </dev/tty) 2>/dev/null; then
        warn "No terminal available for confirmation; leaving $ZSHRC unchanged."
        return 1
    fi

    printf 'Add the plugin source block to %s? [y/N] ' "$ZSHRC" >/dev/tty
    local reply
    read -r reply </dev/tty || reply=""

    case "$reply" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

main() {
    info "Installing $EXTENSION"
    say "    Version: ${VERSION:-latest}"
    say "    Target:  $DIR"

    fetch_archive
    install_extension

    if confirm_rc; then
        if [[ -f "$ZSHRC" ]] &&
           grep -qF 'zsh-explain-autofix/explain-autofix.zsh' "$ZSHRC" &&
           ! grep -qF "$MARK_BEGIN" "$ZSHRC"; then
            warn "A legacy unmarked Explain Autofix source line exists in $ZSHRC."
            warn "It was left untouched. Review it to avoid loading the old installation twice."
        fi

        write_rc
    else
        say ""
        say "Add this to $ZSHRC when ready:"
        rc_block
    fi

    say ""
    info "Installation complete."
    say "Restart zsh or run: source \"$ZSHRC\""
    say "Then press Alt+E after a failed command."
}

main "$@"
