# validate.ps1 -- Check Claude framework setup and project doc health
# Usage: .\validate.ps1 [-ProjectDir D:\repos\MyProject]

param([string]$ProjectDir = ".")

$Errors   = 0
$Warnings = 0

function Pass($msg)  { Write-Host "  PASS  $msg" -ForegroundColor Green }
function Fail($msg)  { Write-Host "  FAIL  $msg" -ForegroundColor Red;    $script:Errors++ }
function Warn($msg)  { Write-Host "  WARN  $msg" -ForegroundColor Yellow; $script:Warnings++ }

Write-Host ""
Write-Host "Claude Framework Validation"
Write-Host "==========================="

# -- Global install checks -----------------------------------------------------
Write-Host ""
Write-Host "[ Global Install ]"

$AgentDir = "$env:USERPROFILE\.claude\agents"
if (Test-Path $AgentDir) {
    $count = (Get-ChildItem "$AgentDir\*.md").Count
    if ($count -ge 17) { Pass "$count agents installed" }
    else               { Fail "Only $count agents installed -- expected 17. Re-run setup.ps1." }
} else {
    Fail "~\.claude\agents\ not found -- run setup.ps1 first"
}

$ClaudeMd = "$env:USERPROFILE\.claude\CLAUDE.md"
if (Test-Path $ClaudeMd) {
    $size = (Get-Item $ClaudeMd).Length
    if ($size -gt 4096) { Fail "CLAUDE.md is $size bytes -- over 4KB limit" }
    else                { Pass "CLAUDE.md is $size bytes" }
} else {
    Warn "CLAUDE.md not found -- run setup.ps1"
}

$Settings = "$env:USERPROFILE\.claude\settings.json"
if (Test-Path $Settings) {
    $content = Get-Content $Settings -Raw
    if ($content -match "secret-scanner")  { Pass "secret-scanner hook wired" }
    else                                   { Warn "secret-scanner not wired -- run wire-hooks.ps1" }
    if ($content -match "claude-md-guard") { Pass "claude-md-guard hook wired" }
    else                                   { Warn "claude-md-guard not wired -- run wire-hooks.ps1" }
} else {
    Warn "settings.json not found -- hooks not active"
}

# -- Project doc checks --------------------------------------------------------
Write-Host ""
Write-Host "[ Project Docs: $ProjectDir ]"

$claudeFile = "$ProjectDir\CLAUDE.md"
if (Test-Path $claudeFile) {
    $size = (Get-Item $claudeFile).Length
    $kb   = [math]::Round($size/1024, 1)
    if ($size -gt 4096) { Fail "CLAUDE.md is ${kb}KB -- over 4KB limit. Move detail to DESIGN.md." }
    else                { Pass "CLAUDE.md is ${kb}KB" }
} else {
    Warn "No CLAUDE.md in project root"
}

foreach ($md in @("ORCHESTRATOR.md","DEPLOYMENT.md")) {
    $path = "$ProjectDir\$md"
    if (Test-Path $path) {
        if (Get-Content $path | Select-String "^Extends:") { Pass "$md has Extends: line" }
        else                                               { Warn "$md missing 'Extends:' line" }
    }
}

# -- Unfilled placeholder check ------------------------------------------------
Write-Host ""
Write-Host "[ Unfilled Placeholders ]"

$foundBrackets = $false
Get-ChildItem "$ProjectDir\*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.md" } | ForEach-Object {
    $found = Select-String -Path $_.FullName -Pattern "\[YOUR_[A-Z_]+\]|\[your-[a-z-]+\]"
    if ($found) {
        Warn "$($_.Name) has unfilled [placeholders]"
        $found | Select-Object -First 3 | ForEach-Object { Write-Host "         $_" }
        $script:foundBrackets = $true
    }
}
if (-not $foundBrackets) { Pass "No unfilled placeholders found" }

# -- Summary -------------------------------------------------------------------
Write-Host ""
Write-Host "==========================="
if ($Errors -eq 0 -and $Warnings -eq 0) {
    Write-Host "  All checks passed." -ForegroundColor Green
} elseif ($Errors -eq 0) {
    Write-Host "  $Warnings warning(s) -- review above." -ForegroundColor Yellow
} else {
    Write-Host "  $Errors error(s), $Warnings warning(s) -- fix errors before proceeding." -ForegroundColor Red
    exit 1
}
Write-Host ""
