#!/usr/bin/env bash
set -Eeuo pipefail

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

tmux_version="$(tmux -V | awk '{print $2}')"
tmux_major="${tmux_version%%.*}"
tmux_minor="${tmux_version#*.}"
tmux_minor="${tmux_minor%%[^0-9]*}"
if (( tmux_major < 3 || (tmux_major == 3 && tmux_minor < 5) )); then
  echo "tmux 3.5 or newer is required for CSI-u extended keys (found $tmux_version)" >&2
  exit 1
fi

private_worktree_package="$HOME/.pi/agent/local-packages/arvore-pi-extensions/packages/worktree"
if [[ ! -d "$private_worktree_package" ]]; then
  echo "Missing private Pi worktree package: $private_worktree_package" >&2
  echo "Clone or link arvore-pi-extensions before running this installer." >&2
  exit 1
fi

linked_targets=()
backup_paths=()

rollback_links() {
  local status=$?
  local index target backup
  trap - ERR

  echo "Installation failed; restoring previous configuration links." >&2
  for ((index=${#linked_targets[@]} - 1; index >= 0; index--)); do
    target="${linked_targets[$index]}"
    backup="${backup_paths[$index]}"
    rm -f "$target"
    if [[ -n "$backup" && ( -e "$backup" || -L "$backup" ) ]]; then
      mv "$backup" "$target"
    fi
  done

  exit "$status"
}

link_config() {
  local source="$1"
  local target="$2"
  local backup=""

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    printf 'Already linked: %s\n' "$target"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup="${target}.backup-${timestamp}"
    mv "$target" "$backup"
    printf 'Backed up: %s -> %s\n' "$target" "$backup"
  fi

  if ! ln -s "$source" "$target"; then
    if [[ -n "$backup" ]]; then
      mv "$backup" "$target"
    fi
    return 1
  fi

  linked_targets+=("$target")
  backup_paths+=("$backup")
  printf 'Linked: %s -> %s\n' "$target" "$source"
}

install_pi_extension_dependencies() {
  local extension
  for extension in linear-mcp subagents; do
    npm ci --prefix "$repo_dir/pi/extensions/$extension"
  done
}

config_sources=(
  "$repo_dir/.tmux.conf"
  "$repo_dir/nvim"
  "$repo_dir/herdr/config.toml"
  "$repo_dir/pi/settings.json"
  "$repo_dir/pi/themes"
  "$repo_dir/pi/extensions"
  "$repo_dir/agents/skills/writing-quality-code"
  "$repo_dir/agents/skills/interface-polish"
  "$repo_dir/agents/skills/emilkowal-animations"
  "$repo_dir/agents/skills/git-conventions"
  "$repo_dir/agents/skills/codex-security"
  "$repo_dir/agents/skills/orthogonal"
)
for source in "${config_sources[@]}"; do
  if [[ ! -e "$source" ]]; then
    echo "Missing configuration source: $source" >&2
    exit 1
  fi
done

# Complete network/package work before replacing any active configuration.
install_pi_extension_dependencies
"$repo_dir/herdr/install-plugins.sh"

trap rollback_links ERR
link_config "$repo_dir/.tmux.conf" "$HOME/.tmux.conf"
link_config "$repo_dir/nvim" "$HOME/.config/nvim"
link_config "$repo_dir/herdr/config.toml" "$HOME/.config/herdr/config.toml"
link_config "$repo_dir/pi/settings.json" "$HOME/.pi/agent/settings.json"
link_config "$repo_dir/pi/themes" "$HOME/.pi/agent/themes"
link_config "$repo_dir/pi/extensions" "$HOME/.pi/agent/extensions"
link_config "$repo_dir/agents/skills/writing-quality-code" "$HOME/.agents/skills/writing-quality-code"
link_config "$repo_dir/agents/skills/interface-polish" "$HOME/.agents/skills/interface-polish"
link_config "$repo_dir/agents/skills/emilkowal-animations" "$HOME/.agents/skills/emilkowal-animations"
link_config "$repo_dir/agents/skills/git-conventions" "$HOME/.agents/skills/git-conventions"
link_config "$repo_dir/agents/skills/codex-security" "$HOME/.agents/skills/codex-security"
link_config "$repo_dir/agents/skills/orthogonal" "$HOME/.agents/skills/orthogonal"
trap - ERR

cat <<'EOF'

Configuration installed. Restart tmux completely to enable CSI-u keys:
  tmux kill-server

Then restart Pi and Herdr, or reload Herdr with:
  herdr server reload-config
EOF
