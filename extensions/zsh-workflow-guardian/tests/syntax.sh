#!/usr/bin/env bash
set -euo pipefail
command -v zsh >/dev/null || { echo "zsh required" >&2; exit 77; }
zsh -n "$(dirname "$0")/../workflow-guardian.zsh"
echo "Syntax OK: zsh-workflow-guardian"
