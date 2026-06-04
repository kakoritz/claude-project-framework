#!/bin/bash
# validate.sh — Check Claude framework setup and project doc health
# Run from: project root (checks project docs) OR repo root (checks global install)
# Usage: ./validate.sh [--project /path/to/project]

set -e

ERRORS=0
WARNINGS=0
PROJECT_DIR=${2:-"."}

pass()  { echo "  PASS  $1"; }
fail()  { echo "  FAIL  $1"; ERRORS=$((ERRORS+1)); }
warn()  { echo "  WARN  $1"; WARNINGS=$((WARNINGS+1)); }

echo ""
echo "Claude Framework Validation"
echo "==========================="

# ── Global install checks ─────────────────────────────────────────────────────
echo ""
echo "[ Global Install ]"

AGENT_DIR="$HOME/.claude/agents"
if [ -d "$AGENT_DIR" ]; then
    COUNT=$(ls "$AGENT_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$COUNT" -ge 15 ]; then
        pass "$COUNT agents installed"
    else
        fail "Only $COUNT agents installed — expected 15. Re-run install.sh."
    fi
else
    fail "~/.claude/agents/ not found — run install.sh first"
fi

CLAUDE_MD="$HOME/.claude/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
    SIZE=$(wc -c < "$CLAUDE_MD")
    if [ "$SIZE" -gt 4096 ]; then
        fail "~/.claude/CLAUDE.md is ${SIZE} bytes — over 4KB limit"
    else
        pass "~/.claude/CLAUDE.md is ${SIZE} bytes"
    fi
else
    warn "~/.claude/CLAUDE.md not found — run install.sh"
fi

SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
    if grep -q "secret-scanner" "$SETTINGS" 2>/dev/null; then
        pass "secret-scanner hook wired in settings.json"
    else
        warn "secret-scanner not wired — run wire-hooks.sh"
    fi
    if grep -q "claude-md-guard" "$SETTINGS" 2>/dev/null; then
        pass "claude-md-guard hook wired in settings.json"
    else
        warn "claude-md-guard not wired — run wire-hooks.sh"
    fi
else
    warn "settings.json not found — hooks not active"
fi

# ── Project doc checks ────────────────────────────────────────────────────────
echo ""
echo "[ Project Docs: $PROJECT_DIR ]"

if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    SIZE=$(wc -c < "$PROJECT_DIR/CLAUDE.md")
    KB=$(awk "BEGIN {printf \"%.1f\", $SIZE/1024}")
    if [ "$SIZE" -gt 4096 ]; then
        fail "CLAUDE.md is ${KB}KB — over 4KB limit. Move detail to DESIGN.md."
    else
        pass "CLAUDE.md is ${KB}KB"
    fi
else
    warn "No CLAUDE.md in project root"
fi

for md in ORCHESTRATOR.md DEPLOYMENT.md; do
    if [ -f "$PROJECT_DIR/$md" ]; then
        if grep -q "^Extends:" "$PROJECT_DIR/$md"; then
            pass "$md has Extends: line"
        else
            warn "$md exists but missing 'Extends:' line — add global standard reference"
        fi
    fi
done

# ── Unfilled placeholder check ────────────────────────────────────────────────
echo ""
echo "[ Unfilled Placeholders ]"

FOUND_BRACKETS=0
for md in "$PROJECT_DIR"/*.md; do
    [ -f "$md" ] || continue
    # Look for [UPPER_CASE] placeholder patterns (not markdown links)
    if grep -qE "\[YOUR_[A-Z_]+\]|\[your-[a-z-]+\]" "$md" 2>/dev/null; then
        warn "$(basename $md) has unfilled [placeholders]"
        grep -nE "\[YOUR_[A-Z_]+\]|\[your-[a-z-]+\]" "$md" | head -3 | sed 's/^/         /'
        FOUND_BRACKETS=1
    fi
done
[ $FOUND_BRACKETS -eq 0 ] && pass "No unfilled placeholders found"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "==========================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "  All checks passed."
elif [ $ERRORS -eq 0 ]; then
    echo "  $WARNINGS warning(s) — review above."
else
    echo "  $ERRORS error(s), $WARNINGS warning(s) — fix errors before proceeding."
    exit 1
fi
echo ""
