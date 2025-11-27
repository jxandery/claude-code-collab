# Server Setup Guide

**One-time setup for creating a shared collaboration server**

This guide is for the **host** who is setting up the server for the first time. You only need to do this once.

---

## Prerequisites

- [ ] Basic command line knowledge
- [ ] Credit card for cloud server (DigitalOcean: $12/month, or AWS)
- [ ] 30-60 minutes for setup

---

## Step 1: Create a Cloud Server

### Option A: DigitalOcean (Recommended - Easiest)

1. **Sign up:** https://www.digitalocean.com/
   - Get $200 free credit for 60 days

2. **Create a Droplet:**
   - Click "Create" → "Droplets"
   - **Image:** Ubuntu 22.04 LTS
   - **Plan:** Basic, $12/month (2GB RAM, 1 CPU)
   - **Datacenter:** Choose one close to your team (e.g., San Francisco, New York)
   - **Authentication:** SSH Keys (we'll set this up in Step 2)
   - **Hostname:** `claude-collab-server`

3. **Get your server IP:**
   - After creation, you'll see an IP address like `68.183.159.246`
   - Save this - you'll need it!

### Option B: AWS EC2

1. **Sign in:** AWS Console → EC2
2. **Launch Instance:**
   - **AMI:** Ubuntu Server 22.04 LTS
   - **Type:** t2.small (2GB RAM)
   - **Security Group:** Allow SSH (port 22) from anywhere (or specific IPs)
   - **Key Pair:** Create new or use existing

3. **Get your server IP:**
   - Find "Public IPv4 address" in instance details

### Option C: Other Providers

Any Linux server works:
- Google Cloud Platform
- Linode
- Vultr
- Your own dedicated server

**Requirements:**
- Ubuntu 22.04 LTS (or similar Linux)
- At least 2GB RAM
- SSH access
- Public IP address

---

## Step 2: Set Up SSH Keys

SSH keys let you connect to the server without typing passwords.

### Check if you have SSH keys

```bash
ls ~/.ssh/id_rsa.pub
# or
ls ~/.ssh/id_ed25519.pub
```

**If you see a file**, you already have keys! Skip to "Copy your public key" below.

### Create SSH keys (if you don't have them)

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
# Press Enter for all prompts (accept defaults)
```

Or if you prefer RSA:
```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
# Press Enter for all prompts (accept defaults)
```

### Copy your public key

```bash
# For ED25519:
cat ~/.ssh/id_ed25519.pub

# For RSA:
cat ~/.ssh/id_rsa.pub
```

**Copy this entire output** - you'll need it in the next step.

It looks like:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJl3dIeudNqd... your-email@example.com
```

---

## Step 3: Initial Server Connection

### Connect as root

```bash
# Replace with your server's IP
ssh root@68.183.159.246
```

**First time connecting?** You'll see a message about authenticity. Type `yes` and press Enter.

If DigitalOcean: Check your email for the root password.

---

## Step 4: Create a Shared User Account

This user account will be shared by all collaborators.

```bash
# Create user (still as root)
adduser claudeteam
# Enter a password when prompted (you'll share this OR use SSH keys)

# Add to sudo group (for admin access if needed)
usermod -aG sudo claudeteam

# Switch to the new user
su - claudeteam
cd ~
```

---

## Step 5: Set Up SSH Key Access

### For the claudeteam user

```bash
# Create SSH directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create authorized_keys file
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Add your SSH public key

```bash
nano ~/.ssh/authorized_keys
```

**Paste your public key** from Step 2 (one key per line).

To add collaborators later: Paste their public keys on new lines.

**Save and exit:** `Ctrl+X`, then `Y`, then `Enter`

### Test SSH key access

Open a **new terminal** (keep the current one open just in case):

```bash
ssh claudeteam@68.183.159.246
# Should connect without password!
```

**Success?** You can close the root session.

**Doesn't work?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#problem-permission-denied-publickey)

---

## Step 6: Install Dependencies

Run these commands as the `claudeteam` user:

### Update system

```bash
sudo apt update && sudo apt upgrade -y
```

### Install tmux and git

```bash
sudo apt install -y tmux git curl
```

### Verify tmux

```bash
tmux -V
# Should show: tmux 3.x or higher
```

### Install Node.js (required for Claude Code)

```bash
# Download and run NodeSource setup script
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version  # Should show: v20.x.x
npm --version   # Should show: 10.x.x
```

---

## Step 7: Install Claude Code

### Install Claude Code globally

```bash
npm install -g @anthropic-ai/claude-code
```

**Note:** If you get permission errors, you may need to use `sudo`:
```bash
sudo npm install -g @anthropic-ai/claude-code
```

### Authenticate Claude Code

```bash
claude-code auth login
```

**What happens:**
1. You'll see a URL in the terminal
2. Copy and paste it into your browser
3. Log in with your Anthropic/Claude account
4. The terminal will confirm authentication

### Test Claude Code

```bash
claude-code --version
# Should show the version number

# Quick test (optional)
claude-code
# Should start Claude Code
# Type Ctrl+C to exit
```

---

## Step 8: Install Collaboration Scripts

### Clone the repository

```bash
cd ~
git clone https://github.com/jxandery/claude-code-collab.git
cd claude-code-collab
```

### Run the installer

```bash
./install.sh
```

This installs the collaboration scripts to `~/bin`.

### Reload shell

```bash
source ~/.bashrc
# or if using zsh:
source ~/.zshrc
```

### Verify installation

```bash
which join-claude-session.sh
# Should show: /home/claudeteam/bin/join-claude-session.sh
```

---

## Step 9: Create Initial tmux Session (Optional)

You can pre-create the session, or the host can create it each time.

```bash
# Create a session named claude-collab
tmux new-session -s claude-collab -d

# Verify it exists
tmux ls
# Should show: claude-collab: 1 windows (created ...)
```

---

## Step 10: Server Setup Complete!

Your server is ready! Here's what you have:

- ✓ Ubuntu server running
- ✓ SSH key access configured
- ✓ tmux installed
- ✓ Claude Code installed and authenticated
- ✓ Collaboration scripts installed

### Share with your team:

**Server Details:**
- IP Address: `68.183.159.246` (your actual IP)
- Username: `claudeteam`
- Session name: `claude-collab`

**Next steps for you:**
→ Go to [HOST-INSTRUCTIONS.md](HOST-INSTRUCTIONS.md) to create your first session

**For collaborators:**
→ Send them [COLLABORATOR-INSTRUCTIONS.md](COLLABORATOR-INSTRUCTIONS.md)

---

## Maintenance

### Update collaboration scripts

Periodically update the scripts to get new features:

```bash
ssh claudeteam@68.183.159.246
cd ~/claude-code-collab
git pull
exit
```

### Update Claude Code

```bash
ssh claudeteam@68.183.159.246
npm update -g @anthropic-ai/claude-code
exit
```

### Check server status

```bash
ssh claudeteam@68.183.159.246

# Check running tmux sessions
tmux ls

# Check disk space
df -h

# Check memory
free -h
```

---

## Adding New Collaborators

To add a new person:

1. **Get their SSH public key** (they run: `cat ~/.ssh/id_ed25519.pub`)
2. **Add it to authorized_keys:**
   ```bash
   ssh claudeteam@68.183.159.246
   nano ~/.ssh/authorized_keys
   # Paste their key on a new line
   # Save: Ctrl+X, Y, Enter
   exit
   ```
3. **Send them [COLLABORATOR-INSTRUCTIONS.md](COLLABORATOR-INSTRUCTIONS.md)**

---

## Security Notes

### Good practices:

- ✓ Use SSH keys (not passwords)
- ✓ Keep the server updated: `sudo apt update && sudo apt upgrade`
- ✓ Only share access with trusted team members
- ✓ Use a strong password for the `claudeteam` account

### Optional hardening:

- Disable password authentication (SSH keys only)
- Set up a firewall (ufw)
- Use fail2ban to prevent brute force attacks
- Change the SSH port from 22

See DigitalOcean's security guides for more details.

---

## Cost

| Provider        | Plan          | Cost/Month | RAM  | CPU  |
|-----------------|---------------|------------|------|------|
| DigitalOcean    | Basic Droplet | $12        | 2GB  | 1    |
| AWS EC2         | t2.small      | ~$17       | 2GB  | 1    |
| Linode          | Nanode 2GB    | $12        | 2GB  | 1    |
| Google Cloud    | e2-small      | ~$15       | 2GB  | 2    |

**Split the cost:** If 2 people use it, that's $6/month each!

---

## Troubleshooting

Having issues? See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Common issues:
- [SSH connection problems](TROUBLESHOOTING.md#problem-permission-denied-publickey)
- [Claude Code installation issues](TROUBLESHOOTING.md#problem-claude-code-not-found)
- [tmux not found](TROUBLESHOOTING.md#problem-tmux-command-not-found)

---

## Next Steps

Server is set up! Now:

→ **You (host):** [HOST-INSTRUCTIONS.md](HOST-INSTRUCTIONS.md)

→ **Collaborators:** [COLLABORATOR-INSTRUCTIONS.md](COLLABORATOR-INSTRUCTIONS.md)

→ **Back to overview:** [REMOTE-QUICK-START.md](REMOTE-QUICK-START.md)
