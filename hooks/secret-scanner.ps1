# PreToolUse:Write hook — blocks writes containing secret patterns
# Zero token cost. Runs before Claude writes any file.

$raw  = [Console]::In.ReadToEnd()
$data = $raw | ConvertFrom-Json
$file    = $data.tool_input.file_path
$content = $data.tool_input.content

# .env.example and .env.sample are meant to show key names — allow them
if ($file -match "\.env\.example|\.env\.sample") { exit 0 }

$patterns = @(
    'AKIA[0-9A-Z]{16}',
    'sk-ant-[a-zA-Z0-9\-]+',
    'sk-[a-zA-Z0-9]{48}',
    '-----BEGIN.*(RSA |EC |OPENSSH )?PRIVATE',
    'password\s*=\s*.{4,}',
    'client_secret\s*=\s*.{4,}',
    'api_key\s*=\s*.{4,}',
    'ANTHROPIC_API_KEY\s*=\s*.{4,}'
)

foreach ($pattern in $patterns) {
    if ($content -imatch $pattern) {
        Write-Output "SECRET SCANNER BLOCKED: $file"
        Write-Output "Pattern matched: $pattern"
        Write-Output "Looks like a secret. Use environment variables, Secrets Manager, or Windows Credential Manager instead."
        exit 2
    }
}

exit 0
