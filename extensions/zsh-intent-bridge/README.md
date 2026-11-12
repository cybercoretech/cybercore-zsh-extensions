# zsh-intent-bridge

Maps a few plain-language filesystem requests to visible command proposals. This starter implementation uses local templates and never executes them.

## Install
Copy `intent-bridge.zsh` to `~/.zsh/` and add this line to `~/.zshrc`:

```zsh
source "$HOME/.zsh/intent-bridge.zsh"
```

Restart Zsh. Review the source before enabling it.

## Safety
This extension does not silently execute proposed commands or destructive recovery actions.
