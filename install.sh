#!/bin/bash

# Claude Code Collaboration - Installation Script
# This installs the collaboration script for the current user

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

# Copy the scripts
echo -e "${BLUE}→ Installing collaboration scripts...${NC}"
cp join-claude-session.sh ~/bin/
chmod +x ~/bin/join-claude-session.sh

if [ -f join-claude-session-split.sh ]; then
    cp join-claude-session-split.sh ~/bin/
    chmod +x ~/bin/join-claude-session-split.sh
    echo -e "${GREEN}  ✓ Installed join-claude-session-split.sh (split-pane mode)${NC}"
fi

echo -e "${GREEN}  ✓ Installed join-claude-session.sh (simple mode)${NC}"

# Check if ~/bin is in PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
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
echo -e "${BLUE}Two modes available:${NC}"
echo ""
echo -e "${GREEN}1. Split-Pane Mode (Recommended)${NC}"
echo -e "   Shows Claude output and your input in one terminal window"
echo -e "   ${YELLOW}join-claude-session-split.sh <username> <server-ip> [user] [session]${NC}"
echo ""
echo -e "${BLUE}2. Simple Input Mode${NC}"
echo -e "   Input only - requires separate terminal for viewing"
echo -e "   ${YELLOW}join-claude-session.sh <username> [session]${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. If PATH was updated, run: source $SHELL_RC"
echo "  2. See README.md for usage instructions"
echo ""
