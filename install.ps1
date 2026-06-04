# install.ps1 — Install DCLI Claude global config to %USERPROFILE%\.claude\
# Run from: %USERPROFILE%\dotfiles-claude\
# No admin required. Run as your normal user account.

$RepoDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = "$env:USERPROFILE\.claude"
$AgentsDir = "$ClaudeDir\agents"

Write-Host ""
Write-Host "DCLI Claude Global Install"
Write-Host "=========================="

# ── Agents (always safe — create/overwrite) ───────────────────────────────────
New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null
Get-ChildItem "$RepoDir\agents\*.md" | ForEach-Object {
    Copy-Item $_.FullName "$AgentsDir\$($_.Name)" -Force
    Write-Host "  OK agents\$($_.Name)"
}

# ── RTK (Windows-only token optimizer) ────────────────────────────────────────
Copy-Item "$RepoDir\windows\RTK.md" "$ClaudeDir\RTK.md" -Force
Write-Host "  OK RTK.md"

# ── CLAUDE.md — smart handling ─────────────────────────────────────────────────
$claudeDest  = "$ClaudeDir\CLAUDE.md"
$ourContent  = "@RTK.md`n`n" + (Get-Content "$RepoDir\CLAUDE.md" -Raw)

Write-Host ""

if (-not (Test-Path $claudeDest)) {
    # Fresh install — no existing file
    Set-Content $claudeDest $ourContent -NoNewline -Encoding UTF8
    Write-Host "  OK CLAUDE.md (fresh install)"

} else {
    $existing     = Get-Content $claudeDest -Raw
    $existingSize = [math]::Round((Get-Item $claudeDest).Length / 1024, 1)
    $alreadySynced = ($existing -match "DCLI Infrastructure") -and ($existing -match "Agent Standards")

    if ($alreadySynced) {
        Write-Host "  CLAUDE.md already contains DCLI global standards — skipping"
        Write-Host "  (run with -ForceClaudeUpdate to override)"
    } else {
        Write-Host "  Existing CLAUDE.md found ($($existingSize)KB)"
        if ($existingSize -gt 4) {
            Write-Host "  WARNING: File is over 4KB — may contain content worth preserving"
        }
        Write-Host ""
        Write-Host "  What would you like to do?"
        Write-Host "    [R] Replace  — backup existing, install DCLI global standards"
        Write-Host "    [M] Merge    — backup + Claude Code will merge intelligently"
        Write-Host "    [S] Skip     — leave CLAUDE.md untouched"
        Write-Host ""
        $choice = Read-Host "  Choice (R/M/S)"

        switch ($choice.ToUpper()) {
            "R" {
                $ts     = Get-Date -Format "yyyyMMdd-HHmmss"
                $backup = "$claudeDest.bak.$ts"
                Copy-Item $claudeDest $backup
                Set-Content $claudeDest $ourContent -NoNewline -Encoding UTF8
                Write-Host "  OK CLAUDE.md replaced"
                Write-Host "  Backup: $backup"
            }
            "M" {
                $ts     = Get-Date -Format "yyyyMMdd-HHmmss"
                $backup = "$claudeDest.bak.$ts"
                Copy-Item $claudeDest $backup
                Write-Host "  Backup saved: $backup"
                Write-Host ""
                Write-Host "  ┌─ Run this prompt in Claude Code (any project terminal): ──────────────┐"
                Write-Host "  │                                                                       │"
                Write-Host "  │  My existing CLAUDE.md is backed up at:                               │"
                Write-Host "  │  $backup"
                Write-Host "  │                                                                       │"
                Write-Host "  │  The DCLI global standard is at:                                      │"
                Write-Host "  │  $RepoDir\CLAUDE.md                                                   │"
                Write-Host "  │                                                                       │"
                Write-Host "  │  Please merge them: keep my personal context, add DCLI global         │"
                Write-Host "  │  standards (agents, model rules, code style) where missing.           │"
                Write-Host "  │  Result must be under 4KB. Write to ~/.claude/CLAUDE.md              │"
                Write-Host "  └───────────────────────────────────────────────────────────────────────┘"
            }
            "S" {
                Write-Host "  CLAUDE.md unchanged"
            }
            default {
                Write-Host "  Invalid choice — CLAUDE.md unchanged"
            }
        }
    }
}

# ── Hooks ─────────────────────────────────────────────────────────────────────
$HooksDir = "$ClaudeDir\hooks"
New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null
Get-ChildItem "$RepoDir\hooks\*.ps1" | ForEach-Object {
    Copy-Item $_.FullName "$HooksDir\$($_.Name)" -Force
    Write-Host "  OK hooks\$($_.Name)"
}

Write-Host ""
Write-Host "Done. Restart Claude Code to pick up changes."
Write-Host ""
Write-Host "  ┌─ Add hooks to %USERPROFILE%\.claude\settings.json ─────────────────┐"
Write-Host "  │  Merge this into your hooks section (keep any existing hooks):    │"
Write-Host "  │                                                                   │"
Write-Host "  │  `"PreToolUse`": [{                                                 │"
Write-Host "  │    `"matcher`": `"Write`",                                            │"
Write-Host "  │    `"hooks`": [{`"type`": `"command`",                                  │"
Write-Host "  │      `"command`": `"powershell -File $HooksDir\secret-scanner.ps1`"}] │"
Write-Host "  │  }],                                                              │"
Write-Host "  │  `"PostToolUse`": [{                                                │"
Write-Host "  │    `"matcher`": `"Write`",                                            │"
Write-Host "  │    `"hooks`": [{`"type`": `"command`",                                  │"
Write-Host "  │      `"command`": `"powershell -File $HooksDir\claude-md-guard.ps1`"}] │"
Write-Host "  │  }]                                                               │"
Write-Host "  └───────────────────────────────────────────────────────────────────┘"
Write-Host ""
