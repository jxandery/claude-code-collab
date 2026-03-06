#!/bin/bash

# Claude Code Collaboration - SSH Key Setup
# Detects existing SSH keys, generates one if needed, and displays your public key.
#
# Usage:
#   setup-ssh.sh              # Auto-detect or create key
#   setup-ssh.sh --show       # Just show your current public key
#   setup-ssh.sh --check HOST # Check if your key works against a server

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

MODE="${1:-setup}"
HOST="${2:-}"

print_ok()   { echo -e "${GREEN}  ✓ $1${NC}"; }
print_warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
print_fail() { echo -e "${RED}  ✗ $1${NC}"; }

# ─── Detect existing keys ───

detect_key() {
    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        echo "ed25519"
    elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        echo "rsa"
    else
        echo "none"
    fi
}

get_public_key_path() {
    local type
    type=$(detect_key)
    case "$type" in
        ed25519) echo "$HOME/.ssh/id_ed25519.pub" ;;
        rsa)     echo "$HOME/.ssh/id_rsa.pub" ;;
        *)       echo "" ;;
    esac
}

show_key() {
    local key_path
    key_path=$(get_public_key_path)

    if [ -z "$key_path" ]; then
        print_fail "No SSH key found. Run: setup-ssh.sh"
        return 1
    fi

    local key_type
    key_type=$(detect_key)

    echo ""
    echo -e "${BOLD}Your SSH public key ($(echo "$key_type" | tr '[:lower:]' '[:upper:]')):${NC}"
    echo -e "${YELLOW}────────────────────────────────────────${NC}"
    cat "$key_path"
    echo -e "${YELLOW}────────────────────────────────────────${NC}"
    echo ""
    echo -e "${DIM}This is your PUBLIC key — safe to share with your host.${NC}"
    echo -e "${RED}Never share the file without .pub — that's your private key.${NC}"
    echo ""
}

check_connection() {
    local host="$1"
    if [ -z "$host" ]; then
        echo "Usage: setup-ssh.sh --check SERVER_IP"
        exit 1
    fi

    echo ""
    echo -e "${BOLD}Testing SSH connection to ${host}...${NC}"
    echo ""

    # Show which key SSH will offer
    echo -e "${DIM}Keys SSH will try:${NC}"
    ssh -v -o ConnectTimeout=5 -o BatchMode=yes "claudeteam@${host}" "exit" 2>&1 | grep "Offering public key" | while read -r line; do
        echo -e "  ${BLUE}${line}${NC}"
    done

    echo ""
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "claudeteam@${host}" "echo ok" 2>/dev/null; then
        print_ok "Connection successful!"
    else
        print_fail "Connection failed."
        echo ""
        echo "  Common fixes:"
        echo "  1. Ask your host to add your public key to the server"
        echo "     (show them your key with: setup-ssh.sh --show)"
        echo "  2. Check the server IP is correct"
        echo "  3. Check the server is running"
        echo ""
    fi
}

# ─── Main: Setup flow ───

setup() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   SSH Key Setup                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""

    local key_type
    key_type=$(detect_key)

    if [ "$key_type" != "none" ]; then
        print_ok "Found existing $(echo "$key_type" | tr '[:lower:]' '[:upper:]') key"
        show_key
        echo -e "  ${DIM}Your key is ready. Share the output above with your host.${NC}"
        return 0
    fi

    print_warn "No SSH key found. Let's create one."
    echo ""

    read -p "  Your email (for key label, press Enter to skip): " email
    email="${email:-user@claude-collab}"

    echo ""
    echo "  Creating ED25519 key (modern, secure)..."
    echo ""

    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""

    echo ""
    print_ok "SSH key created!"
    show_key
    echo -e "  ${BOLD}Next step:${NC} Send the key above to your host."
    echo ""
}

# ─── Route ───

case "$MODE" in
    --show)    show_key ;;
    --check)   check_connection "$HOST" ;;
    setup|*)   setup ;;
esac
