#!/bin/bash
# wire-hooks.sh — Safely merge hook entries into ~/.claude/settings.json
# Run after install.sh. Never replaces the full settings.json — only adds hooks.

CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
HOOKS_DIR="$CLAUDE_DIR/hooks"
TS=$(date +%Y%m%d-%H%M%S)

echo ""
echo "Wire Hooks into settings.json"
echo "=============================="

# Create settings.json if it doesn't exist
if [ ! -f "$SETTINGS" ]; then
    echo '{"hooks":{}}' > "$SETTINGS"
    echo "  Created new settings.json"
fi

# Backup
BACKUP="$SETTINGS.bak.$TS"
cp "$SETTINGS" "$BACKUP"
echo "  Backup: $BACKUP"

# Use Python to safely merge hooks (available on all target machines)
python3 - <<EOF
import json, sys

with open('$SETTINGS', 'r') as f:
    settings = json.load(f)

if 'hooks' not in settings:
    settings['hooks'] = {}

# PreToolUse hooks to add
pre = settings['hooks'].get('PreToolUse', [])
secret_hook = {
    "matcher": "Write",
    "hooks": [{"type": "command", "command": "$HOOKS_DIR/secret-scanner.sh"}]
}
# Only add if not already present
if not any(h.get('matcher') == 'Write' and
           any('secret-scanner' in str(x) for x in h.get('hooks', []))
           for h in pre):
    pre.append(secret_hook)
    print("  Added: secret-scanner (PreToolUse:Write)")
else:
    print("  Already present: secret-scanner")

settings['hooks']['PreToolUse'] = pre

# PostToolUse hooks to add
post = settings['hooks'].get('PostToolUse', [])
guard_hook = {
    "matcher": "Write",
    "hooks": [{"type": "command", "command": "$HOOKS_DIR/claude-md-guard.sh"}]
}
if not any(h.get('matcher') == 'Write' and
           any('claude-md-guard' in str(x) for x in h.get('hooks', []))
           for h in post):
    post.append(guard_hook)
    print("  Added: claude-md-guard (PostToolUse:Write)")
else:
    print("  Already present: claude-md-guard")

settings['hooks']['PostToolUse'] = post

with open('$SETTINGS', 'w') as f:
    json.dump(settings, f, indent=2)

print("  settings.json updated.")
EOF

echo ""
echo "Done. Restart Claude Code to activate hooks."
echo ""
