# ~/.zshrc  - macOS and WSL. Works with or without oh-my-zsh.
# Secrets / API keys / company-specific exports go in ~/.zshrc.local (never committed).

export EDITOR="${EDITOR:-code --wait}"
HISTFILE=~/.zsh_history HISTSIZE=50000 SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space auto_cd

# Homebrew (Apple Silicon + Intel)
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"

# oh-my-zsh, if installed (prompt comes from starship, so ZSH_THEME stays empty)
if [ -d "$HOME/.oh-my-zsh" ]; then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME=""
  plugins=(git fzf docker aws uv)
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit && compinit
fi

[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"

command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
command -v direnv   >/dev/null && eval "$(direnv hook zsh)"
command -v fzf      >/dev/null && source <(fzf --zsh 2>/dev/null)

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
