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

# Core collaboration scripts
cp join-claude-session.sh ~/bin/
chmod +x ~/bin/join-claude-session.sh
echo -e "${GREEN}  ✓ Installed join-claude-session.sh (simple mode)${NC}"

if [ -f join-claude-session-split.sh ]; then
    cp join-claude-session-split.sh ~/bin/
    chmod +x ~/bin/join-claude-session-split.sh
    echo -e "${GREEN}  ✓ Installed join-claude-session-split.sh (split-pane mode)${NC}"
fi

# Utility scripts
if [ -f start-collaboration.sh ]; then
    cp start-collaboration.sh ~/bin/
    chmod +x ~/bin/start-collaboration.sh
    echo -e "${GREEN}  ✓ Installed start-collaboration.sh (interactive wizard)${NC}"
fi

if [ -f list-sessions.sh ]; then
    cp list-sessions.sh ~/bin/
    chmod +x ~/bin/list-sessions.sh
    echo -e "${GREEN}  ✓ Installed list-sessions.sh (view active sessions)${NC}"
fi

if [ -f download-from-server.sh ]; then
    cp download-from-server.sh ~/bin/
    chmod +x ~/bin/download-from-server.sh
    echo -e "${GREEN}  ✓ Installed download-from-server.sh (download files)${NC}"
fi

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
echo -e "${BLUE}Quick Start:${NC}"
echo ""
echo -e "${GREEN}→ New User? Start Here:${NC}"
echo -e "   ${YELLOW}start-collaboration.sh${NC}"
echo -e "   Interactive wizard to set up and connect"
echo ""
echo -e "${BLUE}Available Commands:${NC}"
echo ""
echo -e "${GREEN}1. start-collaboration.sh${NC}"
echo -e "   Interactive setup - easiest for beginners"
echo ""
echo -e "${GREEN}2. list-sessions.sh [server-ip] [user]${NC}"
echo -e "   View all active sessions on the server"
echo ""
echo -e "${GREEN}3. download-from-server.sh <remote-path> [local-path]${NC}"
echo -e "   Download files created during collaboration"
echo ""
echo -e "${GREEN}4. join-claude-session-split.sh <name> <server> [user] [session]${NC}"
echo -e "   Split-pane mode (advanced users)"
echo ""
echo -e "${GREEN}5. join-claude-session.sh <name> [session]${NC}"
echo -e "   Simple mode (advanced users)"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. If PATH was updated, run: source $SHELL_RC"
echo "  2. Run: start-collaboration.sh"
echo "  3. See docs/ folder for detailed guides"
echo ""
