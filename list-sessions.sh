#!/bin/bash

# List Active tmux Sessions on Collaboration Server
# Shows all active Claude Code collaboration sessions

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

CONFIG_FILE="$HOME/.claude-collab-config"

# Load config if it exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Parse command line arguments
REMOTE_HOST="${1:-${COLLAB_HOST}}"
REMOTE_USER="${2:-${COLLAB_REMOTE_USER:-claudeteam}}"

# Validate configuration
if [ -z "$REMOTE_HOST" ]; then
    echo -e "${RED}Error: Server IP not provided!${NC}"
    echo ""
    echo "Usage:"
    echo "  $0 <server-ip> [remote-user]"
    echo ""
    echo "Example:"
    echo "  $0 68.183.159.246 claudeteam"
    echo ""
    echo "Or set environment variables:"
    echo "  export COLLAB_HOST='68.183.159.246'"
    echo "  export COLLAB_REMOTE_USER='claudeteam'"
    exit 1
fi

echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║  Claude Code Collaboration - Active Sessions         ║${NC}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Server:${NC} ${REMOTE_HOST}"
echo -e "${BLUE}User:${NC}   ${REMOTE_USER}"
echo ""

# Get session list
echo -e "${BOLD}Fetching active sessions...${NC}"
echo ""

SESSION_LIST=$(ssh "${REMOTE_USER}@${REMOTE_HOST}" "tmux ls 2>/dev/null" || echo "")

if [ -z "$SESSION_LIST" ]; then
    echo -e "${YELLOW}⚠${NC} No active tmux sessions found on the server"
    echo ""
    echo "To create a new session:"
    echo "  1. SSH to server: ssh ${REMOTE_USER}@${REMOTE_HOST}"
    echo "  2. Create session: tmux new-session -s claude-collab"
    echo "  3. Start Claude Code: claude-code"
    echo "  4. Detach: Ctrl+B, then D"
    exit 0
fi

# Parse and display sessions
echo -e "${GREEN}✓${NC} Active sessions:"
echo ""
echo "$SESSION_LIST" | while IFS= read -r line; do
    # Extract session name (everything before the first colon)
    SESSION_NAME=$(echo "$line" | cut -d':' -f1)
    # Extract rest of the info
    SESSION_INFO=$(echo "$line" | cut -d':' -f2-)

    echo -e "  ${BOLD}${SESSION_NAME}${NC}: ${SESSION_INFO}"
done

echo ""
echo -e "${BOLD}Actions:${NC}"
echo ""
echo "To join a session:"
echo "  ./join-claude-session-split.sh YourName ${REMOTE_HOST} ${REMOTE_USER} <session-name>"
echo ""
echo "To view a session (read-only):"
echo "  ssh ${REMOTE_USER}@${REMOTE_HOST}"
echo "  tmux attach-session -r -t <session-name>"
echo ""
echo "To kill a session:"
echo "  ssh ${REMOTE_USER}@${REMOTE_HOST}"
echo "  tmux kill-session -t <session-name>"
echo ""
