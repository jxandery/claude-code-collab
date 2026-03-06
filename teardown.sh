#!/bin/bash

# Claude Code Collaboration - Teardown / Cleanup
# Cleanly stops collaboration sessions and provides server cleanup guidance.
#
# Usage:
#   teardown.sh                    # Clean up local sessions only
#   teardown.sh SERVER_IP          # Clean up local + remote sessions
#   teardown.sh --local            # Only clean local tmux sessions
#   teardown.sh --remote SERVER_IP # Only clean remote session

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

MODE="${1:-all}"
SERVER="${2:-${COLLAB_HOST}}"
REMOTE_USER="${COLLAB_REMOTE_USER:-claudeteam}"
SESSION="${COLLAB_SESSION:-claude-collab}"

# Handle flags
case "$1" in
    --local)  MODE="local" ;;
    --remote) MODE="remote"; SERVER="${2:-${COLLAB_HOST}}" ;;
    --help|-h)
        echo "Usage:"
        echo "  teardown.sh                    # Clean local + remote"
        echo "  teardown.sh SERVER_IP          # Clean local + specific remote"
        echo "  teardown.sh --local            # Clean local only"
        echo "  teardown.sh --remote SERVER_IP # Clean remote only"
        exit 0
        ;;
    *)
        if [ -n "$1" ] && [[ "$1" != --* ]]; then
            SERVER="$1"
            MODE="all"
        fi
        ;;
esac

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Collaboration Cleanup                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

CLEANED=0

# ─── Local cleanup ───

if [ "$MODE" = "local" ] || [ "$MODE" = "all" ]; then
    echo -e "${BOLD}Local Sessions${NC}"
    echo ""

    # Find and kill collaboration sessions (cc-*)
    LOCAL_SESSIONS=$(tmux list-sessions 2>/dev/null | grep "^cc-" | cut -d: -f1 || true)

    if [ -n "$LOCAL_SESSIONS" ]; then
        echo "$LOCAL_SESSIONS" | while read -r sess; do
            tmux kill-session -t "$sess" 2>/dev/null && \
                echo -e "${GREEN}  ✓${NC} Killed local session: ${sess}" || \
                echo -e "${YELLOW}  ⚠${NC} Could not kill: ${sess}"
        done
        CLEANED=1
    else
        echo -e "${DIM}  No local collaboration sessions found.${NC}"
    fi

    # Clean up temp scripts
    TEMP_SCRIPTS=$(ls /tmp/claude-collab-input-*.sh 2>/dev/null || true)
    if [ -n "$TEMP_SCRIPTS" ]; then
        rm -f /tmp/claude-collab-input-*.sh
        echo -e "${GREEN}  ✓${NC} Cleaned up temporary input scripts"
        CLEANED=1
    fi

    echo ""
fi

# ─── Remote cleanup ───

if [ "$MODE" = "remote" ] || [ "$MODE" = "all" ]; then
    if [ -n "$SERVER" ]; then
        echo -e "${BOLD}Remote Server (${SERVER})${NC}"
        echo ""

        if ssh -o ConnectTimeout=5 -o BatchMode=yes "${REMOTE_USER}@${SERVER}" "exit" 2>/dev/null; then
            # Kill remote tmux session
            read -p "  Kill remote session '${SESSION}'? (y/n): " confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                if ssh "${REMOTE_USER}@${SERVER}" "tmux kill-session -t ${SESSION} 2>/dev/null"; then
                    echo -e "${GREEN}  ✓${NC} Killed remote session: ${SESSION}"
                    CLEANED=1
                else
                    echo -e "${YELLOW}  ⚠${NC} Session '${SESSION}' was not running"
                fi
            else
                echo -e "${DIM}  Skipped remote session cleanup.${NC}"
            fi
        else
            echo -e "${YELLOW}  ⚠${NC} Cannot connect to ${SERVER} — skipping remote cleanup"
        fi

        echo ""
    elif [ "$MODE" = "remote" ]; then
        echo "  No server specified."
        echo "  Usage: teardown.sh --remote SERVER_IP"
        echo ""
    fi
fi

# ─── Server destruction guidance ───

if [ -n "$SERVER" ]; then
    echo -e "${BOLD}Want to stop paying for the server?${NC}"
    echo ""
    echo -e "  ${DIM}If using DigitalOcean:${NC}"
    echo -e "  ${DIM}  1. Go to https://cloud.digitalocean.com/droplets${NC}"
    echo -e "  ${DIM}  2. Click your droplet → Destroy → Confirm${NC}"
    echo -e "  ${DIM}  3. Billing stops immediately${NC}"
    echo ""
    echo -e "  ${YELLOW}Note: Destroying the server deletes everything.${NC}"
    echo -e "  ${YELLOW}You'll need to set up from scratch if you want to collaborate again.${NC}"
    echo ""
fi

echo -e "${GREEN}Done.${NC}"
echo ""
