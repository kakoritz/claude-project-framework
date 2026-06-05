#!/bin/bash
# new-project.sh — Scaffold a new DCLI project with Claude MD templates
# Usage: ./new-project.sh [name] [dest-path]
# Run from: ~/claude-project-framework/

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE=$(date +%Y-%m-%d)
DEFAULT_PATH="$HOME/repos"

echo ""
echo "DCLI New Project"
echo "================"

NAME=$1
DEST_BASE=${2:-$DEFAULT_PATH}

if [ -z "$NAME" ]; then
    read -p "Project name (e.g. RPA.MyBot.Performer): " NAME
fi

echo ""
echo "Project type:"
echo "  [1] UiPath Bot       (Dispatcher or Performer)"
echo "  [2] C# Library       (reusable .NET library)"
echo "  [3] C# API           (ASP.NET Core minimal API)"
echo "  [4] Web UX           (Node.js + React frontend + backend)"
echo "  [5] Python           (script, agent, or service)"
echo ""
read -p "Type (1-5): " TYPE_CHOICE

case "$TYPE_CHOICE" in
    1) TYPE="uipath-bot"      ;;
    2) TYPE="csharp-library"  ;;
    3) TYPE="csharp-api"      ;;
    4) TYPE="nodejs-react"    ;;
    5) TYPE="python"          ;;
    *) echo "Invalid choice '$TYPE_CHOICE'"; exit 1 ;;
esac

TEMPLATE_DIR="$REPO_DIR/templates/$TYPE"
DEST_DIR="$DEST_BASE/$NAME"

echo ""

if [ -d "$DEST_DIR" ]; then
    echo "Folder already exists: $DEST_DIR"
    read -p "Add Claude MDs to existing folder? (y/n): " confirm
    [ "$confirm" != "y" ] && echo "Cancelled." && exit 0
else
    mkdir -p "$DEST_DIR"
    echo "Created: $DEST_DIR"
fi

echo ""
for f in "$TEMPLATE_DIR"/*.md; do
    fname=$(basename "$f")
    sed "s/{{PROJECT_NAME}}/$NAME/g; s/{{DATE}}/$DATE/g" "$f" > "$DEST_DIR/$fname"
    echo "  OK $fname"
done

echo ""

# ── UiPath: offer Orchestrator scan ──────────────────────────────────────────
if [ "$TYPE" = "uipath-bot" ]; then
    echo "  Orchestrator scan — auto-populate queue IDs, bucket IDs, assets."
    echo "  Requires UIPATH_CLIENT_ID and UIPATH_CLIENT_SECRET in .env or environment."
    echo ""
    read -p "  Scan Orchestrator now? (y/n): " scan_choice
    if [ "${scan_choice,,}" = "y" ]; then
        echo ""
        echo "  Enter folder paths for each environment (comma-separated)."
        echo "  Example: Production/Shared Services/TIR,Test/Shared Services/TIR,Development/Shared Services/TIR"
        echo ""
        read -p "  Folder paths: " orch_folders
        if [ -n "$orch_folders" ]; then
            python3 "$REPO_DIR/tools/scan-orchestrator.py" \
                --folders "$orch_folders" \
                --project-name "$NAME" \
                --output "$DEST_DIR/ORCHESTRATOR.md"
        else
            echo "  No paths entered — ORCHESTRATOR.md left as template."
        fi
    else
        echo "  Skipped. Edit $DEST_DIR/ORCHESTRATOR.md to fill in IDs manually."
        echo "  Or run: python3 $REPO_DIR/tools/scan-orchestrator.py --folders \"<paths>\" --output $DEST_DIR/ORCHESTRATOR.md"
    fi
    echo ""
fi

echo "Done. Open $DEST_DIR in Claude Code to get started."
echo ""
[ "$TYPE" != "uipath-bot"  ] && echo "Next: fill in the [placeholder] values in each MD file."
[ "$TYPE" = "csharp-api"   ] && echo "      DEPLOYMENT.md needs your APP_NAME and AWS resource names."
[ "$TYPE" = "nodejs-react" ] && echo "      DEPLOYMENT.md needs your APP_NAME and AWS resource names."
echo ""
