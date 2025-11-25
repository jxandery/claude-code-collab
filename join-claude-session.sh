#!/bin/bash

# Claude Code Collaboration Script - Simple Input Mode
# This provides an input prompt only. You'll need a separate terminal to view Claude's responses.
#
# For a better experience with split-pane view, use: join-claude-session-split.sh
#
# Usage: join-claude-session.sh [username] [session-name]
# If no username provided, defaults to hostname
#
# Note: This script runs ON the server after you SSH in, not on your local machine.

USER_NAME="${1}"
SESSION="${2:-test-collab}"

# Find tmux - check common locations
if command -v tmux &> /dev/null; then
    TMUX_BIN=$(command -v tmux)
elif [ -f /opt/homebrew/bin/tmux ]; then
    TMUX_BIN="/opt/homebrew/bin/tmux"
elif [ -f /usr/local/bin/tmux ]; then
    TMUX_BIN="/usr/local/bin/tmux"
else
    echo "Error: tmux not found! Please install tmux first:"
    echo "  brew install tmux"
    exit 1
fi

# If no username provided, default to hostname
if [ -z "$USER_NAME" ]; then
    USER_NAME=$(hostname -s)
    if [ -z "$USER_NAME" ]; then
        USER_NAME=$(hostname)
    fi
fi

# Check if session exists
if ! $TMUX_BIN list-sessions 2>/dev/null | grep -q "^${SESSION}:"; then
    echo "Error: tmux session '${SESSION}' not found!"
    echo ""
    echo "Please create the shared session first:"
    echo "  tmux new-session -s ${SESSION}"
    echo "  claude-code"
    echo ""
    echo "Then detach (Ctrl+B, D) and run this script again."
    exit 1
fi

# Colors for nice output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Claude Code Collaboration Mode        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo -e "${BLUE}User:${NC}    ${USER_NAME}"
echo -e "${BLUE}Session:${NC} ${SESSION}"
echo ""
echo -e "${YELLOW}Your prompts will be prefixed with [${USER_NAME}]${NC}"
echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
echo ""

# Main input loop
while true; do
    read -e -p "[${USER_NAME}]> " input
    if [ -n "$input" ]; then
        $TMUX_BIN send-keys -t $SESSION "[${USER_NAME}] $input"
        $TMUX_BIN send-keys -t $SESSION Enter
    fi
done
