<#
.SYNOPSIS
  Copies the configs from this repo into their real locations on Windows.
  Existing files that differ are backed up to <file>.bak-<timestamp> first. Safe to re-run.

.EXAMPLE
  .\scripts\apply.ps1
  .\scripts\apply.ps1 -SkipExtensions
  .\scripts\apply.ps1 -WhatIf          # show what would change
  .\scripts\apply.ps1 -Root C:\tmp\sandbox -SkipExtensions   # trial run into a fake home dir

  Keep this file ASCII-only (Windows PowerShell 5.1 reads BOM-less files as ANSI).
#>
[CmdletBinding(SupportsShouldProcess)]
param([switch]$SkipExtensions, [string]$Root)

$ErrorActionPreference = 'Continue'
$Repo = Split-Path -Parent $PSScriptRoot
$Shared = Join-Path $Repo 'shared'
$HomeDir = $env:USERPROFILE
$AppData = $env:APPDATA
# Documents may be redirected to OneDrive on company machines - ask Windows where it really is.
$Docs = [Environment]::GetFolderPath('MyDocuments')
if ($Root) {
    $HomeDir = $Root; $AppData = Join-Path $Root 'AppData\Roaming'; $Docs = Join-Path $Root 'Documents'
}
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

function Install-File([string]$Src, [string]$Dst) {
    if (-not (Test-Path $Src)) { Write-Warning "missing in repo: $Src"; return }
    $dir = Split-Path -Parent $Dst
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    if (Test-Path $Dst) {
        if ((Get-FileHash $Src).Hash -eq (Get-FileHash $Dst).Hash) { Write-Host "  same     $Dst"; return }
        if ($PSCmdlet.ShouldProcess($Dst, 'backup')) { Copy-Item $Dst "$Dst.bak-$Stamp" -Force }
    }
    if ($PSCmdlet.ShouldProcess($Dst, "copy from $Src")) {
        Copy-Item $Src $Dst -Force
        Write-Host "  updated  $Dst"
    }
}

function Install-IfMissing([string]$Src, [string]$Dst) {
    if (Test-Path $Dst) { Write-Host "  kept     $Dst (exists, not overwritten)"; return }
    Install-File $Src $Dst
}

function Install-Dir([string]$SrcDir, [string]$DstDir) {
    if (-not (Test-Path $SrcDir)) { return }
    Get-ChildItem $SrcDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($SrcDir.Length).TrimStart('\')
        Install-File $_.FullName (Join-Path $DstDir $rel)
    }
}

function Merge-Json($Base, $Extra) {
    foreach ($p in $Extra.PSObject.Properties) {
        $Base | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force
    }
    return $Base
}

# --- Git -------------------------------------------------------------------------
Write-Step 'git'
Install-File (Join-Path $Shared 'git\.gitconfig') (Join-Path $HomeDir '.gitconfig')
Install-File (Join-Path $Shared 'git\.gitignore_global') (Join-Path $HomeDir '.gitignore_global')
$localGit = Join-Path $HomeDir '.gitconfig.local'
if (-not (Test-Path $localGit)) {
    $name = Read-Host '  git user.name (personal)'
    $email = Read-Host '  git user.email (personal, e.g. the GitHub noreply address)'
    $content = "[user]`n`tname = $name`n`temail = $email`n"
    [IO.File]::WriteAllText($localGit, $content, $Utf8NoBom)
    Write-Host "  created  $localGit"
} else { Write-Host "  kept     $localGit" }
# Git for Windows normally sets this in the system config; make sure it is there.
if (-not $Root -and -not (git config --get credential.helper)) { git config --file $localGit credential.helper manager }

# --- Shells ----------------------------------------------------------------------
Write-Step 'shell (Git Bash + PowerShell + starship)'
Install-File (Join-Path $Shared 'shell\.bashrc') (Join-Path $HomeDir '.bashrc')
Install-File (Join-Path $Shared 'shell\aliases.sh') (Join-Path $HomeDir '.config\shell\aliases.sh')
Install-File (Join-Path $Shared 'shell\starship.toml') (Join-Path $HomeDir '.config\starship.toml')
# Git Bash only reads .bashrc via .bash_profile
$bashProfile = Join-Path $HomeDir '.bash_profile'
if (-not (Test-Path $bashProfile)) {
    [IO.File]::WriteAllText($bashProfile, "[ -f ~/.bashrc ] && . ~/.bashrc`n", $Utf8NoBom)
    Write-Host "  created  $bashProfile"
}

foreach ($sub in 'PowerShell', 'WindowsPowerShell') {
    Install-File (Join-Path $Shared 'powershell\profile.ps1') (Join-Path $Docs "$sub\Microsoft.PowerShell_profile.ps1")
}

# --- Editors (Cursor + VS Code share settings) -----------------------------------
Write-Step 'editors'
$editors = @(
    @{ Name = 'Cursor'; Cli = 'cursor'; Dir = Join-Path $AppData 'Cursor\User'; Extra = 'extensions.cursor.txt' },
    @{ Name = 'VS Code'; Cli = 'code'; Dir = Join-Path $AppData 'Code\User'; Extra = 'extensions.vscode.txt' }
)
foreach ($e in $editors) {
    $hasCli = [bool](Get-Command $e.Cli -ErrorAction SilentlyContinue)
    if (-not $hasCli -and -not (Test-Path $e.Dir)) { Write-Host "  skip     $($e.Name) (not installed)"; continue }
    Install-File (Join-Path $Shared 'editor\settings.json') (Join-Path $e.Dir 'settings.json')
    Install-File (Join-Path $Shared 'editor\keybindings.json') (Join-Path $e.Dir 'keybindings.json')
    Install-Dir (Join-Path $Shared 'editor\snippets') (Join-Path $e.Dir 'snippets')
    if ($SkipExtensions -or -not $hasCli) { continue }
    $installed = & $e.Cli --list-extensions 2>$null
    $failed = @()
    foreach ($file in 'extensions.txt', $e.Extra) {
        foreach ($line in Get-Content (Join-Path $Shared "editor\$file")) {
            $ext = $line.Trim()
            if (-not $ext -or $ext.StartsWith('#')) { continue }
            if ($installed -contains ($ext -split '@')[0]) { continue }
            & $e.Cli --install-extension $ext --force *> $null
            if ($LASTEXITCODE -ne 0) { $failed += $ext }
        }
    }
    if ($failed) { Write-Warning "$($e.Name): could not install $($failed -join ', ') (not in its marketplace?)" }
    else { Write-Host "  $($e.Name) extensions ok" }
}

# --- Claude Code -----------------------------------------------------------------
Write-Step 'Claude Code (~/.claude)'
$claude = Join-Path $HomeDir '.claude'
Install-File (Join-Path $Shared 'claude\CLAUDE.md') (Join-Path $claude 'CLAUDE.md')
Install-File (Join-Path $Shared 'claude\keybindings.json') (Join-Path $claude 'keybindings.json')
Install-Dir (Join-Path $Shared 'claude\output-styles') (Join-Path $claude 'output-styles')
Install-Dir (Join-Path $Shared 'claude\hooks') (Join-Path $claude 'hooks')
Install-Dir (Join-Path $Shared 'claude\commands') (Join-Path $claude 'commands')
Install-Dir (Join-Path $Shared 'claude\agents') (Join-Path $claude 'agents')

$base = Get-Content -Raw (Join-Path $Shared 'claude\settings.base.json') | ConvertFrom-Json
$hooks = Get-Content -Raw (Join-Path $Shared 'claude\settings.windows-hooks.json') | ConvertFrom-Json
$merged = (Merge-Json $base $hooks) | ConvertTo-Json -Depth 32
$tmp = Join-Path $env:TEMP "claude-settings-$Stamp.json"
[IO.File]::WriteAllText($tmp, $merged, $Utf8NoBom)
Install-File $tmp (Join-Path $claude 'settings.json')
Remove-Item $tmp -ErrorAction SilentlyContinue

# --- Postgres / SSH --------------------------------------------------------------
Write-Step 'psql + ssh'
Install-File (Join-Path $Shared 'pg\.psqlrc') (Join-Path $AppData 'postgresql\psqlrc.conf')
Install-IfMissing (Join-Path $Shared 'ssh\config.example') (Join-Path $HomeDir '.ssh\config')

Write-Host "`nDone. Backups (if any) are next to the originals as *.bak-$Stamp" -ForegroundColor Green
