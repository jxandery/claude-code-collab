# Claude Code Collaboration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue)](https://github.com/jxandery/claude-code-collab)
[![Shell](https://img.shields.io/badge/shell-bash-green)](https://github.com/jxandery/claude-code-collab)

Enable multiple people to collaborate on the same Claude Code session in real-time, with automatic user attribution.

**Repository:** https://github.com/jxandery/claude-code-collab

## What This Does

- **Multiple users** can interact with one Claude Code session
- **User attribution**: Each prompt is automatically prefixed with `[Username]`
- **Real-time**: Everyone sees all interactions as they happen
- **Simple setup**: Just run a script on each person's machine

## Two Ways to Collaborate

### ⚡ tmate (Quick Start - 5 minutes)
**Best for:** Testing, demos, quick sessions
- Zero networking setup required
- Works instantly from anywhere
- Free forever
- Manual username prefixing
- [→ tmate setup guide](docs/tmate-setup.md)

### 🚀 SSH+tmux (Professional Setup - 30-60 minutes)
**Best for:** Regular collaboration, better UX
- Automatic username prefixing
- Split-screen interface (view/input separated)
- Requires cloud server ($12/mo) or your Mac with port forwarding
- Full control and privacy
- [→ SSH+tmux setup guide](docs/setup-for-host.md)

**Not sure which to choose?** See the [detailed comparison guide](docs/tmate-vs-ssh-tmux.md).

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

Claude sees:
```
[host] Add authentication
[collaborator] Can we use JWT?
[host] Yes, let's do that
```

---

## Quick Start

### Local Testing (Single Machine)

> **⚠️ SECURITY WARNING**: Local testing on your machine should ONLY be used for testing the concept yourself. DO NOT allow external collaborators to access your local machine as this grants them full system access, including all your files, credentials, SSH keys, and the ability to execute any commands with your user privileges. For actual collaboration, always use a dedicated cloud server (DigitalOcean, AWS, etc.).

Test the concept on your own machine before setting up with colleagues:

**Terminal 1: Shared Claude Code View**
```bash
tmux new-session -s test-collab
claude-code
# Ctrl+B, D to detach
```

**Terminal 2: Your Input (as "host")**
```bash
./join-claude-session.sh host
```

**Terminal 3: Simulate Another User (as "collaborator")**
```bash
./join-claude-session.sh collaborator
```

Type in Terminal 2 and 3, watch responses in Terminal 1!

**📖 For detailed local testing guide, see [QUICK-TEST-LOCAL-MAC.md](docs/QUICK-TEST-LOCAL-MAC.md)**

---

## Installation (Per User)

Each collaborator runs this on their own machine:

### Option 1: Automated Install

```bash
# Clone the repo
git clone https://github.com/jxandery/claude-code-collab.git
cd claude-code-collab

# Run installer
./install.sh

# If PATH was updated, reload shell
source ~/.zshrc  # or ~/.bashrc
```

### Option 2: Manual Install

```bash
# Clone the repo
git clone https://github.com/jxandery/claude-code-collab.git

# Copy script to ~/bin
mkdir -p ~/bin
cp claude-code-collab/join-claude-session.sh ~/bin/
chmod +x ~/bin/join-claude-session.sh

# Add ~/bin to PATH (if not already)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## Usage

### For Local Testing (Same Machine)

> **⚠️ SECURITY WARNING**: This is for local testing only. Never allow remote users to access your local machine.

**Step 1: Create shared session**
```bash
tmux new-session -s test-collab
claude-code
# Press Ctrl+B, then D to detach
```

**Step 2: Open multiple terminals**

Terminal 1 (Shared View):
```bash
tmux attach-session -t test-collab
```

Terminal 2 (Host):
```bash
join-claude-session.sh host
```

Terminal 3 (Collaborator):
```bash
join-claude-session.sh collaborator
```

### For Remote Collaboration (Different Machines)

**Step 1: Set up shared server** (One person does this)
- See [setup-for-host.md](docs/setup-for-host.md) for detailed host setup
- See [setup-for-collaborator.md](docs/setup-for-collaborator.md) for collaborator setup instructions
- Or use the quick version below

**Step 2: Each collaborator connects**

On shared server (first time only):
```bash
ssh yourteam@shared-server.com
tmux new-session -s claude-collab
claude-code
# Ctrl+B, D to detach
```

On each person's local machine:
```bash
# Method 1: Use your name explicitly
ssh yourteam@shared-server.com
join-claude-session.sh YourName claude-collab

# Method 2: Let it use your hostname
join-claude-session.sh
```

---

## Command Line Options

```bash
# Use hostname as username (default)
join-claude-session.sh

# Specify username
join-claude-session.sh host

# Specify username and session name
join-claude-session.sh host my-session

# Custom session (useful for multiple projects)
join-claude-session.sh collaborator project-alpha
```

---

## Architecture

### Local Testing Setup (⚠️ For Testing Only - Security Risk for Real Collaboration)
```
┌─────────────────────────────────────────────────────┐
│         Your Mac (⚠️ TESTING ONLY)                  │
│                                                     │
│  Terminal 1       Terminal 2       Terminal 3       │
│  ┌──────────┐    ┌─────────┐    ┌──────────────┐    │
│  │  Claude  │<-- │  Host   │    │ Collaborator │    │
│  │   Code   │    │ Input   │    │    Input     │    │
│  └──────────┘    └─────────┘    └──────────────┘    │
│       ▲                │                 │          │
│       └────────────────┴─────────────────┘          │
│                  tmux session                       │
└─────────────────────────────────────────────────────┘
```

### Remote Collaboration Setup
```
Host's Machine           Shared Server         Collaborator's Machine
┌──────────────┐        ┌───────────────┐        ┌──────────────────┐
│              │        │               │        │                  │
│ Input Script │─SSH───>│ tmux session  │<──SSH──│  Input Script    │
│ [host]>      │        │ Claude Code   │        │ [collaborator]>  │
└──────────────┘        │               │        └──────────────────┘
                        └───────────────┘
```

---

## Requirements

- **tmux** (install: `brew install tmux`)
- **Claude Code** (installed and authenticated)
- **Bash** (macOS and Linux default shell)
- **SSH access** to shared server (for remote collaboration)

---

## Troubleshooting

### "tmux: command not found"
```bash
brew install tmux
# Then reload shell
source ~/.zshrc
```

### "Session not found"
Create the session first:
```bash
tmux new-session -s test-collab
claude-code
# Ctrl+B, D to detach
```

### Messages not appearing in Claude
Make sure you're using the correct session name:
```bash
# Check what sessions exist
tmux ls

# Use the correct name
join-claude-session.sh YourName your-session-name
```

### ~/bin not in PATH
```bash
# Add to your shell config
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Script shows hostname instead of my name
Specify your name explicitly:
```bash
join-claude-session.sh YourName
```

---

## How It Works

1. **One shared tmux session** runs Claude Code
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

---

## File Structure

```
claude-code-collab/
├── README.md                          # This file
├── LICENSE                            # MIT License
├── .gitignore                         # Git ignore file
├── install.sh                         # Automated installer
├── join-claude-session.sh             # Main collaboration script
└── docs/                              # Documentation
    ├── setup-for-host.md              # Detailed setup guide (host)
    ├── setup-for-collaborator.md      # Setup guide (collaborator)
    └── QUICK-TEST-LOCAL-MAC.md        # Local testing guide
```

---

## FAQ

### Can more than 2 people collaborate?
Yes! Each person just runs `join-claude-session.sh TheirName` and all messages appear in the shared session.

### Do we need to be on the same network?
No. For remote collaboration, you need a shared server (cloud VM or one person's machine with SSH access).

### Can we use different Claude Code subscriptions?
Only one Claude Code instance runs (on the shared server). You share that one subscription.

### How much does it cost?
- **Local testing**: Free (just uses your existing Claude Code)
- **Remote collaboration**: $0-12/month for a small cloud server (e.g., DigitalOcean)

### Is this officially supported by Anthropic?
No, this is a community workaround using tmux for terminal sharing. It's a simple script that sends keystrokes to a shared terminal session.

### Can we work asynchronously?
The tmux session persists, so you can collaborate async. But for best experience, work together in real-time with voice chat.

---

## Advanced Usage

### Multiple Projects

Create different sessions for different projects:

```bash
# Project 1
tmux new-session -s project-alpha
claude-code
# Ctrl+B, D

# Project 2
tmux new-session -s project-beta
claude-code
# Ctrl+B, D

# Connect to specific project
join-claude-session.sh host project-alpha
join-claude-session.sh collaborator project-beta
```

### Custom Usernames

Get creative with usernames for clarity:

```bash
join-claude-session.sh alice-frontend
join-claude-session.sh bob-backend
join-claude-session.sh sarah-pm
```

### Voice Coordination

For best experience, use voice chat (Zoom/Discord/Slack) while collaborating:

```
Host (voice): "Let me ask about authentication"
Host (types): Add JWT authentication
[Everyone sees Claude's response]

Collaborator (voice): "Can I ask about error handling?"
Collaborator (types): How should we handle auth failures?
[Everyone sees Claude's response]
```

---

## Comparison with Alternatives

| Approach | Pros | Cons | Cost |
|----------|------|------|------|
| **This (tmux + script)** | Simple, works today, real attribution | Requires shared server | $0-12/mo |
| Screen share | Zero setup | Passive for viewers | Free |
| VS Code Live Share | Good for code review | Only host controls Claude | Free |
| Git + docs | Works async | No real-time, manual process | Free |
| Custom web app | Purpose-built | Months of development | High |

---

## Contributing

Ideas for improvements:

- [ ] Support for Windows (WSL)
- [ ] Web UI for easier access
- [ ] Session recording/playback
- [ ] Better conflict resolution for simultaneous input
- [ ] Integration with Slack/Discord bots

Pull requests welcome!

---

## License

MIT License - see [LICENSE](LICENSE) file

---

## Credits

Created to solve real-time Claude Code collaboration for distributed teams. Inspired by classic pair programming and terminal multiplexing.

---

## Documentation

- **[Local Testing Guide](docs/QUICK-TEST-LOCAL-MAC.md)** - Test on your Mac before remote setup
- **[Host Setup Guide](docs/setup-for-host.md)** - Detailed server setup instructions
- **[Collaborator Setup Guide](docs/setup-for-collaborator.md)** - Instructions for joining an existing setup

---

## Support

- **Issues**: Open an issue on GitHub
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: See the `/docs` folder for detailed guides

---

## Related Projects

- [tmate](https://tmate.io/) - Instant terminal sharing
- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [Claude Code](https://claude.ai/code) - AI pair programming tool

---

**Built with ❤️ for better collaboration**
