#!/bin/bash

# Claude Code Collaboration Script - Simple Input Mode
# This provides an input prompt only. You'll need a separate terminal to view Claude's responses.
#
# For a better experience with split-pane view, use: join-claude-session-split.sh
#
# Usage: join-claude-session.sh [username] [session-name] [--prefix PREFIX]
# If no username provided, defaults to hostname
# If no prefix provided, defaults to username
#
# Note: This script runs ON the server after you SSH in, not on your local machine.

# Parse flags
PREFIX=""
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

USER_NAME="${POSITIONAL[0]}"
SESSION="${POSITIONAL[1]:-test-collab}"

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

# Default prefix to env var or username
if [ -z "$PREFIX" ]; then
    PREFIX="${COLLAB_PREFIX:-$USER_NAME}"
fi

# Check if session exists
if ! $TMUX_BIN list-sessions 2>/dev/null | grep -q "^${SESSION}:"; then
    echo "Error: tmux session '${SESSION}' not found!"
    echo ""
    echo "Available sessions:"
    $TMUX_BIN list-sessions 2>/dev/null || echo "  (none)"
    echo ""
    echo "To create the shared session:"
    echo "  tmux new-session -s ${SESSION}"
    echo "  claude-code"
    echo "  # Press Ctrl+B, then D to detach"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
DIM='\033[2m'
NC='\033[0m'

# Health check
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Claude Code Collaboration Mode        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}  ✓${NC} tmux session '${SESSION}' found"

# Check if Claude Code appears to be running in the session
SESSION_CONTENT=$($TMUX_BIN capture-pane -t "$SESSION" -p 2>/dev/null || echo "")
if echo "$SESSION_CONTENT" | grep -qiE 'claude|❯|>'; then
    echo -e "${GREEN}  ✓${NC} Claude Code appears to be running"
else
    echo -e "${YELLOW}  ⚠${NC} Could not confirm Claude Code is running"
    echo -e "${DIM}    (It may still be fine — check the view terminal)${NC}"
fi

echo ""
echo -e "${BLUE}User:${NC}    ${USER_NAME}"
echo -e "${BLUE}Session:${NC} ${SESSION}"
echo ""
echo -e "${YELLOW}Your prompts will be prefixed with [${PREFIX}]${NC}"
echo ""
echo -e "${DIM}  Ctrl+C     = exit this input script${NC}"
echo -e "${DIM}  Ctrl+B, D  = detach from tmux (session keeps running)${NC}"
echo ""

# Graceful exit on Ctrl+C
cleanup() {
    echo ""
    echo -e "${GREEN}Disconnected. The shared session is still running.${NC}"
    echo -e "To rejoin: ${YELLOW}join-claude-session.sh ${USER_NAME} ${SESSION}${NC}"
    exit 0
}
trap cleanup INT

# Main input loop
while true; do
    read -e -p "[${PREFIX}]> " input
    if [ -n "$input" ]; then
        if ! $TMUX_BIN send-keys -t "$SESSION" "[${PREFIX}] $input" 2>/dev/null || \
           ! $TMUX_BIN send-keys -t "$SESSION" Enter 2>/dev/null; then
            echo -e "${YELLOW}  ⚠ Could not send to session. It may have ended.${NC}"
            echo "  Check with: tmux ls"
        fi
    fi
done
