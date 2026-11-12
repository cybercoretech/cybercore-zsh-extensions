#!/usr/bin/env bash
set -euo pipefail
command -v zsh >/dev/null || { echo "zsh required" >&2; exit 77; }
zsh -n "$(dirname "$0")/../intent-bridge.zsh"
echo "Syntax OK: zsh-intent-bridge"
