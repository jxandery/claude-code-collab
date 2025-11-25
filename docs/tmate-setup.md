# tmate Setup Guide - Quick Collaboration

Get collaborating in 5 minutes with zero networking setup.

---

## What You'll Build

```
Your Mac (tmate)  ──► tmate.io servers ◄── Collaborator (SSH)
    │                                            │
    └────────────► Both see Claude Code ◄────────┘
```

---

## Prerequisites

- [ ] macOS or Linux
- [ ] Claude Code installed and authenticated
- [ ] 5 minutes

---

## For the Host (Person Starting Session)

### Step 1: Install tmate

```bash
# Install via Homebrew
brew install tmate
```

Verify installation:
```bash
tmate -V
```

Should show: `tmate 2.4.0` or similar

### Step 2: Start tmate Session

```bash
tmate
```

You'll see a message like:
```
Tip: if you wish to use tmate only for remote access, run: tmate -F
To see the following messages again, run in a tmate session: tmate show-messages

Connecting to ssh.tmate.io...
Note: clear your terminal before sharing readonly access
web session read only: https://tmate.io/t/ro-gHVPEkc7GsykEqS43T4ePz2pt
ssh session read only: ssh ro-gHVPEkc7GsykEqS43T4ePz2pt@nyc1.tmate.io
web session: https://tmate.io/t/6jDBYRuszJXpefjJChzfNLdRX
ssh session: ssh 6jDBYRuszJXpefjJChzfNLdRX@nyc1.tmate.io
```

### Step 3: Start Claude Code

In the tmate terminal:
```bash
claude-code
```

Wait for Claude Code to start up.

### Step 4: Get Connection Info

Open a NEW terminal (NOT the tmate one) and run:
```bash
tmate show-messages
```

Or you can scroll up in the tmate terminal to see the connection strings.

### Step 5: Share with Collaborator

Send your collaborator the **ssh session** line:
```
ssh 6jDBYRuszJXpefjJChzfNLdRX@nyc1.tmate.io
```

**Important:**
- Share ONLY the part after the colon: `ssh XXX@nyc1.tmate.io`
- Don't include the words "ssh session:"
- This connection string is unique to your session

### Step 6: Start Collaborating

Once your collaborator connects, you'll both see the same terminal.

**Type with manual prefixes:**
```
[host] Add user authentication
```

Your collaborator will see this immediately and Claude will respond.

---

## For the Collaborator (Person Joining)

### Step 1: Get Connection String

The host will send you something like:
```
ssh ABjen7Ptvb9v3vt5N34eDvk6Z@nyc1.tmate.io
```

### Step 2: Connect

Copy and paste that ENTIRE command:
```bash
ssh ABjen7Ptvb9v3vt5N34eDvk6Z@nyc1.tmate.io
```

**Common mistake:**
- ❌ `ssh session: ssh ABjen7Ptvb9v3vt5N34eDvk6Z@nyc1.tmate.io`
- ✅ `ssh ABjen7Ptvb9v3vt5N34eDvk6Z@nyc1.tmate.io`

(Only the part after the colon!)

### Step 3: You're In!

You'll see the same Claude Code session as the host.

**Type with manual prefixes:**
```
[collaborator] Can we add JWT support?
```

---

## User Attribution (Manual Prefixing)

Since everyone types in the same terminal, manually prefix your messages:

### Host types:
```
[host] Create a login function
```

### Collaborator types:
```
[collaborator] Should we add error handling?
```

### Claude sees:
```
[host] Create a login function
[collaborator] Should we add error handling?
```

---

## Semi-Automatic Prefixing (Optional)

If you want help with prefixing, you can use shell aliases:

### Setup Prefix Aliases

**Host adds to their shell (in ~/.zshrc or ~/.bashrc):**
```bash
# tmate collaboration aliases
alias h='echo "[host] "'
```

**Collaborator adds to their shell:**
```bash
# tmate collaboration aliases
alias c='echo "[collaborator] "'
```

Reload shell: `source ~/.zshrc`

### Usage

Instead of typing:
```
[host] Add authentication
```

Type:
```bash
h Add authentication
```

The alias expands to:
```
[host] Add authentication
```

**Benefit:**
- Faster than typing full prefix
- Less error-prone
- Still manual but easier

**Note:** This is not true automatic prefixing (which requires the SSH+tmux approach), but it's a helpful shortcut.

---

## Using the Helper Script (Recommended)

We provide a script that reminds you to use manual prefixing and connects you:

### Step 1: Make Script Executable

```bash
chmod +x join-tmate-session.sh
chmod +x start-tmate-collaboration.sh
```

### Step 2: Host Uses Start Script

```bash
./start-tmate-collaboration.sh
```

This will:
- Start tmate
- Start Claude Code
- Show you the connection string to share

### Step 3: Collaborator Uses Join Script

```bash
./join-tmate-session.sh collaborator 'ABjen7Ptvb9v3vt5N34eDvk6Z@nyc1.tmate.io'
```

This will:
- Remind you about manual prefixing format
- Show you your username for prefixing
- Connect you to the session

---

## Tips for Smooth Collaboration

### 1. Use Voice Chat

Coordinate via Discord, Zoom, or Slack:
```
Host (voice): "Let me ask about authentication"
Host (types): [host] Add JWT authentication
```

### 2. Take Turns

Don't type simultaneously - coordinate who's asking questions.

### 3. Be Explicit with Prefixes

Always use `[username]` so Claude knows who's asking.

### 4. Review Before Entering

Type your question, review it has the prefix, then hit Enter.

### 5. Use Short Prefixes

Instead of `[collaborator]`, you could use:
- `[c]`
- `[collab]`
- `[bob]` (real names)

Just be consistent!

---

## Session Management

### Viewing Connection Info Anytime

If you forget your connection string:

```bash
# In a NEW terminal (not the tmate one):
tmate show-messages

# Or:
tmate -S /tmp/tmate.sock show-messages
```

### Ending the Session

**Host:**
- Type `exit` in the tmate terminal
- Or press Ctrl+D
- Session ends for everyone

**Collaborator:**
- Type `exit` or press Ctrl+D
- You disconnect, but session continues for others

### Reconnecting After Disconnect

**Same connection string still works** as long as host's tmate session is running.

Collaborator just runs:
```bash
ssh ABjen7Ptvb9v3vt5N34eDvk6Z@nyc1.tmate.io
```

Again to rejoin.

---

## Troubleshooting

### "Could not resolve hostname session:"

You copied too much. Only copy the part AFTER the colon:

❌ `ssh session: ssh ABjen7@nyc1.tmate.io`
✅ `ssh ABjen7@nyc1.tmate.io`

### "Connection refused"

- Check your internet connection
- tmate.io servers might be down (rare)
- Try again in a few moments

### "Connection timed out"

- Firewall might be blocking
- Try different network
- Check if port 22 is open

### Can't see collaborator's typing

- Are you both connected to the same session string?
- Ask host to share the connection string again
- Verify you copied the entire string

### Multiple Claude instances appearing

- Each person who runs `claude-code` creates a new instance
- Only the HOST should start Claude Code
- Collaborators should only connect via SSH

---

## Security Considerations

### What tmate Can See

- tmate.io servers relay your traffic (encrypted)
- Your terminal session content is visible to tmate.io infrastructure
- Use for non-sensitive work or trust tmate.io

### Limiting Access

**Read-only session (viewers can't type):**
```bash
tmate -F
```

Share the "read only" connection string for viewers.

**Session with custom socket:**
```bash
tmate -S /tmp/my-collab-socket
```

Better isolation between sessions if you run multiple.

### Private tmate Server

You can self-host tmate servers for complete privacy:
- See https://github.com/tmate-io/tmate-ssh-server
- Requires server setup (defeats the "no setup" benefit)

---

## Comparison: tmate vs SSH+tmux

| Feature | tmate | SSH+tmux |
|---------|-------|----------|
| Setup time | 5 min | 30-60 min |
| Prefixing | Manual | Automatic |
| Cost | Free | $0-12/mo |
| Privacy | Via tmate.io | Direct |

For automatic prefixing, see [setup-for-host.md](setup-for-host.md).

---

## Advanced: Multiple Projects

You can run multiple tmate sessions:

### Project 1:
```bash
tmate -S /tmp/project-alpha
```

### Project 2:
```bash
tmate -S /tmp/project-beta
```

Each gets its own connection string. Share the appropriate one with collaborators.

---

## Quick Reference

### Host Quick Start
```bash
brew install tmate
tmate
claude-code
# Share connection string with collaborator
```

### Collaborator Quick Start
```bash
ssh XXX@nyc1.tmate.io
# Remember to prefix: [collaborator] your message
```

### Prefix Template
```
[your-name] Your question or request here
```

---

## Next Steps

- **Want automatic prefixing?** See [tmate-vs-ssh-tmux.md](tmate-vs-ssh-tmux.md) for SSH+tmux approach
- **Need help deciding?** See [tmate-vs-ssh-tmux.md](tmate-vs-ssh-tmux.md) comparison
- **Ready for production setup?** See [setup-for-host.md](setup-for-host.md) for cloud server

---

## Support

**Issues with tmate itself:**
- https://github.com/tmate-io/tmate

**Issues with this collaboration setup:**
- See main repository README

---

**Ready to start?** Run `brew install tmate` and share your terminal in 5 minutes!
