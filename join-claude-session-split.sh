#!/bin/bash

# Claude Code Collaboration Script - Split Pane Mode
# Shows Claude Code output (top) and your input (bottom) in one terminal window.
#
# Usage:
#   join-claude-session-split.sh <username> <server-ip> [remote-user] [session] [--prefix PREFIX]
#   join-claude-session-split.sh --debug <username> <server-ip> [remote-user] [session]
#
# Examples:
#   join-claude-session-split.sh jack 68.183.159.246 claudeteam claude-collab
#   join-claude-session-split.sh jack 68.183.159.246 --prefix JY
#   join-claude-session-split.sh collaborator 68.183.159.246
#
# Or set environment variables:
#   export COLLAB_HOST="68.183.159.246"
#   export COLLAB_REMOTE_USER="claudeteam"
#   export COLLAB_SESSION="claude-collab"
#   export COLLAB_PREFIX="JY"
#   join-claude-session-split.sh jack

DEBUG=0
PREFIX=""
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)
            DEBUG=1
            shift
            ;;
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
REMOTE_HOST="${POSITIONAL[1]:-${COLLAB_HOST}}"
REMOTE_USER="${POSITIONAL[2]:-${COLLAB_REMOTE_USER:-claudeteam}}"
SESSION="${POSITIONAL[3]:-${COLLAB_SESSION:-claude-collab}}"

# If no username provided, use hostname
if [ -z "$USER_NAME" ]; then
    USER_NAME=$(hostname -s 2>/dev/null || hostname)
    if [ -z "$USER_NAME" ]; then
        USER_NAME="User"
    fi
fi

# Default prefix to env var or username
if [ -z "$PREFIX" ]; then
    PREFIX="${COLLAB_PREFIX:-$USER_NAME}"
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

# Detect OS for sed compatibility
SED_INPLACE=(-i '')
if [[ "$(uname -s)" == "Linux" ]]; then
    SED_INPLACE=(-i)
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Claude Code Collaboration - Split View   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""

# ─── Health checks ───

echo -e "${BLUE}Checking connection...${NC}"

# Test SSH connection
if ssh -o ConnectTimeout=5 -o BatchMode=yes "${REMOTE_USER}@${REMOTE_HOST}" "exit" 2>/dev/null; then
    echo -e "${GREEN}  ✓${NC} SSH connection to ${REMOTE_HOST}"
else
    echo -e "${RED}  ✗${NC} Cannot connect to ${REMOTE_USER}@${REMOTE_HOST}"
    echo ""
    echo "  Possible fixes:"
    echo "  1. Check the server IP is correct"
    echo "  2. Run: setup-ssh.sh --check ${REMOTE_HOST}"
    echo "  3. Ask your host if the server is running"
    exit 1
fi

# Check tmux session exists on remote
if ssh -o ConnectTimeout=5 "${REMOTE_USER}@${REMOTE_HOST}" "tmux has-session -t ${SESSION} 2>/dev/null" 2>/dev/null; then
    echo -e "${GREEN}  ✓${NC} tmux session '${SESSION}' is running"
else
    echo -e "${RED}  ✗${NC} tmux session '${SESSION}' not found on server"
    echo ""
    echo "  Ask your host to start it:"
    echo "    ssh ${REMOTE_USER}@${REMOTE_HOST}"
    echo "    tmux new-session -s ${SESSION} -d"
    echo "    tmux send-keys -t ${SESSION} 'claude' C-m"
    exit 1
fi

# Check if Claude Code is running (best effort)
REMOTE_CONTENT=$(ssh -o ConnectTimeout=5 "${REMOTE_USER}@${REMOTE_HOST}" "tmux capture-pane -t ${SESSION} -p 2>/dev/null" 2>/dev/null || echo "")
if echo "$REMOTE_CONTENT" | grep -qiE 'claude|❯|>'; then
    echo -e "${GREEN}  ✓${NC} Claude Code appears to be running"
else
    echo -e "${YELLOW}  ⚠${NC} Could not confirm Claude Code is running"
    echo -e "${DIM}    (It may still be fine — check after connecting)${NC}"
fi

echo ""
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
tmux split-window -v -t "${LOCAL_SESSION}:main" -p 30

# Capture the pane ID of the new pane (will be bottom pane)
BOTTOM_PANE=$(tmux list-panes -t "${LOCAL_SESSION}:main" -F "#{pane_id}" | tail -1)

# Top pane: SSH to shared session (read-only view)
tmux select-pane -t "$TOP_PANE"
tmux send-keys -t "$TOP_PANE" \
    "echo 'Connecting to ${REMOTE_HOST}...'; ssh -t ${REMOTE_USER}@${REMOTE_HOST} 'tmux attach-session -r -t ${SESSION}'" C-m

# Give it a moment to connect
sleep 2

# Bottom pane: Create a temporary input script
# Using heredoc with variable expansion to avoid sed placeholder replacement
TEMP_SCRIPT="/tmp/claude-collab-input-${USER_NAME}.sh"

cat > "$TEMP_SCRIPT" << EOF
#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
DIM='\033[2m'
NC='\033[0m'

echo -e "\${GREEN}=== Your Input Terminal ===\${NC}"
echo "Type your prompts below. They will be prefixed with [${PREFIX}]"
echo ""
echo -e "\${DIM}  Ctrl+C     = exit input (session keeps running)\${NC}"
echo -e "\${DIM}  Ctrl+B, D  = detach from tmux entirely\${NC}"
echo ""

cleanup() {
    echo ""
    echo -e "\${GREEN}Disconnected. The shared session is still running.\${NC}"
    echo "To rejoin: join-claude-session-split.sh ${USER_NAME} ${REMOTE_HOST} ${REMOTE_USER} ${SESSION}"
    exit 0
}
trap cleanup INT

while true; do
    read -e -p "[${PREFIX}]> " input
    if [ -n "\$input" ]; then
        # Escape single quotes in input for safe transmission
        escaped_input=\$(printf '%s' "\$input" | sed "s/'/'\\\\\\\\''/g")
        if ! ssh ${REMOTE_USER}@${REMOTE_HOST} "tmux send-keys -t ${SESSION} '[${PREFIX}] \${escaped_input}' && tmux send-keys -t ${SESSION} Enter" 2>/dev/null; then
            echo -e "\${YELLOW}  Failed to send. Check connection.\${NC}"
            echo "  Try: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tmux ls'"
        fi
    fi
done
EOF

chmod +x "$TEMP_SCRIPT"

[ "$DEBUG" -eq 1 ] && echo "[debug] Temp script: $TEMP_SCRIPT" && cat "$TEMP_SCRIPT"

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
