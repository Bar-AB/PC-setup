#!/usr/bin/env bash
# Fresh macOS dev machine bootstrap:  bash macos/install.sh
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v brew >/dev/null; then
  echo "==> Installing Homebrew (also installs Xcode Command Line Tools)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi

echo "==> brew bundle"
brew bundle --file="$REPO/macos/Brewfile" || echo "!! some Brewfile entries failed - see above"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> oh-my-zsh (KEEP_ZSHRC so ours is not overwritten)"
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "==> uv tools"
for t in "graphifyy[postgres]" ruff fastmcp; do uv tool install "$t" || true; done
uv tool update-shell || true
command -v graphify >/dev/null && graphify claude install || true

bash "$REPO/scripts/apply.sh"
mise install || true   # node/python from ~/.config/mise/config.toml
git -C "$REPO" config core.hooksPath .githooks

cat <<'EOF'

Next:
  1. Open a new terminal
  2. gh auth login
  3. ssh-keygen -t ed25519 -C "<laptop-name>" && gh ssh-key add ~/.ssh/id_ed25519.pub
  4. claude   (login / Bedrock)
  5. iTerm2 -> Profiles -> Text -> Font: JetBrainsMono Nerd Font
EOF
