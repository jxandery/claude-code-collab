# DigitalOcean Cloud Setup - Complete Guide

Set up Claude Code collaboration using DigitalOcean in about 60 minutes.

**Cost:** $12/month (split between collaborators = $6/each)
**Benefit:** No port forwarding, works from anywhere, automatic user prefixing

---

## What You'll Build

```
Your Mac ──SSH──► DigitalOcean Droplet ◄──SSH── Collaborator
                  (Ubuntu Server)
                  running Claude Code
                  with tmux session
                        ↓
                  Automatic [username] prefixing
                  Split-screen interface
```

---

## Prerequisites

- [ ] Credit card (for DigitalOcean)
- [ ] 60 minutes
- [ ] Basic terminal familiarity

**New to DigitalOcean?** Get $200 credit (60 days free): https://www.digitalocean.com/

---

## Part 1: Create SSH Key (5 minutes)

### On Your Mac

Check if you already have an SSH key:
```bash
# Check for ED25519 (modern, recommended)
ls ~/.ssh/id_ed25519.pub

# OR check for RSA (older but common)
ls ~/.ssh/id_rsa.pub
```

**If you have either one**, skip to displaying your key below.

**If you see "No such file" for both**, create one:
```bash
# Modern ED25519 key (recommended)
ssh-keygen -t ed25519 -C "your-email@example.com"

# OR traditional RSA key (if ED25519 not supported)
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

Press Enter for all prompts (accept defaults):
- File location: (just press Enter)
- Passphrase: (press Enter for no passphrase, or set one)

Display your public key:
```bash
# If you have ED25519:
cat ~/.ssh/id_ed25519.pub

# OR if you have RSA:
cat ~/.ssh/id_rsa.pub
```

You'll see something like:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-email@example.com
# OR
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... your-email@example.com
```

**Copy this entire line.** You'll need it in the next step.

> **Note:** ED25519 and RSA are different key types. Make sure you copy the PUBLIC key (`.pub` file) that you're actually using.

---

## Part 2: Create DigitalOcean Droplet (10 minutes)

### Step 1: Sign Up for DigitalOcean

1. Go to https://www.digitalocean.com/
2. Click "Sign Up"
3. Create account with email or GitHub
4. Add payment method (get $200 credit if new user)

### Step 2: Create Droplet

1. **Click "Create" (top right) → "Droplets"**

2. **Choose Region:**
   - Select closest to you and your collaborator
   - Recommendation: **San Francisco 3** or **New York 1**

3. **Choose Image:**
   - Click **"Ubuntu"**
   - Select **"22.04 (LTS) x64"**

4. **Choose Size:**
   - Click **"Basic"** plan
   - CPU option: **"Regular"**
   - Scroll to find: **$12/mo** option
     - 2 GB RAM / 1 CPU
     - 50 GB SSD
     - 2 TB Transfer
   - Click this option

5. **Choose Authentication Method:**
   - Click **"SSH Key"** (recommended)
   - Click **"New SSH Key"**
   - Paste your public key (from Part 1)
   - Name it: "My Mac" or "Your Name Mac"
   - Click **"Add SSH Key"**

6. **Finalize Details:**
   - **Hostname:** `claude-collab-server`
   - **Tags:** (optional) add `collaboration`
   - **Project:** Default Project (or create new)
   - Leave other options as default

7. **Click "Create Droplet"**

### Step 3: Get Your Droplet's IP Address

After 1-2 minutes, your droplet will be ready.

You'll see a screen showing:
- **Droplet name:** claude-collab-server
- **IP address:** Something like `164.92.123.456`

**Write down this IP address** - you'll need it throughout setup.

---

## Part 3: Initial Server Connection (2 minutes)

### Test Connection

Open Terminal on your Mac and run:
```bash
ssh root@164.92.123.456
```
*Replace `164.92.123.456` with your actual IP address*

**First time connecting:**
You'll see a message like:
```
The authenticity of host '164.92.123.456' can't be established.
ECDSA key fingerprint is SHA256:...
Are you sure you want to continue connecting (yes/no)?
```

Type: `yes` and press Enter

You should see:
```
Welcome to Ubuntu 22.04 LTS
...
root@claude-collab-server:~#
```

**You're now connected to your cloud server!**

---

## Part 4: Server Setup (20 minutes)

### Step 1: Create Collaboration User

```bash
# Create a user for collaboration
adduser claudeteam
```

You'll be prompted:
- **Password:** Choose a strong password (write it down)
- **Full Name:** (press Enter to skip)
- **Room Number, etc.:** (press Enter to skip all)
- **Is this correct?** Type `Y`

```bash
# Give sudo privileges
usermod -aG sudo claudeteam

# Switch to new user
su - claudeteam
```

You're now the `claudeteam` user. The prompt changes to:
```
claudeteam@claude-collab-server:~$
```

### Step 2: Set Up SSH Keys for Collaboration User

```bash
# Create SSH directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create authorized keys file
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Now add SSH keys:
```bash
nano ~/.ssh/authorized_keys
```

This opens a text editor. Paste:
1. **Your public key** (from Part 1)
2. **Get your collaborator's public key and paste it on a NEW line**
   - Have them run on their machine: `cat ~/.ssh/id_rsa.pub`
   - They send you the output
   - Paste it on line 2

**Example file contents:**
```
ssh-rsa AAAAB3...your_key_here... you@yourmac
ssh-rsa AAAAB3...collab_key_here... collab@theirmac
```

**Save and exit:**
- Press: `Ctrl + X`
- Press: `Y` (to confirm save)
- Press: `Enter` (to confirm filename)

### Step 3: Update System

```bash
sudo apt update && sudo apt upgrade -y
```

Enter the password you created for `claudeteam`.

This takes 2-5 minutes. Wait for it to complete.

### Step 4: Install tmux

```bash
sudo apt install -y tmux git curl
```

Verify:
```bash
tmux -V
```

Should show: `tmux 3.2a` or similar

### Step 5: Install Node.js

Claude Code requires Node.js:

```bash
# Add Node.js repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

Should show:
```
v20.x.x
10.x.x
```

### Step 6: Install Claude Code

```bash
# Install Claude Code CLI globally
npm install -g @anthropic-ai/claude-code

# Verify installation
claude-code --version
```

Should show the version number.

### Step 7: Authenticate Claude Code

```bash
claude-code auth login
```

You'll see:
```
Please visit the following URL to authenticate:
https://claude.ai/auth/some-unique-url
```

**Copy this URL** and paste it into your web browser.

1. Log in to your Claude account
2. Click "Authorize"
3. Return to your terminal

You should see:
```
Authentication successful!
```

### Step 8: Test Claude Code

```bash
claude-code
```

Wait for it to start (10-20 seconds).

When you see the Claude Code prompt, type:
```
What is 2+2?
```

If Claude responds with "4", you're good!

Exit Claude Code:
```
exit
```
Or press `Ctrl + D`

---

## Part 5: Install Collaboration Script (10 minutes)

### Step 1: Clone Repository on Server

Still as `claudeteam` user on the server:

```bash
cd ~
git clone https://github.com/jxandery/claude-code-collab.git
cd claude-code-collab
```

### Step 2: Install Script

```bash
./install.sh
```

You'll see:
```
✓ Added ~/bin to PATH in /home/claudeteam/.bashrc
```

Reload your shell:
```bash
source ~/.bashrc
```

Verify installation:
```bash
which join-claude-session.sh
```

Should show: `/home/claudeteam/bin/join-claude-session.sh`

### Step 3: Create Shared tmux Session

```bash
# Create a detached tmux session
tmux new-session -s claude-collab -d

# Start Claude Code in the session
tmux send-keys -t claude-collab "claude-code" C-m

# Wait a moment for Claude Code to start
sleep 5

# Verify session is running
tmux ls
```

Should show:
```
claude-collab: 1 windows (created ...)
```

**Perfect!** The session is running in the background.

### Step 4: Exit Server

```bash
exit  # Exit from claudeteam user
exit  # Exit from root user
```

You're back on your local Mac.

The tmux session with Claude Code is still running on the server!

---

## Part 6: Set Up Your Local Mac (10 minutes)

### Step 1: Clone Repository Locally

On your Mac:

```bash
cd ~
git clone https://github.com/jxandery/claude-code-collab.git
cd claude-code-collab
```

### Step 2: Install Script Locally

```bash
./install.sh
```

Reload your shell:
```bash
source ~/.zshrc
# Or if you use bash: source ~/.bashrc
```

Verify:
```bash
which join-claude-session.sh
```

Should show: `/Users/yourname/bin/join-claude-session.sh`

### Step 3: Test SSH Connection

```bash
ssh claudeteam@164.92.123.456
```
*Replace with your server's IP*

If prompted for password, enter the `claudeteam` password you created.

**If it asks for password and you don't want to type it every time:**

Run this on your Mac:
```bash
ssh-copy-id claudeteam@164.92.123.456
```

Now try again - should connect without password!

Once connected:
```bash
# Verify tmux session
tmux ls

# Should show: claude-collab
```

Exit:
```bash
exit
```

---

## Part 7: Join Collaboration Session (5 minutes)

### Understanding the Setup

You'll need **TWO terminals** for the best experience:
- **Terminal 1:** Your input (with `[host]>` prompt)
- **Terminal 2:** View Claude's responses (read-only)

### Terminal 1: Your Input

From your Mac:

```bash
# Step 1: SSH to the server
ssh claudeteam@164.92.123.456

# Step 2: Join the session (IMPORTANT: This runs ON the server, not your Mac)
join-claude-session.sh host claude-collab
```

You'll see:
```
Claude Code Collaboration Mode
User: host
Session: claude-collab

Your prompts will be prefixed with [host]
Press Ctrl+C to exit

[host]> _
```

### Terminal 2: View Claude's Responses

Open a **second terminal** on your Mac and run:

```bash
# SSH to the server
ssh claudeteam@164.92.123.456

# Attach to the session in read-only mode
tmux attach-session -r -t claude-collab
```

You'll see Claude Code running with all interactions.

### Try It Out

In **Terminal 1** (input), type:
```
What is 2+2?
```

**You should see in the top pane:**
```
[host] What is 2+2?
Claude: 2 + 2 equals 4.
```

**Success!** The `[host]` prefix was added automatically!

### Exit the Session

Press: `Ctrl + B`, then press `D`

This detaches from the session (it keeps running).

Type `exit` to disconnect from SSH.

---

## Part 8: Add Your Collaborator (5 minutes)

### Get Collaborator's SSH Key

Have your collaborator run on their machine:

```bash
# Check if they have a key
ls ~/.ssh/id_rsa.pub
```

If not, they create one:
```bash
ssh-keygen -t rsa -b 4096
# Press Enter for all prompts
```

Then they run:
```bash
cat ~/.ssh/id_rsa.pub
```

They send you the entire output.

### Add Collaborator's Key to Server

On your Mac:

```bash
# SSH to server
ssh claudeteam@164.92.123.456

# Edit authorized keys
nano ~/.ssh/authorized_keys
```

Add their public key on a **new line** (line 3 if you already have 2 keys).

**Save:** Ctrl + X, Y, Enter

Exit server:
```bash
exit
```

### Share Connection Info with Collaborator

Send them:

```
Server IP: 164.92.123.456
Username: claudeteam
Session name: claude-collab
Password: [the claudeteam password, or tell them to use SSH key]

Repository: https://github.com/jxandery/claude-code-collab
```

### Collaborator Setup (On Their Machine)

Your collaborator runs:

```bash
# Clone repository
cd ~
git clone https://github.com/jxandery/claude-code-collab.git
cd claude-code-collab

# Install script
./install.sh
source ~/.zshrc  # or ~/.bashrc

# Test connection
ssh claudeteam@164.92.123.456
# Should connect!

# Join session
join-claude-session.sh collaborator claude-collab
```

They'll see the same split-screen interface, but their prompt will say `[collaborator]>`

---

## Part 9: Start Collaborating!

### Both of you connect:

**Host:**
```bash
ssh claudeteam@164.92.123.456
join-claude-session.sh host claude-collab
```

**Collaborator:**
```bash
ssh claudeteam@164.92.123.456
join-claude-session.sh collaborator claude-collab
```

### Example Session:

**Host types in bottom pane:**
```
Create a function to validate email addresses
```

**Both see in top pane:**
```
[host] Create a function to validate email addresses
Claude: I'll create an email validation function...
```

**Collaborator types in their bottom pane:**
```
Can we also add phone validation?
```

**Both see in top pane:**
```
[collaborator] Can we also add phone validation?
Claude: Absolutely! Let me add phone validation too...
```

**Magic! 🎉**

---

## Managing Your Server

### Check if Claude Code Session is Running

```bash
ssh claudeteam@YOUR_SERVER_IP
tmux ls
```

Should show:
```
claude-collab: 1 windows (created ...)
```

### Restart Claude Code Session (if needed)

```bash
ssh claudeteam@YOUR_SERVER_IP

# Kill old session
tmux kill-session -t claude-collab

# Create new session
tmux new-session -s claude-collab -d
tmux send-keys -t claude-collab "claude-code" C-m
```

### View Session Directly (Troubleshooting)

```bash
ssh claudeteam@YOUR_SERVER_IP

# Attach to session
tmux attach-session -t claude-collab

# You'll see Claude Code running
# To detach: Ctrl+B, then D
```

---

## Troubleshooting

### "Connection refused" when SSH

**Check droplet is running:**
1. Log into DigitalOcean dashboard
2. Click "Droplets"
3. Verify status is "Active" (green dot)

**Check IP address:**
- Make sure you're using the correct IP from DigitalOcean dashboard

### "Permission denied (publickey)"

Your SSH key isn't on the server, or you're using the wrong key type.

**Step 1: Identify which key you're using**

On your local machine, run:
```bash
ssh -v claudeteam@YOUR_SERVER_IP 2>&1 | grep "Offering public key"
```

Look for a line like:
```
Offering public key: /Users/you/.ssh/id_ed25519 ED25519
# OR
Offering public key: /Users/you/.ssh/id_rsa RSA
```

**Step 2: Get the correct public key**

```bash
# If using ED25519:
cat ~/.ssh/id_ed25519.pub

# If using RSA:
cat ~/.ssh/id_rsa.pub
```

Copy the entire output.

**Step 3: Add it to the server**

```bash
# Connect with password (if you set one) or as root
ssh claudeteam@YOUR_SERVER_IP
# OR
ssh root@YOUR_SERVER_IP
su - claudeteam

# Edit authorized_keys
nano ~/.ssh/authorized_keys

# Paste your public key on a new line
# Make sure it's all ONE line (no line breaks in the middle)
# Save: Ctrl+X, Y, Enter

# Fix permissions if needed
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Exit and try again
exit
ssh claudeteam@YOUR_SERVER_IP  # Should work now
```

**Common Issues:**
- Using ED25519 key but added RSA key to server (or vice versa)
- Key was split across multiple lines when pasted
- Wrong permissions on `.ssh` directory or `authorized_keys` file
- Pasted the private key instead of public key

### "No session found: claude-collab"

Session isn't running.

**Fix:**
```bash
ssh claudeteam@YOUR_SERVER_IP

# Create session
tmux new-session -s claude-collab -d
tmux send-keys -t claude-collab "claude-code" C-m
```

### Claude Code not responding

**Restart it:**
```bash
ssh claudeteam@YOUR_SERVER_IP

# Kill session
tmux kill-session -t claude-collab

# Start fresh
tmux new-session -s claude-collab -d
tmux send-keys -t claude-collab "claude-code" C-m
```

### Can't find join-claude-session.sh

**Reinstall script:**
```bash
cd ~/claude-code-collab
./install.sh
source ~/.zshrc
```

---

## Cost & Billing

### Monthly Cost

**DigitalOcean Basic Droplet:**
- **$12/month** ($0.018/hour)
- 2 GB RAM
- 1 CPU
- 50 GB SSD
- 2 TB transfer

**Split between 2 people:** $6/month each

### New User Credit

- $200 credit for 60 days
- **First 60 days are FREE!**
- Cancel anytime before credit runs out

### Monitoring Costs

1. Log into DigitalOcean
2. Click "Billing" in left menu
3. See month-to-date usage

### Destroying the Droplet (to save money)

If you want to pause and not pay:

1. DigitalOcean dashboard
2. Click "Droplets"
3. Click droplet name
4. Click "Destroy"
5. Type droplet name to confirm

**Note:** This deletes everything! You'll need to set up from scratch again.

---

## Security Best Practices

### Disable Password Authentication (Use SSH Keys Only)

```bash
ssh claudeteam@YOUR_SERVER_IP
sudo nano /etc/ssh/sshd_config
```

Find and change:
```
PasswordAuthentication no
```

Save and restart SSH:
```bash
sudo systemctl restart sshd
```

### Enable Firewall

```bash
ssh claudeteam@YOUR_SERVER_IP

# Allow SSH
sudo ufw allow 22/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### Keep System Updated

Run monthly:
```bash
ssh claudeteam@YOUR_SERVER_IP
sudo apt update && sudo apt upgrade -y
```

---

## Quick Reference Card

**Print this and keep handy:**

```
═══════════════════════════════════════
  CLAUDE CODE COLLABORATION
═══════════════════════════════════════

Server IP: ________________

Username: claudeteam

Session: claude-collab

═══════════════════════════════════════
  COMMANDS
═══════════════════════════════════════

Join session:
  ssh claudeteam@SERVER_IP
  join-claude-session.sh YOUR_NAME claude-collab

Check if running:
  ssh claudeteam@SERVER_IP
  tmux ls

Restart session:
  ssh claudeteam@SERVER_IP
  tmux kill-session -t claude-collab
  tmux new-session -s claude-collab -d
  tmux send-keys -t claude-collab "claude-code" C-m

Exit session:
  Ctrl+B, then D

═══════════════════════════════════════
```

---

## Next Steps

- [ ] Part 1: Create SSH key ✓
- [ ] Part 2: Create DigitalOcean droplet ✓
- [ ] Part 3: Connect to server ✓
- [ ] Part 4: Set up server ✓
- [ ] Part 5: Install collaboration script ✓
- [ ] Part 6: Set up local Mac ✓
- [ ] Part 7: Join session ✓
- [ ] Part 8: Add collaborator ✓
- [ ] Part 9: Start collaborating! ✓

---

## Support

- **DigitalOcean Documentation:** https://docs.digitalocean.com/
- **DigitalOcean Community:** https://www.digitalocean.com/community
- **Repository Issues:** https://github.com/jxandery/claude-code-collab/issues
- **tmux Guide:** https://tmuxcheatsheet.com/

---

**Ready to start?** Begin with Part 1 and you'll be collaborating in about an hour!
