# ~/.bashrc  - used by Git Bash on Windows and bash in WSL/Linux.
# Secrets / machine-specific exports go in ~/.bashrc.local (never committed).

[ -n "$PS1" ] || return 0   # non-interactive: stop here

export EDITOR="${EDITOR:-code --wait}"
export HISTSIZE=50000 HISTFILESIZE=100000 HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize 2>/dev/null

# Windows (Git Bash): make winget-installed tools win over Git's bundled ones
case "$(uname -s)" in MINGW*|MSYS*) export PATH="$HOME/.local/bin:$PATH" ;; esac

[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"

command -v starship >/dev/null && eval "$(starship init bash)"
command -v zoxide   >/dev/null && eval "$(zoxide init bash)"
command -v direnv   >/dev/null && eval "$(direnv hook bash)"
command -v fzf      >/dev/null && eval "$(fzf --bash 2>/dev/null)"

[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
