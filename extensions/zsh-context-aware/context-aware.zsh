cca() {
  print -P "%F{cyan}[Context Aware]%f $PWD"
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    print "Git root: $(git rev-parse --show-toplevel)"
    print "Branch: $(git branch --show-current)"
  fi
  [[ -n "$VIRTUAL_ENV" ]] && print "Python venv: $VIRTUAL_ENV"
  [[ -n "$CONDA_PREFIX" ]] && print "Conda: $CONDA_PREFIX"
  [[ -f pyproject.toml ]] && print "Python project"
  [[ -f Cargo.toml ]] && print "Rust project"
  [[ -f package.json ]] && print "Node project"
  [[ -f go.mod ]] && print "Go project"
  [[ -f Dockerfile ]] && print "Dockerfile detected"
  local tool
  for tool in git zsh python3 uv cargo rustc node npm pnpm go docker podman kubectl gh; do
    (( $+commands[$tool] )) && print "Available: $tool"
  done
}
