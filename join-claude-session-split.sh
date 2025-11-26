#!/bin/bash

# Claude Code Collaboration Script - Split Pane Mode
# Shows Claude Code output and your input in one terminal window
#
# Usage: join-claude-session-split.sh [username] [server] [remote-user] [session]
#
# Examples:
#   join-claude-session-split.sh jack 68.183.159.246 claudeteam claude-collab
#   join-claude-session-split.sh collaborator 68.183.159.246 claudeteam claude-collab
#
# Or set environment variables:
#   export COLLAB_HOST="68.183.159.246"
#   export COLLAB_REMOTE_USER="claudeteam"
#   export COLLAB_SESSION="claude-collab"
#   join-claude-session-split.sh jack

USER_NAME="${1}"
REMOTE_HOST="${2:-${COLLAB_HOST}}"
REMOTE_USER="${3:-${COLLAB_REMOTE_USER:-claudeteam}}"
SESSION="${4:-${COLLAB_SESSION:-claude-collab}}"

# If no username provided, use hostname
if [ -z "$USER_NAME" ]; then
    USER_NAME=$(hostname -s 2>/dev/null || hostname)
    if [ -z "$USER_NAME" ]; then
        USER_NAME="User"
    fi
fi

# Validate configuration
if [ -z "$REMOTE_HOST" ]; then
    echo "Error: Server IP not provided!"
    echo ""
    echo "Usage:"
    echo "  $0 <username> <server-ip> [remote-user] [session]"
    echo ""
    echo "Example:"
    echo "  $0 jack 68.183.159.246 claudeteam claude-collab"
    echo ""
    echo "Or set environment variables:"
    echo "  export COLLAB_HOST='68.183.159.246'"
    echo "  export COLLAB_REMOTE_USER='claudeteam'"
    echo "  export COLLAB_SESSION='claude-collab'"
    exit 1
fi

# Check if tmux is available locally
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux not found!"
    echo "Please install tmux:"
    echo "  brew install tmux"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Claude Code Collaboration - Split View   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo -e "${BLUE}User:${NC}         ${USER_NAME}"
echo -e "${BLUE}Server:${NC}       ${REMOTE_HOST}"
echo -e "${BLUE}Remote User:${NC}  ${REMOTE_USER}"
echo -e "${BLUE}Session:${NC}      ${SESSION}"
echo ""
echo -e "${YELLOW}Setting up split view...${NC}"

# Create local tmux session with split view
LOCAL_SESSION="cc-${USER_NAME}"

# Kill existing session if it exists
tmux kill-session -t "$LOCAL_SESSION" 2>/dev/null

# Create new session without loading config to avoid conflicts
tmux -f /dev/null new-session -d -s "$LOCAL_SESSION" -n main

# Capture the pane ID of the original pane (will be top pane)
TOP_PANE=$(tmux list-panes -t "${LOCAL_SESSION}:main" -F "#{pane_id}" | head -1)

# Split: -v creates vertical split (top/bottom), -p 30 makes new pane 30%
# After split-window -v: new pane is BELOW and becomes active
# We want: top=Claude view (70%), bottom=input (30%)
tmux split-window -v -t "${LOCAL_SESSION}:main" -p 30

# Capture the pane ID of the new pane (will be bottom pane)
BOTTOM_PANE=$(tmux list-panes -t "${LOCAL_SESSION}:main" -F "#{pane_id}" | tail -1)

# Now we have reliable pane IDs regardless of pane-base-index setting:
# - TOP_PANE = top (original pane, 70%) - for Claude session view
# - BOTTOM_PANE = bottom (new pane, 30%) - for input script

# Select top pane explicitly and send SSH command
tmux select-pane -t "$TOP_PANE"
echo -e "${YELLOW}Connecting to shared Claude Code session...${NC}"
tmux send-keys -t "$TOP_PANE" \
    "echo 'Connecting to ${REMOTE_HOST}...'; ssh -t ${REMOTE_USER}@${REMOTE_HOST} 'tmux attach-session -r -t ${SESSION}'" C-m

# Give it a moment to connect
sleep 2

# Bottom pane (pane 1): Create a temporary input script
TEMP_SCRIPT="/tmp/claude-collab-input-${USER_NAME}.sh"
cat > "$TEMP_SCRIPT" << 'SCRIPT_END'
#!/bin/bash
USER_NAME="USER_NAME_PLACEHOLDER"
REMOTE_USER="REMOTE_USER_PLACEHOLDER"
REMOTE_HOST="REMOTE_HOST_PLACEHOLDER"
SESSION="SESSION_PLACEHOLDER"

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}=== Your Input Terminal ===${NC}"
echo "Type your prompts below. They will be prefixed with [${USER_NAME}]"
echo "Press Ctrl+C to exit"
echo ""

while true; do
    read -e -p "[${USER_NAME}]> " input
    if [ -n "$input" ]; then
        # Escape single quotes in input
        escaped_input=$(printf %s "$input" | sed "s/'/'\\\\\''/g")
        # Send text and Enter as one command to avoid SSH escaping issues
        ssh ${REMOTE_USER}@${REMOTE_HOST} "tmux send-keys -t ${SESSION} '[${USER_NAME}] ${escaped_input}' && tmux send-keys -t ${SESSION} Enter"
    fi
done
SCRIPT_END

# Replace placeholders
sed -i '' "s/USER_NAME_PLACEHOLDER/${USER_NAME}/g" "$TEMP_SCRIPT"
sed -i '' "s/REMOTE_USER_PLACEHOLDER/${REMOTE_USER}/g" "$TEMP_SCRIPT"
sed -i '' "s/REMOTE_HOST_PLACEHOLDER/${REMOTE_HOST}/g" "$TEMP_SCRIPT"
sed -i '' "s/SESSION_PLACEHOLDER/${SESSION}/g" "$TEMP_SCRIPT"

chmod +x "$TEMP_SCRIPT"

# Run the script in bottom pane
tmux select-pane -t "$BOTTOM_PANE"
tmux send-keys -t "$BOTTOM_PANE" "$TEMP_SCRIPT" C-m

# Select bottom pane as active (so user can type immediately)
tmux select-pane -t "$BOTTOM_PANE"

# Attach to the local session without loading config
echo -e "${GREEN}Done! Attaching to collaboration session...${NC}"
echo ""
sleep 1
tmux -f /dev/null attach-session -t "$LOCAL_SESSION"
