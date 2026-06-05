# setup.ps1 -- Install or update DCLI Claude global config
# Run from: %USERPROFILE%\claude-project-framework\  (or wherever the repo lives)
# No admin required. Run as your normal user account.
#
# Usage:
#   .\setup.ps1               auto-detect (update if agents exist, fresh otherwise)
#   .\setup.ps1 --fresh       force full fresh install
#   .\setup.ps1 --update      force update mode
#   .\setup.ps1 --add-markers add framework markers to existing CLAUDE.md, then exit

param([string]$Mode = "")

$RepoDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = "$env:USERPROFILE\.claude"
$AgentsDir = "$ClaudeDir\agents"
$HooksDir  = "$ClaudeDir\hooks"
$Arg       = if ($args.Count -gt 0) { $args[0] } else { $Mode }

# -- Detect python command (python3 on Linux/Mac, python on Windows) -----------
$Python = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }

# -- --add-markers shortcut ----------------------------------------------------
if ($Arg -eq "--add-markers") {
    & $Python "$RepoDir\tools\claude-md.py" add-markers "$ClaudeDir\CLAUDE.md"
    exit 0
}

# -- Auto-detect mode ----------------------------------------------------------
$agentFiles = Get-ChildItem "$AgentsDir\*.md" -ErrorAction SilentlyContinue
$mode = if ($agentFiles.Count -gt 0) { "update" } else { "fresh" }
if ($Arg -eq "--fresh")  { $mode = "fresh" }
if ($Arg -eq "--update") { $mode = "update" }

# -- Read config.yaml ----------------------------------------------------------
function Read-Config([string]$Key, [string]$Default) {
    try {
        $result = & $Python -c "import yaml; d=yaml.safe_load(open('$RepoDir/config.yaml')); print(d$Key)" 2>$null
        if ($result) { return $result.Trim() } else { return $Default }
    } catch { return $Default }
}
$Haiku    = Read-Config "['models']['haiku']"   "claude-haiku-4-5-20251001"
$Sonnet   = Read-Config "['models']['sonnet']"  "claude-sonnet-4-6"
$Opus     = Read-Config "['models']['opus']"    "claude-opus-4-8"
$RepoVer  = Read-Config ".get('version','?')"   "?"
$InstVer  = if (Test-Path "$ClaudeDir\.framework-version") {
                Get-Content "$ClaudeDir\.framework-version" -Raw
            } else { "none" }

Write-Host ""
if ($mode -eq "update") {
    Write-Host "Claude Framework -- Update  (installed: $($InstVer.Trim()) -> repo: $RepoVer)"
} else {
    Write-Host "Claude Framework -- Fresh Install  (repo: $RepoVer)"
}
Write-Host "================================================"

# -- Python deps: tree-sitter for hooks ---------------------------------------
Write-Host ""
try {
    pip install --user tree-sitter "tree-sitter-languages>=1.10" --quiet 2>$null
    Write-Host "  OK  tree-sitter (hooks now use AST-aware secret scanning)"
} catch {
    Write-Host "  WARN tree-sitter install failed -- hooks fall back to regex scanning"
}

# -- RTK (token optimizer) ----------------------------------------------------
$rtkSrc = "$RepoDir\windows\RTK.md"
if (Test-Path $rtkSrc) {
    Copy-Item $rtkSrc "$ClaudeDir\RTK.md" -Force
}

if (Get-Command rtk -ErrorAction SilentlyContinue) {
    Write-Host "  OK  rtk $(rtk --version 2>$null)"
} else {
    Write-Host "  Installing rtk..."
    $installed = $false

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install rtk --silent 2>$null
        if (Get-Command rtk -ErrorAction SilentlyContinue) { $installed = $true }
    }

    if (-not $installed -and (Get-Command cargo -ErrorAction SilentlyContinue)) {
        cargo install rtk --quiet 2>$null
        if (Get-Command rtk -ErrorAction SilentlyContinue) { $installed = $true }
    }

    if ($installed) {
        Write-Host "  OK  rtk installed"
    } else {
        Write-Host "  WARN rtk install failed -- install manually: winget install rtk  OR  cargo install rtk"
    }
}

# -- Agents --------------------------------------------------------------------
Write-Host ""
New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null
$ANew = 0; $AUpd = 0; $ASame = 0

Get-ChildItem "$RepoDir\agents\*.md" | ForEach-Object {
    $name = $_.Name
    $dest = "$AgentsDir\$name"

    # Apply model name substitution
    $content = (Get-Content $_.FullName -Raw -Encoding UTF8) `
        -replace 'claude-haiku-4-5-20251001', $Haiku `
        -replace 'claude-sonnet-4-6', $Sonnet `
        -replace 'claude-opus-4-8', $Opus

    if (-not (Test-Path $dest)) {
        [System.IO.File]::WriteAllText($dest, $content, [System.Text.Encoding]::UTF8)
        Write-Host "  +  agents\$name"
        $ANew++
    } else {
        $existing = Get-Content $dest -Raw -Encoding UTF8
        if ($existing -ne $content) {
            [System.IO.File]::WriteAllText($dest, $content, [System.Text.Encoding]::UTF8)
            Write-Host "  ~  agents\$name"
            $AUpd++
        } else {
            $ASame++
        }
    }
}

# -- Hooks ---------------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null
$HNew = 0; $HUpd = 0

Get-ChildItem "$RepoDir\hooks\*" | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
    $name = $_.Name
    $dest = "$HooksDir\$name"

    if (-not (Test-Path $dest)) {
        Copy-Item $_.FullName $dest -Force
        Write-Host "  +  hooks\$name"
        $HNew++
    } else {
        $srcHash  = (Get-FileHash $_.FullName  -Algorithm MD5).Hash
        $dstHash  = (Get-FileHash $dest         -Algorithm MD5).Hash
        if ($srcHash -ne $dstHash) {
            Copy-Item $_.FullName $dest -Force
            Write-Host "  ~  hooks\$name"
            $HUpd++
        }
    }
}

# -- Global docs (org-private knowledge files) --------------------------------
$globalDir = "$RepoDir\global"
if (Test-Path $globalDir) {
    $gNew = 0; $gUpd = 0
    Get-ChildItem "$globalDir\*" | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
        $name = $_.Name
        $dest = "$ClaudeDir\$name"
        if (-not (Test-Path $dest)) {
            Copy-Item $_.FullName $dest
            Write-Host "  +  $name"
            $gNew++
        } else {
            $srcHash  = (Get-FileHash $_.FullName  -Algorithm MD5).Hash
            $destHash = (Get-FileHash $dest -Algorithm MD5).Hash
            if ($srcHash -ne $destHash) {
                Copy-Item $_.FullName $dest -Force
                Write-Host "  ~  $name"
                $gUpd++
            }
        }
    }
    if ($gNew + $gUpd -gt 0) { Write-Host "" }
}

# -- CLAUDE.md -----------------------------------------------------------------
Write-Host ""
$claudeDest = "$ClaudeDir\CLAUDE.md"

if ($mode -eq "update") {
    # Update mode: only touch framework-marked sections, ask before each change
    & $Python "$RepoDir\tools\claude-md.py" update-sections $claudeDest "$RepoDir\CLAUDE.md"

} else {
    # Fresh install: R/M/S prompt
    $ourContent = "@RTK.md`n`n" + (Get-Content "$RepoDir\CLAUDE.md" -Raw -Encoding UTF8)

    if (-not (Test-Path $claudeDest)) {
        [System.IO.File]::WriteAllText($claudeDest, $ourContent, [System.Text.Encoding]::UTF8)
        Write-Host "  OK  CLAUDE.md (fresh install)"

    } else {
        $existingSize = [math]::Round((Get-Item $claudeDest).Length / 1024, 1)
        $existing     = Get-Content $claudeDest -Raw -Encoding UTF8
        $hasMarkers   = $existing -match 'framework-agent-standards'

        if ($hasMarkers) {
            Write-Host "  CLAUDE.md already has framework markers."
            Write-Host "  Re-run with --update to update individual sections."
        } else {
            if ($existingSize -gt 4) {
                Write-Host "  WARNING: existing CLAUDE.md is ${existingSize}KB -- may contain content worth preserving"
            }
            Write-Host ""
            Write-Host "  What would you like to do with the existing CLAUDE.md?"
            Write-Host "    [R] Replace  -- backup existing, write framework standard"
            Write-Host "    [M] Merge    -- backup + get a Claude Code merge prompt"
            Write-Host "    [S] Skip     -- leave CLAUDE.md untouched"
            Write-Host ""
            $choice = Read-Host "  Choice (R/M/S)"

            switch ($choice.ToUpper()) {
                "R" {
                    $ts     = Get-Date -Format "yyyyMMdd-HHmmss"
                    $backup = "$claudeDest.bak.$ts"
                    Copy-Item $claudeDest $backup
                    [System.IO.File]::WriteAllText($claudeDest, $ourContent, [System.Text.Encoding]::UTF8)
                    Write-Host "  OK  CLAUDE.md replaced"
                    Write-Host "  Backup: $backup"
                }
                "M" {
                    $ts     = Get-Date -Format "yyyyMMdd-HHmmss"
                    $backup = "$claudeDest.bak.$ts"
                    Copy-Item $claudeDest $backup
                    Write-Host "  Backup: $backup"
                    Write-Host ""
                    Write-Host "  +-  Paste this prompt into Claude Code  -+"
                    Write-Host "  |                                        |"
                    Write-Host "  |  My existing CLAUDE.md is backed up:  |"
                    Write-Host "  |    $backup"
                    Write-Host "  |  Framework standard is at:             |"
                    Write-Host "  |    $RepoDir\CLAUDE.md                  |"
                    Write-Host "  |  Merge them: keep my personal context  |"
                    Write-Host "  |  (Who I Am, org infra), add framework  |"
                    Write-Host "  |  sections where missing. Preserve      |"
                    Write-Host "  |  <!-- BEGIN/END:framework-* --> marks. |"
                    Write-Host "  |  Under 4KB. Write to ~/.claude/CLAUDE.md"
                    Write-Host "  +-----------------------------------------+"
                }
                "S" {
                    Write-Host "  CLAUDE.md unchanged"
                }
                default {
                    Write-Host "  Invalid -- CLAUDE.md unchanged"
                }
            }
        }
    }
}

# -- Version sentinel ----------------------------------------------------------
Set-Content "$ClaudeDir\.framework-version" $RepoVer -Encoding UTF8

# -- Summary -------------------------------------------------------------------
Write-Host ""
Write-Host "================================================"
if ($mode -eq "update") {
    Write-Host "Update complete."
    Write-Host "  Agents  +$ANew new  ~$AUpd updated  $ASame unchanged"
    Write-Host "  Hooks   +$HNew new  ~$HUpd updated"
} else {
    $total = (Get-ChildItem "$AgentsDir\*.md" -ErrorAction SilentlyContinue).Count
    Write-Host "Install complete. $total agents installed."
}
Write-Host ""
Write-Host "  Wire hooks (if not already done):"
Write-Host "    .\wire-hooks.ps1"
Write-Host ""
