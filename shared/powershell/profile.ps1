# PowerShell profile (Windows PowerShell 5.1 and PowerShell 7).
# Installed to $PROFILE by scripts/apply.ps1.
# Secrets / machine-specific env vars go in profile.local.ps1 next to this file (never committed).
# Keep this file ASCII-only: Windows PowerShell 5.1 misreads UTF-8 files without a BOM.

function Test-Cmd($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

# --- Editing / history -------------------------------------------------------
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Windows -HistoryNoDuplicates -BellStyle None
    try { Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView } catch { }
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# --- Aliases / helpers -------------------------------------------------------
function g { git @args }
function gs { git st @args }
function gl { git lg @args }
function gp { git push @args }
function gpl { git pull @args }
function lg { lazygit @args }
function ccr { claude --resume @args }
function mkcd($path) { New-Item -ItemType Directory -Force $path | Out-Null; Set-Location $path }
function which($name) { (Get-Command $name -ErrorAction SilentlyContinue).Source }
function venv { if (-not (Test-Path .venv)) { uv venv }; . .\.venv\Scripts\Activate.ps1 }
function pyt { uv run pytest -q @args }
if (Test-Cmd eza) {
    function ll { eza -la --git --group-directories-first @args }
    function lt { eza --tree --level=2 --git-ignore @args }
} else {
    function ll { Get-ChildItem -Force @args }
}

# --- Prompt & tools ----------------------------------------------------------
if (Test-Cmd starship) { Invoke-Expression (& starship init powershell --print-full-init | Out-String) }
# mise: shims work in both PS 5.1 and 7 (mise activate only supports pwsh 7)
$miseShims = Join-Path $env:LOCALAPPDATA 'mise\shims'
if ((Test-Path $miseShims) -and ($env:Path -notlike "*$miseShims*")) { $env:Path = "$miseShims;$env:Path" }
if (Test-Cmd zoxide) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }

# --- Local, uncommitted overrides (API keys, AWS_PROFILE, proxies...) --------
$localProfile = Join-Path (Split-Path $PROFILE) 'profile.local.ps1'
if (Test-Path $localProfile) { . $localProfile }
