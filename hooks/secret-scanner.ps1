# PreToolUse:Write hook -- blocks writes containing secret patterns
# Zero token cost. Runs before Claude writes any file.
# Uses tree-sitter context when available to avoid flagging comments and test strings.

$raw  = [Console]::In.ReadToEnd()
$data = $raw | ConvertFrom-Json
$file    = $data.tool_input.file_path
$content = $data.tool_input.content

# Files to always allow
if ($file -match "\.env\.example|\.env\.sample|\.env\.template|\.test\.|\.spec\.|_test\.|\.md$") { exit 0 }

# Allow if content has # noscan directive
if ($content -match "# noscan") { exit 0 }

# -- Determine what to scan ----------------------------------------------------
$hooksDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ext = [System.IO.Path]::GetExtension($file).TrimStart('.')
$checkContent = $content
$tsExts = @('py', 'cs', 'js', 'ts', 'tsx', 'jsx')

if ($tsExts -contains $ext) {
    $tmpFile = [System.IO.Path]::GetTempFileName()
    $tmpFileExt = "$tmpFile.$ext"
    [System.IO.File]::WriteAllText($tmpFileExt, $content, [System.Text.Encoding]::UTF8)

    $tsScript = Join-Path $hooksDir "ts-context.py"
    if (Test-Path $tsScript) {
        try {
            $py = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }
            $tsResult = & $py $tsScript $tmpFileExt 2>$null
            if ($tsResult) {
                $tsJson = $tsResult | ConvertFrom-Json
                if (-not $tsJson.fallback) {
                    $checkContent = ($tsJson.strings + $tsJson.assignments) -join "`n"
                }
            }
        } catch {}
    }

    Remove-Item $tmpFileExt -ErrorAction SilentlyContinue
    Remove-Item $tmpFile -ErrorAction SilentlyContinue
}

# -- Scan for secret patterns --------------------------------------------------
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
    if ($checkContent -imatch $pattern) {
        Write-Output "SECRET SCANNER BLOCKED: $file"
        Write-Output "Pattern matched: $pattern"
        Write-Output "Looks like a secret. Use environment variables, Secrets Manager, or Windows Credential Manager instead."
        exit 2
    }
}

exit 0
