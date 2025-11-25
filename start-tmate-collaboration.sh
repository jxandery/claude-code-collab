#!/bin/bash

# Start tmate Collaboration Session
# For the HOST who starts the Claude Code session

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Starting tmate Collaboration Session  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if tmate is installed
if ! command -v tmate &> /dev/null; then
    echo -e "${YELLOW}tmate is not installed!${NC}"
    echo ""
    echo "Install it with:"
    echo -e "  ${GREEN}brew install tmate${NC}"
    echo ""
    exit 1
fi

# Check if claude-code is available
if ! command -v claude-code &> /dev/null; then
    echo -e "${YELLOW}Warning: claude-code command not found${NC}"
    echo "Make sure Claude Code is installed and in your PATH"
    echo ""
fi

echo -e "${BLUE}Starting tmate session...${NC}"
echo ""

# Start tmate in detached mode
tmate -S /tmp/tmate-collab new-session -d

# Wait for tmate to connect
echo -e "${YELLOW}Waiting for tmate to connect...${NC}"
sleep 2

# Get connection info
tmate -S /tmp/tmate-collab display -p '#{tmate_ssh}' > /tmp/tmate-connection.txt 2>/dev/null || true

CONNECTION=$(cat /tmp/tmate-connection.txt 2>/dev/null || echo "")

if [ -z "$CONNECTION" ]; then
    echo -e "${YELLOW}Getting connection info...${NC}"
    sleep 2
    tmate -S /tmp/tmate-collab display -p '#{tmate_ssh}' > /tmp/tmate-connection.txt 2>/dev/null || true
    CONNECTION=$(cat /tmp/tmate-connection.txt 2>/dev/null || echo "")
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  tmate Session Started!                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

if [ -n "$CONNECTION" ]; then
    echo -e "${BLUE}Share this connection string with your collaborator:${NC}"
    echo -e "${YELLOW}$CONNECTION${NC}"
    echo ""
fi

echo -e "${BLUE}To get connection info later, run:${NC}"
echo -e "  tmate -S /tmp/tmate-collab display -p '#{tmate_ssh}'"
echo ""

# Start Claude Code in the tmate session
echo -e "${YELLOW}Starting Claude Code in tmate session...${NC}"
tmate -S /tmp/tmate-collab send-keys "claude-code" C-m

# Attach to the session
echo -e "${BLUE}Attaching to session...${NC}"
echo ""
sleep 1

tmate -S /tmp/tmate-collab attach
