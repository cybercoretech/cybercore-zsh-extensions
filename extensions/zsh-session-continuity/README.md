# zsh-session-continuity

Stores project-scoped objectives, progress notes, decisions, and next steps in local Markdown handoff files.

## Install
Copy `session-continuity.zsh` to `~/.zsh/` and add this line to `~/.zshrc`:

```zsh
source "$HOME/.zsh/session-continuity.zsh"
```

Restart Zsh. Review the source before enabling it.

## Safety
This extension does not silently execute proposed commands or destructive recovery actions.
