# PostToolUse:Write hook -- warns Claude if CLAUDE.md exceeds 4KB
# Zero token cost unless it fires (one warning line = ~20 tokens).

$raw  = [Console]::In.ReadToEnd()
$data = $raw | ConvertFrom-Json
$file = $data.tool_input.file_path

if ($file -notmatch "CLAUDE\.md$") { exit 0 }
if (-not (Test-Path $file))        { exit 0 }

$size = (Get-Item $file).Length
$kb   = [math]::Round($size / 1024, 1)

if ($size -gt 4096) {
    Write-Output "CLAUDE.md GUARD: $file is ${kb}KB -- over the 4KB limit."
    Write-Output "CLAUDE.md should be rules only. Move detail to DESIGN.md, ORCHESTRATOR.md, or other Delta MDs."
    Write-Output "Current: $size bytes. Target: under 4096 bytes."
}

exit 0
