<#
.SYNOPSIS
  Fresh Windows dev machine bootstrap: winget packages -> dev tools -> configs.

.EXAMPLE
  # From a normal (non-admin) PowerShell, inside the cloned repo:
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
  .\windows\install.ps1            # core packages + configs
  .\windows\install.ps1 -All       # also optional packages (Docker, DBeaver, Bruno, Ollama)
  .\windows\install.ps1 -WithWSL   # also install WSL + Ubuntu (needs a reboot)
  .\windows\install.ps1 -SkipPackages   # only re-apply configs
  .\windows\install.ps1 -PersonalPlugins  # + my home Claude plugins (cc10x, codex, mods)

  Keep this file ASCII-only (Windows PowerShell 5.1 reads BOM-less files as ANSI).
#>
[CmdletBinding()]
param(
    [switch]$All,
    [switch]$WithWSL,
    [switch]$SkipPackages,
    [switch]$SkipTools,
    [switch]$SkipExtensions,
    [switch]$PersonalPlugins,   # enable my home Claude plugins (check company AI policy first)
    [switch]$Force              # overwrite seed configs that already exist (with backup)
)

# 'Continue' on purpose: in PS 5.1, 'Stop' turns any stderr line from a native exe (winget, uv) into a crash.
$ErrorActionPreference = 'Continue'
$Repo = Split-Path -Parent $PSScriptRoot

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

# --- 1. winget packages ----------------------------------------------------------
if (-not $SkipPackages) {
    Write-Step 'Installing winget packages'
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget not found. Install "App Installer" from the Microsoft Store, then re-run.'
    }
    $failed = @()
    foreach ($line in Get-Content (Join-Path $PSScriptRoot 'winget-packages.txt')) {
        $id = $line.Trim()
        if (-not $id -or $id.StartsWith('#')) { continue }
        if ($id.StartsWith('?')) {
            if (-not $All) { Write-Host "  skip (optional): $($id.Substring(1))"; continue }
            $id = $id.Substring(1)
        }
        $listed = winget list --id $id -e --accept-source-agreements 2>$null | Out-String
        if ($listed -match [regex]::Escape($id)) { Write-Host "  ok (installed): $id"; continue }
        Write-Host "  installing: $id"
        winget install --id $id -e --silent --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) { $failed += $id }
    }
    Update-SessionPath
    if ($failed) { Write-Warning ("Failed: " + ($failed -join ', ') + "  -> try 'winget search <name>'") }
}

# --- 2. WSL (optional) -----------------------------------------------------------
if ($WithWSL) {
    Write-Step 'Installing WSL + Ubuntu (reboot required afterwards)'
    wsl --install -d Ubuntu
    Write-Host '  After reboot, inside Ubuntu run:  bash /mnt/c/<path-to-this-repo>/linux/install.sh'
}

# --- 3. Language-level tools (uv / npm) -----------------------------------------
if (-not $SkipTools) {
    Write-Step 'Installing uv tools'
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        foreach ($t in @('graphifyy[postgres]', 'pre-commit', 'ruff', 'fastmcp')) {
            uv tool install $t
            if ($LASTEXITCODE -ne 0) { Write-Warning "uv tool install $t failed" }
        }
        uv tool update-shell
        if (Get-Command graphify -ErrorAction SilentlyContinue) { graphify claude install }
    } else { Write-Warning 'uv not on PATH yet - open a new terminal and re-run with -SkipPackages' }
}

# --- 4. Configs ------------------------------------------------------------------
Write-Step 'Applying configs'
& (Join-Path $Repo 'scripts\apply.ps1') -SkipExtensions:$SkipExtensions -PersonalPlugins:$PersonalPlugins -Force:$Force

# --- 5. Repo safety: gitleaks pre-commit hook for THIS repo -----------------------
git -C $Repo config core.hooksPath .githooks

Write-Step 'Done. Next steps:'
Write-Host @'
  1. Open a NEW terminal (PATH + profile changes).
  2. gh auth login                     (token stays in the OS credential store, not in this repo)
  3. ssh-keygen -t ed25519 -C "<laptop-name>" ; gh ssh-key add $HOME\.ssh\id_ed25519.pub
  4. claude                            (login, or Bedrock if the company decided so)
  5. Windows Terminal -> Settings -> Defaults -> Appearance -> Font: "JetBrainsMono Nerd Font"
  6. Run .\scripts\verify.ps1
'@
