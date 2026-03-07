#!/bin/bash

# Claude Code Collaboration - Server Bootstrap
# Run this on a fresh Ubuntu server to set up everything in one command.
#
# Usage (from your local machine):
#   scp server-bootstrap.sh root@YOUR_SERVER_IP:/tmp/
#   ssh root@YOUR_SERVER_IP 'bash /tmp/server-bootstrap.sh'
#
# Or with a collaborator's SSH key:
#   ssh root@YOUR_SERVER_IP 'bash /tmp/server-bootstrap.sh "ssh-ed25519 AAAA...key..."'
#
# What this does:
#   1. Creates 'claudeteam' user
#   2. Configures SSH key access
#   3. Installs tmux, git, curl, Node.js
#   4. Installs Claude Code
#   5. Clones the collaboration repo
#   6. Installs collaboration scripts
#   7. Creates a shared tmux session
#
# Requires: Ubuntu 20.04+ and root access

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

COLLAB_USER="claudeteam"
SESSION_NAME="claude-collab"
EXTRA_SSH_KEY=""
COLLAB_PASSWORD=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --password)
            COLLAB_PASSWORD="$2"
            shift 2
            ;;
        *)
            # First positional arg = extra SSH key (backward compatible)
            if [ -z "$EXTRA_SSH_KEY" ]; then
                EXTRA_SSH_KEY="$1"
            fi
            shift
            ;;
    esac
done

# Generate a random password if none provided
if [ -z "$COLLAB_PASSWORD" ]; then
    COLLAB_PASSWORD=$(openssl rand -base64 12 | tr -d '/+=' | head -c 16)
fi

print_step() { echo -e "\n${BLUE}▸ ${BOLD}$1${NC}"; }
print_ok()   { echo -e "${GREEN}  ✓ $1${NC}"; }
print_warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
print_fail() { echo -e "${RED}  ✗ $1${NC}"; }

# ─── Checks ───

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root.${NC}"
    echo "Usage: ssh root@YOUR_SERVER 'bash /tmp/server-bootstrap.sh'"
    exit 1
fi

if ! grep -qiE 'ubuntu|debian' /etc/os-release 2>/dev/null; then
    print_warn "This script is designed for Ubuntu/Debian. Other distros may need adjustments."
fi

echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Claude Code Collaboration - Server Setup ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"

# ─── Step 1: Create user ───

print_step "Creating '$COLLAB_USER' user..."

if id "$COLLAB_USER" &>/dev/null; then
    print_ok "User '$COLLAB_USER' already exists"
else
    adduser --disabled-password --gecos "" "$COLLAB_USER"
    usermod -aG sudo "$COLLAB_USER"
    # Allow sudo without password for initial setup
    echo "$COLLAB_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$COLLAB_USER"
    print_ok "User '$COLLAB_USER' created with sudo access"
fi

# Set password for ssh-copy-id self-service
echo "${COLLAB_USER}:${COLLAB_PASSWORD}" | chpasswd
print_ok "Password set for '$COLLAB_USER'"

# Enable password auth so collaborators can use ssh-copy-id
if grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config 2>/dev/null; then
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    print_ok "Password authentication enabled for ssh-copy-id"
else
    print_ok "Password authentication already enabled"
fi

# ─── Step 2: SSH keys ───

print_step "Configuring SSH access..."

SSHDIR="/home/$COLLAB_USER/.ssh"
AUTHKEYS="$SSHDIR/authorized_keys"

mkdir -p "$SSHDIR"
touch "$AUTHKEYS"

# Copy root's authorized keys if any (the host likely added theirs here during Droplet creation)
if [ -f /root/.ssh/authorized_keys ]; then
    # Merge without duplicates
    while IFS= read -r key; do
        [ -z "$key" ] && continue
        [[ "$key" == \#* ]] && continue
        if ! grep -qF "$key" "$AUTHKEYS" 2>/dev/null; then
            echo "$key" >> "$AUTHKEYS"
        fi
    done < /root/.ssh/authorized_keys
    print_ok "Copied SSH keys from root"
fi

# Add extra key if provided
if [ -n "$EXTRA_SSH_KEY" ]; then
    if ! grep -qF "$EXTRA_SSH_KEY" "$AUTHKEYS" 2>/dev/null; then
        echo "$EXTRA_SSH_KEY" >> "$AUTHKEYS"
        print_ok "Added collaborator SSH key"
    else
        print_ok "Collaborator SSH key already present"
    fi
fi

chown -R "$COLLAB_USER:$COLLAB_USER" "$SSHDIR"
chmod 700 "$SSHDIR"
chmod 600 "$AUTHKEYS"
print_ok "SSH permissions set"

# ─── Step 3: System packages ───

print_step "Updating system packages..."

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq
print_ok "System updated"

print_step "Installing tmux, git, curl..."

apt-get install -y -qq tmux git curl
print_ok "tmux $(tmux -V 2>/dev/null || echo 'installed')"
print_ok "git $(git --version 2>/dev/null | awk '{print $3}' || echo 'installed')"

# ─── Step 4: Node.js ───

print_step "Installing Node.js..."

if command -v node &>/dev/null; then
    print_ok "Node.js already installed: $(node --version)"
else
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
    apt-get install -y -qq nodejs
    print_ok "Node.js $(node --version) installed"
    print_ok "npm $(npm --version) installed"
fi

# ─── Step 5: Claude Code ───

print_step "Installing Claude Code..."

if command -v claude &>/dev/null; then
    print_ok "Claude Code already installed"
else
    npm install -g @anthropic-ai/claude-code 2>/dev/null || {
        print_warn "Claude Code install via npm had warnings (this is usually fine)"
    }
    if command -v claude &>/dev/null; then
        print_ok "Claude Code installed"
    else
        print_warn "Claude Code may need manual installation"
        echo "  Try: npm install -g @anthropic-ai/claude-code"
    fi
fi

# ─── Step 6: Collaboration repo and scripts ───

print_step "Installing collaboration scripts..."

REPO_DIR="/home/$COLLAB_USER/claude-code-collab"

if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
    su - "$COLLAB_USER" -c "cd $REPO_DIR && git pull --quiet" 2>/dev/null || true
    print_ok "Repository updated"
else
    su - "$COLLAB_USER" -c "git clone --quiet https://github.com/jxandery/claude-code-collab.git $REPO_DIR" 2>/dev/null || {
        # If clone fails (private repo), just create the dir and copy scripts
        mkdir -p "$REPO_DIR"
        chown "$COLLAB_USER:$COLLAB_USER" "$REPO_DIR"
        print_warn "Could not clone repo — scripts will be installed from local copy if available"
    }
fi

# Install scripts for the collab user
BINDIR="/home/$COLLAB_USER/bin"
mkdir -p "$BINDIR"

# Copy scripts from repo if they exist
for script in join-claude-session.sh join-claude-session-split.sh diagnose.sh teardown.sh add-collaborator.sh; do
    if [ -f "$REPO_DIR/$script" ]; then
        cp "$REPO_DIR/$script" "$BINDIR/"
        chmod +x "$BINDIR/$script"
    fi
done

chown -R "$COLLAB_USER:$COLLAB_USER" "$BINDIR"

# Add ~/bin to PATH for claudeteam
BASHRC="/home/$COLLAB_USER/.bashrc"
if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$BASHRC" 2>/dev/null; then
    echo '' >> "$BASHRC"
    echo '# Claude Code Collaboration' >> "$BASHRC"
    echo 'export PATH="$HOME/bin:$PATH"' >> "$BASHRC"
fi
print_ok "Scripts installed to ~/bin"

# ─── Step 7: Create shared tmux session ───

print_step "Creating shared tmux session..."

# Kill existing session if any
su - "$COLLAB_USER" -c "tmux kill-session -t $SESSION_NAME 2>/dev/null" || true

su - "$COLLAB_USER" -c "tmux new-session -s $SESSION_NAME -d"
print_ok "tmux session '$SESSION_NAME' created"

echo ""
echo -e "${YELLOW}NOTE: Claude Code needs to be authenticated and started manually.${NC}"
echo -e "  To do this:"
echo -e "  ${BLUE}ssh ${COLLAB_USER}@THIS_SERVER_IP${NC}"
echo -e "  ${BLUE}tmux attach-session -t ${SESSION_NAME}${NC}"
echo -e "  ${BLUE}claude${NC}  (to start Claude Code)"
echo -e "  ${BLUE}# Then press Ctrl+B, D to detach${NC}"

# ─── Done ───

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Server Setup Complete!                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""

KEY_COUNT=$(wc -l < "$AUTHKEYS" | tr -d ' ')
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo 'YOUR_SERVER_IP')

echo -e "  ${BOLD}Summary:${NC}"
echo -e "  • User:         ${COLLAB_USER}"
echo -e "  • Password:     ${COLLAB_PASSWORD}"
echo -e "  • SSH keys:     ${KEY_COUNT} key(s) configured"
echo -e "  • tmux session: ${SESSION_NAME}"
echo -e "  • Node.js:      $(node --version 2>/dev/null || echo 'check manually')"
echo -e "  • Claude Code:  $(claude --version 2>/dev/null || echo 'needs authentication')"
echo ""
echo -e "  ${BOLD}What to do next:${NC}"
echo -e "  1. SSH in as ${COLLAB_USER} and authenticate Claude Code"
echo -e "  2. Start Claude Code in the tmux session"
echo -e "  3. Share the info below with your collaborators"
echo ""
echo -e "  ${YELLOW}━━━━━━━━ SHARE THIS WITH COLLABORATORS ━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}Server IP:${NC}  ${SERVER_IP}"
echo -e "  ${BOLD}Username:${NC}   ${COLLAB_USER}"
echo -e "  ${BOLD}Password:${NC}   ${COLLAB_PASSWORD}"
echo -e "  ${BOLD}Session:${NC}    ${SESSION_NAME}"
echo ""
echo -e "  ${BOLD}Collaborator commands:${NC}"
echo -e "  ssh-copy-id ${COLLAB_USER}@${SERVER_IP}  # enter password once"
echo -e "  git clone https://github.com/jxandery/claude-code-collab.git"
echo -e "  cd claude-code-collab && ./install.sh"
echo -e "  join-claude-session-split.sh NAME ${SERVER_IP} ${COLLAB_USER} ${SESSION_NAME}"
echo ""
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
