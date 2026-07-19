#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
timestamp="$(date +%Y%m%d-%H%M%S)"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "$1 is required before installing these configs" >&2
    exit 1
  fi
}

if [[ "$repo_dir" == *"/.worktrees/"* ]]; then
  echo "Refusing to install symlinks from a disposable Git worktree: $repo_dir" >&2
  echo "Run this installer from the stable configs checkout instead." >&2
  exit 1
fi

for command in npm pi herdr tmux nvim; do
  require_command "$command"
done

private_worktree_package="$HOME/.pi/agent/local-packages/arvore-pi-extensions/packages/worktree"
if [[ ! -d "$private_worktree_package" ]]; then
  echo "Missing private Pi worktree package: $private_worktree_package" >&2
  echo "Clone or link arvore-pi-extensions before running this installer." >&2
  exit 1
fi

link_config() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    printf 'Already linked: %s\n' "$target"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup="${target}.backup-${timestamp}"
    mv "$target" "$backup"
    printf 'Backed up: %s -> %s\n' "$target" "$backup"
  fi

  ln -s "$source" "$target"
  printf 'Linked: %s -> %s\n' "$target" "$source"
}

install_pi_extension_dependencies() {
  local extension
  for extension in linear-mcp subagents; do
    npm ci --prefix "$repo_dir/pi/extensions/$extension"
  done
}

# Complete network/package work before replacing any active configuration.
install_pi_extension_dependencies
"$repo_dir/herdr/install-plugins.sh"

link_config "$repo_dir/.tmux.conf" "$HOME/.tmux.conf"
link_config "$repo_dir/nvim" "$HOME/.config/nvim"
link_config "$repo_dir/herdr/config.toml" "$HOME/.config/herdr/config.toml"
link_config "$repo_dir/pi/settings.json" "$HOME/.pi/agent/settings.json"
link_config "$repo_dir/pi/themes" "$HOME/.pi/agent/themes"
link_config "$repo_dir/pi/extensions" "$HOME/.pi/agent/extensions"

cat <<'EOF'

Configuration installed. Restart tmux completely to enable CSI-u keys:
  tmux kill-server

Then restart Pi and Herdr, or reload Herdr with:
  herdr server reload-config
EOF
