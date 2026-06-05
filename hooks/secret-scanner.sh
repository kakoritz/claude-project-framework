#!/bin/bash
# PreToolUse:Write hook — blocks writes containing secret patterns
# Zero token cost. Runs before Claude writes any file.
# Uses tree-sitter context when available to avoid flagging comments and test strings.

RAW=$(cat)
FILE=$(echo "$RAW" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
CONTENT=$(echo "$RAW" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('content',''))" 2>/dev/null)

# Files to always allow
SKIP_PATTERNS=(".env.example" ".env.sample" ".env.template" "*.test.*" "*.spec.*" "*_test.*" "*.md")
for pat in "${SKIP_PATTERNS[@]}"; do
    case "$FILE" in $pat) exit 0 ;; esac
done

# Allow if content has # noscan directive
if echo "$CONTENT" | grep -q "# noscan"; then
    exit 0
fi

# ── Determine what to scan ────────────────────────────────────────────────────
# For supported file types, use tree-sitter to extract only string literals and
# assignment values — comments and other non-secret nodes are excluded.
# Falls back to scanning full content if tree-sitter is unavailable.

HOOKS_DIR="$(dirname "$0")"
EXT="${FILE##*.}"
CHECK_CONTENT="$CONTENT"

case "$EXT" in
    py|cs|js|ts|tsx|jsx)
        TMPFILE=$(mktemp --suffix=".$EXT" 2>/dev/null || mktemp)
        printf '%s' "$CONTENT" > "$TMPFILE"
        TS_RESULT=$(python3 "$HOOKS_DIR/ts-context.py" "$TMPFILE" 2>/dev/null)
        rm -f "$TMPFILE"

        if [ -n "$TS_RESULT" ]; then
            IS_FALLBACK=$(echo "$TS_RESULT" | python3 -c \
                "import sys,json; d=json.load(sys.stdin); print('1' if d.get('fallback') else '0')" 2>/dev/null || echo "1")
            if [ "$IS_FALLBACK" = "0" ]; then
                CHECK_CONTENT=$(echo "$TS_RESULT" | python3 -c \
                    "import sys,json; d=json.load(sys.stdin); print('\n'.join(d.get('strings',[])+d.get('assignments',[])))" 2>/dev/null)
            fi
        fi
        ;;
esac

# ── Scan for secret patterns ──────────────────────────────────────────────────
PATTERNS=(
    'AKIA[0-9A-Z]{16}'                             # AWS Access Key ID
    'sk-ant-[a-zA-Z0-9\-]+'                        # Anthropic API key
    'sk-[a-zA-Z0-9]{48}'                           # OpenAI-style key
    '-----BEGIN.*(RSA |EC |OPENSSH )?PRIVATE'      # Private keys
    'password[[:space:]]*=[[:space:]]*[^$\n]{4,}'  # password=value
    'client_secret[[:space:]]*=[[:space:]]*[^$\n]{4,}'
    'api_key[[:space:]]*=[[:space:]]*[^$\n]{4,}'
    'ANTHROPIC_API_KEY[[:space:]]*=[[:space:]]*[^$\n]{4,}'
)

for pattern in "${PATTERNS[@]}"; do
    if echo "$CHECK_CONTENT" | grep -qiE "$pattern"; then
        echo "SECRET SCANNER BLOCKED: $FILE"
        echo "Pattern matched: $pattern"
        echo "Looks like a secret. Use environment variables, Secrets Manager, or Windows Credential Manager instead."
        exit 2
    fi
done

exit 0
