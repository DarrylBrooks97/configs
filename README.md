# Darryl's configs

Personal configuration for Agent Skills, Pi, Herdr, tmux, and Neovim, plus supporting macOS tools.

## Included

- **Agent Skills:** personal writing-quality, interface polish, animation, security scanning, and Git conventions
- **Pi:** global settings, custom themes, battery/startup extensions, Linear MCP adapter, and subagent tooling
- **Herdr:** tmux-aligned keybindings, Vesper theme, UI preferences, and pinned plugins
- **tmux:** Rose Pine theme, vim-style navigation, TPM plugins, and CSI-u extended keys for Pi
- **Neovim:** Kickstart-based editor configured for TypeScript/JavaScript, Python, Go, formatting, linting, debugging, Git, and UI enhancements

Runtime state and credentials are intentionally excluded. This includes Pi authentication, OAuth tokens, sessions, caches and trust decisions; Herdr sessions and logs; downloaded plugins; and `node_modules`.

## Requirements

- macOS and Homebrew
- Pi
- Herdr
- tmux 3.5 or newer for `extended-keys-format csi-u`
- Neovim
- Node.js and npm for Pi extensions and Codex Security (`22.13+` on Node 22, Node 24, or Node 26)
- Python 3.10 or newer for advanced Codex Security operations

Install Homebrew dependencies:

```bash
brew bundle --file=Brewfile
```

Pi's settings also reference the private Arvore worktree package at:

```text
~/.pi/agent/local-packages/arvore-pi-extensions/packages/worktree
```

Clone or link that repository at the expected location before starting Pi. It remains a separate repository and is not vendored here.

## Install

The installer preflights requirements, installs dependencies and pinned Herdr plugins, then backs up existing targets before creating symlinks. If linking fails, it restores the previous configuration. Run it from the stable clone, not a disposable Git worktree, because the installed symlinks point back to that checkout.

```bash
./install.sh
```

The installer links each managed skill into `~/.agents/skills` individually, so it does not replace skills installed from other sources.

## Update personal skills

Refresh the selected skills from their source repository, review the diff, and commit the result:

```bash
SKILLS_SOURCE_REPO=/path/to/source \
SKILLS_SOURCE_LABEL='source brand' \
  ./agents/sync-agent-skills.sh
git diff -- agents/
```

The updater only mirrors `writing-quality-code`, `interface-polish`, and `git-conventions`, replacing local edits inside those directories. It removes the source branding and records the commit in `agents/agent-skills.lock` so each refresh is traceable. Set `SKILLS_SOURCE_REF` to sync a branch other than `main`.

```bash
SKILLS_SOURCE_REPO=/path/to/source \
SKILLS_SOURCE_LABEL='source brand' \
SKILLS_SOURCE_REF=my-branch \
  ./agents/sync-agent-skills.sh
```

Refresh the complete Emil Kowalski animation skill independently with:

```bash
./agents/sync-emil-animations.sh
```

The `codex-security` skill is maintained locally and runs the current `@openai/codex-security` CLI through `npx`. It defaults to read-only scans and requires explicit approval before applying security patches.

After installation, restart tmux completely so modified key sequences are forwarded correctly:

```bash
tmux kill-server
tmux
```

Herdr configuration can be reloaded without restarting its server:

```bash
herdr server reload-config
```

## Manual links

If a full installation is not wanted, link individual configurations:

```bash
mkdir -p ~/.agents/skills
ln -s "$PWD/.tmux.conf" ~/.tmux.conf
ln -s "$PWD/nvim" ~/.config/nvim
ln -s "$PWD/herdr/config.toml" ~/.config/herdr/config.toml
ln -s "$PWD/pi/settings.json" ~/.pi/agent/settings.json
ln -s "$PWD/pi/themes" ~/.pi/agent/themes
ln -s "$PWD/pi/extensions" ~/.pi/agent/extensions
ln -s "$PWD/agents/skills/writing-quality-code" ~/.agents/skills/writing-quality-code
ln -s "$PWD/agents/skills/interface-polish" ~/.agents/skills/interface-polish
ln -s "$PWD/agents/skills/emilkowal-animations" ~/.agents/skills/emilkowal-animations
ln -s "$PWD/agents/skills/git-conventions" ~/.agents/skills/git-conventions
ln -s "$PWD/agents/skills/codex-security" ~/.agents/skills/codex-security
```

Install only the pinned Herdr plugins with:

```bash
./herdr/install-plugins.sh
```
