# wire-hooks.ps1 -- Safely merge hook entries into %USERPROFILE%\.claude\settings.json
# Run after setup.ps1. Never replaces the full settings.json -- only adds hooks.

$ClaudeDir = "$env:USERPROFILE\.claude"
$Settings  = "$ClaudeDir\settings.json"
$HooksDir  = "$ClaudeDir\hooks"
$Ts        = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host ""
Write-Host "Wire Hooks into settings.json"
Write-Host "=============================="

# Create settings.json if it doesn't exist
if (-not (Test-Path $Settings)) {
    '{"hooks":{}}' | Set-Content $Settings -Encoding UTF8
    Write-Host "  Created new settings.json"
}

# Backup
$Backup = "$Settings.bak.$Ts"
Copy-Item $Settings $Backup
Write-Host "  Backup: $Backup"

# Load JSON natively -- no Python required
$raw      = Get-Content $Settings -Raw -Encoding UTF8
$json     = $raw | ConvertFrom-Json

# Ensure hooks structure exists
if (-not $json.PSObject.Properties['hooks']) {
    $json | Add-Member -MemberType NoteProperty -Name 'hooks' -Value ([PSCustomObject]@{})
}
if (-not $json.hooks.PSObject.Properties['PreToolUse']) {
    $json.hooks | Add-Member -MemberType NoteProperty -Name 'PreToolUse' -Value @()
}
if (-not $json.hooks.PSObject.Properties['PostToolUse']) {
    $json.hooks | Add-Member -MemberType NoteProperty -Name 'PostToolUse' -Value @()
}

# Helper: check if a hook matcher+keyword already exists
function Test-HookExists($list, $matcher, $keyword) {
    foreach ($entry in $list) {
        if ($entry.matcher -eq $matcher) {
            foreach ($h in $entry.hooks) {
                if ($h.command -like "*$keyword*") { return $true }
            }
        }
    }
    return $false
}

# Helper: add a hook entry to a list (array)
function Add-Hook($list, $matcher, $command) {
    $entry = [PSCustomObject]@{
        matcher = $matcher
        hooks   = @([PSCustomObject]@{ type = "command"; command = $command })
    }
    return @($list) + @($entry)
}

# secret-scanner -- PreToolUse:Write
$secretCmd = "powershell -File `"$HooksDir\secret-scanner.ps1`""
if (-not (Test-HookExists $json.hooks.PreToolUse 'Write' 'secret-scanner')) {
    $json.hooks.PreToolUse = Add-Hook $json.hooks.PreToolUse 'Write' $secretCmd
    Write-Host "  Added:          secret-scanner (PreToolUse:Write)"
} else {
    Write-Host "  Already present: secret-scanner"
}

# claude-md-guard -- PostToolUse:Write
$guardCmd = "powershell -File `"$HooksDir\claude-md-guard.ps1`""
if (-not (Test-HookExists $json.hooks.PostToolUse 'Write' 'claude-md-guard')) {
    $json.hooks.PostToolUse = Add-Hook $json.hooks.PostToolUse 'Write' $guardCmd
    Write-Host "  Added:          claude-md-guard (PostToolUse:Write)"
} else {
    Write-Host "  Already present: claude-md-guard"
}

# Write back
$json | ConvertTo-Json -Depth 10 | Set-Content $Settings -Encoding UTF8
Write-Host "  settings.json updated."

Write-Host ""
Write-Host "Done. Restart Claude Code to activate hooks."
Write-Host ""
Write-Host "Note: RTK hook (PreToolUse:Bash) must be wired separately."
Write-Host "See windows\RTK.md for RTK installation and settings.json entry."
Write-Host ""
