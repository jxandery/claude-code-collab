# Collaborator Instructions

**For joining an existing Claude Code collaboration session**

Use this guide to join a session that someone else (the host) has already created.

---

## What You Need

The host should have given you:

- [ ] Server IP address (e.g., `68.183.159.246`)
- [ ] Server username (e.g., `claudeteam`)
- [ ] Session name (e.g., `claude-collab`)
- [ ] Which mode to use: **Split-pane** or **Simple**
- [ ] SSH access (either password or your SSH key added to the server)

---

## Before You Start

### 1. Install the collaboration scripts

**One-time setup** on your local machine:

```bash
# Clone the repository
git clone https://github.com/jxandery/claude-code-collab.git
cd claude-code-collab

# Run installer
./install.sh

# Reload shell
source ~/.zshrc  # or ~/.bashrc
```

### 2. Pull the latest code

**Do this before every session:**

```bash
cd ~/claude-code-collab
git pull
```

If you get merge conflicts, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md#problem-git-pull-shows-divergent-branches)

### 3. Test SSH connection

Make sure you can connect to the server:

```bash
ssh claudeteam@68.183.159.246
# You should connect successfully
exit
```

**If this doesn't work:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#problem-permission-denied-publickey)

---

## Joining the Session

The host will tell you which mode to use. Follow the instructions for that mode:

- **Split-pane mode (recommended):** Shows Claude output + your input in one window
- **Simple mode:** Just an input terminal; view output separately if needed

---

## Option A: Split-Pane Mode (RECOMMENDED)

### From your local machine:

```bash
./join-claude-session-split.sh YourName 68.183.159.246 claudeteam claude-collab
```

**Replace these values:**
- `YourName` - Your name/identifier (e.g., `sarah`, `bob`, `collaborator`)
- `68.183.159.246` - The server IP the host gave you
- `claudeteam` - The server username the host gave you
- `claude-collab` - The session name the host gave you

### What you'll see:

```
┌─────────────────────────────────────────┐
│ Top Pane (70%)                          │
│ Claude Code Output                      │
│ [Shows all messages and Claude's        │
│  responses in real-time]                │
├─────────────────────────────────────────┤
│ Bottom Pane (30%)                       │
│ Your Input Terminal                     │
│ [YourName]> _                           │
└─────────────────────────────────────────┘
```

### Usage:

- **Type in the bottom pane** - your messages will be prefixed with `[YourName]`
- **Watch the top pane** - see everyone's messages and Claude's responses
- **To exit:** Press `Ctrl+C` in the bottom pane, or close the terminal

---

## Option B: Simple Mode

### From your local machine:

#### 1. SSH into the server

```bash
ssh claudeteam@68.183.159.246
```

#### 2. Join the session

```bash
join-claude-session.sh YourName claude-collab
```

**Replace:**
- `YourName` - Your name/identifier
- `claude-collab` - The session name the host gave you

### What you'll see:

```
=== Your Input Terminal ===
Type your prompts below. They will be prefixed with [YourName]
Press Ctrl+C to exit

[YourName]> _
```

### Viewing Claude's Output (Optional)

If you want to watch Claude's responses, open a **second terminal** and run:

```bash
ssh claudeteam@68.183.159.246
tmux attach-session -t claude-collab
```

This shows the live Claude Code session.

**To detach from the view:** Press `Ctrl+B`, then `D`

---

## Testing Your Connection

### Send a test message

Type in your input terminal:

```
[YourName]> Hi everyone, I just joined!
```

**Expected:** You should see your message appear (either in the top pane if using split-pane mode, or in the view terminal if using simple mode). Claude may respond acknowledging you.

**If nothing happens:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#problem-messages-not-appearing)

---

## Collaboration Etiquette

### Use voice chat (highly recommended)

Coordinate with your team on Zoom, Discord, Slack, etc.

**Example coordination:**
```
Host: "Let me ask about authentication"
[Host types their question]
You: "That looks good! Can I follow up?"
[You type your question]
```

### Take turns

- **One person types at a time**
- **Wait for Claude to finish responding** before the next person asks
- **Announce before typing:** "I'm going to ask about error handling..."

### Be clear and specific

Your messages are prefixed with your name, so Claude knows who's asking:

```
[sarah]> Can you add input validation to the login form?
[bob]> Also, let's add rate limiting to prevent brute force attacks
[sarah]> Good idea! Let's do both
```

---

## During the Session

### If you get disconnected

Just run the same join command again:

```bash
# Split-pane mode:
./join-claude-session-split.sh YourName 68.183.159.246 claudeteam claude-collab

# Simple mode:
ssh claudeteam@68.183.159.246
join-claude-session.sh YourName claude-collab
```

The session is still running on the server, so you'll reconnect to the same conversation.

### If you need to step away

Just close your terminal or press `Ctrl+C`. The session continues running for others.

When you come back, reconnect using the same command.

### Exiting the session

When you're done:
- **Split-pane mode:** Press `Ctrl+C` or close the terminal
- **Simple mode:** Press `Ctrl+C` in your input terminal

The host will end the session when everyone is finished.

---

## Common Scenarios

### Multiple people typing at once

**Problem:** Messages overlap or conflict.

**Solution:** Use voice chat to coordinate. Take turns:
```
Voice: "Host is typing..."
[Wait for host to finish]
Voice: "Sarah, your turn!"
[Sarah types]
```

### Can't see other people's messages

**Problem:** You only see your own messages.

**Possible causes:**
1. **Not connected to the same session** - Verify session name with host
2. **Top pane disconnected (split-pane mode)** - Exit and reconnect
3. **Not watching output (simple mode)** - Open a view terminal (see above)

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#problem-cant-see-collaborators-messages) for more help.

### Host ended the session

If the host kills the session, you'll see an error. Just wait for them to create a new session and reconnect.

---

## Command Reference

| Task                      | Command (Split-pane Mode)                                           | Command (Simple Mode)                                               |
|---------------------------|---------------------------------------------------------------------|---------------------------------------------------------------------|
| Update local code         | `cd ~/claude-code-collab && git pull`                               | `cd ~/claude-code-collab && git pull`                               |
| Test SSH                  | `ssh claudeteam@68.183.159.246`                                     | `ssh claudeteam@68.183.159.246`                                     |
| Join session              | `./join-claude-session-split.sh Name IP User Session`               | `ssh User@IP`, then `join-claude-session.sh Name Session`           |
| View output               | Automatic (top pane)                                                | `ssh User@IP`, then `tmux attach-session -t Session`                |
| Exit                      | `Ctrl+C` or close terminal                                          | `Ctrl+C` in input terminal                                          |
| Reconnect                 | Run the same join command                                           | Run the same join command                                           |

---

## Tips for Success

### Before joining

- ✓ Pull latest code: `git pull`
- ✓ Test SSH connection
- ✓ Join voice chat with your team
- ✓ Confirm session name with host

### During collaboration

- ✓ Use voice chat to coordinate
- ✓ Take turns typing
- ✓ Be patient - wait for Claude to respond
- ✓ Use clear, specific messages

### If something breaks

- ✓ Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- ✓ Try disconnecting and reconnecting
- ✓ Ask the host if the session is still running
- ✓ Verify you're using the correct session name

---

## Troubleshooting

Having issues? See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Common problems:
- [Can't SSH to server](TROUBLESHOOTING.md#problem-permission-denied-publickey)
- [Messages not appearing](TROUBLESHOOTING.md#problem-messages-not-appearing)
- [Can't see other people's messages](TROUBLESHOOTING.md#problem-cant-see-collaborators-messages)
- [Connection drops](TROUBLESHOOTING.md#problem-split-pane-connection-drops)

---

## Quick Start Checklist

- [ ] Scripts installed on your machine (`./install.sh`)
- [ ] Code updated (`git pull`)
- [ ] SSH connection tested
- [ ] Got server details from host (IP, username, session name)
- [ ] Joined using the appropriate mode (split-pane or simple)
- [ ] Sent a test message
- [ ] On voice chat with team
- [ ] Ready to collaborate!

---

## Next Steps

- ✓ You're connected and can send messages
- → Coordinate with your team via voice
- → Start asking Claude questions!
- → See everyone's messages and Claude's responses in real-time

**Questions?** Ask the host or check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

**Back to overview:** [REMOTE-QUICK-START.md](REMOTE-QUICK-START.md)
