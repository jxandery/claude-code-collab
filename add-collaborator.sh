#!/bin/bash

# Claude Code Collaboration - Add Collaborator
# Safely adds a collaborator's SSH public key to the server.
#
# Usage (from your local machine):
#   add-collaborator.sh SERVER_IP "ssh-ed25519 AAAA...their-public-key..."
#   add-collaborator.sh SERVER_IP --from-file /path/to/their-key.pub
#
# What this does:
#   - SSHs to the server as claudeteam
#   - Validates the key format
#   - Adds the key to authorized_keys (if not already present)
#   - Sets correct permissions

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

SERVER="${1:-}"
KEY_ARG="${2:-}"
KEY_SOURCE="${3:-}"

print_ok()   { echo -e "${GREEN}  ✓ $1${NC}"; }
print_fail() { echo -e "${RED}  ✗ $1${NC}"; }

# ─── Usage ───

if [ -z "$SERVER" ] || [ -z "$KEY_ARG" ]; then
    echo "Usage:"
    echo "  add-collaborator.sh SERVER_IP \"ssh-ed25519 AAAA...key...\""
    echo "  add-collaborator.sh SERVER_IP --from-file /path/to/key.pub"
    echo ""
    echo "Example:"
    echo "  add-collaborator.sh 164.92.1.2 \"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... user@email\""
    exit 1
fi

# ─── Get the key ───

if [ "$KEY_ARG" = "--from-file" ]; then
    if [ -z "$KEY_SOURCE" ] || [ ! -f "$KEY_SOURCE" ]; then
        print_fail "File not found: $KEY_SOURCE"
        exit 1
    fi
    SSH_KEY=$(cat "$KEY_SOURCE")
else
    SSH_KEY="$KEY_ARG"
fi

# ─── Validate key format ───

if ! echo "$SSH_KEY" | grep -qE '^ssh-(ed25519|rsa|ecdsa) '; then
    echo ""
    print_fail "That doesn't look like a valid SSH public key."
    echo ""
    echo "  A public key should start with:"
    echo "    ssh-ed25519 AAAA..."
    echo "    ssh-rsa AAAA..."
    echo ""
    echo "  Common mistakes:"
    echo "  • Pasting the private key (no .pub extension)"
    echo "  • Key got split across multiple lines during copy/paste"
    echo "  • Missing the key type prefix"
    echo ""
    exit 1
fi

# Safety check - warn if it looks like a private key
if echo "$SSH_KEY" | grep -q "PRIVATE KEY"; then
    echo ""
    print_fail "This looks like a PRIVATE key! Do not share private keys."
    echo ""
    echo "  Ask your collaborator to send their PUBLIC key instead:"
    echo "    cat ~/.ssh/id_ed25519.pub"
    echo "    (note the .pub extension)"
    echo ""
    exit 1
fi

# ─── Add key to server ───

echo ""
echo -e "${BOLD}Adding collaborator's key to ${SERVER}...${NC}"
echo ""

# Use a heredoc-based approach to avoid quoting issues
ssh "claudeteam@${SERVER}" bash << REMOTE_SCRIPT
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

KEY='${SSH_KEY}'

if grep -qF "\$KEY" ~/.ssh/authorized_keys 2>/dev/null; then
    echo "KEY_ALREADY_EXISTS"
else
    echo "\$KEY" >> ~/.ssh/authorized_keys
    echo "KEY_ADDED"
fi
REMOTE_SCRIPT

RESULT=$?

if [ $RESULT -eq 0 ]; then
    print_ok "Collaborator's SSH key has been added to the server."
    echo ""
    echo "  Tell your collaborator to test with:"
    echo -e "  ${YELLOW}ssh claudeteam@${SERVER}${NC}"
    echo ""
else
    print_fail "Could not connect to server."
    echo "  Make sure you can SSH to: claudeteam@${SERVER}"
    exit 1
fi
