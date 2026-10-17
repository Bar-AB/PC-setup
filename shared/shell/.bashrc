# ~/.bashrc  - used by Git Bash on Windows and bash in WSL/Linux.
# Secrets / machine-specific exports go in ~/.bashrc.local (never committed).

[ -n "$PS1" ] || return 0   # non-interactive: stop here

export EDITOR="${EDITOR:-code --wait}"
export HISTSIZE=50000 HISTFILESIZE=100000 HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize 2>/dev/null

# Windows (Git Bash): make winget-installed tools win over Git's bundled ones
case "$(uname -s)" in MINGW*|MSYS*) export PATH="$HOME/.local/bin:$PATH" ;; esac

[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"

omp_theme="$HOME/.config/oh-my-posh/agnoster.omp.json"
if command -v oh-my-posh >/dev/null && [ -f "$omp_theme" ]; then
  eval "$(oh-my-posh init bash --config "$omp_theme")"
elif command -v starship >/dev/null; then
  eval "$(starship init bash)"
fi
command -v zoxide   >/dev/null && eval "$(zoxide init bash)"
command -v direnv   >/dev/null && eval "$(direnv hook bash)"
command -v mise     >/dev/null && eval "$(mise activate bash)"
command -v fzf      >/dev/null && eval "$(fzf --bash 2>/dev/null)"

[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
