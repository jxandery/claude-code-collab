# Quick Test Setup - Local Mac Only (No Cloud Server)

> **⚠️ CRITICAL SECURITY WARNING**
>
> This guide is for **LOCAL TESTING ONLY** using multiple terminal windows on **YOUR OWN MACHINE**.
>
> **DO NOT use your local Mac for real collaboration with other people!**
>
> Allowing remote access to your local machine would give collaborators:
> - Full access to all your files, credentials, and SSH keys
> - Ability to execute any commands with your user privileges
> - Access to sensitive data, API tokens, and cloud credentials
> - Potential to install malware or create backdoors
> - Access to your local network and other systems
>
> **For actual collaboration, you MUST use a dedicated cloud server (DigitalOcean, AWS, etc.).**

## Purpose

Test the collaboration concept on your Mac before setting up a cloud server. You'll simulate both host and collaborator on the same machine to see how it works.

**Time:** 10-15 minutes

---

## What You'll Do

1. Create a shared tmux session on your Mac
2. Open two terminal windows **on the same Mac**
3. One terminal = "host" typing (simulated)
4. Other terminal = "collaborator" typing (simulated)
5. Both see the same Claude Code output
6. Test the auto-prefixing behavior

**Note:** You are simulating collaboration by yourself on one machine. This is safe because no external access is involved.

---

## STEP 1: Install tmux (If Needed)

```bash
# Check if tmux is installed
which tmux

# If not installed:
brew install tmux
```

---

## STEP 2: Start Claude Code in a Shared tmux Session

```bash
# Create a new tmux session named "test-collab"
tmux new-session -s test-collab

# Inside tmux, start Claude Code
claude-code

# Test that Claude Code works - ask it something simple:
# "What is 2+2?"

# Now detach from the session (keep it running in background)
# Press: Ctrl+B, then press D
```

You should be back at your normal terminal. Claude Code is still running in the background.

---

## STEP 3: Create a Simple Test Script

```bash
# Create the test directory
mkdir -p ~/bin

# Create a simpler version for local testing
cat > ~/bin/claude-test-local.sh << 'SCRIPT'
#!/bin/bash

# Local test version - connects to local tmux session
USER_NAME="${1:-User}"
SESSION="test-collab"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== Claude Code Local Test ===${NC}"
echo -e "${BLUE}Your name: ${USER_NAME}${NC}"
echo -e "${BLUE}Session: ${SESSION}${NC}"
echo ""

# Create local tmux session for this user
LOCAL_SESSION="test-${USER_NAME}"

# Kill existing session if it exists
tmux kill-session -t "$LOCAL_SESSION" 2>/dev/null

# Create new session with split view
tmux new-session -d -s "$LOCAL_SESSION" -n main

# Top pane: Read-only view of shared session
tmux send-keys -t "${LOCAL_SESSION}:main.0" \
    "tmux attach-session -r -t ${SESSION}" C-m

# Wait a moment
sleep 0.5

# Split window vertically (30% height for input)
tmux split-window -v -t "${LOCAL_SESSION}:main" -p 30

# Bottom pane: Input terminal
tmux send-keys -t "${LOCAL_SESSION}:main.1" \
    "echo '=== Your Input Terminal (${USER_NAME}) ==='" C-m
tmux send-keys -t "${LOCAL_SESSION}:main.1" \
    "echo 'Type prompts below (auto-prefixed with [${USER_NAME}])'" C-m
tmux send-keys -t "${LOCAL_SESSION}:main.1" \
    "echo 'Press Ctrl+C to exit'" C-m
tmux send-keys -t "${LOCAL_SESSION}:main.1" \
    "echo ''" C-m

# Create the input loop
tmux send-keys -t "${LOCAL_SESSION}:main.1" \
"while true; do
    read -e -p '[${USER_NAME}]> ' input
    if [ -n \"\$input\" ]; then
        tmux send-keys -t ${SESSION} '[${USER_NAME}] \$input' C-m
    fi
done" C-m

# Attach to the local session
tmux attach-session -t "$LOCAL_SESSION"
SCRIPT

# Make it executable
chmod +x ~/bin/claude-test-local.sh
```

---

## STEP 4: Test It!

### Open Two Terminal Windows

**Terminal 1 (host):**
```bash
~/bin/claude-test-local.sh host
```

**Terminal 2 (collaborator):**
```bash
~/bin/claude-test-local.sh collaborator
```

### What You Should See

Each terminal window will be split:

**Terminal 1 (host's view):**
```
┌────────────────────────────────────────┐
│ TOP: Shared Claude Code Output         │
│ (Both host and collaborator see this)  │
│                                        │
│ [host] What is 2+2?                    │
│ Claude: 2+2 equals 4.                  │
│                                        │
│ [collaborator] What about 3+3?         │
│ Claude: 3+3 equals 6.                  │
└────────────────────────────────────────┘
├────────────────────────────────────────┤
│ BOTTOM: host's Input                   │
│ [host]> What is 2+2?                   │
│ [host]> _                              │
└────────────────────────────────────────┘
```

**Terminal 2 (collaborator's view):**
```
┌────────────────────────────────────────┐
│ TOP: Shared Claude Code Output         │
│ (Same as host's top pane)              │
│                                        │
│ [host] What is 2+2?                    │
│ Claude: 2+2 equals 4.                  │
│                                        │
│ [collaborator] What about 3+3?         │
│ Claude: 3+3 equals 6.                  │
└────────────────────────────────────────┘
├────────────────────────────────────────┤
│ BOTTOM: collaborator's Input           │
│ [collaborator]> What about 3+3?        │
│ [collaborator]> _                      │
└────────────────────────────────────────┘
```

---

## STEP 5: Try Some Test Prompts

### In host's Terminal (bottom pane):
```
[host]> Add a function that calculates the sum of two numbers
```

Watch it appear in the top pane with `[host]` prefix. Claude will respond.

### In collaborator's Terminal (bottom pane):
```
[collaborator] Can you also add error handling?
```

Watch it appear in BOTH top panes (host's and collaborator's) with `[collaborator]` prefix. Claude will respond.

### In host's Terminal:
```
[host]> Great! Now add some tests
```

Both of you see this!

---

## What This Demonstrates

✅ **User Attribution:** Claude sees `[host]` and `[collaborator]` in the prompts
✅ **Real-time Sharing:** Both terminals see all interactions
✅ **Auto-prefixing:** You don't manually type `[host]`, it's added automatically
✅ **Natural Flow:** Take turns asking questions, both see responses

---

## Arranging Your Screen for Demo

**Option 1: Side-by-side**
```
┌──────────────────┬──────────────────┐
│   host's         │   collaborator's │
│   Terminal       │   Terminal       │
│                  │                  │
│  [Shared View]   │  [Shared View]   │
│  ┌────────────┐  │  ┌────────────┐  │
│  │ Claude Out │  │  │ Claude Out │  │
│  └────────────┘  │  └────────────┘  │
│  ┌────────────┐  │  ┌────────────┐  │
│  │host's Input│  │  │collaborator│  │
│  │            │  │  │   Input    │  │
│  └────────────┘  │  └────────────┘  │
└──────────────────┴──────────────────┘
```

**Option 2: Use macOS Spaces** (different desktops)
- Swipe between them to show the perspective switch

---

## Demo Script for Colleagues

### Setup (1 minute)
"I've set up a shared Claude Code session. Let me show you two perspectives..."

### Show host's Perspective (30 seconds)
```bash
~/bin/claude-test-local.sh host
```
"This is host's terminal. He can type here..."

### Show collaborator's Perspective (30 seconds)
```bash
# In new terminal
~/bin/claude-test-local.sh collaborator
```
"This is collaborator's terminal. He can type here too..."

### Interactive Demo (2-3 minutes)
```
host types: [host]> Create a user authentication function
[Show Claude's response in both terminals]

collaborator types: [collaborator]> Can we add JWT support to that?
[Show Claude's updated response in both terminals]

host types: [host]> Perfect! Now let's add tests
[Show Claude's response in both terminals]
```

### Key Points to Highlight
1. "Notice how Claude sees WHO is asking what?"
2. "Both people see the SAME output in real-time"
3. "Each person types on their own terminal comfortably"
4. "This is like pair programming, but remote!"
5. "For the real setup, we'd use a cloud server so we're on different machines"

---

## Cleaning Up After Demo

### Exit the Test Sessions

**In each terminal:**
- Press Ctrl+C to exit the input loop
- Or press Ctrl+B, then D to detach

### Kill the Test Sessions

```bash
# Kill the shared session
tmux kill-session -t test-collab

# Kill host's view
tmux kill-session -t test-host

# Kill collaborator's view
tmux kill-session -t test-collaborator

# Verify all are gone
tmux ls
# Should show "no server running" or not list the test sessions
```

---

## Next Steps After Demo

If your colleagues like it:

1. **"This was all on my Mac. For real use, we'd set up a $12/month server"**
2. **"Then we can both connect from our own computers"**
3. **"Takes about 2 hours to set up the first time"**
4. **Show them `setup-for-host.md` for the full setup**

---

## Troubleshooting the Demo

### "No session found: test-collab"
```bash
# The shared session died. Recreate it:
tmux new-session -s test-collab -d
tmux send-keys -t test-collab "claude-code" C-m
```

### Can't see what the other "person" typed
```bash
# Exit both test sessions (Ctrl+C)
# Kill them:
tmux kill-session -t test-host
tmux kill-session -t test-collaborator
# Restart them
~/bin/claude-test-local.sh host  # In terminal 1
~/bin/claude-test-local.sh collaborator  # In terminal 2
```

### Claude Code isn't responding
```bash
# Check if it's running:
tmux attach-session -t test-collab

# If you see Claude Code prompt, good!
# If not, start it:
claude-code

# Then detach: Ctrl+B, then D
```

### Script not found
```bash
# Use full path:
~/bin/claude-test-local.sh host

# Or check it exists:
ls -l ~/bin/claude-test-local.sh

# If not there, go back to Step 3
```

---

## Pro Tips for Demo

1. **Prepare a simple prompt sequence** ahead of time so you know what to type
2. **Use realistic examples** your colleagues will relate to
3. **Have both terminal windows visible** so they see the mirroring
4. **Type slowly** so they can follow what's happening
5. **Narrate as you go**: "Now I'm typing as host...", "Watch collaborator's terminal update..."

---

## Example Demo Conversation

```
You (narrating): "Let me show you host's perspective first..."
[Open host's terminal]

You (narrating): "host wants to add a feature..."
host types: [host]> Create a function to validate email addresses

You (narrating): "Claude responds with code. Now let's see collaborator's perspective..."
[Switch to collaborator's terminal]

You (narrating): "collaborator sees everything host did, and can add to it..."
collaborator types: [collaborator]> Can you also add phone number validation?

You (narrating): "Notice collaborator's request appears in host's terminal too..."
[Switch back to host's terminal, show collaborator's message appeared]

You (narrating): "Claude responds to collaborator, building on host's original request..."
[Show Claude's response in both terminals]

You: "This is real-time collaboration with Claude Code. Questions?"
```

---

## Time Estimate

- **Setup:** 10-15 minutes (Steps 1-3)
- **Demo:** 5 minutes
- **Cleanup:** 2 minutes
- **Total:** ~20-25 minutes

---

## Benefits of Testing Locally First

✅ No cloud account needed yet
✅ No cost
✅ Validate the concept works
✅ Practice the demo
✅ Get colleague buy-in before investing time in full setup
✅ Troubleshoot in private

---

## What's Different from Real Setup?

**Local Test (Safe):**
- Both "users" on same Mac
- Simulated with two terminal windows
- Just for demo/proof-of-concept
- **No external access** - safe for testing
- **No security risk** - you're only accessing your own machine

**Real Setup (with cloud server - Required for actual collaboration):**
- Each person on their own computer
- Cloud server in between
- Actually remote collaboration
- Costs $12/month
- **Secure** - collaborators access shared server, not your personal machine
- **Isolated** - your personal files and credentials remain private

The **experience is identical**, but the security model is completely different! Never skip the cloud server for real collaboration.

---

## Ready to Demo?

```bash
# Step 1: Start shared session
tmux new-session -s test-collab
claude-code
# Ctrl+B, then D to detach

# Step 2: Open two terminals
# Terminal 1:
~/bin/claude-test-local.sh host

# Terminal 2:
~/bin/claude-test-local.sh collaborator

# Step 3: Start typing in each and watch the magic! ✨
```

Good luck with your demo! This should really impress your colleagues.
