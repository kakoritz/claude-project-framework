#!/bin/bash
# setup.sh — Install or update DCLI Claude global config
# Run from: ~/claude-project-framework/
#
# Usage:
#   ./setup.sh               auto-detect (update if agents exist, fresh otherwise)
#   ./setup.sh --fresh       force full fresh install
#   ./setup.sh --update      force update mode
#   ./setup.sh --add-markers add framework markers to existing CLAUDE.md, then exit

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"
HOOKS_DIR="$CLAUDE_DIR/hooks"

# ── --add-markers shortcut ────────────────────────────────────────────────────
if [ "$1" = "--add-markers" ]; then
    python3 "$REPO_DIR/tools/claude-md.py" add-markers "$CLAUDE_DIR/CLAUDE.md"
    exit 0
fi

# ── Auto-detect mode ──────────────────────────────────────────────────────────
AGENT_COUNT=$(ls "$AGENTS_DIR"/*.md 2>/dev/null | wc -l 2>/dev/null || echo 0)
MODE="fresh"
[ "${AGENT_COUNT:-0}" -gt 0 ] && MODE="update"
[ "$1" = "--fresh" ]  && MODE="fresh"
[ "$1" = "--update" ] && MODE="update"

# ── Read config.yaml ──────────────────────────────────────────────────────────
_cfg() {
    python3 -c "import yaml; d=yaml.safe_load(open('$REPO_DIR/config.yaml')); print(d$1)" 2>/dev/null || echo "$2"
}
HAIKU=$(_cfg "['models']['haiku']"   "claude-haiku-4-5-20251001")
SONNET=$(_cfg "['models']['sonnet']" "claude-sonnet-4-6")
OPUS=$(_cfg "['models']['opus']"     "claude-opus-4-8")
REPO_VER=$(_cfg ".get('version','?')" "?")
INST_VER=$(cat "$CLAUDE_DIR/.framework-version" 2>/dev/null || echo "none")

echo ""
if [ "$MODE" = "update" ]; then
    echo "Claude Framework — Update  (installed: $INST_VER → repo: $REPO_VER)"
else
    echo "Claude Framework — Fresh Install  (repo: $REPO_VER)"
fi
echo "================================================"

# ── Python deps: tree-sitter for hooks ───────────────────────────────────────
echo ""
if command -v pip3 >/dev/null 2>&1; then
    pip3 install --user --quiet tree-sitter "tree-sitter-languages>=1.10" 2>/dev/null \
        && echo "  OK  tree-sitter (hooks now use AST-aware secret scanning)" \
        || echo "  WARN tree-sitter install failed — hooks fall back to regex scanning"
else
    echo "  SKIP tree-sitter (pip3 not found — hooks will use regex scanning)"
fi

# ── RTK (token optimizer) ────────────────────────────────────────────────────
if command -v rtk >/dev/null 2>&1; then
    echo "  OK  rtk $(rtk --version 2>/dev/null)"
elif command -v cargo >/dev/null 2>&1; then
    echo "  Installing rtk via cargo..."
    cargo install rtk --quiet 2>/dev/null \
        && echo "  OK  rtk installed" \
        || echo "  WARN rtk install failed -- install manually: cargo install rtk"
else
    echo "  WARN rtk not found and cargo not available -- install rtk manually for token savings"
fi

# ── Agents ────────────────────────────────────────────────────────────────────
echo ""
mkdir -p "$AGENTS_DIR"
A_NEW=0; A_UPD=0; A_SAME=0

for agent in "$REPO_DIR/agents/"*.md; do
    [ -f "$agent" ] || continue
    name=$(basename "$agent")
    dest="$AGENTS_DIR/$name"

    tmp=$(mktemp)
    sed "s/claude-haiku-4-5-20251001/$HAIKU/g; \
         s/claude-sonnet-4-6/$SONNET/g; \
         s/claude-opus-4-8/$OPUS/g" "$agent" > "$tmp"

    if [ ! -f "$dest" ]; then
        cp "$tmp" "$dest"
        echo "  +  agents/$name"
        A_NEW=$((A_NEW + 1))
    elif ! diff -q "$tmp" "$dest" >/dev/null 2>&1; then
        cp "$tmp" "$dest"
        echo "  ~  agents/$name"
        A_UPD=$((A_UPD + 1))
    else
        A_SAME=$((A_SAME + 1))
    fi
    rm -f "$tmp"
done

# ── Hooks ─────────────────────────────────────────────────────────────────────
mkdir -p "$HOOKS_DIR"
H_NEW=0; H_UPD=0

for hook in "$REPO_DIR/hooks/"*; do
    [ -f "$hook" ] || continue
    name=$(basename "$hook")
    dest="$HOOKS_DIR/$name"

    if [ ! -f "$dest" ]; then
        cp "$hook" "$dest"
        chmod +x "$dest" 2>/dev/null || true
        echo "  +  hooks/$name"
        H_NEW=$((H_NEW + 1))
    elif ! diff -q "$hook" "$dest" >/dev/null 2>&1; then
        cp "$hook" "$dest"
        chmod +x "$dest" 2>/dev/null || true
        echo "  ~  hooks/$name"
        H_UPD=$((H_UPD + 1))
    fi
done

# ── Global docs (org-private knowledge files) ────────────────────────────────
if [ -d "$REPO_DIR/global" ]; then
    G_NEW=0; G_UPD=0
    for doc in "$REPO_DIR/global/"*; do
        [ -f "$doc" ] || continue
        name=$(basename "$doc")
        dest="$CLAUDE_DIR/$name"
        if [ ! -f "$dest" ]; then
            cp "$doc" "$dest"
            echo "  +  $name"
            G_NEW=$((G_NEW + 1))
        elif ! diff -q "$doc" "$dest" >/dev/null 2>&1; then
            cp "$doc" "$dest"
            echo "  ~  $name"
            G_UPD=$((G_UPD + 1))
        fi
    done
    [ $((G_NEW + G_UPD)) -gt 0 ] && echo "" || true
fi

# ── CLAUDE.md ─────────────────────────────────────────────────────────────────
echo ""
CLAUDE_DEST="$CLAUDE_DIR/CLAUDE.md"

if [ "$MODE" = "update" ]; then
    # Update mode: only touch framework-marked sections, ask before each change
    python3 "$REPO_DIR/tools/claude-md.py" update-sections "$CLAUDE_DEST" "$REPO_DIR/CLAUDE.md"

else
    # Fresh install: full R/M/S prompt
    OUR_CONTENT=$(cat "$REPO_DIR/CLAUDE.md")

    if [ ! -f "$CLAUDE_DEST" ]; then
        printf '%s\n' "$OUR_CONTENT" > "$CLAUDE_DEST"
        echo "  OK  CLAUDE.md (fresh install)"

    else
        EXISTING_SIZE=$(wc -c < "$CLAUDE_DEST" | tr -d ' ')
        HAS_MARKERS=0
        grep -q "framework-agent-standards" "$CLAUDE_DEST" 2>/dev/null && HAS_MARKERS=1

        if [ $HAS_MARKERS -eq 1 ]; then
            echo "  CLAUDE.md already has framework markers."
            echo "  Re-run with --update to update individual sections."
        else
            [ "$EXISTING_SIZE" -gt 4096 ] && \
                echo "  WARNING: existing CLAUDE.md is ${EXISTING_SIZE} bytes — may contain content worth preserving"
            echo ""
            echo "  What would you like to do with the existing CLAUDE.md?"
            echo "    [R] Replace  — backup existing, write framework standard"
            echo "    [M] Merge    — backup + get a Claude Code merge prompt"
            echo "    [S] Skip     — leave CLAUDE.md untouched"
            echo ""
            read -p "  Choice (R/M/S): " choice
            case "${choice^^}" in
                R)
                    TS=$(date +%Y%m%d-%H%M%S)
                    cp "$CLAUDE_DEST" "$CLAUDE_DEST.bak.$TS"
                    printf '%s\n' "$OUR_CONTENT" > "$CLAUDE_DEST"
                    echo "  OK  CLAUDE.md replaced"
                    echo "  Backup: $CLAUDE_DEST.bak.$TS"
                    ;;
                M)
                    TS=$(date +%Y%m%d-%H%M%S)
                    cp "$CLAUDE_DEST" "$CLAUDE_DEST.bak.$TS"
                    echo "  Backup: $CLAUDE_DEST.bak.$TS"
                    echo ""
                    echo "  ┌─ Paste this prompt into Claude Code ─────────────────────────────────┐"
                    echo "  │                                                                      │"
                    echo "  │  My existing CLAUDE.md is backed up at:                              │"
                    echo "  │    $CLAUDE_DEST.bak.$TS"
                    echo "  │  The framework standard is at:                                       │"
                    echo "  │    $REPO_DIR/CLAUDE.md                                               │"
                    echo "  │  Merge them: keep my personal context (Who I Am, org infra), add     │"
                    echo "  │  framework sections (agents, model rules, code style, branch rules)  │"
                    echo "  │  where missing. Preserve <!-- BEGIN/END:framework-* --> markers.     │"
                    echo "  │  Result must be under 4KB. Write to ~/.claude/CLAUDE.md             │"
                    echo "  └──────────────────────────────────────────────────────────────────────┘"
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
fi

# ── Version sentinel ──────────────────────────────────────────────────────────
echo "$REPO_VER" > "$CLAUDE_DIR/.framework-version"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "================================================"
if [ "$MODE" = "update" ]; then
    echo "Update complete."
    echo "  Agents  +$A_NEW new  ~$A_UPD updated  $A_SAME unchanged"
    echo "  Hooks   +$H_NEW new  ~$H_UPD updated"
else
    TOTAL=$(ls "$AGENTS_DIR"/*.md 2>/dev/null | wc -l || echo 0)
    echo "Install complete. $TOTAL agents installed."
fi
echo ""
echo "  Wire hooks (if not already done):"
echo "    bash $REPO_DIR/wire-hooks.sh"
echo ""
