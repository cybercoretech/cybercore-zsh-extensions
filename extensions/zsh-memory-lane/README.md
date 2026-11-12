# zsh-memory-lane

Searches local Zsh history, narrows recall by project path, and stores named text recipes. Recipe display never executes commands.

## Install
Copy `memory-lane.zsh` to `~/.zsh/` and add this line to `~/.zshrc`:

```zsh
source "$HOME/.zsh/memory-lane.zsh"
```

Restart Zsh. Review the source before enabling it.

## Safety
This extension does not silently execute proposed commands or destructive recovery actions.
