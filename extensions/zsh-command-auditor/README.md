# zsh-command-auditor

Records command text, timestamp, working directory, and exit status in a local daily log. Logs may contain secrets.

## Install
Copy `command-auditor.zsh` to `~/.zsh/` and add this line to `~/.zshrc`:

```zsh
source "$HOME/.zsh/command-auditor.zsh"
```

Restart Zsh. Review the source before enabling it.

## Safety
This extension does not silently execute proposed commands or destructive recovery actions.
