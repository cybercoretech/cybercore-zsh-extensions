# zsh-git-sentinel

Read-only Git status assistant for working-tree changes, untracked files, branches, upstreams, and ahead/behind counts. It never mutates repository state.

## Install
Copy `git-sentinel.zsh` to `~/.zsh/` and add this line to `~/.zshrc`:

```zsh
source "$HOME/.zsh/git-sentinel.zsh"
```

Restart Zsh. Review the source before enabling it.

## Safety
This extension does not silently execute proposed commands or destructive recovery actions.
