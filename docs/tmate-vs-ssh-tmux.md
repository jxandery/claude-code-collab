# Choosing Your Collaboration Method: tmate vs SSH+tmux

This guide helps you choose between two approaches for Claude Code collaboration.

---

## Quick Comparison

| Feature | tmate | SSH+tmux |
|---------|-------|----------|
| **Setup Time** | 5 minutes | 30-60 minutes |
| **Network Config** | None needed | Port forwarding or cloud server |
| **Router Setup** | Not required | Required (unless cloud) |
| **User Prefixing** | Manual typing | Automatic with script |
| **Interface** | Single shared terminal | Split view (output/input) |
| **Cost** | Free | Free (your Mac) or $12/mo (cloud) |
| **Privacy** | Via tmate.io servers | Direct to your server |
| **Firewall Issues** | None - works everywhere | May need configuration |
| **Best For** | Quick testing, demos | Regular collaboration |

---

## Method 1: tmate (Instant Sharing)

### What is tmate?

tmate is a fork of tmux that automatically shares your terminal session via public relay servers. No server setup, no port forwarding, no networking knowledge required.

### Architecture

```
┌──────────────┐                                    ┌────────────────┐
│              │                                    │                │
│  Your Mac    │──┐                            ┌───│  Collaborator  │
│  (running    │  │                            │   │  (connects via │
│   Claude     │  │                            │   │   simple SSH)  │
│   Code)      │  │                            │   │                │
└──────────────┘  │    ┌──────────────────┐   │   └────────────────┘
                  └────│  tmate.io relay  │───┘
                       │     servers      │
                       │   (free, public) │
                       └──────────────────┘
```

### Setup Process

**Host (5 minutes):**
1. Install tmate: `brew install tmate`
2. Start tmate: `tmate`
3. Start Claude Code: `claude-code`
4. Get connection string: `tmate show-messages`
5. Share the `ssh XXX@tmate.io` line with collaborator

**Collaborator (1 minute):**
1. Run: `ssh XXX@nyc1.tmate.io`
2. You're in!

### User Attribution

**Manual prefixing required:**
```
[host] Add user authentication
[collaborator] Can we use JWT?
```

Everyone types in the same terminal and must manually add their username prefix.

### Pros

✅ **Instant setup** - works in 5 minutes
✅ **No networking knowledge needed** - zero configuration
✅ **Works from anywhere** - through firewalls, different networks
✅ **Free** - no server costs
✅ **Perfect for demos** - show someone quickly

### Cons

❌ **Manual prefixing** - must type `[username]` yourself
❌ **External dependency** - relies on tmate.io servers
❌ **Less privacy** - traffic routes through tmate.io
❌ **Same terminal** - everyone types in same space
❌ **No input separation** - can't have separate input/output views

### When to Use tmate

- **First time trying collaboration** - test the concept quickly
- **Demos and presentations** - show colleagues how it works
- **Different networks** - when port forwarding isn't possible
- **Quick pairing sessions** - ad-hoc collaboration
- **You're okay with manual prefixes** - typing `[name]` isn't a dealbreaker

---

## Method 2: SSH+tmux (Professional Setup)

### What is SSH+tmux?

Traditional approach using SSH to connect to a server (your Mac or cloud) that's running a tmux session with Claude Code.

### Architecture

**Option A: Using Your Mac**
```
┌──────────────────┐        SSH         ┌────────────────────┐
│                  │◄───────────────────│                    │
│  Your Mac        │                    │  Collaborator      │
│  (SSH server)    │                    │  (SSH client)      │
│  ┌────────────┐  │                    │                    │
│  │ tmux       │  │                    │                    │
│  │ Claude Code│  │                    │                    │
│  └────────────┘  │                    │                    │
└──────────────────┘                    └────────────────────┘
      ▲
      │ Requires port forwarding
      │ on your home router
```

**Option B: Using Cloud Server**
```
┌──────────────┐         SSH         ┌─────────────────┐         SSH         ┌────────────────┐
│              │────────────────────►│                 │◄────────────────────│                │
│  Your Mac    │                     │  Cloud Server   │                     │  Collaborator  │
│              │                     │  ($12/month)    │                     │                │
└──────────────┘                     │  ┌───────────┐  │                     └────────────────┘
                                     │  │   tmux    │  │
                                     │  │ Claude Code│ │
                                     │  └───────────┘  │
                                     └─────────────────┘
```

### Setup Process

**Option A: Your Mac as Server (30-45 min):**
1. Enable Remote Login in System Settings
2. Find your public IP
3. Set up port forwarding on router
4. Install tmux: `brew install tmux`
5. Start shared session: `tmux new-session -s claude-collab`
6. Start Claude Code: `claude-code`
7. Share your IP and username with collaborator

**Option B: Cloud Server (60-90 min):**
1. Create DigitalOcean/AWS server
2. Install tmux and Claude Code
3. Create shared user account
4. Set up SSH keys
5. Start shared session
6. Share server IP with collaborator

**Collaborator:**
1. Install the collaboration script
2. Run: `join-claude-session.sh collaborator`
3. Automatic prefixing works!

### User Attribution

**Automatic prefixing with script:**
- You type: `Add user authentication`
- Script sends: `[host] Add user authentication`
- Claude sees: `[host] Add user authentication`

### Pros

✅ **Automatic user attribution** - script adds `[username]`
✅ **Split-screen interface** - top (view), bottom (input)
✅ **Full control** - you own the infrastructure
✅ **Better privacy** - direct server connection
✅ **Professional setup** - clean UX for regular use
✅ **Input separation** - your own input terminal

### Cons

❌ **More setup time** - 30-90 minutes
❌ **Networking required** - port forwarding or cloud
❌ **Costs money** - $12/month for cloud (or free with your Mac)
❌ **Requires SSH knowledge** - more technical
❌ **Your Mac must stay on** - if using Mac as server

### When to Use SSH+tmux

- **Regular collaboration** - working together frequently
- **Professional projects** - need reliable, clean UX
- **Prefer automatic prefixing** - don't want to type `[name]`
- **Value privacy** - prefer direct connection
- **Have budget** - $12/month is acceptable
- **Technical comfort** - okay with SSH and networking

---

## Detailed Feature Comparison

### User Experience

**tmate:**
```
$ tmate
[Both users type in same terminal]
[host] Add authentication
[collaborator] Can we use JWT?
Claude: Yes, here's how to implement JWT...
```
- Everyone sees and types in same space
- Must coordinate who's typing
- Manual attribution via typing `[name]`

**SSH+tmux:**
```
Host's view:                    Collaborator's view:
┌─────────────────────┐        ┌─────────────────────┐
│ Shared Claude Output│        │ Shared Claude Output│
│ [host] Add auth     │        │ [host] Add auth     │
│ Claude: Here's...   │        │ Claude: Here's...   │
│ [collaborator] JWT? │        │ [collaborator] JWT? │
│ Claude: Yes...      │        │ Claude: Yes...      │
├─────────────────────┤        ├─────────────────────┤
│ [host]> _           │        │ [collaborator]> _   │
│ (Your input here)   │        │ (Your input here)   │
└─────────────────────┘        └─────────────────────┘
```
- Each person has their own input area
- Shared output view at top
- Automatic prefixing
- Clear separation

### Security & Privacy

**tmate:**
- Traffic routes through tmate.io public servers
- Encrypted, but third-party relay
- Open source - can self-host tmate servers if desired
- Good for non-sensitive work

**SSH+tmux:**
- Direct connection to your server
- No third-party relay
- You control the infrastructure
- Better for sensitive/proprietary work

### Reliability

**tmate:**
- Dependent on tmate.io availability
- Generally reliable (~99% uptime)
- If tmate.io is down, can't collaborate

**SSH+tmux:**
- Dependent on your server/Mac availability
- You control uptime
- Your internet connection matters

### Cost Analysis

| Approach | Initial Setup | Monthly Cost | Annual Cost |
|----------|--------------|--------------|-------------|
| **tmate** | Free | $0 | $0 |
| **SSH+tmux (your Mac)** | Free | $0 | $0 |
| **SSH+tmux (DigitalOcean)** | Free | $12 | $144 |
| **SSH+tmux (AWS EC2)** | Free | ~$17 | ~$204 |

---

## Hybrid Approach: Start with tmate, Upgrade Later

### Recommended Path

**Week 1: Test with tmate**
- Install tmate in 5 minutes
- Try collaboration with manual prefixes
- See if you like the workflow
- Decide if you want to continue

**If you like it: Upgrade to SSH+tmux**
- Spend an afternoon setting up cloud server
- Get automatic prefixing
- Better long-term experience

**Benefits:**
- Low barrier to entry (test quickly)
- Don't invest time if collaboration doesn't work for you
- Upgrade only if you're committed

---

## Making Your Decision

### Choose tmate if:
- [ ] You want to try RIGHT NOW (5 min setup)
- [ ] You're testing to see if collaboration works for you
- [ ] You rarely collaborate (< once per week)
- [ ] Router/networking setup sounds intimidating
- [ ] Zero budget
- [ ] You're okay typing `[username]` manually
- [ ] Quick demos to colleagues

### Choose SSH+tmux if:
- [ ] You collaborate regularly (> once per week)
- [ ] You want the best user experience
- [ ] Automatic prefixing is important
- [ ] You have $12/month budget OR willing to configure router
- [ ] You want full control and privacy
- [ ] Split-screen interface appeals to you
- [ ] Professional/long-term use

---

## Migration Path

### If You Start with tmate and Want to Upgrade:

1. **Keep using tmate for now** - it works!
2. **Set up SSH+tmux during non-collaboration time**
3. **Test SSH+tmux setup** before switching fully
4. **Switch when ready** - use the original `join-claude-session.sh` script
5. **Keep tmate as backup** - useful for quick sessions

---

## Setup Guides

- **tmate Setup:** See [tmate-setup.md](tmate-setup.md)
- **SSH+tmux with Cloud Server:** See [setup-for-host.md](setup-for-host.md)
- **SSH+tmux with Your Mac:** See [QUICK-TEST-LOCAL-MAC.md](QUICK-TEST-LOCAL-MAC.md) (local testing only)
- **Local Testing (same machine):** See [QUICK-TEST-LOCAL-MAC.md](QUICK-TEST-LOCAL-MAC.md)

---

## FAQ

### Can I switch between tmate and SSH+tmux?
Yes! They're independent. Use tmate for quick sessions, SSH+tmux for regular work.

### Is tmate secure?
Yes, traffic is encrypted. However, it routes through tmate.io servers. For highly sensitive work, use SSH+tmux.

### Can I self-host tmate servers?
Yes! tmate is open source. You can run your own relay servers. See [tmate documentation](https://tmate.io/).

### Do I need to choose just one?
No! Many teams use tmate for quick demos and SSH+tmux for regular work.

### What if my collaborator is on Windows?
- tmate: Works via WSL (Windows Subsystem for Linux)
- SSH+tmux: Also works via WSL
Both approaches require WSL on Windows

---

## Recommendation Summary

**🚀 Getting Started (First Time)?**
→ Use **tmate** - be collaborating in 5 minutes

**💼 Professional Regular Use?**
→ Use **SSH+tmux** - better UX and automation

**🤔 Not Sure Yet?**
→ Start with **tmate**, upgrade later if needed

---

**Ready to get started?**
- [tmate Quick Start](tmate-setup.md)
- [SSH+tmux Detailed Setup](setup-for-host.md)
