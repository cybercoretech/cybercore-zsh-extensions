#!/bin/sh
#
# zsh-ghost-ai installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/cybercoretech/cybercore-zsh-extensions/main/extensions/zsh-ghost-ai/install.sh | sh
#
# Options:
#   --version <tag>   Install a shared monorepo release (default: latest);
#                     "main" installs the development branch, unverified.
#   --yes             Noninteractive mode; use defaults and ZGA_* variables.
#   --provider <p>    ollama (default), anthropic or openai.
#   --pull            Download the default Ollama model if missing (~1 GB).
#   --dir <path>      Installation directory.
#   --no-rc           Do not modify zshrc; print the source instruction.
#   --from <file>     Install from a local extension archive.
#   -h, --help        Show this help.
#
# Release assets:
#   zsh-ghost-ai-<tag>.tar.gz
#   SHA256SUMS
#
# This extension is installed independently from the monorepo.

set -u

REPO="cybercoretech/cybercore-zsh-extensions"
EXTENSION="zsh-ghost-ai"
OLLAMA_MODEL="qwen2.5-coder:1.5b"
MARK_BEGIN="# >>> zsh-ghost-ai >>>"
MARK_END="# <<< zsh-ghost-ai <<<"

say()  { printf '%s\n' "$*"; }
info() { printf '\033[1m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
    sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//'
}

ask() {
    if [ "$YES" = 1 ] || ! [ -r /dev/tty ] || ! (: </dev/tty) 2>/dev/null; then
        [ "$2" = y ]
        return
    fi

    if [ "$2" = y ]; then hint="[Y/n]"; else hint="[y/N]"; fi
    printf '%s %s ' "$1" "$hint" >/dev/tty
    read -r reply </dev/tty || reply=""

    case "$reply" in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        *) [ "$2" = y ] ;;
    esac
}

prompt() {
    if [ "$YES" = 1 ] || ! [ -r /dev/tty ] || ! (: </dev/tty) 2>/dev/null; then
        printf '%s' "$2"
        return
    fi

    printf '%s [%s] ' "$1" "$2" >/dev/tty
    read -r reply </dev/tty || reply=""
    printf '%s' "${reply:-$2}"
}

install_hint() {
    if command -v pacman >/dev/null 2>&1; then
        say "  sudo pacman -S --needed $*"
    elif command -v apt-get >/dev/null 2>&1; then
        say "  sudo apt-get install $*"
    elif command -v dnf >/dev/null 2>&1; then
        say "  sudo dnf install $*"
    elif command -v brew >/dev/null 2>&1; then
        say "  brew install $*"
    else
        say "  install: $*"
    fi
}

check_requirements() {
    missing=""
    for tool in zsh curl jq tar find awk; do
        command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"
    done

    if [ -n "$missing" ]; then
        say "zsh-ghost-ai needs:$missing"
        install_hint "$missing"
        die "missing requirements"
    fi

    zsh -fc 'autoload -Uz is-at-least; is-at-least 5.8' ||
        die "zsh 5.8 or newer is needed (found $(zsh --version))"

    if command -v sha256sum >/dev/null 2>&1; then
        SHA="sha256sum"
    elif command -v shasum >/dev/null 2>&1; then
        SHA="shasum -a 256"
    else
        die "need sha256sum or shasum to verify downloads"
    fi
}

verify() {
    archive=$1
    sums=$2
    filename=${archive##*/}

    want=$(awk -v f="$filename" \
        '$2 == f || $2 == "*" f { print $1; exit }' "$sums")

    [ -n "$want" ] || die "$filename is not listed in SHA256SUMS"

    got=$($SHA "$archive" | awk '{print $1}')
    [ "$want" = "$got" ] ||
        die "checksum mismatch for $filename"

    info "Checksum verified: $filename"
}

latest_version() {
    curl -fsSL \
        "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null |
        jq -r '.tag_name // empty' 2>/dev/null
}

fetch_release() {
    tmp=$1

    if [ -n "$FROM" ]; then
        [ -f "$FROM" ] || die "no such archive: $FROM"

        TARBALL="$tmp/${FROM##*/}"
        cp "$FROM" "$TARBALL"

        sums="$(dirname "$FROM")/SHA256SUMS"
        if [ -f "$sums" ]; then
            verify "$TARBALL" "$sums"
        else
            warn "No adjacent SHA256SUMS found; local archive is not verified."
        fi
        return
    fi

    if [ -z "$VERSION" ]; then
        VERSION=$(latest_version) ||
            VERSION=""

        [ -n "$VERSION" ] ||
            die "could not determine latest release; use --version main for development"
    fi

    if [ "$VERSION" = main ]; then
        TARBALL="$tmp/$EXTENSION-main.tar.gz"
        info "Downloading the monorepo main branch"

        curl -fsSL -o "$TARBALL" \
            "https://codeload.github.com/$REPO/tar.gz/refs/heads/main" ||
            die "could not download the monorepo main branch"

        return
    fi

    case "$VERSION" in
        -*|*/*|*[!A-Za-z0-9._-]*)
            die "invalid version/tag: $VERSION"
            ;;
    esac

    base="https://github.com/$REPO/releases/download/$VERSION"
    TARBALL="$tmp/$EXTENSION-$VERSION.tar.gz"

    info "Downloading $EXTENSION $VERSION"

    curl -fsSL -o "$TARBALL" \
        "$base/$EXTENSION-$VERSION.tar.gz" ||
        die "could not download $EXTENSION-$VERSION.tar.gz"

    curl -fsSL -o "$tmp/SHA256SUMS" \
        "$base/SHA256SUMS" ||
        die "could not download SHA256SUMS for $VERSION"

    verify "$TARBALL" "$tmp/SHA256SUMS"
}

install_files() {
    tmp=$1
    unpack="$tmp/unpacked"

    mkdir -p "$unpack"
    tar -xzf "$TARBALL" -C "$unpack" ||
        die "could not unpack archive"

    src=$(find "$unpack" -type f -name zsh-ghost-ai.plugin.zsh -print |
        head -n 1)

    [ -n "$src" ] ||
        die "archive does not contain zsh-ghost-ai.plugin.zsh"

    src=${src%/*}
    [ -f "$src/zsh-ghost-ai.plugin.zsh" ] ||
        die "invalid extension archive layout"

    parent=${DIR%/*}
    [ "$parent" != "$DIR" ] || parent="."
    mkdir -p "$parent" || die "could not create installation parent"

    staging="$DIR.new.$$"
    previous="$DIR.old.$$"

    rm -rf "$staging" "$previous"
    mkdir -p "$staging" || die "could not create staging directory"

    cp -R "$src/." "$staging/" ||
        die "could not stage extension files"

    [ -f "$staging/zsh-ghost-ai.plugin.zsh" ] ||
        die "staged installation is incomplete"

    if [ -e "$DIR" ]; then
        mv "$DIR" "$previous" ||
            die "could not move existing installation aside"
    fi

    if ! mv "$staging" "$DIR"; then
        if [ -e "$previous" ]; then
            mv "$previous" "$DIR" ||
                warn "could not restore previous installation from $previous"
        fi
        die "could not activate new installation"
    fi

    rm -rf "$previous"
    info "Installed $EXTENSION to $DIR"
}

zshrc_path() {
    printf '%s/.zshrc' "${ZDOTDIR:-$HOME}"
}

rc_block() {
    say "$MARK_BEGIN"

    if [ "$PROVIDER" != ollama ]; then
        say "zstyle ':ghost-ai:*' provider $PROVIDER"
    fi

    if [ -n "$RC_EXTRA" ]; then
        printf '%s\n' "$RC_EXTRA"
    fi

    say "source \"$DIR/zsh-ghost-ai.plugin.zsh\""
    say "$MARK_END"
}

write_rc() {
    rc=$(zshrc_path)
    [ -f "$rc" ] || : >"$rc"

    block=$(rc_block)
    tmprc="$rc.zga.$$"

    awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
        $0 == begin { skip = 1; next }
        $0 == end   { skip = 0; next }
        !skip       { print }
    ' "$rc" >"$tmprc.clean" || die "could not read $rc"

    if grep -n 'zsh-syntax-highlighting' "$tmprc.clean" |
        grep -v '^[0-9]*:[[:space:]]*#' >/dev/null; then

        line=$(grep -n 'zsh-syntax-highlighting' "$tmprc.clean" |
            grep -v '^[0-9]*:[[:space:]]*#' |
            head -n 1 | cut -d: -f1)

        {
            head -n $((line - 1)) "$tmprc.clean"
            printf '%s\n' "$block"
            tail -n +"$line" "$tmprc.clean"
        } >"$tmprc"
    else
        {
            cat "$tmprc.clean"
            [ ! -s "$tmprc.clean" ] ||
                [ -z "$(tail -c 1 "$tmprc.clean")" ] ||
                echo
            printf '%s\n' "$block"
        } >"$tmprc"
    fi

    rm -f "$tmprc.clean"
    if cat "$tmprc" >"$rc"; then
        rm -f "$tmprc"
    else
        rm -f "$tmprc"
        die "could not update $rc"
    fi

    info "Updated $rc"
}

detect_manager() {
    if { [ -n "${ZSH:-}" ] && [ -d "$ZSH" ]; } ||
        [ -d "$HOME/.oh-my-zsh" ]; then
        echo oh-my-zsh
    elif grep -qs 'zinit' "$(zshrc_path)"; then
        echo zinit
    elif grep -qs 'antidote' "$(zshrc_path)"; then
        echo antidote
    fi
}

setup_provider() {
    if [ "$PROVIDER" != ollama ]; then
        return
    fi

    if curl -s -m 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
        if curl -s -m 2 http://localhost:11434/api/tags |
            jq -e --arg m "$OLLAMA_MODEL" \
                '[.models[]? | select(.name == $m)] | length > 0' \
                2>/dev/null | grep -q true; then
            info "Ollama has $OLLAMA_MODEL"
        elif [ "$PULL" = 1 ] ||
            ask "Download the default model $OLLAMA_MODEL (about 1 GB) with Ollama?" y; then
            info "ollama pull $OLLAMA_MODEL"
            ollama pull "$OLLAMA_MODEL" ||
                warn "pull failed; run later: ollama pull $OLLAMA_MODEL"
        else
            say "Later: ollama pull $OLLAMA_MODEL"
        fi
        return
    fi

    if [ "$YES" = 1 ]; then
        warn "Ollama is not running. Install it from https://ollama.com, then run: ollama pull $OLLAMA_MODEL"
        return
    fi

    say ""
    say "Ollama (the default, a local model) isn't running here. Pick a model:"
    say "  1) Ollama: I'll install it from https://ollama.com myself"
    say "  2) Claude (needs ANTHROPIC_API_KEY; the line and context are sent to Anthropic)"
    say "  3) An OpenAI-compatible server (llama.cpp, LM Studio, vLLM, OpenRouter...)"

    choice=$(prompt "Choice" 1)

    case "$choice" in
        2)
            PROVIDER=anthropic
            [ -n "${ANTHROPIC_API_KEY:-}" ] ||
                warn "ANTHROPIC_API_KEY isn't set; configure it in zsh or use zstyle key-cmd."
            ;;
        3)
            PROVIDER=openai
            url=$(prompt "Server URL (without /v1)" "http://localhost:8080")
            model=$(prompt "Model name" "")
            RC_EXTRA="zstyle ':ghost-ai:*' endpoint $url"
            [ -n "$model" ] &&
                RC_EXTRA="$RC_EXTRA
zstyle ':ghost-ai:*' model $model"
            ;;
        *)
            say "After installing Ollama: ollama pull $OLLAMA_MODEL"
            ;;
    esac
}

confirm_rc() {
    [ "$NO_RC" = 0 ] || return 1
    [ "$YES" = 1 ] && return 0

    if ! [ -r /dev/tty ] || ! (: </dev/tty) 2>/dev/null; then
        warn "No terminal available for confirmation; leaving $(zshrc_path) unchanged."
        return 1
    fi

    printf 'Add the Ghost AI source block to %s? [y/N] ' \
        "$(zshrc_path)" >/dev/tty

    read -r reply </dev/tty || reply=""

    case "$reply" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

main() {
    VERSION="${ZGA_VERSION:-}"
    YES="${ZGA_YES:-0}"
    PROVIDER="${ZGA_PROVIDER:-ollama}"
    DIR="${ZGA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zsh-ghost-ai}"
    PULL=0
    NO_RC=0
    FROM=""
    RC_EXTRA=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --version)
                [ $# -ge 2 ] || die "--version needs a tag"
                VERSION=$2
                shift
                ;;
            --yes|-y) YES=1 ;;
            --provider)
                [ $# -ge 2 ] || die "--provider needs a value"
                PROVIDER=$2
                shift
                ;;
            --pull) PULL=1 ;;
            --dir)
                [ $# -ge 2 ] || die "--dir needs a path"
                DIR=$2
                shift
                ;;
            --no-rc) NO_RC=1 ;;
            --from)
                [ $# -ge 2 ] || die "--from needs a file"
                FROM=$2
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *) die "unknown option: $1 (try --help)" ;;
        esac
        shift
    done

    [ -n "$DIR" ] || die "installation directory cannot be empty"

    case "$PROVIDER" in
        ollama|anthropic|openai) ;;
        *) die "unknown provider: $PROVIDER" ;;
    esac

    check_requirements

    tmp=$(mktemp -d "${TMPDIR:-/tmp}/zga-install.XXXXXX") ||
        die "mktemp failed"

    trap 'rm -rf "$tmp"' EXIT
    trap 'exit 1' HUP INT TERM

    fetch_release "$tmp"
    install_files "$tmp"
    setup_provider

    manager=$(detect_manager)

    if [ "$NO_RC" = 1 ]; then
        say ""
        say "Add this to $(zshrc_path):"
        rc_block
    elif [ "$manager" = oh-my-zsh ]; then
        custom="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}/plugins"
        mkdir -p "$custom" ||
            die "could not create Oh My Zsh plugins directory"

        ln -sfn "$DIR" "$custom/zsh-ghost-ai"
        info "Linked into Oh My Zsh: $custom/zsh-ghost-ai"

        say "Add zsh-ghost-ai to plugins=(...) in $(zshrc_path), before zsh-syntax-highlighting."

        if [ "$PROVIDER" != ollama ] || [ -n "$RC_EXTRA" ]; then
            say "Add these settings above the plugin line:"
            [ "$PROVIDER" != ollama ] &&
                say "  zstyle ':ghost-ai:*' provider $PROVIDER"
            [ -n "$RC_EXTRA" ] &&
                printf '  %s\n' "$RC_EXTRA"
        fi
    elif confirm_rc; then
        if [ -n "$manager" ]; then
            say "Found $manager; adding a plain source block."
        fi
        write_rc
    else
        say ""
        say "Add this to $(zshrc_path) when ready:"
        rc_block
    fi

    say ""
    info "Checking the setup"

    zsh -fic "zstyle ':ghost-ai:*' provider $PROVIDER; $(printf '%s' "$RC_EXTRA" | tr '\n' ';') source '$DIR/zsh-ghost-ai.plugin.zsh' && ghost-ai doctor" </dev/null ||
        warn "Ghost AI doctor reported an issue; review the output above."

    say ""
    say "Done. Start a new shell to use it: exec zsh"
    say "Type a command and wait a moment; press → to accept the ghost text."
}

main "$@"
