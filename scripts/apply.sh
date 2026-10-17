#!/usr/bin/env bash
# Copies configs from this repo into place on macOS / Linux / WSL.
# Existing files that differ are backed up to <file>.bak-<timestamp>. Safe to re-run.
#   scripts/apply.sh                    # apply
#   SKIP_EXTENSIONS=1 scripts/apply.sh  # skip editor extensions
#   ROOT=/tmp/sandbox scripts/apply.sh  # trial run into a fake home dir
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
S="$REPO/shared"
H="${ROOT:-$HOME}"
STAMP="$(date +%Y%m%d-%H%M%S)"

step() { printf '\n\033[36m==> %s\033[0m\n' "$1"; }

put() {  # put <src> <dst>
  local src="$1" dst="$2"
  [ -e "$src" ] || { echo "  missing in repo: $src"; return; }
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ]; then
    cmp -s "$src" "$dst" && { echo "  same     $dst"; return; }
    cp "$dst" "$dst.bak-$STAMP"
  fi
  cp "$src" "$dst" && echo "  updated  $dst"
}
put_if_missing() { [ -e "$2" ] && echo "  kept     $2" || put "$1" "$2"; }
put_dir() {  # put_dir <srcdir> <dstdir>
  [ -d "$1" ] || return 0
  (cd "$1" && find . -type f) | while read -r f; do put "$1/${f#./}" "$2/${f#./}"; done
}

step git
put "$S/git/.gitconfig" "$H/.gitconfig"
put "$S/git/.gitignore_global" "$H/.gitignore_global"
if [ ! -e "$H/.gitconfig.local" ]; then
  read -rp "  git user.name (personal): " gname
  read -rp "  git user.email (personal): " gemail
  printf '[user]\n\tname = %s\n\temail = %s\n' "$gname" "$gemail" > "$H/.gitconfig.local"
  case "$(uname -s)" in Darwin) git config --file "$H/.gitconfig.local" credential.helper osxkeychain ;; esac
  echo "  created  $H/.gitconfig.local"
fi

step shell
put "$S/shell/.zshrc" "$H/.zshrc"
put "$S/shell/.zprofile" "$H/.zprofile"
put "$S/shell/.tmux.conf" "$H/.tmux.conf"
put "$S/shell/.bashrc" "$H/.bashrc"
put "$S/shell/aliases.sh" "$H/.config/shell/aliases.sh"
put "$S/shell/starship.toml" "$H/.config/starship.toml"
put "$S/mise/config.toml" "$H/.config/mise/config.toml"

step editors
case "$(uname -s)" in
  Darwin) BASE="$H/Library/Application Support" ;;
  *)      BASE="$H/.config" ;;
esac
for pair in "Cursor:cursor:extensions.cursor.txt" "Code:code:extensions.vscode.txt"; do
  IFS=: read -r app cli extra <<<"$pair"
  dir="$BASE/$app/User"
  if ! command -v "$cli" >/dev/null && [ ! -d "$dir" ]; then echo "  skip     $app (not installed)"; continue; fi
  put "$S/editor/settings.json" "$dir/settings.json"
  put "$S/editor/keybindings.json" "$dir/keybindings.json"
  put_dir "$S/editor/snippets" "$dir/snippets"
  if [ -z "${SKIP_EXTENSIONS:-}" ] && command -v "$cli" >/dev/null; then
    installed="$("$cli" --list-extensions 2>/dev/null)"
    failed=""
    for ext in $(grep -hv '^\s*#' "$S/editor/extensions.txt" "$S/editor/$extra" | tr -d '\r' | grep .); do
      echo "$installed" | grep -qix "${ext%@*}" && continue
      "$cli" --install-extension "$ext" --force >/dev/null 2>&1 || failed="$failed $ext"
    done
    [ -n "$failed" ] && echo "  $app: could not install:$failed" || echo "  $app extensions ok"
  fi
done

step "Claude Code (~/.claude)"
C="$H/.claude"
put "$S/claude/CLAUDE.md" "$C/CLAUDE.md"
put "$S/claude/keybindings.json" "$C/keybindings.json"
for d in output-styles commands agents; do put_dir "$S/claude/$d" "$C/$d"; done
hooks_file=""
[ "$(uname -s)" = Darwin ] && hooks_file="$S/claude/settings.macos-hooks.json"
tmp="$(mktemp)"
if command -v jq >/dev/null; then
  if [ -n "$hooks_file" ]; then jq -s '.[0] * .[1]' "$S/claude/settings.base.json" "$hooks_file" >"$tmp"
  else jq . "$S/claude/settings.base.json" >"$tmp"; fi
else
  python3 - "$S/claude/settings.base.json" "$hooks_file" >"$tmp" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
if sys.argv[2]: d.update(json.load(open(sys.argv[2])))
print(json.dumps(d, indent=2))
PY
fi
put "$tmp" "$C/settings.json"; rm -f "$tmp"

step "psql + pgcli + ssh"
put "$S/pg/.psqlrc" "$H/.psqlrc"
put "$S/pg/pgcli.config" "$H/.config/pgcli/config"
put_if_missing "$S/ssh/config.example" "$H/.ssh/config"
chmod 700 "$H/.ssh" 2>/dev/null; chmod 600 "$H/.ssh/config" 2>/dev/null

printf '\n\033[32mDone. Backups (if any) are next to the originals as *.bak-%s\033[0m\n' "$STAMP"
