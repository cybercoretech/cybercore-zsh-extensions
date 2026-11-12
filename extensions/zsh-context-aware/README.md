# zsh-context-aware

Detects local project manifests, Git context, virtual environments, container files, and installed developer tools.

## Install
Copy `context-aware.zsh` to `~/.zsh/` and add this line to `~/.zshrc`:

```zsh
source "$HOME/.zsh/context-aware.zsh"
```

Restart Zsh. Review the source before enabling it.

## Safety
This extension does not silently execute proposed commands or destructive recovery actions.
