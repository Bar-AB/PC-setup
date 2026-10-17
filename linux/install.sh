#!/usr/bin/env bash
# Ubuntu / WSL bootstrap:  bash linux/install.sh
# Tip (WSL): keep projects in the Linux filesystem (~/work), NOT under /mnt/c - much faster with Docker.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> apt packages"
sudo apt-get update
sudo apt-get install -y \
  zsh tmux git curl unzip build-essential jq ripgrep fd-find bat fzf direnv \
  python3-venv pipx postgresql-client pgcli universal-ctags
mkdir -p "$HOME/.local/bin"
# Ubuntu renames these binaries
ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd" 2>/dev/null || true
ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat" 2>/dev/null || true
export PATH="$HOME/.local/bin:$PATH"

echo "==> uv, starship, zoxide (official installers, user-local)"
command -v uv >/dev/null       || curl -LsSf https://astral.sh/uv/install.sh | sh
command -v starship >/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
command -v zoxide >/dev/null   || curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
command -v mise >/dev/null     || curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

echo "==> GitHub CLI"
if ! command -v gh >/dev/null; then
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update && sudo apt-get install -y gh
fi

echo "==> uv tools"
for t in "graphifyy[postgres]" ruff pre-commit fastmcp; do uv tool install "$t" || true; done

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
[ "$(basename "${SHELL:-}")" = zsh ] || chsh -s "$(command -v zsh)" || true

bash "$REPO/scripts/apply.sh"

cat <<'EOF'

Not installed here on purpose:
  - Node/Python versions: `mise install` (reads ~/.config/mise/config.toml)
  - Docker: Docker Desktop's WSL integration, or Docker Engine (docs.docker.com/engine/install/ubuntu)
  - granted (AWS SSO helper): see docs.commonfate.io/granted/getting-started
EOF
