# Setup Guide for host - Claude Code Collaboration with collaborator

## Overview

You and collaborator will be able to:
- Type on your own local machines
- Your inputs are automatically prefixed: `[host]` and `[collaborator]`
- Both see Claude Code's responses in real-time
- Claude knows who asked what!

---

## Prerequisites

- [ ] SSH access (you already have this on Mac)
- [ ] tmux installed locally (we'll install if needed)
- [ ] A shared server for running Claude Code (see options below)

---

## STEP 1: Get a Shared Server

You need one server where Claude Code will run. Both you and collaborator will connect to it.

### Option A: Use DigitalOcean (Recommended - Easiest)

1. Go to https://www.digitalocean.com/
2. Create an account (get $200 free credit for 60 days)
3. Create a Droplet:
   - **Image:** Ubuntu 22.04 LTS
   - **Plan:** Basic ($12/month, 2GB RAM, 1 CPU)
   - **Datacenter:** San Francisco (good for both ET and PT)
   - **Authentication:** SSH Keys (we'll set this up next)
   - **Hostname:** claude-collab-server

4. You'll get an IP address like `164.92.123.456`

### Option B: Use AWS EC2

1. Go to AWS Console → EC2
2. Launch Instance:
   - **AMI:** Ubuntu Server 22.04 LTS
   - **Type:** t2.small (1GB RAM, enough to start)
   - **Security Group:** Allow SSH (port 22) from your and collaborator's IPs

3. Download the .pem key file

### Option C: Use Your Own Mac (Quick Test Only)

> **⚠️ CRITICAL SECURITY WARNING**: DO NOT USE YOUR LOCAL MACHINE FOR REAL COLLABORATION!
>
> Allowing remote login to your Mac gives collaborators:
> - **Full access** to all your files and data
> - **Complete control** over your system with your user privileges
> - **Access to credentials**: SSH keys, API tokens, passwords, cloud credentials
> - **Ability to install malware**, create backdoors, or steal intellectual property
> - **Access to your network** and potentially other systems you can reach
>
> **This option should ONLY be used for quick personal testing with multiple terminal windows on your own machine. NEVER enable Remote Login for external collaborators.**

If you just want to test before setting up a server (with no external access):
1. ~~Enable Remote Login: System Preferences → Sharing → Remote Login~~ **DO NOT enable Remote Login**
2. Use multiple terminal windows on your own Mac to simulate collaboration
3. Follow the local testing guide: [QUICK-TEST-LOCAL-MAC.md](QUICK-TEST-LOCAL-MAC.md)

**For any real collaboration with other people, you MUST use Option A (DigitalOcean) or Option B (AWS).**

---

## STEP 2: Set Up SSH Keys (If You Don't Have Them)

Check if you have SSH keys:
```bash
ls ~/.ssh/id_rsa.pub
```

If you see "No such file", create them:
```bash
ssh-keygen -t rsa -b 4096 -C "host@claudecollab"
# Press Enter for all prompts (accept defaults)
```

Copy your public key:
```bash
cat ~/.ssh/id_rsa.pub
```

You'll need to:
1. Copy this public key
2. Add it to the shared server (we'll do this in Step 4)
3. Get collaborator's public key and add it too

---

## STEP 3: Install tmux on Your Local Mac

Check if you have tmux:
```bash
which tmux
```

If not installed:
```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tmux
brew install tmux
```

---

## STEP 4: Set Up the Shared Server

SSH into your shared server for the first time:
```bash
# Replace with your server's IP
ssh root@164.92.123.456
```

### A. Create a Shared User Account

```bash
# Create a user for collaboration
sudo adduser claudeteam
# Set a password (you'll share this with collaborator, or use SSH keys)

# Add to sudo group (in case you need admin access)
sudo usermod -aG sudo claudeteam

# Switch to the new user
su - claudeteam
cd ~
```

### B. Set Up SSH Key Access

```bash
# Still as claudeteam user
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Now add both your and collaborator's public keys:
```bash
nano ~/.ssh/authorized_keys
```

Paste both public keys (one per line):
```
ssh-rsa AAAAB3NzaC1yc2EAAAA... host@claudecollab
ssh-rsa AAAAB3NzaC1yc2EAAAA... collaborator@claudecollab
```

Save and exit (Ctrl+X, Y, Enter)

### C. Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install tmux
sudo apt install -y tmux git curl

# Install Node.js (needed for Claude Code)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installations
tmux -V
node --version
npm --version
```

### D. Install Claude Code on the Server

```bash
# Follow official Claude Code installation
# (Check the latest instructions from Anthropic)

# Typical installation:
npm install -g @anthropic-ai/claude-code

# Or if using a different method, follow official docs
```

### E. Configure Claude Code

```bash
# Log in to Claude Code on the server
claude-code auth login

# This will give you a URL to visit
# Open it in your browser and authenticate
# The token will be saved on the server
```

### F. Create the Shared tmux Session

```bash
# Create a tmux session that both you and collaborator will use
tmux new-session -s claude-collab -d

# Verify it's running
tmux ls
# Should show: claude-collab: 1 windows (created ...)
```

### G. Test that tmux is Accessible

```bash
# Attach to it
tmux attach-session -t claude-collab

# You should see a blank terminal
# Type something, then detach: Ctrl+B, then D

# Exit the SSH session
exit
```

---

## STEP 5: Set Up Your Local Machine (host)

### A. Create Environment Variables

```bash
# Open your shell config file
nano ~/.zshrc
# Or if you use bash: nano ~/.bashrc
```

Add these lines at the end:
```bash
# Claude Collaboration Settings
export COLLAB_USER_NAME="host"
export COLLAB_HOST="164.92.123.456"  # Replace with your server IP
export COLLAB_REMOTE_USER="claudeteam"
export COLLAB_SESSION="claude-collab"
```

Save and exit, then reload:
```bash
source ~/.zshrc
# or: source ~/.bashrc
```

### B. Create the Collaboration Script

```bash
# Create a bin directory if you don't have one
mkdir -p ~/bin

# Create the script
nano ~/bin/claude-collab.sh
```

Paste this script:
```bash
#!/bin/bash

# Claude Code Collaboration Script
# Usage: claude-collab.sh [your-name]

USER_NAME="${1:-${COLLAB_USER_NAME:-User}}"
REMOTE_HOST="${COLLAB_HOST}"
REMOTE_USER="${COLLAB_REMOTE_USER}"
SESSION="${COLLAB_SESSION:-claude-collab}"

# Validate configuration
if [ -z "$REMOTE_HOST" ]; then
    echo "Error: COLLAB_HOST not set!"
    echo "Please set it in your ~/.zshrc or ~/.bashrc"
    echo "Example: export COLLAB_HOST='164.92.123.456'"
    exit 1
fi

if [ -z "$REMOTE_USER" ]; then
    echo "Error: COLLAB_REMOTE_USER not set!"
    echo "Please set it in your ~/.zshrc or ~/.bashrc"
    echo "Example: export COLLAB_REMOTE_USER='claudeteam'"
    exit 1
fi

# Colors for better UX
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Claude Code Collaboration ===${NC}"
echo -e "${BLUE}Your name: ${USER_NAME}${NC}"
echo -e "${BLUE}Server: ${REMOTE_HOST}${NC}"
echo -e "${BLUE}Session: ${SESSION}${NC}"
echo ""
echo -e "${YELLOW}Setting up split view...${NC}"

# Create local tmux session with split view
LOCAL_SESSION="cc-${USER_NAME}"

# Kill existing session if it exists
tmux kill-session -t "$LOCAL_SESSION" 2>/dev/null

# Create new session
tmux new-session -d -s "$LOCAL_SESSION" -n main

# Top pane: Read-only view of shared session
echo -e "${YELLOW}Connecting to shared Claude Code session...${NC}"
tmux send-keys -t "${LOCAL_SESSION}:main.0" \
    "echo 'Connecting to shared session...'; ssh -t ${REMOTE_USER}@${REMOTE_HOST} 'tmux attach-session -r -t ${SESSION}'" C-m

# Give it a moment to connect
sleep 1

# Split window vertically
tmux split-window -v -t "${LOCAL_SESSION}:main" -p 30

# Bottom pane: Input terminal with auto-prefix
tmux send-keys -t "${LOCAL_SESSION}:main.1" \
    "echo -e '\033[1;32m=== Your Input Terminal ===\033[0m'" C-m

tmux send-keys -t "${LOCAL_SESSION}:main.1" \
    "echo 'Type your prompts below. They will be prefixed with [${USER_NAME}]'" C-m

tmux send-keys -t "${LOCAL_SESSION}:main.1" \
    "echo 'Press Ctrl+C to exit'" C-m

tmux send-keys -t "${LOCAL_SESSION}:main.1" \
    "echo ''" C-m

# Create the input loop
tmux send-keys -t "${LOCAL_SESSION}:main.1" \
"while true; do
    read -e -p '[${USER_NAME}]> ' input
    if [ -n \"\$input\" ]; then
        ssh ${REMOTE_USER}@${REMOTE_HOST} \"tmux send-keys -t ${SESSION} '[${USER_NAME}] \$input' C-m\"
    fi
done" C-m

# Attach to the local session
echo -e "${GREEN}Done! Attaching to collaboration session...${NC}"
sleep 1
tmux attach-session -t "$LOCAL_SESSION"
```

Save and exit (Ctrl+X, Y, Enter)

Make it executable:
```bash
chmod +x ~/bin/claude-collab.sh
```

### C. Add ~/bin to Your PATH (If Not Already)

```bash
# Check if ~/bin is in your PATH
echo $PATH | grep "$HOME/bin"
```

If you don't see it, add it:
```bash
# Add to ~/.zshrc or ~/.bashrc
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## STEP 6: Test Your Setup

### A. Test SSH Connection

```bash
ssh claudeteam@164.92.123.456
# You should connect without password (using SSH key)
# Type 'exit' to disconnect
```

If this doesn't work:
- Check that you added your SSH public key to `~/.ssh/authorized_keys` on the server
- Try with password: `ssh claudeteam@164.92.123.456` and enter the password you created

### B. Test the Collaboration Script

```bash
claude-collab.sh host
```

You should see:
- **Top pane**: Connection to the shared tmux session
- **Bottom pane**: Your input prompt `[host]> `

Try typing something:
```
[host]> Hello from host's machine
```

You should see it appear in the top pane!

### C. Start Claude Code on the Shared Session

To actually start Claude Code:

1. In a separate terminal, SSH directly to the server:
```bash
ssh claudeteam@164.92.123.456
```

2. Attach to the shared session (not read-only):
```bash
tmux attach-session -t claude-collab
```

3. Start Claude Code:
```bash
claude-code
```

4. Now detach (Ctrl+B, then D)

5. Go back to your collaboration terminal - you should see Claude Code running!

6. Type in your bottom pane:
```
[host]> What is 2+2?
```

Claude should respond in the top pane!

---

## STEP 7: Send Setup Instructions to collaborator

I've created a separate file for collaborator: `setup-for-collaborator.md`

Send collaborator:
1. The `setup-for-collaborator.md` file
2. The server IP address
3. The `claudeteam` user password (if not using SSH keys)
4. OR: Ask collaborator to send you his SSH public key

collaborator will run the same script but with his name:
```bash
claude-collab.sh collaborator
```

---

## Usage Guide

### Starting a Collaboration Session

**host:**
```bash
claude-collab.sh host
```

**collaborator:**
```bash
claude-collab.sh collaborator
```

### During the Session

- **Type in the bottom pane** - your input is automatically prefixed
- **View in the top pane** - see all Claude responses
- **Coordinate via voice/Slack** - "I'm asking a question now..."

Example session:
```
Top pane (shared view):
[host] Add user authentication with JWT
Claude: I'll help you implement JWT authentication...

[collaborator] Can we also handle refresh tokens?
Claude: Yes collaborator, building on host's authentication...

[host] Great! Now let's write tests
Claude: I'll write tests for both the JWT and refresh token functionality...
```

### Exiting

- **To exit your input loop**: Ctrl+C in the bottom pane
- **To detach from tmux**: Ctrl+B, then D
- **To fully quit**: Type `exit` or close the terminal

### Reattaching

If you get disconnected or want to rejoin:
```bash
claude-collab.sh host
```

Your input loop will reconnect automatically.

---

## Troubleshooting

### "Connection refused" when SSHing
- Check the server IP address
- Verify the server is running
- Check firewall rules (port 22 must be open)

### "Permission denied (publickey)"
- Verify your SSH key is in `~/.ssh/authorized_keys` on the server
- Try connecting with password: `ssh -o PubkeyAuthentication=no claudeteam@SERVER_IP`

### "No session found: claude-collab"
- SSH to server and create it: `tmux new-session -s claude-collab -d`

### Can't see collaborator's messages
- Make sure you're both connected to the same session
- Verify: SSH to server, run `tmux ls`, should show `claude-collab` session

### Messages not appearing in top pane
- The top pane connection might have dropped
- Exit and restart: `claude-collab.sh host`

### Claude Code not responding
- Make sure Claude Code is actually running on the server
- SSH to server: `ssh claudeteam@SERVER_IP`
- Attach to session: `tmux attach-session -t claude-collab`
- Check if Claude Code is running, if not, start it: `claude-code`

---

## Advanced: Voice Coordination

For the best experience, use voice chat while collaborating:

1. **Discord/Slack Call:**
   ```
   host: "Let me ask about authentication"
   [host types in bottom pane]
   collaborator: "That looks good!"
   collaborator: "Can I ask about error handling?"
   [collaborator types in bottom pane]
   ```

2. **Quick Chat:**
   - "I'm typing now..."
   - "Your turn!"
   - "Wait, let me add to that..."

---

## Cost

- **DigitalOcean Droplet**: $12/month (2GB RAM)
- **AWS EC2 t2.small**: ~$17/month
- **Claude Code subscription**: Per your existing plan

You and collaborator can split the server cost: **$6/month each!**

---

## Next Steps

- [ ] Set up shared server (Step 4)
- [ ] Configure your local machine (Step 5)
- [ ] Test the setup (Step 6)
- [ ] Send instructions to collaborator
- [ ] Schedule a test session together
- [ ] Start collaborating!

---

## Questions?

If something doesn't work:
1. Check the Troubleshooting section
2. Verify each step completed successfully
3. Test SSH connection independently
4. Make sure tmux session exists on server

Ready to set this up? Start with Step 1!
