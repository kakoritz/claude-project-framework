#!/bin/bash
# PostToolUse:Write hook — warns Claude if CLAUDE.md exceeds 4KB
# Zero token cost unless it fires (one warning line = ~20 tokens).

RAW=$(cat)
FILE=$(echo "$RAW" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Only care about CLAUDE.md files
if [[ "$FILE" != *"CLAUDE.md"* ]]; then
    exit 0
fi

[ ! -f "$FILE" ] && exit 0

SIZE=$(wc -c < "$FILE")
KB=$(awk "BEGIN {printf \"%.1f\", $SIZE/1024}")

if [ "$SIZE" -gt 4096 ]; then
    echo "CLAUDE.md GUARD: $FILE is ${KB}KB — over the 4KB limit."
    echo "CLAUDE.md should be rules only. Move detail to DESIGN.md, ORCHESTRATOR.md, or other Delta MDs."
    echo "Current: ${SIZE} bytes. Target: under 4096 bytes."
fi

exit 0
