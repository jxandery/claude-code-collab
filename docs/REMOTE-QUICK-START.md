# Remote Collaboration - Quick Start Guide

This guide helps you set up real-time Claude Code collaboration between multiple people on different machines.

---

## Who Should Read What?

Choose your scenario:

### 🆕 First Time Setup

**Setting up a server for the first time?**
→ Read [SERVER-SETUP.md](SERVER-SETUP.md)

This covers:
- Creating a cloud server (DigitalOcean, AWS, etc.)
- Installing tmux, Claude Code, and collaboration scripts
- Setting up SSH access
- One-time configuration

---

### 👥 Ready to Collaborate

**Already have a configured server?**

#### If you're the HOST (creating the session):
→ Read [HOST-INSTRUCTIONS.md](HOST-INSTRUCTIONS.md)

This covers:
- Creating a new Claude Code session on the server
- Connecting your input terminal
- Split-pane vs Simple mode

#### If you're a COLLABORATOR (joining existing session):
→ Read [COLLABORATOR-INSTRUCTIONS.md](COLLABORATOR-INSTRUCTIONS.md)

This covers:
- Joining an existing Claude Code session
- Connecting your input terminal
- Split-pane vs Simple mode

---

### 🔧 Having Problems?

**Something not working?**
→ Read [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

This covers:
- Git pull conflicts
- SSH connection issues
- tmux detach problems
- Messages not appearing
- And more...

---

## What You Need

Before starting, ensure you have:

- [ ] A server with SSH access (IP address like `68.183.159.246`)
- [ ] Server username (like `claudeteam`)
- [ ] Scripts installed on your local machine (`./install.sh`)
- [ ] Scripts installed on the server (`./install.sh`)
- [ ] Latest code pulled everywhere (`git pull`)

---

## Quick Overview

### How It Works

1. **One shared server** runs Claude Code in a tmux session
2. **Host creates** the session on the server
3. **Everyone connects** from their local machines
4. **All messages** are automatically prefixed with `[username]`
5. **Everyone sees** Claude's responses in real-time

### Two Interface Modes

**Split-pane mode (recommended):**
- Top pane: Claude Code output (70%)
- Bottom pane: Your input (30%)
- All in one terminal window

**Simple mode:**
- One terminal for input
- Separate terminal (optional) to view Claude output
- More flexible but requires coordination

---

## Typical Session Flow

### First Time (30-60 minutes)
1. Set up server → [SERVER-SETUP.md](SERVER-SETUP.md)
2. Test as host → [HOST-INSTRUCTIONS.md](HOST-INSTRUCTIONS.md)
3. Invite collaborators → Send them [COLLABORATOR-INSTRUCTIONS.md](COLLABORATOR-INSTRUCTIONS.md)

### Regular Sessions (5 minutes)
1. Everyone pulls latest code: `git pull`
2. Host creates session (2 min)
3. Collaborators join (1 min)
4. Start collaborating!

---

## File Guide

| File                              | Purpose                            | Who Reads It                  |
|-----------------------------------|------------------------------------|-------------------------------|
| **SERVER-SETUP.md**               | One-time server configuration      | Host (first time only)        |
| **HOST-INSTRUCTIONS.md**          | Creating and connecting to session | Host (every session)          |
| **COLLABORATOR-INSTRUCTIONS.md**  | Joining existing session           | Collaborators (every session) |
| **TROUBLESHOOTING.md**            | Problem solving                    | Anyone having issues          |
| **REMOTE-QUICK-START.md**         | Overview and navigation            | Everyone (you are here!)      |

---

## Support

- **Issues:** https://github.com/jxandery/claude-code-collab/issues
- **Discussions:** https://github.com/jxandery/claude-code-collab/discussions
- **Main README:** [../README.md](../README.md)

---

## Ready to Start?

→ **First time?** Go to [SERVER-SETUP.md](SERVER-SETUP.md)

→ **Server already set up?**
- Host: [HOST-INSTRUCTIONS.md](HOST-INSTRUCTIONS.md)
- Collaborator: [COLLABORATOR-INSTRUCTIONS.md](COLLABORATOR-INSTRUCTIONS.md)

→ **Problems?** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
