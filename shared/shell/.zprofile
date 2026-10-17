# ~/.zprofile - login shell setup (macOS Terminal/iTerm open login shells). Runs before .zshrc.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"
[ -f "$HOME/.zprofile.local" ] && source "$HOME/.zprofile.local"
