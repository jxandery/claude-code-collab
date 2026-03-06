# Claude Code Collaboration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue)](https://github.com/jxandery/claude-code-collab)
[![Shell](https://img.shields.io/badge/shell-bash-green)](https://github.com/jxandery/claude-code-collab)

Enable multiple people to collaborate on the same Claude Code session in real-time, with automatic user attribution.

**Repository:** https://github.com/jxandery/claude-code-collab

## TL;DR

```bash
git clone https://github.com/jxandery/claude-code-collab.git
cd claude-code-collab
./setup.sh    # Interactive wizard — picks the right setup for you
```

That's it. The wizard asks if you're a host or collaborator and walks you through everything.

---

## What This Does

- **Multiple users** can interact with one Claude Code session
- **User attribution**: Each prompt is automatically prefixed with `[Username]`
- **Real-time**: Everyone sees all interactions as they happen
- **Simple setup**: Run the setup wizard and follow the prompts

## Demo

```
Host's Terminal            Shared Claude Code           Collaborator's Terminal
┌───────────────────┐     ┌────────────────────┐      ┌───────────────────────┐
│ [host]> Add auth  │ --> │ [host] Add auth    │  <-- │                       │
│                   │     │ Claude: Here's...  │      │                       │
│                   │     │                    │      │ [collaborator]> JWT?  │
│                   │     │ [collaborator] JWT?│      │                       │
└───────────────────┘     │ Claude: Sure...    │      └───────────────────────┘
                          └────────────────────┘
```

---

## Getting Started

### Option 1: Setup Wizard (Recommended)

```bash
./setup.sh
```

The wizard will:
1. Ask your role (host, collaborator, or local test)
2. Check prerequisites (tmux, SSH)
3. Set up SSH keys if needed
4. Install all scripts
5. Give you the exact commands to run

### Option 2: Quick Local Test

Try the concept on your own machine in 2 minutes:

```bash
# Terminal 1: Start shared session
tmux new-session -s test-collab
claude-code
# Press Ctrl+B, then D to detach

# Terminal 2: Join as "host"
./join-claude-session.sh host test-collab

# Terminal 3: Join as "collaborator"
./join-claude-session.sh collaborator test-collab
```

Type in Terminal 2 or 3 — watch it appear with `[host]` or `[collaborator]` prefix!

### Option 3: Remote Collaboration

**Host** sets up a cloud server (one-time, ~30 min):
```bash
# 1. Create a DigitalOcean droplet ($12/mo, $200 free credit for new users)
# 2. Bootstrap the server:
scp server-bootstrap.sh root@YOUR_SERVER_IP:/tmp/
ssh root@YOUR_SERVER_IP 'bash /tmp/server-bootstrap.sh'
# 3. Connect:
join-claude-session-split.sh host YOUR_SERVER_IP claudeteam claude-collab
```

**Collaborator** just connects (~5 min):
```bash
./setup.sh   # Choose "collaborator", enter server IP, done
join-claude-session-split.sh YourName SERVER_IP claudeteam claude-collab
```

---

## Available Scripts

| Script | What it does |
|--------|-------------|
| `setup.sh` | Interactive setup wizard |
| `install.sh` | Install all scripts to `~/bin` |
| `join-claude-session-split.sh` | Join session with split view (recommended) |
| `join-claude-session.sh` | Join session with input-only mode |
| `setup-ssh.sh` | Detect/create SSH keys |
| `add-collaborator.sh` | Add a collaborator's SSH key to the server |
| `server-bootstrap.sh` | One-command server setup (run on Ubuntu server) |
| `diagnose.sh` | Check if everything is working |
| `teardown.sh` | Clean up sessions |

---

## Troubleshooting

Run the diagnostic tool first:
```bash
diagnose.sh                    # Check local setup
diagnose.sh YOUR_SERVER_IP     # Check local + remote
```

<details>
<summary>Common issues and fixes</summary>

### "tmux: command not found"
```bash
brew install tmux       # macOS
sudo apt install tmux   # Linux
```

### "Session not found"
```bash
# Check what sessions exist
tmux ls

# Create the session
tmux new-session -s test-collab
claude-code
# Ctrl+B, D to detach
```

### "Permission denied (publickey)"
```bash
# See which key SSH is trying to use
setup-ssh.sh --check YOUR_SERVER_IP

# Show your public key to send to the host
setup-ssh.sh --show
```

### Disconnected? Just reconnect
```bash
# The session keeps running even if you disconnect.
# Simply run the join command again:
join-claude-session-split.sh YourName SERVER_IP claudeteam claude-collab
```

### Scripts not found after install
```bash
source ~/.zshrc   # or ~/.bashrc
# Scripts are in ~/bin — this adds it to your PATH
```

</details>

---

## tmux Cheatsheet

tmux is the terminal multiplexer that makes this work. Here's what you need to know:

| Action | Keys | What happens |
|--------|------|-------------|
| **Detach** (leave session running) | `Ctrl+B`, then `D` | You exit but session keeps running |
| **Scroll up** | `Ctrl+B`, then `[`, then arrow keys | View history. Press `q` to exit scroll |
| **Switch panes** | `Ctrl+B`, then arrow keys | Move between split panes |
| **Exit input loop** | `Ctrl+C` | Stops the input script (session keeps running) |

**Key concept:** Detaching is NOT the same as closing. When you detach (`Ctrl+B, D`), the session continues in the background. You can reconnect later.

---

## Architecture

```
Host's Machine           Shared Server         Collaborator's Machine
┌──────────────┐        ┌───────────────┐        ┌──────────────────┐
│              │        │               │        │                  │
│ Input Script │─SSH───>│ tmux session  │<──SSH──│  Input Script    │
│ [host]>      │        │ Claude Code   │        │ [collaborator]>  │
└──────────────┘        │               │        └──────────────────┘
                        └───────────────┘
```

<details>
<summary>How it works under the hood</summary>

1. **One shared tmux session** runs Claude Code on a server
2. **Each user runs a script** on their machine that:
   - Prompts for input
   - Automatically prefixes input with `[Username]`
   - Sends the prefixed input to the shared session via `tmux send-keys`
3. **Everyone watches** the shared session to see Claude's responses

### Why tmux?

- **Session sharing**: Multiple people can view/interact with same terminal
- **Detachable**: Sessions persist even if you disconnect
- **Remote friendly**: Works great over SSH
- **No special server needed**: Just a regular Linux/Mac terminal

</details>

---

## When You're Done

```bash
# Clean up local sessions
teardown.sh

# Clean up local + remote
teardown.sh YOUR_SERVER_IP

# To stop paying for the server:
# Go to DigitalOcean dashboard → Droplets → Destroy
```

---

## FAQ

<details>
<summary>Can more than 2 people collaborate?</summary>

Yes! Each person just runs the join script with their name. All messages appear in the shared session.
</details>

<details>
<summary>How much does it cost?</summary>

- **Local testing**: Free
- **Remote collaboration**: $12/month for a DigitalOcean server (split = $6/each)
- New DigitalOcean users get $200 free credit (60 days free)
</details>

<details>
<summary>Is this officially supported by Anthropic?</summary>

No, this is a community tool using tmux for terminal sharing. It sends keystrokes to a shared terminal session.
</details>

<details>
<summary>What if I get disconnected?</summary>

Just run the join command again. The tmux session keeps running on the server even when everyone disconnects. All history is preserved.
</details>

<details>
<summary>Can we work asynchronously?</summary>

The tmux session persists, so you can collaborate async. But for best experience, work together in real-time with voice chat (Zoom/Discord/Slack).
</details>

---

## File Structure

```
claude-code-collab/
├── README.md                          # This file
├── setup.sh                           # Interactive setup wizard
├── install.sh                         # Script installer
├── server-bootstrap.sh                # One-command server setup
├── join-claude-session.sh             # Simple input mode
├── join-claude-session-split.sh       # Split-pane mode (recommended)
├── setup-ssh.sh                       # SSH key setup helper
├── add-collaborator.sh                # Add collaborator SSH key
├── diagnose.sh                        # Diagnostic tool
├── teardown.sh                        # Cleanup tool
├── LICENSE                            # MIT License
└── docs/                              # Detailed guides
    ├── digitalocean-setup.md          # Full DigitalOcean walkthrough
    ├── setup-for-host.md              # Host setup guide
    ├── setup-for-collaborator.md      # Collaborator setup guide
    ├── QUICK-TEST-LOCAL-MAC.md        # Local testing guide
    ├── tmate-setup.md                 # tmate quick-start guide
    └── tmate-vs-ssh-tmux.md           # Comparison guide
```

---

## Documentation

| Guide | Audience | Time |
|-------|----------|------|
| [DigitalOcean Setup](docs/digitalocean-setup.md) | Host (full walkthrough) | 60 min |
| [Host Setup](docs/setup-for-host.md) | Host (general) | 30-60 min |
| [Collaborator Setup](docs/setup-for-collaborator.md) | Collaborator | 15-20 min |
| [Local Testing](docs/QUICK-TEST-LOCAL-MAC.md) | Anyone (demo) | 10-15 min |
| [tmate Setup](docs/tmate-setup.md) | Quick sharing | 5 min |
| [tmate vs SSH+tmux](docs/tmate-vs-ssh-tmux.md) | Decision guide | — |

---

## Contributing

Pull requests welcome! See [ideas for improvements](https://github.com/jxandery/claude-code-collab/issues).

## License

MIT License - see [LICENSE](LICENSE) file

## Support

- **Issues**: [GitHub Issues](https://github.com/jxandery/claude-code-collab/issues)
- **Diagnostics**: Run `diagnose.sh` for self-service troubleshooting
