# Quick "did everything install?" check. Keep ASCII-only.
$checks = [ordered]@{
    git = 'git --version'; gh = 'gh --version'; uv = 'uv --version'; mise = 'mise --version'; python = 'python --version'
    node = 'node --version'; pnpm = 'pnpm --version'; claude = 'claude --version'
    cursor = 'cursor --version'; code = 'code --version'; aws = 'aws --version'; psql = 'psql --version'
    jq = 'jq --version'; rg = 'rg --version'; fd = 'fd --version'; fzf = 'fzf --version'; bat = 'bat --version'
    eza = 'eza --version'; zoxide = 'zoxide --version'; ohmyposh = 'oh-my-posh version'; lazygit = 'lazygit --version'
    just = 'just --version'; gitleaks = 'gitleaks version'; docker = 'docker --version'; graphify = 'graphify --help'
}
foreach ($name in $checks.Keys) {
    $cmd = ($checks[$name] -split ' ')[0]
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        $v = (Invoke-Expression "$($checks[$name]) 2>&1" | Select-Object -First 1)
        Write-Host ("  [ok]   {0,-9} {1}" -f $name, $v) -ForegroundColor Green
    } else {
        Write-Host ("  [MISS] {0}" -f $name) -ForegroundColor Yellow
    }
}
Write-Host "`nAlso try:  docker run --rm hello-world   |   aws sts get-caller-identity   |   gh auth status"
