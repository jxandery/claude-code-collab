# Troubleshooting Guide

Solutions to common problems when using Claude Code collaboration.

---

## Table of Contents

- [Git Issues](#git-issues)
- [SSH Connection Issues](#ssh-connection-issues)
- [tmux Issues](#tmux-issues)
- [Claude Code Issues](#claude-code-issues)
- [Session and Message Issues](#session-and-message-issues)
- [Script Issues](#script-issues)

---

## Git Issues

### Problem: "git pull" shows divergent branches

**Symptoms:**
```
hint: You have divergent branches and need to specify how to reconcile them.
fatal: Need to specify how to reconcile divergent branches.
```

**Cause:** Local changes conflict with remote changes.

**Solution 1: Discard local changes (recommended for collaboration servers)**

```bash
git fetch origin
git reset --hard origin/main
```

This throws away any local changes and matches the remote exactly.

**Solution 2: Stash local changes**

```bash
git stash
git pull origin main
git stash pop  # Only if you need the local changes back
```

This temporarily saves your local changes.

**Solution 3: Configure default pull behavior**

```bash
# Choose one:
git config pull.rebase false  # Merge (default)
git config pull.rebase true   # Rebase
git config pull.ff only       # Fast-forward only

# Then try again:
git pull
```

---

### Problem: Permission denied when pulling

**Symptoms:**
```
Permission denied (publickey).
fatal: Could not read from remote repository.
```

**Solution:** The repository is public, so use HTTPS instead:

```bash
cd ~/claude-code-collab
git remote set-url origin https://github.com/jxandery/claude-code-collab.git
git pull
```

---

## SSH Connection Issues

### Problem: "Permission denied (publickey)"

**Symptoms:**
```
Permission denied (publickey).
```

**Cause:** Your SSH key isn't authorized on the server.

**Solution 1: Use password authentication**

```bash
ssh -o PubkeyAuthentication=no claudeteam@68.183.159.246
# Enter password when prompted
```

**Solution 2: Add your SSH key to the server**

```bash
# On your local machine, copy your public key
cat ~/.ssh/id_rsa.pub
# or
cat ~/.ssh/id_ed25519.pub

# SSH to server with password
ssh -o PubkeyAuthentication=no claudeteam@68.183.159.246

# Add your key to authorized_keys
nano ~/.ssh/authorized_keys
# Paste your public key on a new line
# Save: Ctrl+X, Y, Enter

# Test it
exit
ssh claudeteam@68.183.159.246  # Should work without password
```

**Solution 3: Check SSH key permissions**

```bash
# On your local machine
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa  # or id_ed25519
chmod 644 ~/.ssh/id_rsa.pub  # or id_ed25519.pub
```

---

### Problem: SSH connection timeout

**Symptoms:**
```
ssh: connect to host test-collab port 22: Operation timed out
```

**Cause 1: Using a hostname instead of IP**

**Solution:** Use the actual IP address:
```bash
# Wrong:
ssh claudeteam@test-collab

# Right:
ssh claudeteam@68.183.159.246
```

**Cause 2: Server is down or unreachable**

**Solution:**
- Verify the server is running (check your cloud provider dashboard)
- Check if you're on a network that blocks SSH (some corporate networks do)
- Try from a different network

**Cause 3: Firewall blocking port 22**

**Solution:**
- Check your cloud provider's firewall/security group settings
- Ensure port 22 is open for SSH

---

### Problem: "Host key verification failed"

**Symptoms:**
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

**Cause:** Server was rebuilt or SSH keys changed.

**Solution:**

```bash
# Remove old key
ssh-keygen -R 68.183.159.246

# Try connecting again
ssh claudeteam@68.183.159.246
# Type 'yes' when prompted
```

---

## tmux Issues

### Problem: "tmux: command not found"

**Symptoms:**
```
-bash: tmux: command not found
```

**Solution on macOS:**
```bash
brew install tmux
```

**Solution on Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install tmux
```

**Solution on Linux (CentOS/RHEL):**
```bash
sudo yum install tmux
```

---

### Problem: "tmux detach" says "no server running"

**Symptoms:**
```
no server running on /tmp/tmux-1001/default
```

**Cause:** You're not inside a tmux session.

**Solution 1: Check if sessions exist**

```bash
tmux ls
```

If no sessions exist, you need to create one first:
```bash
tmux new-session -s claude-collab
```

**Solution 2: Attach to existing session**

If sessions exist:
```bash
tmux attach-session -t claude-collab
```

Then try detaching: `Ctrl+B`, then `D`

---

### Problem: Ctrl+B, D just types "D" instead of detaching

**Cause:** The key sequence wasn't pressed correctly.

**Solution 1: Correct key sequence**

1. Press and hold `Ctrl` + `B` together
2. Release both keys **completely**
3. Press `D` alone (not while holding anything)

**Solution 2: Use command instead**

```bash
tmux detach
```

**Solution 3: Check if you're in a tmux session**

```bash
echo $TMUX
# If empty, you're not in tmux
```

If not in tmux, you need to attach first:
```bash
tmux attach-session -t claude-collab
```

---

### Problem: "Session not found"

**Symptoms:**
```
session not found: claude-collab
```

**Cause:** The session doesn't exist yet.

**Solution:** Create the session first:

```bash
tmux new-session -s claude-collab
claude-code
# Detach: Ctrl+B, then D
```

---

### Problem: "sessions should be nested with care"

**Symptoms:**
```
sessions should be nested with care, unset $TMUX to force
```

**Cause:** You're trying to create a tmux session from inside another tmux session.

**Solution 1: Detach from current session first**

```bash
# Detach from current session
tmux detach

# Now create new session
tmux new-session -s claude-collab
```

**Solution 2: Force it (not recommended)**

```bash
TMUX= tmux new-session -s claude-collab
```

---

## Claude Code Issues

### Problem: Claude Code not responding

**Symptoms:** You type messages but Claude doesn't respond.

**Cause 1: Claude Code isn't running**

**Solution:**
```bash
ssh claudeteam@68.183.159.246
tmux attach-session -t claude-collab

# Check if you see Claude Code interface
# If not, start it:
claude-code

# Detach: Ctrl+B, then D
exit
```

**Cause 2: Claude Code crashed**

**Solution:**
Same as Cause 1 - reattach and restart Claude Code.

**Cause 3: Network issues**

**Solution:**
- Check your internet connection
- Check the server's internet connection
- Claude Code requires internet to communicate with Anthropic servers

---

### Problem: "claude-code: command not found"

**Symptoms:**
```
-bash: claude-code: command not found
```

**Cause:** Claude Code isn't installed or not in PATH.

**Solution:**

```bash
# Check if it's installed
npm list -g @anthropic-ai/claude-code

# If not installed:
npm install -g @anthropic-ai/claude-code

# If permission error:
sudo npm install -g @anthropic-ai/claude-code

# Verify installation
claude-code --version
```

---

### Problem: "Auto-update failed" in Claude Code

**Symptoms:**
```
⚠ Auto-update failed · Try claude doctor or npm i -g @anthropic-ai/claude-code
```

**Solution:**

```bash
# Update Claude Code manually
npm update -g @anthropic-ai/claude-code

# Or reinstall
npm install -g @anthropic-ai/claude-code
```

---

## Session and Message Issues

### Problem: Messages not appearing

**Symptoms:** You type messages but they don't appear in Claude.

**Cause 1: Connected to wrong session**

**Solution:**
```bash
# Check what sessions exist
ssh claudeteam@68.183.159.246
tmux ls

# Make sure you're connecting to the right one
./join-claude-session-split.sh YourName IP username correct-session-name
```

**Cause 2: Scripts sending to wrong session**

**Solution:**
Exit and rejoin with the correct session name:
```bash
# Make sure the session name matches exactly
./join-claude-session-split.sh host 68.183.159.246 claudeteam claude-collab
#                                                                ^^^^^^^^^^^^^ Must match
```

**Cause 3: Not detached from session**

If you're still attached to the tmux session where Claude is running, the input scripts might not work properly.

**Solution:**
Detach from the Claude session: `Ctrl+B`, then `D`

---

### Problem: Can't see collaborator's messages

**Symptoms:** You only see your own messages, not others'.

**Cause 1: Not connected to same session**

**Solution:**
Verify everyone is using the same session name:
```bash
ssh claudeteam@68.183.159.246
tmux ls
# Verify the session name

# Reconnect with correct name
./join-claude-session-split.sh YourName 68.183.159.246 claudeteam claude-collab
```

**Cause 2: Top pane disconnected (split-pane mode)**

**Solution:**
Exit and reconnect:
```bash
# Press Ctrl+C or close terminal
# Then reconnect
./join-claude-session-split.sh YourName 68.183.159.246 claudeteam claude-collab
```

**Cause 3: Not watching output (simple mode)**

**Solution:**
Open a view terminal:
```bash
ssh claudeteam@68.183.159.246
tmux attach-session -t claude-collab
```

---

### Problem: "[username]: command not found" errors

**Symptoms:**
```
[host]: command not found
[collaborator]: command not found
```

**Cause:** The join script is connecting to the server shell, not sending to the tmux session.

**Solution:**

1. **Verify the session exists:**
   ```bash
   ssh claudeteam@68.183.159.246
   tmux ls
   # Should show: claude-collab: 1 windows ...
   ```

2. **Make sure Claude Code is running in that session:**
   ```bash
   tmux attach-session -t claude-collab
   # You should see Claude Code interface
   # If not, start it: claude-code
   # Detach: Ctrl+B, then D
   exit
   ```

3. **Restart the join script from your local machine:**
   ```bash
   ./join-claude-session-split.sh host 68.183.159.246 claudeteam claude-collab
   ```

---

### Problem: Split-pane connection drops or freezes

**Symptoms:** Top pane shows "Connection closed" or stops updating.

**Solution:**

```bash
# Exit the split-pane session
# Press Ctrl+C in bottom pane, or close terminal

# Reconnect
./join-claude-session-split.sh YourName 68.183.159.246 claudeteam claude-collab
```

If this keeps happening:
- Check your internet connection stability
- Check the server's stability
- Try simple mode instead of split-pane mode

---

## Script Issues

### Problem: Scripts not found

**Symptoms:**
```
-bash: ./join-claude-session-split.sh: No such file or directory
```

**Cause:** Scripts not installed or not in the right directory.

**Solution:**

```bash
# Make sure you're in the right directory
cd ~/claude-code-collab

# Pull latest code
git pull

# Run installer
./install.sh

# Try again
./join-claude-session-split.sh host 68.183.159.246 claudeteam claude-collab
```

---

### Problem: "Permission denied" when running scripts

**Symptoms:**
```
-bash: ./join-claude-session-split.sh: Permission denied
```

**Cause:** Script isn't executable.

**Solution:**

```bash
chmod +x ~/claude-code-collab/*.sh
# Or
chmod +x ~/bin/join-claude-session*.sh
```

---

### Problem: Environment variables not set

**Symptoms:**
```
Error: COLLAB_HOST not set!
```

**Solution 1: Pass parameters explicitly**

```bash
./join-claude-session-split.sh host 68.183.159.246 claudeteam claude-collab
```

**Solution 2: Set environment variables**

```bash
# Add to ~/.zshrc or ~/.bashrc
export COLLAB_HOST="68.183.159.246"
export COLLAB_REMOTE_USER="claudeteam"
export COLLAB_SESSION="claude-collab"

# Reload shell
source ~/.zshrc  # or ~/.bashrc
```

---

## Session Management Issues

### Problem: Too many old sessions cluttering the server

**Symptoms:**
```bash
tmux ls
# Shows many old sessions you don't need anymore
```

**Solution: Clean up old sessions**

```bash
# List all sessions
ssh claudeteam@68.183.159.246
tmux ls

# Kill specific old sessions
tmux kill-session -t old-session-name
tmux kill-session -t another-old-session

# Or kill all sessions (DANGER: kills everything!)
tmux kill-server
```

**Better approach:** Use the list-sessions utility:
```bash
list-sessions.sh 68.183.159.246 claudeteam
# Shows all sessions with details
# Then kill ones you don't need
```

---

### Problem: Forgot to save work before killing session

**Symptoms:**
Session killed, work was lost.

**Prevention:**
Always follow the [session lifecycle checklist](HOST-INSTRUCTIONS.md#before-ending-a-session):
1. Notify collaborators
2. Save/download all work
3. Verify everyone disconnected
4. Then kill session

**If it already happened:**
- Check if files are still on server: `ssh user@server 'ls -la ~/project'`
- Check git history: `ssh user@server 'cd ~/project && git log'`
- Claude's conversation is lost (not recoverable)

---

### Problem: Don't know if session is still in use

**Symptoms:**
Old session exists, not sure if anyone is using it.

**Solution: Check for attached clients**

```bash
ssh claudeteam@68.183.159.246
tmux list-clients -t session-name
# If empty, no one is connected
```

Or check session details:
```bash
ssh claudeteam@68.183.159.246
tmux ls
# Look at "created" time and "attached" count
# Example: claude-collab: 1 windows (created Wed Nov 27 14:30:00 2025) [140x50] (attached)
```

If "(attached)" is missing, no one is connected.

---

### Problem: Session ended unexpectedly

**Symptoms:**
Connected to session, suddenly disconnected, session is gone.

**Possible causes:**

1. **Someone killed the session**
   - Check with collaborators
   - Recreate session following host instructions

2. **Server restarted**
   - Check server uptime: `ssh user@server 'uptime'`
   - tmux sessions don't survive reboots
   - Recreate session

3. **tmux server crashed**
   - Rare, but possible
   - Check server logs: `ssh user@server 'dmesg | tail -50'`
   - Recreate session

**Recovery:**
Follow [HOST-INSTRUCTIONS.md Step 2](HOST-INSTRUCTIONS.md#step-2-host---create-the-shared-claude-code-session) to create new session.

---

### Problem: Can't tell which session is for which project

**Symptoms:**
```bash
tmux ls
claude-collab: 1 windows ...
session-2: 1 windows ...
work: 1 windows ...
# Not clear what each is for
```

**Solution: Use descriptive session names**

Instead of generic names:
```bash
# Bad
tmux new-session -s work
tmux new-session -s project
```

Use descriptive names:
```bash
# Good
tmux new-session -s frontend-redesign
tmux new-session -s api-bugfix
tmux new-session -s auth-feature
```

**Tip:** Include date or ticket number:
```bash
tmux new-session -s bug-1234-login-fix
tmux new-session -s 2025-11-27-planning
```

---

## General Debugging Steps

### When something goes wrong:

1. **Check if the server is running:**
   ```bash
   ping 68.183.159.246
   ```

2. **Check if SSH works:**
   ```bash
   ssh claudeteam@68.183.159.246
   ```

3. **Check if tmux session exists:**
   ```bash
   ssh claudeteam@68.183.159.246 'tmux ls'
   ```

4. **Check if Claude Code is running:**
   ```bash
   ssh claudeteam@68.183.159.246
   tmux attach-session -t claude-collab
   # Look for Claude Code interface
   # Detach: Ctrl+B, then D
   exit
   ```

5. **Pull latest code:**
   ```bash
   cd ~/claude-code-collab
   git pull
   ```

6. **Try again:**
   ```bash
   ./join-claude-session-split.sh YourName 68.183.159.246 claudeteam claude-collab
   ```

---

## Still Having Issues?

### Get help:

- **GitHub Issues:** https://github.com/jxandery/claude-code-collab/issues
- **GitHub Discussions:** https://github.com/jxandery/claude-code-collab/discussions

### When reporting an issue, include:

1. What you were trying to do
2. The exact command you ran
3. The complete error message
4. Your operating system (macOS, Linux, Windows/WSL)
5. Whether you're the host or a collaborator
6. Which mode you're using (split-pane or simple)

---

## Quick Reference

| Issue                                  | Quick Fix                                                          |
|----------------------------------------|--------------------------------------------------------------------|
| Git pull fails                         | `git fetch origin && git reset --hard origin/main`                |
| Can't SSH                              | `ssh -o PubkeyAuthentication=no user@IP` (use password)           |
| tmux not found                         | `brew install tmux` (macOS) or `sudo apt install tmux` (Linux)    |
| Ctrl+B, D types "D"                    | Use `tmux detach` command instead                                  |
| Session not found                      | Create it: `tmux new-session -s claude-collab`                     |
| Claude not responding                  | Reattach and restart: `tmux attach -t session`, then `claude-code` |
| Messages not appearing                 | Verify session name matches exactly                                |
| Scripts not found                      | `cd ~/claude-code-collab && git pull && ./install.sh`             |
| Connection timeout                     | Use IP address instead of hostname                                 |

---

**Back to guides:**
- [REMOTE-QUICK-START.md](REMOTE-QUICK-START.md)
- [HOST-INSTRUCTIONS.md](HOST-INSTRUCTIONS.md)
- [COLLABORATOR-INSTRUCTIONS.md](COLLABORATOR-INSTRUCTIONS.md)
