<#
.SYNOPSIS
  The reverse of apply.ps1: copies configs you changed on THIS machine back into the repo,
  then scans them so nothing secret gets committed. Review `git diff` before committing!
  Only GENERIC files are captured. ~/.claude/CLAUDE.md, settings.json, commands/ and agents/
  are never captured: on a work machine they hold company conventions that must not leave it.
  Keep ASCII-only.
#>
$ErrorActionPreference = 'Continue'
$Repo = Split-Path -Parent $PSScriptRoot
$Shared = Join-Path $Repo 'shared'
$H = $env:USERPROFILE
$Docs = [Environment]::GetFolderPath('MyDocuments')

$map = @(
    @{ From = "$env:APPDATA\Cursor\User\settings.json"; To = 'editor\settings.json' },
    @{ From = "$env:APPDATA\Cursor\User\keybindings.json"; To = 'editor\keybindings.json' },
    @{ From = "$H\.claude\keybindings.json"; To = 'claude\keybindings.json' },
    @{ From = "$H\.config\starship.toml"; To = 'shell\starship.toml' },
    @{ From = "$H\.config\oh-my-posh\agnoster.omp.json"; To = 'oh-my-posh\agnoster.omp.json' },
    @{ From = "$H\.config\mise\config.toml"; To = 'mise\config.toml' },
    @{ From = "$env:LOCALAPPDATA\dbcli\pgcli\config"; To = 'pg\pgcli.config' },
    @{ From = "$Docs\PowerShell\Microsoft.PowerShell_profile.ps1"; To = 'powershell\profile.ps1' }
)
foreach ($m in $map) {
    if (Test-Path $m.From) { Copy-Item $m.From (Join-Path $Shared $m.To) -Force; Write-Host "  captured $($m.To)" }
}
foreach ($d in 'output-styles') {
    $src = "$H\.claude\$d"
    if (Test-Path $src) { Copy-Item $src (Join-Path $Shared "claude") -Recurse -Force; Write-Host "  captured claude\$d" }
}
if (Test-Path "$env:APPDATA\Cursor\User\snippets") {
    Copy-Item "$env:APPDATA\Cursor\User\snippets" (Join-Path $Shared 'editor') -Recurse -Force
}
if (Get-Command cursor -ErrorAction SilentlyContinue) {
    $snap = Join-Path $Shared 'editor\extensions.snapshot.txt'
    "# Snapshot from $env:COMPUTERNAME on $(Get-Date -Format yyyy-MM-dd) - compare with extensions*.txt" | Set-Content $snap
    cursor --list-extensions --show-versions | Add-Content $snap
    Write-Host '  captured editor\extensions.snapshot.txt'
}
# NOT captured on purpose: ~/.claude/CLAUDE.md, settings.json, commands/, agents/ (machine/company
# specific). To share a generic rule across machines, add it to shared\claude\CLAUDE.md by hand.

Write-Host "`n==> Looking for things that should not be committed" -ForegroundColor Cyan
$suspicious = 'password|passwd|secret|token|api[_-]?key|connections"|BEGIN .*PRIVATE KEY|\b10\.\d+\.\d+\.\d+\b|\b192\.168\.|amazonaws\.com|arn:aws'
Get-ChildItem $Shared -Recurse -File | Select-String -Pattern $suspicious |
    ForEach-Object { Write-Warning "$($_.Path.Substring($Repo.Length+1)):$($_.LineNumber): $($_.Line.Trim())" }
if (Get-Command gitleaks -ErrorAction SilentlyContinue) {
    gitleaks dir $Repo --no-banner
} else { Write-Warning 'gitleaks not installed - run: winget install Gitleaks.Gitleaks' }

Write-Host "`nNow review:  git -C `"$Repo`" diff" -ForegroundColor Green
