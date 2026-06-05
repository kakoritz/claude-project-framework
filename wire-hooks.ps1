# wire-hooks.ps1 — Safely merge hook entries into %USERPROFILE%\.claude\settings.json
# Run after setup.ps1. Never replaces the full settings.json — only adds hooks.

$ClaudeDir  = "$env:USERPROFILE\.claude"
$Settings   = "$ClaudeDir\settings.json"
$HooksDir   = "$ClaudeDir\hooks"
$Ts         = Get-Date -Format "yyyyMMdd-HHmmss"

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

# Use Python to safely merge (available on all dev machines)
$script = @"
import json, sys

with open(r'$Settings', 'r') as f:
    settings = json.load(f)

if 'hooks' not in settings:
    settings['hooks'] = {}

pre = settings['hooks'].get('PreToolUse', [])
secret_hook = {
    'matcher': 'Write',
    'hooks': [{'type': 'command', 'command': 'powershell -File $HooksDir\\\\secret-scanner.ps1'}]
}
if not any(h.get('matcher') == 'Write' and
           any('secret-scanner' in str(x) for x in h.get('hooks', []))
           for h in pre):
    pre.append(secret_hook)
    print('  Added: secret-scanner (PreToolUse:Write)')
else:
    print('  Already present: secret-scanner')

settings['hooks']['PreToolUse'] = pre

post = settings['hooks'].get('PostToolUse', [])
guard_hook = {
    'matcher': 'Write',
    'hooks': [{'type': 'command', 'command': 'powershell -File $HooksDir\\\\claude-md-guard.ps1'}]
}
if not any(h.get('matcher') == 'Write' and
           any('claude-md-guard' in str(x) for x in h.get('hooks', []))
           for h in post):
    post.append(guard_hook)
    print('  Added: claude-md-guard (PostToolUse:Write)')
else:
    print('  Already present: claude-md-guard')

settings['hooks']['PostToolUse'] = post

with open(r'$Settings', 'w') as f:
    json.dump(settings, f, indent=2)

print('  settings.json updated.')
"@

$py = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }
& $py -c $script

Write-Host ""
Write-Host "Done. Restart Claude Code to activate hooks."
Write-Host ""
Write-Host "Note: RTK hook (PreToolUse:Bash) must be wired separately."
Write-Host "See windows\RTK.md for RTK installation and settings.json entry."
Write-Host ""
