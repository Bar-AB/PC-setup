# Shared aliases/functions for bash (Git Bash, WSL) and zsh (macOS, WSL).

has() { command -v "$1" >/dev/null 2>&1; }

# Navigation / listing
if has eza; then
  alias ls='eza --group-directories-first'
  alias ll='eza -la --git --group-directories-first'
  alias lt='eza --tree --level=2 --git-ignore'
else
  alias ll='ls -lah'
fi
has bat && alias cat='bat --paging=never --style=plain'
alias ..='cd ..'
alias ...='cd ../..'

# Git
alias g='git'
alias gs='git st'
alias gl='git lg'
alias gp='git push'
alias gpl='git pull'
alias lg='lazygit'

# Python / uv
venv() {  # create (if needed) + activate .venv
  [ -d .venv ] || uv venv
  if [ -f .venv/bin/activate ]; then . .venv/bin/activate; else . .venv/Scripts/activate; fi
}
alias pyt='uv run pytest -q'
alias rf='uv run ruff check --fix . && uv run ruff format .'

# Claude Code
alias ccr='claude --resume'

# mkdir + cd
mkcd() { mkdir -p "$1" && cd "$1"; }

# Search code quickly: rgf <pattern>  (ripgrep + fzf preview, opens result in $EDITOR)
rgf() {
  has rg && has fzf || { echo "needs rg + fzf"; return 1; }
  rg --line-number --no-heading --color=always "$@" |
    fzf --ansi --delimiter : --preview 'bat --color=always {1} --highlight-line {2}' |
    cut -d: -f1,2
}
