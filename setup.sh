#!/bin/bash

# Claude Code Collaboration - Interactive Setup Wizard
# Guides users through the right setup path based on their role and needs.

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Helpers
print_header() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Claude Code Collaboration Setup Wizard   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▸ ${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}  ✗ $1${NC}"
}

print_info() {
    echo -e "${DIM}    $1${NC}"
}

ask_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local count=${#options[@]}

    echo ""
    echo -e "${BOLD}$prompt${NC}"
    echo ""
    for i in "${!options[@]}"; do
        echo -e "  ${GREEN}$((i+1)))${NC} ${options[$i]}"
    done
    echo ""

    while true; do
        read -p "Enter choice (1-${count}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
            return $((choice - 1))
        fi
        echo -e "${RED}Please enter a number between 1 and ${count}${NC}"
    done
}

press_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

# ─── Detect environment ───

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

detect_shell_rc() {
    if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

# ─── SSH key setup (shared logic) ───

setup_ssh_key() {
    print_step "Checking SSH keys..."
    echo ""

    local key_path=""
    local key_type=""

    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        key_path="$HOME/.ssh/id_ed25519.pub"
        key_type="ED25519"
        print_success "Found ED25519 key"
    elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        key_path="$HOME/.ssh/id_rsa.pub"
        key_type="RSA"
        print_success "Found RSA key"
    fi

    if [ -z "$key_path" ]; then
        print_warn "No SSH key found. Let's create one."
        echo ""
        echo -e "  Creating an ED25519 key (modern, recommended)..."
        echo ""

        read -p "  Your email (for key label, or press Enter to skip): " email
        email="${email:-user@claude-collab}"

        ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
        key_path="$HOME/.ssh/id_ed25519.pub"
        key_type="ED25519"
        echo ""
        print_success "SSH key created"
    fi

    echo ""
    echo -e "${BOLD}  Your public key (${key_type}):${NC}"
    echo -e "${YELLOW}  ──────────────────────────────────────${NC}"
    cat "$key_path"
    echo -e "${YELLOW}  ──────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${DIM}Copy the line above when needed. This is safe to share.${NC}"
    echo -e "  ${RED}Never share the file WITHOUT .pub — that's your private key.${NC}"
}

# ─── Install scripts ───

install_scripts() {
    print_step "Installing collaboration scripts..."

    mkdir -p "$HOME/bin"

    # List of scripts to install
    local scripts=(
        "join-claude-session.sh"
        "join-claude-session-split.sh"
        "setup-ssh.sh"
        "add-collaborator.sh"
        "diagnose.sh"
        "teardown.sh"
    )

    for script in "${scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            cp "$SCRIPT_DIR/$script" "$HOME/bin/"
            chmod +x "$HOME/bin/$script"
            print_success "Installed $script"
        fi
    done

    # Add ~/bin to PATH if needed
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        local shell_rc
        shell_rc=$(detect_shell_rc)
        if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$shell_rc" 2>/dev/null; then
            echo '' >> "$shell_rc"
            echo '# Added by Claude Code Collaboration' >> "$shell_rc"
            echo 'export PATH="$HOME/bin:$PATH"' >> "$shell_rc"
            print_success "Added ~/bin to PATH in $shell_rc"
            print_warn "Run: source $shell_rc  (to activate in this terminal)"
        fi
        export PATH="$HOME/bin:$PATH"
    else
        print_success "~/bin already in PATH"
    fi
}

# ─── Check prerequisites ───

check_prerequisites() {
    print_step "Checking prerequisites..."

    local missing=0

    # tmux
    if command -v tmux &>/dev/null || [ -f /opt/homebrew/bin/tmux ] || [ -f /usr/local/bin/tmux ]; then
        print_success "tmux installed"
    else
        print_error "tmux not installed"
        local os
        os=$(detect_os)
        if [ "$os" = "macos" ]; then
            echo ""
            read -p "  Install tmux with Homebrew? (y/n): " install_tmux
            if [ "$install_tmux" = "y" ] || [ "$install_tmux" = "Y" ]; then
                if command -v brew &>/dev/null; then
                    brew install tmux
                    print_success "tmux installed"
                else
                    print_error "Homebrew not found. Install it first:"
                    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
                    missing=1
                fi
            else
                missing=1
            fi
        else
            echo "  Install with: sudo apt install -y tmux"
            missing=1
        fi
    fi

    # SSH
    if command -v ssh &>/dev/null; then
        print_success "SSH available"
    else
        print_error "SSH not available"
        missing=1
    fi

    return $missing
}

# ─── Flow: Local Test ───

flow_local_test() {
    echo ""
    echo -e "${GREEN}━━━ Local Testing Setup ━━━${NC}"
    echo ""
    echo "  This sets up a local demo using multiple terminals on your machine."
    echo "  No cloud server or SSH needed — just tmux."
    echo ""

    check_prerequisites || { echo ""; echo "Please install missing tools and re-run."; exit 1; }
    install_scripts

    echo ""
    echo -e "${GREEN}━━━ Ready to Test! ━━━${NC}"
    echo ""
    echo -e "  ${BOLD}Quick start:${NC}"
    echo ""
    echo -e "  ${YELLOW}1.${NC} Start a shared session:"
    echo -e "     ${DIM}tmux new-session -s test-collab${NC}"
    echo -e "     ${DIM}claude-code${NC}"
    echo -e "     ${DIM}# Press Ctrl+B, then D to detach${NC}"
    echo ""
    echo -e "  ${YELLOW}2.${NC} Open Terminal 1 (host):"
    echo -e "     ${DIM}join-claude-session.sh host test-collab${NC}"
    echo ""
    echo -e "  ${YELLOW}3.${NC} Open Terminal 2 (collaborator):"
    echo -e "     ${DIM}join-claude-session.sh collaborator test-collab${NC}"
    echo ""
    echo -e "  ${YELLOW}4.${NC} Type in either terminal — watch it appear in both!"
    echo ""
    echo -e "  ${DIM}Full guide: docs/QUICK-TEST-LOCAL-MAC.md${NC}"
    echo ""
}

# ─── Flow: Host Setup ───

flow_host() {
    echo ""
    echo -e "${GREEN}━━━ Host Setup ━━━${NC}"
    echo ""

    check_prerequisites || { echo ""; echo "Please install missing tools and re-run."; exit 1; }
    setup_ssh_key
    press_enter
    install_scripts

    echo ""
    echo -e "${GREEN}━━━ Next Steps ━━━${NC}"
    echo ""
    echo -e "  ${BOLD}You need a cloud server. Two options:${NC}"
    echo ""
    echo -e "  ${YELLOW}Option A: DigitalOcean (Recommended)${NC}"
    echo -e "  ${DIM}  - \$12/month, easiest setup, \$200 free credit for new users${NC}"
    echo -e "  ${DIM}  - Full guide: docs/digitalocean-setup.md${NC}"
    echo ""
    echo -e "  ${YELLOW}Option B: AWS EC2${NC}"
    echo -e "  ${DIM}  - ~\$17/month, more options${NC}"
    echo -e "  ${DIM}  - Full guide: docs/setup-for-host.md${NC}"
    echo ""
    echo -e "  ${BOLD}Once you have a server, run this to set it up in one command:${NC}"
    echo ""
    echo -e "  ${YELLOW}  scp server-bootstrap.sh root@YOUR_SERVER_IP:/tmp/${NC}"
    echo -e "  ${YELLOW}  ssh root@YOUR_SERVER_IP 'bash /tmp/server-bootstrap.sh'${NC}"
    echo ""
    echo -e "  ${BOLD}Then add your collaborator's SSH key:${NC}"
    echo ""
    echo -e "  ${YELLOW}  add-collaborator.sh YOUR_SERVER_IP \"ssh-ed25519 AAAA...their-key...\"${NC}"
    echo ""
    echo -e "  ${BOLD}Finally, connect:${NC}"
    echo ""
    echo -e "  ${YELLOW}  join-claude-session-split.sh host YOUR_SERVER_IP claudeteam claude-collab${NC}"
    echo ""
}

# ─── Flow: Collaborator Setup ───

flow_collaborator() {
    echo ""
    echo -e "${GREEN}━━━ Collaborator Setup ━━━${NC}"
    echo ""
    echo "  Your host has already set up the server."
    echo "  You just need to configure your machine and connect."
    echo ""

    # Get info from user
    read -p "  Server IP (from your host): " server_ip
    if [ -z "$server_ip" ]; then
        print_error "Server IP is required. Get it from your host and re-run."
        exit 1
    fi

    read -p "  Your name (for attribution, e.g. 'alice'): " collab_name
    collab_name="${collab_name:-collaborator}"

    echo ""
    check_prerequisites || { echo ""; echo "Please install missing tools and re-run."; exit 1; }
    setup_ssh_key

    echo ""
    echo -e "${BOLD}  Send the public key above to your host so they can add it to the server.${NC}"
    press_enter

    install_scripts

    # Save env vars
    local shell_rc
    shell_rc=$(detect_shell_rc)

    echo ""
    print_step "Saving connection settings..."

    # Only add if not already present
    if ! grep -q 'COLLAB_HOST' "$shell_rc" 2>/dev/null; then
        cat >> "$shell_rc" << EOF

# Claude Code Collaboration Settings
export COLLAB_HOST="${server_ip}"
export COLLAB_REMOTE_USER="claudeteam"
export COLLAB_SESSION="claude-collab"
EOF
        print_success "Saved to $shell_rc"
    else
        print_warn "Connection settings already exist in $shell_rc"
        print_info "Edit manually if you need to update the server IP"
    fi

    # Test SSH connection
    echo ""
    print_step "Testing SSH connection..."
    echo ""

    if ssh -o ConnectTimeout=5 -o BatchMode=yes "claudeteam@${server_ip}" "echo 'connected'" 2>/dev/null; then
        print_success "SSH connection works!"

        # Check if tmux session exists
        if ssh -o ConnectTimeout=5 "claudeteam@${server_ip}" "tmux has-session -t claude-collab 2>/dev/null" 2>/dev/null; then
            print_success "Collaboration session is running on server"
        else
            print_warn "No collaboration session found yet — host may need to start it"
        fi
    else
        print_warn "Could not connect automatically."
        print_info "Your host may need to add your SSH key first."
        print_info "After they do, test with: ssh claudeteam@${server_ip}"
    fi

    echo ""
    echo -e "${GREEN}━━━ Ready! ━━━${NC}"
    echo ""
    echo -e "  ${BOLD}To join a session:${NC}"
    echo ""
    echo -e "  ${YELLOW}  join-claude-session-split.sh ${collab_name} ${server_ip} claudeteam claude-collab${NC}"
    echo ""
    echo -e "  ${BOLD}To diagnose issues:${NC}"
    echo ""
    echo -e "  ${YELLOW}  diagnose.sh ${server_ip}${NC}"
    echo ""
    echo -e "  ${DIM}Full guide: docs/setup-for-collaborator.md${NC}"
    echo ""
}

# ─── Main ───

print_header

echo -e "  This wizard will guide you through setting up Claude Code"
echo -e "  collaboration. It only takes a few minutes."

ask_choice "What's your role?" \
    "I'm the HOST (setting up the server for collaboration)" \
    "I'm a COLLABORATOR (joining someone else's setup)" \
    "I just want to TEST locally on my own machine"
role=$?

case $role in
    0) flow_host ;;
    1) flow_collaborator ;;
    2) flow_local_test ;;
esac
