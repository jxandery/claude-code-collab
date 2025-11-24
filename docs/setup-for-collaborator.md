# Setup Guide for collaborator - Claude Code Collaboration with host

## Overview

You and host will collaborate using Claude Code with:
- Type on your own local machine
- Your inputs are automatically prefixed with `[collaborator]`
- host's inputs show as `[host]`
- Both see Claude Code's responses in real-time
- Claude knows who asked what!

host has already set up the shared server. You just need to configure your local machine and connect.

---

## What host Should Give You

- [ ] Server IP address (e.g., `164.92.123.456`)
- [ ] Username: `claudeteam`
- [ ] Either:
  - Password for `claudeteam` account, OR
  - Confirmation that your SSH key has been added

---

## STEP 1: Set Up SSH Keys (If You Don't Have Them)

Check if you have SSH keys:
```bash
ls ~/.ssh/id_rsa.pub
```

If you see "No such file", create them:
```bash
ssh-keygen -t rsa -b 4096 -C "collaborator@claudecollab"
# Press Enter for all prompts (accept defaults)
```

Display your public key:
```bash
cat ~/.ssh/id_rsa.pub
```

**Send this public key to host** so he can add it to the server.

---

## STEP 2: Install tmux on Your Local Machine

### macOS:
```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tmux
brew install tmux
```

### Linux (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install -y tmux
```

### Verify installation:
```bash
tmux -V
# Should show: tmux 3.x
```

---

## STEP 3: Test SSH Connection to Shared Server

Replace `164.92.123.456` with the IP host gave you:

```bash
ssh claudeteam@164.92.123.456
```

**If using SSH key (no password):**
- Should connect automatically
- Type `exit` to disconnect

**If using password:**
- Enter the password host gave you
- Type `exit` to disconnect

**If connection fails:**
- Verify the IP address is correct
- Check with host that your SSH key was added
- Try with password if key doesn't work

---

## STEP 4: Set Up Your Local Machine

### A. Create Environment Variables

Open your shell config file:
```bash
# If you use zsh (default on newer macOS):
nano ~/.zshrc

# If you use bash:
nano ~/.bashrc
```

Add these lines at the end (replace `164.92.123.456` with your server IP):
```bash
# Claude Collaboration Settings
export COLLAB_USER_NAME="collaborator"
export COLLAB_HOST="164.92.123.456"  # Replace with host's server IP
export COLLAB_REMOTE_USER="claudeteam"
export COLLAB_SESSION="claude-collab"
```

Save and exit (Ctrl+X, Y, Enter), then reload:
```bash
source ~/.zshrc
# or: source ~/.bashrc
```

### B. Create the Collaboration Script

```bash
# Create a bin directory
mkdir -p ~/bin

# Create the script
nano ~/bin/claude-collab.sh
```

Paste this entire script:
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

### C. Add ~/bin to Your PATH

```bash
# Check if ~/bin is in your PATH
echo $PATH | grep "$HOME/bin"
```

If you don't see it, add it:
```bash
# For zsh:
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# For bash:
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## STEP 5: Test Your Setup

### A. Test SSH Connection Again

```bash
ssh claudeteam@164.92.123.456
# Should connect without issues
# Type 'exit' to disconnect
```

### B. Test the Collaboration Script

```bash
claude-collab.sh collaborator
```

You should see:
```
=== Claude Code Collaboration ===
Your name: collaborator
Server: 164.92.123.456
Session: claude-collab

Setting up split view...
Connecting to shared Claude Code session...
```

Then a split screen appears:
- **Top pane**: Shared Claude Code session (read-only view)
- **Bottom pane**: Your input prompt `[collaborator]> `

### C. Try Sending a Message

In the bottom pane, type:
```
[collaborator]> Hello from collaborator's machine!
```

You should see it appear in the top pane!

---

## STEP 6: Start Collaborating with host

### Before Your First Session

Coordinate with host via Slack/Discord/phone:
1. Agree on a time
2. Make sure Claude Code is running on the server (host will handle this initially)
3. Both run your collaboration scripts

### Starting the Session

**collaborator runs:**
```bash
claude-collab.sh collaborator
```

**host runs:**
```bash
claude-collab.sh host
```

### During the Session

**Top pane (both of you see this):**
```
[host] Add user authentication with JWT
Claude: I'll help you implement JWT authentication...
[Here's the code...]

[collaborator] Can we also handle refresh tokens?
Claude: Yes collaborator, building on host's authentication...
[Updated code with refresh tokens...]

[host] Perfect! Now let's write tests
Claude: I'll create tests for both features...
```

**Bottom pane (your input):**
```
[collaborator]> Can we also handle refresh tokens?
[collaborator]> Let me ask about error handling
[collaborator]> _
```

### Best Practices

1. **Use voice/video chat** for coordination:
   - "Let me ask a question..."
   - "Go ahead, I'll wait"
   - Discuss Claude's responses together

2. **Take turns naturally:**
   - One person asks, both review the response
   - Other person asks follow-up
   - Collaborative discussion

3. **Be clear about changes:**
   - "I'm going to ask Claude to refactor this"
   - "Can you ask about error handling?"

---

## Keyboard Shortcuts

### In tmux:
- **Detach from session:** Ctrl+B, then D
- **Switch panes:** Ctrl+B, then arrow keys
- **Scroll in top pane:** Ctrl+B, then [, then use arrow keys (q to exit scroll mode)

### In the input loop:
- **Exit input loop:** Ctrl+C
- **Clear your input:** Ctrl+U
- **Recall previous command:** Up arrow

---

## Troubleshooting

### Can't connect to server
```bash
# Test basic SSH:
ssh claudeteam@164.92.123.456

# If it fails:
# 1. Verify IP address with host
# 2. Try with password: ssh -o PubkeyAuthentication=no claudeteam@SERVER_IP
# 3. Check that host added your SSH key
```

### "No session found: claude-collab"
The shared tmux session doesn't exist. Ask host to:
```bash
# host should SSH to server and run:
tmux new-session -s claude-collab -d
```

### Can't see host's messages or Claude's responses
- Make sure you're both connected to the same session
- Try exiting and restarting: `claude-collab.sh collaborator`
- Verify with host that Claude Code is running on the server

### Top pane shows "Connection refused"
- The SSH connection to the server failed
- Check network connectivity
- Verify server is running

### Messages I type don't appear in top pane
- The bottom pane SSH connection might have an issue
- Check that you can SSH to the server independently
- Exit (Ctrl+C) and restart the script

### "Command not found: claude-collab.sh"
- Make sure you added ~/bin to your PATH
- Verify the script is executable: `ls -l ~/bin/claude-collab.sh`
- Try running with full path: `~/bin/claude-collab.sh collaborator`

---

## Timezone Coordination (PT to ET)

Since you're Pacific and host is Eastern (3-hour difference):

**Your overlap window: 9am-2pm PT (12pm-5pm ET)**

### Suggested Schedule:
- **Morning (6am-9am PT):** Solo work on your local Claude Code
- **Overlap (9am-12pm PT):** Pair session with host 2-3x per week
- **Afternoon (12pm-5pm PT):** Solo work, document for host

### Async Handoff:
When not pairing, document your work:
```bash
# In your project:
.claude/daily-logs/2025-01-21-collaborator-PT.md
```

Include:
- What you worked on
- What Claude Code helped with
- Questions for host
- Status of current work

---

## Cost Sharing

The server costs $12/month. You and host can split it:
- **$6/month each** for unlimited collaboration!

---

## What to Do If...

### host isn't available but you want to use Claude Code
Use Claude Code on your local machine as normal. Document what you do for the next pair session.

### You want to work on the shared server independently
```bash
# SSH to the server
ssh claudeteam@164.92.123.456

# Attach to the shared session (not read-only)
tmux attach-session -t claude-collab

# Start Claude Code if not running
claude-code

# Work as normal, but be aware host might see your work later
# Detach when done: Ctrl+B, then D
```

### You want to see the full history
```bash
# SSH to server
ssh claudeteam@164.92.123.456

# Attach to session
tmux attach-session -r -t claude-collab

# Enter scroll mode
# Ctrl+B, then [
# Use arrow keys or Page Up/Down to scroll
# Press 'q' to exit scroll mode
```

---

## Next Steps Checklist

- [ ] Create SSH keys (or use existing)
- [ ] Send public key to host
- [ ] Install tmux locally
- [ ] Test SSH connection to server
- [ ] Create environment variables in ~/.zshrc or ~/.bashrc
- [ ] Create the claude-collab.sh script
- [ ] Make script executable
- [ ] Add ~/bin to PATH
- [ ] Test the script: `claude-collab.sh collaborator`
- [ ] Coordinate first session with host
- [ ] Start collaborating!

---

## Quick Reference

### Connect to Collaboration:
```bash
claude-collab.sh collaborator
```

### Exit Collaboration:
- Ctrl+C in bottom pane
- Or Ctrl+B, then D to detach

### Reconnect:
```bash
claude-collab.sh collaborator
```

---

## Support

If you run into issues:
1. Check the Troubleshooting section
2. Verify each setup step
3. Test SSH independently: `ssh claudeteam@SERVER_IP`
4. Coordinate with host to debug together

---

Ready to collaborate with host? Follow the steps and you'll be up and running in about 15-20 minutes!
