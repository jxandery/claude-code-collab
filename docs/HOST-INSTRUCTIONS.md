# Host Instructions

**For the person creating and starting the Claude Code session**

Use this guide every time you want to start a new collaboration session.

---

## Prerequisites

Before starting:

- [ ] Server is set up (see [SERVER-SETUP.md](SERVER-SETUP.md))
- [ ] You have the server IP address (e.g., `68.183.159.246`)
- [ ] You have the server username (e.g., `claudeteam`)
- [ ] Scripts are installed on your local machine (`./install.sh`)
- [ ] You pulled the latest code: `cd ~/claude-code-collab && git pull`

---

## Quick Reference

**Server:** `68.183.159.246` (replace with your server IP)
**Username:** `claudeteam` (replace with your server username)
**Session:** `claude-collab` (or choose your own name)

---

## Step 0: Update Code Everywhere

**IMPORTANT:** Before each session, ensure everyone has the latest code.

### Update code on your local machine

```bash
cd ~/claude-code-collab
git pull
```

If you get merge conflicts, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md#problem-git-pull-shows-divergent-branches)

### Update code on the server

```bash
ssh claudeteam@68.183.159.246
cd ~/claude-code-collab
git pull
exit
```

---

## Step 1: Clean Up Old Sessions (Optional)

If you want to start fresh, kill any old session with the same name:

```bash
ssh claudeteam@68.183.159.246
tmux kill-session -t claude-collab
exit
```

**Note:** This only kills the specific session (`claude-collab`), not other sessions you might have running.

**Skip this step** if you want to resume an existing session.

---

## Step 2: Create the Claude Code Session

### A. SSH into the server

```bash
ssh claudeteam@68.183.159.246
```

### B. Navigate to your project directory

```bash
cd ~/claude-code-collab
# Or navigate to wherever you want to work
```

### C. Create a new tmux session

```bash
tmux new-session -s claude-collab
```

**What you'll see:** Your terminal will change - usually a green status bar appears at the bottom.

### D. Start Claude Code

```bash
claude-code
```

**Wait for:** The Claude welcome screen to load (shows "Welcome back [Your Name]!" and recent activity).

This may take 5-10 seconds.

### E. Detach from the session

**This is the important part** - you need to detach so others can connect.

**Method 1: Keyboard shortcut (recommended)**

1. Press and hold `Ctrl` + `B` together
2. Release both keys
3. Press `D` (just D by itself)

**What you should see:** `[detached (from session claude-collab)]`

**Common mistake:** If you see the letter "D" typed in your terminal, you did it wrong. Make sure to press `Ctrl+B` first, release, THEN press D.

**Method 2: Type a command**

If the keyboard shortcut isn't working:
```bash
tmux detach
```

**Troubleshooting:** If you see "no server running", the tmux session isn't active. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#problem-tmux-detach-says-no-server-running)

### F. Verify the session is running

```bash
tmux ls
```

**Expected output:**
```
claude-collab: 1 windows (created Wed Nov 27 12:34:56 2025)
```

### G. Exit SSH

```bash
exit
```

You're now back on your local machine.

---

## Step 3: Connect Your Input Terminal

Now connect from your **local machine** to send commands to Claude.

Choose **ONE** of the two options below:

---

### Option A: Split-Pane Mode (RECOMMENDED)

This gives you Claude output and input in one window.

**From your local machine:**

```bash
./join-claude-session-split.sh host 68.183.159.246 claudeteam claude-collab
```

**Replace these values:**
- `host` - Your name/identifier
- `68.183.159.246` - Your server IP
- `claudeteam` - Your server username
- `claude-collab` - Your session name

**What you'll see:**

```
┌─────────────────────────────────────────┐
│ Top Pane (70%)                          │
│ Claude Code Output                      │
│ [Shows Claude's responses in real-time] │
│                                         │
├─────────────────────────────────────────┤
│ Bottom Pane (30%)                       │
│ Your Input Terminal                     │
│ [host]> _                               │
└─────────────────────────────────────────┘
```

**Usage:**
- Type in the bottom pane
- Watch responses in the top pane
- Both panes are in the same terminal window

**To exit:** Press `Ctrl+C` in the bottom pane, or close the terminal

---

### Option B: Simple Mode

This gives you just an input terminal. You'll need a separate terminal to watch Claude's output.

#### B1. Connect your input terminal

**From your local machine:**

```bash
ssh claudeteam@68.183.159.246
join-claude-session.sh host claude-collab
```

**What you'll see:**

```
=== Your Input Terminal ===
Type your prompts below. They will be prefixed with [host]
Press Ctrl+C to exit

[host]> _
```

#### B2. Open a second terminal to view output (optional)

Open a **new terminal window** and run:

```bash
ssh claudeteam@68.183.159.246
tmux attach-session -t claude-collab
```

This lets you watch Claude's responses.

**To detach from view terminal:** Press `Ctrl+B`, then `D`

---

## Step 4: Test Your Connection

Type a test message:

```
[host]> Hello Claude, can you confirm you see this message?
```

**Expected:** You should see Claude respond to your message.

**If nothing happens:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#problem-claude-code-not-responding)

---

## Step 5: Invite Collaborators

Your session is ready! Now collaborators can join.

**Send them:**
1. [COLLABORATOR-INSTRUCTIONS.md](COLLABORATOR-INSTRUCTIONS.md)
2. Server details:
   - Server IP: `68.183.159.246`
   - Username: `claudeteam`
   - Session name: `claude-collab`

**Tell them which mode you're using:**
- Split-pane mode (recommended)
- Simple mode

Everyone should use the same mode for consistency.

---

## Step 6: Start Collaborating!

### Best practices:

**Use voice chat** (Zoom, Discord, Slack) to coordinate:
```
You: "Let me ask about authentication"
[You type in your terminal]
Collaborator: "That looks good! Can I ask about error handling?"
[Collaborator types in their terminal]
```

**Take turns:**
- One person types at a time
- Wait for Claude to finish responding
- Coordinate who's asking next

**Be clear in your messages:**
```
[host]> Can you implement JWT authentication with refresh tokens?
[collaborator]> What about rate limiting on the auth endpoints?
[host]> Good point! Let's add that too.
```

---

## Managing the Session

### Pause collaboration

Just detach from your terminals:
- **Split-pane mode:** Press `Ctrl+C` or close terminal
- **Simple mode:** Press `Ctrl+C` in input terminal

The session keeps running on the server. You can reconnect anytime.

### Reconnect later

Run the same join command again:
```bash
./join-claude-session-split.sh host 68.183.159.246 claudeteam claude-collab
```

### End the session

When everyone is done:

```bash
ssh claudeteam@68.183.159.246
tmux kill-session -t claude-collab
exit
```

This stops Claude Code and frees up server resources.

---

## Managing Session Lifecycle

Understanding when to keep sessions running versus ending them helps manage server resources and maintain organization.

### When to Keep Sessions Running

✅ **Keep running if:**
- Taking a short break (< 1 hour)
- End of work day, resuming tomorrow morning
- Active project you'll return to within 24 hours
- Concerned about losing Claude's conversation context

**Cost:** Minimal - idle tmux sessions use ~5-10MB RAM each

### When to End Sessions

🛑 **End session if:**
- Project is completely finished
- Won't use for several days
- Multiple abandoned sessions cluttering the server
- Server needs maintenance or restart
- Want to free up resources

### Before Ending a Session

⚠️ **Important checklist:**

1. **Notify all collaborators** - Make sure everyone is done
2. **Save all work:**
   ```bash
   # Download files from server
   download-from-server.sh ~/project ./local-backup/

   # Or commit code if using git
   ssh claudeteam@68.183.159.246
   cd ~/project
   git add .
   git commit -m "Save work from collaboration session"
   git push
   exit
   ```
3. **Note your progress** - Document where you left off for next time
4. **Verify everyone disconnected:**
   ```bash
   ssh claudeteam@68.183.159.246
   tmux list-clients -t claude-collab
   # Should show no clients attached
   exit
   ```

### How to End a Session

**Everyone disconnects first:**
- Split-pane mode: Press `Ctrl+C` or close terminal
- Simple mode: Press `Ctrl+C` in input terminal

**Then host kills the session:**
```bash
ssh claudeteam@68.183.159.246
tmux kill-session -t claude-collab
exit
```

**To kill a specific session without logging in:**
```bash
ssh claudeteam@68.183.159.246 'tmux kill-session -t claude-collab'
```

### What Happens When You Kill a Session?

⚠️ **Important:** Claude Code does NOT persist conversation history between sessions.

When you kill a session:
- ✅ Files on the server remain (in your project directory)
- ✅ Git commits are preserved
- ❌ Claude's conversation context is lost
- ❌ Unsaved work in Claude's memory is lost

**Next time:** You'll start with fresh context, but can reference previous work via files/commits.

### Resuming After Killing a Session

To start fresh later, follow [Step 2](#step-2-host---create-the-shared-claude-code-session) again to create a new session.

**Pro tip:** Keep detailed git commits or notes so you can quickly catch Claude up on context when resuming.

---

## Multiple Projects

You can run multiple sessions for different projects:

```bash
# Create project-specific sessions
tmux new-session -s frontend-work
tmux new-session -s backend-api
tmux new-session -s bug-fixes

# Connect to specific session
./join-claude-session-split.sh host 68.183.159.246 claudeteam frontend-work
```

Just make sure everyone connects to the same session name!

**Managing multiple sessions:** Use `list-sessions.sh` to see all active sessions and clean up old ones periodically.

---

## Command Reference

| Task                        | Command                                                                |
|-----------------------------|------------------------------------------------------------------------|
| Update local code           | `cd ~/claude-code-collab && git pull`                                  |
| Update server code          | `ssh claudeteam@IP 'cd ~/claude-code-collab && git pull'`              |
| Kill specific session       | `ssh claudeteam@IP 'tmux kill-session -t claude-collab'`               |
| Create new session          | `ssh claudeteam@IP`, then `tmux new-session -s claude-collab`          |
| List sessions               | `ssh claudeteam@IP 'tmux ls'`                                          |
| Connect (split-pane)        | `./join-claude-session-split.sh host IP claudeteam claude-collab`      |
| Connect (simple)            | `ssh claudeteam@IP`, then `join-claude-session.sh host claude-collab`  |
| View output (simple mode)   | `ssh claudeteam@IP`, then `tmux attach-session -t claude-collab`       |

---

## Troubleshooting

Having issues? See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Common problems:
- [SSH connection timeout](TROUBLESHOOTING.md#problem-ssh-connection-timeout)
- [tmux detach not working](TROUBLESHOOTING.md#problem-ctrlb-d-just-types-d)
- [Claude not responding](TROUBLESHOOTING.md#problem-claude-code-not-responding)
- [Git pull conflicts](TROUBLESHOOTING.md#problem-git-pull-shows-divergent-branches)

---

## Next Steps

- ✓ Session created and running
- ✓ You're connected and can send messages
- → Send [COLLABORATOR-INSTRUCTIONS.md](COLLABORATOR-INSTRUCTIONS.md) to your team
- → Start collaborating with voice coordination!

**Back to overview:** [REMOTE-QUICK-START.md](REMOTE-QUICK-START.md)
