# 👻 zsh-ghost-ai

Inline AI ghost text for zsh: as you type a command, a completion appears in
dim text after the cursor. Press `→` to accept it. It runs on a local
[Ollama](https://ollama.com) model by default, never blocks your typing, and
never runs anything you didn't accept.

> 🚧 Work in progress. Building toward v0.1.0; see the blueprint's build plan.

## Requirements

zsh 5.8+, `curl`, `jq`, and a model: [Ollama](https://ollama.com) (default),
any OpenAI-compatible server, or Claude.

## Development

```sh
zsh tests/run.zsh        # drives a real interactive zsh through zpty
```

## License

MIT
