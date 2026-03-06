#!/bin/bash

# Claude Code Collaboration - Diagnostic Tool
# Checks the health of your collaboration setup and suggests fixes.
#
# Usage:
#   diagnose.sh                              # Check local setup only
#   diagnose.sh SERVER_IP                    # Check local + remote
#   diagnose.sh SERVER_IP REMOTE_USER        # Custom remote user

set -e

SERVER="${1:-${COLLAB_HOST}}"
REMOTE_USER="${2:-${COLLAB_REMOTE_USER:-claudeteam}}"
SESSION="${COLLAB_SESSION:-claude-collab}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

check_pass() { echo -e "${GREEN}  ✓${NC} $1"; PASS=$((PASS+1)); }
check_warn() { echo -e "${YELLOW}  ⚠${NC} $1"; WARN=$((WARN+1)); }
check_fail() { echo -e "${RED}  ✗${NC} $1"; FAIL=$((FAIL+1)); }
check_info() { echo -e "${DIM}    → $1${NC}"; }

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Collaboration Diagnostic             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# ─── Local checks ───

echo -e "${BOLD}Local Machine${NC}"
echo ""

# tmux
if command -v tmux &>/dev/null || [ -f /opt/homebrew/bin/tmux ] || [ -f /usr/local/bin/tmux ]; then
    check_pass "tmux installed ($(tmux -V 2>/dev/null || echo 'found'))"
else
    check_fail "tmux not installed"
    check_info "Install with: brew install tmux"
fi

# SSH
if command -v ssh &>/dev/null; then
    check_pass "SSH available"
else
    check_fail "SSH not available"
fi

# SSH keys
if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    check_pass "SSH key found (ED25519)"
elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    check_pass "SSH key found (RSA)"
else
    check_warn "No SSH key found"
    check_info "Create one with: setup-ssh.sh"
fi

# Collaboration scripts
if command -v join-claude-session.sh &>/dev/null || [ -f "$HOME/bin/join-claude-session.sh" ]; then
    check_pass "join-claude-session.sh installed"
else
    check_warn "join-claude-session.sh not in PATH"
    check_info "Run: ./install.sh  or  ./setup.sh"
fi

if command -v join-claude-session-split.sh &>/dev/null || [ -f "$HOME/bin/join-claude-session-split.sh" ]; then
    check_pass "join-claude-session-split.sh installed"
else
    check_warn "join-claude-session-split.sh not in PATH"
fi

# Environment variables
if [ -n "$COLLAB_HOST" ]; then
    check_pass "COLLAB_HOST set (${COLLAB_HOST})"
else
    check_info "COLLAB_HOST not set (optional — you can pass server IP as argument)"
fi

# Local tmux sessions
LOCAL_SESSIONS=$(tmux list-sessions 2>/dev/null | grep "^cc-" || true)
if [ -n "$LOCAL_SESSIONS" ]; then
    check_pass "Active collaboration session(s):"
    echo "$LOCAL_SESSIONS" | while read -r line; do
        check_info "$line"
    done
fi

# ─── Remote checks (only if server provided) ───

if [ -n "$SERVER" ]; then
    echo ""
    echo -e "${BOLD}Remote Server (${SERVER})${NC}"
    echo ""

    # SSH connection
    SSH_OK=0
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "${REMOTE_USER}@${SERVER}" "exit" 2>/dev/null; then
        check_pass "SSH connection to ${REMOTE_USER}@${SERVER}"
        SSH_OK=1
    else
        check_fail "Cannot SSH to ${REMOTE_USER}@${SERVER}"
        check_info "Check: setup-ssh.sh --check ${SERVER}"
        echo ""

        # Show which key SSH is trying
        echo -e "${DIM}    SSH debug (keys being offered):${NC}"
        ssh -v -o ConnectTimeout=5 -o BatchMode=yes "${REMOTE_USER}@${SERVER}" "exit" 2>&1 | grep -E "Offering|Authentications" | head -5 | while read -r line; do
            echo -e "${DIM}      $line${NC}"
        done

        echo ""
        echo -e "${BOLD}Cannot proceed with remote checks without SSH access.${NC}"
        echo ""
    fi

    # Only run remote checks if SSH works
    if [ "$SSH_OK" -eq 1 ]; then
        # tmux session
        if ssh -o ConnectTimeout=5 "${REMOTE_USER}@${SERVER}" "tmux has-session -t ${SESSION} 2>/dev/null" 2>/dev/null; then
            check_pass "tmux session '${SESSION}' is running"

            # Session uptime
            CREATED=$(ssh -o ConnectTimeout=5 "${REMOTE_USER}@${SERVER}" "tmux display-message -t ${SESSION} -p '#{session_created}' 2>/dev/null" 2>/dev/null || echo "")
            if [ -n "$CREATED" ]; then
                NOW=$(date +%s)
                ELAPSED=$(( NOW - CREATED ))
                HOURS=$(( ELAPSED / 3600 ))
                MINS=$(( (ELAPSED % 3600) / 60 ))
                check_info "Uptime: ${HOURS}h ${MINS}m"
            fi
        else
            check_fail "tmux session '${SESSION}' not found"
            check_info "Start it: ssh ${REMOTE_USER}@${SERVER} 'tmux new-session -s ${SESSION} -d'"

            # Show what sessions do exist
            REMOTE_SESSIONS=$(ssh -o ConnectTimeout=5 "${REMOTE_USER}@${SERVER}" "tmux list-sessions 2>/dev/null" 2>/dev/null || echo "")
            if [ -n "$REMOTE_SESSIONS" ]; then
                check_info "Available sessions on server:"
                echo "$REMOTE_SESSIONS" | while read -r line; do
                    check_info "  $line"
                done
            fi
        fi

        # Claude Code installed
        if ssh -o ConnectTimeout=5 "${REMOTE_USER}@${SERVER}" "command -v claude >/dev/null 2>&1" 2>/dev/null; then
            check_pass "Claude Code installed on server"
        else
            check_warn "Claude Code not found on server"
            check_info "Install: npm install -g @anthropic-ai/claude-code"
        fi

        # Claude Code running in session (best effort)
        PANE_CONTENT=$(ssh -o ConnectTimeout=5 "${REMOTE_USER}@${SERVER}" "tmux capture-pane -t ${SESSION} -p 2>/dev/null" 2>/dev/null || echo "")
        if echo "$PANE_CONTENT" | grep -qiE 'claude|❯|>'; then
            check_pass "Claude Code appears active in session"
        else
            check_warn "Could not confirm Claude Code is active"
            check_info "Attach to check: ssh ${REMOTE_USER}@${SERVER} 'tmux attach-session -t ${SESSION}'"
        fi

        # Number of clients attached
        NUM_CLIENTS=$(ssh -o ConnectTimeout=5 "${REMOTE_USER}@${SERVER}" "tmux list-clients -t ${SESSION} 2>/dev/null | wc -l" 2>/dev/null || echo "0")
        NUM_CLIENTS=$(echo "$NUM_CLIENTS" | tr -d ' ')
        if [ "$NUM_CLIENTS" -gt 0 ] 2>/dev/null; then
            check_pass "${NUM_CLIENTS} client(s) attached to session"
        else
            check_info "No clients currently attached to session"
        fi
    fi
else
    echo ""
    echo -e "${DIM}  No server specified. Run with server IP for remote checks:${NC}"
    echo -e "${DIM}  diagnose.sh YOUR_SERVER_IP${NC}"
fi

# ─── Summary ───

echo ""
echo -e "${BOLD}━━━ Summary ━━━${NC}"
echo ""
echo -e "  ${GREEN}Passed:${NC}  ${PASS}"
echo -e "  ${YELLOW}Warnings:${NC} ${WARN}"
echo -e "  ${RED}Failed:${NC}  ${FAIL}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}  Some checks failed. See suggestions above.${NC}"
elif [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}  Setup looks mostly good. Review warnings above.${NC}"
else
    echo -e "${GREEN}  Everything looks good!${NC}"
fi
echo ""
