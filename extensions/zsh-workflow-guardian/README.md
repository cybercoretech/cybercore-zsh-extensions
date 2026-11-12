# zsh-workflow-guardian

Tracks a task and last command, recognizes Git projects, warns on selected risky command patterns, and suggests manual checkpoints. It never runs or blocks commands.

## Install
Copy `workflow-guardian.zsh` to `~/.zsh/` and add this line to `~/.zshrc`:

```zsh
source "$HOME/.zsh/workflow-guardian.zsh"
```

Restart Zsh. Review the source before enabling it.

## Safety
This extension does not silently execute proposed commands or destructive recovery actions.
