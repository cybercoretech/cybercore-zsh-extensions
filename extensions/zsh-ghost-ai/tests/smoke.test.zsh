# The plugin loads in an interactive shell and typing works normally.

t_case "loads"
t_start
t_type 'echo hi'
t_dump
t_eq "$D_BUFFER" "echo hi" "typing reaches the buffer"
t_eq "$D_POST" "" "no ghost text without a provider reply"
t_stop

t_case "non-interactive"
local out
out=$(zsh -fc "source ${(q)ZGA_ROOT}/zsh-ghost-ai.plugin.zsh && print loaded-quietly" 2>&1)
t_eq "$out" "loaded-quietly" "sourcing in a script is a silent no-op"

t_case "cli"
out=$(zsh -fic "source ${(q)ZGA_ROOT}/zsh-ghost-ai.plugin.zsh; ghost-ai version" 2>&1)
t_eq "$out" "zsh-ghost-ai 0.1.0" "ghost-ai version"
