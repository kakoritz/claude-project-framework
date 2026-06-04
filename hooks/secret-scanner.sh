#!/bin/bash
# PreToolUse:Write hook — blocks writes containing secret patterns
# Zero token cost. Runs before Claude writes any file.

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

# Scan for secret patterns
PATTERNS=(
    'AKIA[0-9A-Z]{16}'                          # AWS Access Key ID
    'sk-ant-[a-zA-Z0-9\-]+'                     # Anthropic API key
    'sk-[a-zA-Z0-9]{48}'                        # OpenAI-style key
    '-----BEGIN.*(RSA |EC |OPENSSH )?PRIVATE'   # Private keys
    'password[[:space:]]*=[[:space:]]*[^$\n]{4,}'  # password=value
    'client_secret[[:space:]]*=[[:space:]]*[^$\n]{4,}'
    'api_key[[:space:]]*=[[:space:]]*[^$\n]{4,}'
    'ANTHROPIC_API_KEY[[:space:]]*=[[:space:]]*[^$\n]{4,}'
)

for pattern in "${PATTERNS[@]}"; do
    if echo "$CONTENT" | grep -qiE "$pattern"; then
        echo "SECRET SCANNER BLOCKED: $FILE"
        echo "Pattern matched: $pattern"
        echo "Looks like a secret. Use environment variables, Secrets Manager, or Windows Credential Manager instead."
        exit 2
    fi
done

exit 0
