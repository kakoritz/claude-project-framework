#!/bin/bash
# install.sh — Install DCLI Claude global config to ~/.claude/
# Run from: ~/dotfiles-claude/

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"

echo ""
echo "DCLI Claude Global Install"
echo "=========================="

# ── Read model names from config.yaml ────────────────────────────────────────
HAIKU=$(python3 -c "import yaml; print(yaml.safe_load(open('$REPO_DIR/config.yaml'))['models']['haiku'])" 2>/dev/null || echo "claude-haiku-4-5-20251001")
SONNET=$(python3 -c "import yaml; print(yaml.safe_load(open('$REPO_DIR/config.yaml'))['models']['sonnet'])" 2>/dev/null || echo "claude-sonnet-4-6")
OPUS=$(python3 -c "import yaml; print(yaml.safe_load(open('$REPO_DIR/config.yaml'))['models']['opus'])" 2>/dev/null || echo "claude-opus-4-8")

# ── Agents (always safe — create/overwrite, substitute model names) ───────────
mkdir -p "$AGENTS_DIR"
for agent in "$REPO_DIR/agents/"*.md; do
    dest="$AGENTS_DIR/$(basename "$agent")"
    sed "s/claude-haiku-4-5-20251001/$HAIKU/g; s/claude-sonnet-4-6/$SONNET/g; s/claude-opus-4-8/$OPUS/g" "$agent" > "$dest"
    echo "  OK agents/$(basename "$agent")"
done

# ── CLAUDE.md — smart handling ─────────────────────────────────────────────────
CLAUDE_DEST="$CLAUDE_DIR/CLAUDE.md"
OUR_CONTENT=$(cat "$REPO_DIR/CLAUDE.md")

echo ""

if [ ! -f "$CLAUDE_DEST" ]; then
    echo "$OUR_CONTENT" > "$CLAUDE_DEST"
    echo "  OK CLAUDE.md (fresh install)"

else
    EXISTING=$(cat "$CLAUDE_DEST")
    EXISTING_SIZE=$(du -k "$CLAUDE_DEST" | cut -f1)
    ALREADY_SYNCED=0
    echo "$EXISTING" | grep -q "DCLI Infrastructure" && echo "$EXISTING" | grep -q "Agent Standards" && ALREADY_SYNCED=1

    if [ $ALREADY_SYNCED -eq 1 ]; then
        echo "  CLAUDE.md already contains DCLI global standards — skipping"
    else
        echo "  Existing CLAUDE.md found (${EXISTING_SIZE}KB)"
        [ "$EXISTING_SIZE" -gt 4 ] && echo "  WARNING: File is over 4KB — may contain content worth preserving"
        echo ""
        echo "  What would you like to do?"
        echo "    [R] Replace  — backup existing, install DCLI global standards"
        echo "    [M] Merge    — backup + Claude Code will merge intelligently"
        echo "    [S] Skip     — leave CLAUDE.md untouched"
        echo ""
        read -p "  Choice (R/M/S): " choice

        case "${choice^^}" in
            R)
                TS=$(date +%Y%m%d-%H%M%S)
                BACKUP="$CLAUDE_DEST.bak.$TS"
                cp "$CLAUDE_DEST" "$BACKUP"
                echo "$OUR_CONTENT" > "$CLAUDE_DEST"
                echo "  OK CLAUDE.md replaced"
                echo "  Backup: $BACKUP"
                ;;
            M)
                TS=$(date +%Y%m%d-%H%M%S)
                BACKUP="$CLAUDE_DEST.bak.$TS"
                cp "$CLAUDE_DEST" "$BACKUP"
                echo "  Backup saved: $BACKUP"
                echo ""
                echo "  ┌─ Run this prompt in Claude Code (any project terminal): ──────────────┐"
                echo "  │                                                                       │"
                echo "  │  My existing CLAUDE.md is backed up at:                               │"
                echo "  │  $BACKUP"
                echo "  │                                                                       │"
                echo "  │  The DCLI global standard is at:                                      │"
                echo "  │  $REPO_DIR/CLAUDE.md                                                  │"
                echo "  │                                                                       │"
                echo "  │  Please merge them: keep my personal context, add DCLI global         │"
                echo "  │  standards (agents, model rules, code style) where missing.           │"
                echo "  │  Result must be under 4KB. Write to ~/.claude/CLAUDE.md              │"
                echo "  └───────────────────────────────────────────────────────────────────────┘"
                ;;
            S)
                echo "  CLAUDE.md unchanged"
                ;;
            *)
                echo "  Invalid choice — CLAUDE.md unchanged"
                ;;
        esac
    fi
fi

# ── Hooks ─────────────────────────────────────────────────────────────────────
HOOKS_DIR="$CLAUDE_DIR/hooks"
mkdir -p "$HOOKS_DIR"
for hook in "$REPO_DIR/hooks/"*.sh; do
    cp "$hook" "$HOOKS_DIR/$(basename "$hook")"
    chmod +x "$HOOKS_DIR/$(basename "$hook")"
    echo "  OK hooks/$(basename "$hook")"
done

echo ""
echo "Done. Restart Claude Code to pick up changes."
echo ""
echo "  ┌─ Add hooks to ~/.claude/settings.json ────────────────────────────────┐"
echo "  │  Merge this into your hooks section (keep any existing hooks):        │"
echo "  │                                                                       │"
echo "  │  \"PreToolUse\": [{                                                     │"
echo "  │    \"matcher\": \"Write\",                                                │"
echo "  │    \"hooks\": [{\"type\": \"command\",                                      │"
echo "  │      \"command\": \"$HOOKS_DIR/secret-scanner.sh\"}]                      │"
echo "  │  }],                                                                  │"
echo "  │  \"PostToolUse\": [{                                                    │"
echo "  │    \"matcher\": \"Write\",                                                │"
echo "  │    \"hooks\": [{\"type\": \"command\",                                      │"
echo "  │      \"command\": \"$HOOKS_DIR/claude-md-guard.sh\"}]                     │"
echo "  │  }]                                                                   │"
echo "  └───────────────────────────────────────────────────────────────────────┘"
echo ""
