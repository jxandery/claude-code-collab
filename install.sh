#!/bin/bash

# Claude Code Collaboration - Installation Script
# Installs all collaboration scripts for the current user.
#
# Usage:
#   ./install.sh              # Install all scripts to ~/bin
#
# For a guided setup experience, use ./setup.sh instead.

set -e  # Exit on error

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Claude Code Collaboration Installer   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if tmux is installed
if ! command -v tmux &> /dev/null && [ ! -f /opt/homebrew/bin/tmux ] && [ ! -f /usr/local/bin/tmux ]; then
    echo -e "${RED}Error: tmux is not installed!${NC}"
    echo ""
    echo "Please install tmux first:"
    echo -e "${YELLOW}  brew install tmux${NC}"
    echo ""
    exit 1
fi

# Create ~/bin directory if it doesn't exist
echo -e "${BLUE}→ Creating ~/bin directory...${NC}"
mkdir -p ~/bin

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# All scripts to install
SCRIPTS=(
    "join-claude-session.sh"
    "join-claude-session-split.sh"
    "setup-ssh.sh"
    "add-collaborator.sh"
    "diagnose.sh"
    "teardown.sh"
    "start-collaboration.sh"
    "list-sessions.sh"
    "download-from-server.sh"
)

echo -e "${BLUE}→ Installing collaboration scripts...${NC}"

INSTALLED=0
for script in "${SCRIPTS[@]}"; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        cp "$SCRIPT_DIR/$script" ~/bin/
        chmod +x ~/bin/"$script"
        echo -e "${GREEN}  ✓ ${script}${NC}"
        INSTALLED=$((INSTALLED + 1))
    fi
done

if [ "$INSTALLED" -eq 0 ]; then
    echo -e "${RED}  No scripts found to install!${NC}"
    echo "  Make sure you're running this from the claude-code-collab directory."
    exit 1
fi

# Check if ~/bin is in PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo ""
    echo -e "${YELLOW}⚠  ~/bin is not in your PATH${NC}"
    echo ""
    echo "Adding ~/bin to PATH..."

    # Detect shell
    if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi

    # Add to shell config if not already there
    if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$SHELL_RC" 2>/dev/null; then
        echo '' >> "$SHELL_RC"
        echo '# Added by Claude Code Collaboration installer' >> "$SHELL_RC"
        echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_RC"
        echo -e "${GREEN}✓ Added ~/bin to PATH in $SHELL_RC${NC}"
        echo -e "${YELLOW}  Please run: source $SHELL_RC${NC}"
    else
        echo -e "${GREEN}✓ PATH already configured${NC}"
    fi
else
    echo -e "${GREEN}✓ ~/bin is already in PATH${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Installation Complete! ✓              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${INSTALLED} scripts installed to ~/bin"
echo ""
echo -e "${BLUE}Available commands:${NC}"
echo ""
echo -e "  ${GREEN}join-claude-session-split.sh${NC}  Join with split view (recommended)"
echo -e "  ${GREEN}join-claude-session.sh${NC}        Join with input-only mode"
echo -e "  ${GREEN}setup-ssh.sh${NC}                  Set up or check SSH keys"
echo -e "  ${GREEN}add-collaborator.sh${NC}           Add a collaborator's SSH key to server"
echo -e "  ${GREEN}diagnose.sh${NC}                   Check if everything is working"
echo -e "  ${GREEN}teardown.sh${NC}                   Clean up sessions"
echo ""
echo -e "${BLUE}Quick start:${NC}"
echo "  For guided setup:    ./setup.sh"
echo "  For full docs:       See README.md"
echo ""
