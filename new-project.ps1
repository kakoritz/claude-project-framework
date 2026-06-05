# new-project.ps1 — Scaffold a new DCLI project with Claude MD templates
# Usage: .\new-project.ps1 [-Name <name>] [-Path <dest>]
# Run from: %USERPROFILE%\dotfiles-claude\

param(
    [string]$Name,
    [string]$Path = "D:\repos"
)

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Date    = Get-Date -Format "yyyy-MM-dd"

Write-Host ""
Write-Host "DCLI New Project"
Write-Host "================"

if (-not $Name) {
    $Name = Read-Host "Project name (e.g. RPA.MyBot.Performer)"
}

Write-Host ""
Write-Host "Project type:"
Write-Host "  [1] UiPath Bot       (Dispatcher or Performer)"
Write-Host "  [2] C# Library       (reusable .NET library)"
Write-Host "  [3] C# API           (ASP.NET Core minimal API)"
Write-Host "  [4] Web UX           (Node.js + React frontend + backend)"
Write-Host "  [5] Python           (script, agent, or service)"
Write-Host ""
$typeChoice = Read-Host "Type (1-5)"

$TypeMap = @{ "1"="uipath-bot"; "2"="csharp-library"; "3"="csharp-api"; "4"="nodejs-react"; "5"="python" }
if (-not $TypeMap.ContainsKey($typeChoice)) {
    Write-Error "Invalid choice '$typeChoice'"
    exit 1
}
$Type        = $TypeMap[$typeChoice]
$TemplateDir = "$RepoDir\templates\$Type"
$DestDir     = "$Path\$Name"

Write-Host ""

if (Test-Path $DestDir) {
    Write-Host "Folder already exists: $DestDir"
    $confirm = Read-Host "Add Claude MDs to existing folder? (y/n)"
    if ($confirm -ne "y") { Write-Host "Cancelled."; exit 0 }
} else {
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    Write-Host "Created: $DestDir"
}

Write-Host ""
Get-ChildItem "$TemplateDir\*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace '\{\{PROJECT_NAME\}\}', $Name
    $content = $content -replace '\{\{DATE\}\}',         $Date
    Set-Content "$DestDir\$($_.Name)" $content -NoNewline -Encoding UTF8
    Write-Host "  OK $($_.Name)"
}

if ($Type -eq "uipath-bot") {
    Write-Host ""
    Write-Host "Orchestrator Scan"
    Write-Host "-----------------"
    Write-Host "Scan Orchestrator now to populate ORCHESTRATOR.md with live resource IDs?"
    $doScan = Read-Host "Run scan? (y/n)"
    if ($doScan -eq "y") {
        $foldersInput = Read-Host "Folder paths (comma-separated, e.g. Production/Dept/Bot,Test/Dept/Bot)"
        if ($foldersInput) {
            $scanScript = "$RepoDir\tools\scan-orchestrator.py"
            $outputFile = "$DestDir\ORCHESTRATOR.md"
            if (Test-Path $scanScript) {
                Write-Host ""
                python3 $scanScript --folders "$foldersInput" --project-name "$Name" --output "$outputFile"
            } else {
                Write-Host "  SKIP: tools/scan-orchestrator.py not found — fill in ORCHESTRATOR.md manually."
            }
        } else {
            Write-Host "  No folders entered — fill in ORCHESTRATOR.md manually."
        }
    } else {
        Write-Host "  Skipped. Run tools/scan-orchestrator.py later to populate ORCHESTRATOR.md."
    }
}

Write-Host ""
Write-Host "Done. Open $DestDir in Claude Code to get started."
Write-Host ""
Write-Host "Next: fill in the [placeholder] values in each MD file."
if ($Type -eq "uipath-bot") {
    Write-Host "      Check ORCHESTRATOR.md — run tools/scan-orchestrator.py if not yet populated."
}
if ($Type -in @("csharp-api","nodejs-react")) {
    Write-Host "      DEPLOYMENT.md needs your APP_NAME and AWS resource names."
}
Write-Host ""
