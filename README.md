# PC-setup — my dev machine in one command

Personal dotfiles + bootstrap scripts for a fresh **Windows** (primary), **macOS** or **WSL/Ubuntu** dev machine:
packages, shells, git, Cursor/VS Code, Claude Code, psql, ssh.

> **Rule #1: no secrets in this repo, ever.** Keep it private, but write it as if it will be public one day.
> Nothing company-specific either (hosts, AWS account/profile names, internal repo names, project CLAUDE.md files).

## New machine — quick start

### Windows
```powershell
# 1. Git + GitHub CLI first (everything else comes from the repo)
winget install --id Git.Git -e ; winget install --id GitHub.cli -e
# 2. New terminal, then:
gh auth login
gh repo clone <you>/PC-setup $HOME\PC-setup ; cd $HOME\PC-setup
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\windows\install.ps1              # core packages + tools + configs
#   -All          also Docker Desktop / DBeaver / Bruno / Ollama (ask IT first on a company laptop)
#   -WithWSL      also WSL + Ubuntu (reboot, then: bash linux/install.sh inside Ubuntu)
#   -SkipPackages only re-apply configs
.\scripts\verify.ps1
```

### macOS
```bash
xcode-select --install   # if git is missing
git clone https://github.com/<you>/PC-setup ~/PC-setup && cd ~/PC-setup
bash macos/install.sh    # Homebrew + Brewfile + oh-my-zsh + configs
```

### WSL / Ubuntu
```bash
bash linux/install.sh
```

## What's in here

| Path | Goes to | Notes |
|---|---|---|
| `windows/winget-packages.txt` | winget | `?` prefix = optional (`-All`) |
| `macos/Brewfile` | `brew bundle` | refresh with `brew bundle dump --force` |
| `shared/git/.gitconfig` | `~/.gitconfig` | aliases, rebase-on-pull, rerere… **no identity** |
| `shared/git/.gitignore_global` | `~/.gitignore_global` | |
| `shared/git/*.example` | `~/.gitconfig.local`, `~/work/.gitconfig` | name/email live only on the machine |
| `shared/shell/.bashrc`, `.zshrc`, `aliases.sh` | `~/` and `~/.config/shell/` | Git Bash, WSL, macOS |
| `shared/shell/.zprofile`, `.tmux.conf` | `~/` | macOS / WSL only |
| `shared/mise/config.toml` | `~/.config/mise/config.toml` | global node/python versions (projects: `mise.toml` / `.tool-versions`) |
| `shared/shell/starship.toml` | `~/.config/starship.toml` | same prompt everywhere, shows AWS profile |
| `shared/powershell/profile.ps1` | `$PROFILE` (PS 5.1 + 7) | handles OneDrive-redirected Documents |
| `shared/editor/settings.json`, `keybindings.json` | Cursor **and** VS Code user dir | ruff format-on-save |
| `shared/editor/snippets/` | editor `snippets/` | python + React starters |
| `shared/editor/extensions*.txt` | `cursor/code --install-extension` | common + Cursor-only + VS Code-only |
| `shared/claude/` | `~/.claude/` | global CLAUDE.md, settings (plugins, deny rules, notify hooks), keybindings, output styles |
| `shared/claude/project-template/` | copy into a work repo | `.mcp.json` (Postgres restricted, AWS read-only, docs) + guard hook |
| `shared/pg/.psqlrc` | `~/.psqlrc` / `%APPDATA%\postgresql\psqlrc.conf` | |
| `shared/pg/pgcli.config` | `~/.config/pgcli/config` / `%LOCALAPPDATA%\dbcli\pgcli\config` | `destructive_warning = all` |
| `shared/ssh/config.example` | `~/.ssh/config` (only if missing) | **no keys, no company hosts** |

Scripts:
- `scripts/apply.ps1` / `scripts/apply.sh` — copy configs into place. Backs up anything it overwrites as `*.bak-<timestamp>`. Idempotent. Try it safely with `-Root <dir>` / `ROOT=<dir>`.
- `scripts/capture.ps1` — the reverse: pull changes you made on the machine back into the repo, then warn about anything that looks secret + run gitleaks. **Review `git diff` before committing.**
- `scripts/verify.ps1` — what's installed / missing.

## Where secrets go instead (never committed)

| Secret | Lives in |
|---|---|
| git name / email / signing key | `~/.gitconfig.local`, `~/work/.gitconfig` |
| API keys, `AWS_PROFILE`, proxies | `~/.zshrc.local`, `~/.bashrc.local`, `profile.local.ps1` (next to `$PROFILE`) |
| GitHub token | `gh auth login` → OS credential store |
| MCP env / tokens | `~/.claude.json` (created by Claude Code) — never copy it here |
| AWS | `~/.aws/` (SSO via `aws configure sso` or `granted`) |
| DB passwords | `.pgpass` / env vars from `direnv` (`.envrc` is gitignored globally) |
| SSH keys | generate fresh per machine: `ssh-keygen -t ed25519` |

Leak protection:
- `.gitignore` blocks the usual secret filenames.
- `.githooks/pre-commit` runs **gitleaks** on every commit (enabled by the install scripts via `git config core.hooksPath .githooks`; enable manually after a fresh clone if you skip them).
- Before the first push: `gitleaks git .` and `gitleaks dir .`.

## Claude Code per-project guardrails

For a work repo:
```bash
cp -r shared/claude/project-template/.claude  <repo>/
cp shared/claude/project-template/.mcp.json.example <repo>/.mcp.json   # fill env vars via direnv/.zshrc.local
```
`guard.sh` blocks `DROP/TRUNCATE`, `DELETE`/`UPDATE` without `WHERE`, AWS write calls and any psql/aws/kubectl
command that mentions `prod`. It needs `jq` or `python`, and **blocks everything** if neither exists (fail-closed).
MCP server names/flags change fast — check each server's README before relying on the example.

## Work vs. personal

- Clone company repos under `~/work/` (or `C:\work\`) → `includeIf` in `.gitconfig` switches to your work email automatically.
- Ask first whether a personal GitHub account is OK on the company laptop. If not: copy this repo over as a zip, or use only the `winget-packages.txt` + scripts.
- Things not tracked here on purpose: `~/.claude.json`, `~/.config/gh/hosts.yml`, `~/.aws/*`, `.pgpass`, `.npmrc`, `.envrc`, SSH keys, the old machine's `~/.ssh/config` hosts, Claude `autoMode` text (project-specific), and the `command-center` / `herdr` hooks (they belong to tools that install their own hooks).

## Why plain scripts and not chezmoi / stow?

Plain copy scripts are easy to read and audit, and they work the same on Windows without symlink or developer-mode issues.
Day 1 doesn't need more than that. If I end up running a work laptop **and** a home PC with diverging configs,
migrate to [chezmoi](https://www.chezmoi.io/) (`chezmoi init` + `.tmpl` files with `{{ if eq .chezmoi.hostname "work-laptop" }}`).
The `shared/` layout maps 1:1 to chezmoi's `dot_` names.

## Notes

- **Cursor uses Open VSX**, so some Microsoft extensions (Pylance, the MS PostgreSQL extension, Remote-*) are missing; Cursor ships its own forks (`extensions.cursor.txt`). The apply script prints whatever failed instead of stopping.
- `.ps1` files stay **ASCII-only**: Windows PowerShell 5.1 misreads UTF-8 without a BOM.
- Package names in winget/brew change sometimes → `winget search <x>` / `brew search <x>`.

See [`docs/new-job-checklist.md`](docs/new-job-checklist.md) for the first-day checklist.
