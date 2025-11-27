# Feedback and Feature Requests

We want to hear from you! Your feedback helps make Claude Code collaboration better for everyone.

---

## How to Provide Feedback

### 🐛 Found a Bug?

**Open a GitHub Issue:**
1. Go to https://github.com/jxandery/claude-code-collab/issues
2. Click "New Issue"
3. Choose "Bug Report" template
4. Include:
   - What you were trying to do
   - What happened (include error messages)
   - What you expected to happen
   - Your OS (macOS, Linux, Windows/WSL)
   - Which mode you were using (split-pane or simple)

**Example:**
```
Title: Split-pane mode crashes when SSH connection drops

Description:
When using split-pane mode, if my internet drops briefly, the
entire terminal crashes instead of reconnecting gracefully.

Steps to reproduce:
1. Start split-pane mode
2. Disconnect WiFi for 10 seconds
3. Reconnect WiFi
4. Terminal shows "Connection closed" and exits

Expected: Should attempt to reconnect or show helpful error

OS: macOS 13.5
Mode: Split-pane
```

---

### 💡 Have a Feature Idea?

**Open a GitHub Discussion:**
1. Go to https://github.com/jxandery/claude-code-collab/discussions
2. Click "New Discussion"
3. Choose "Ideas" category
4. Describe your idea:
   - What problem does it solve?
   - How would it work?
   - Who would benefit?

**Example:**
```
Title: Add voice chat integration

Problem: We always use Discord/Zoom alongside this tool,
would be great to integrate voice coordination.

Proposed solution: Add optional WebRTC voice chat built into
the split-pane interface, so we don't need a separate app.

Benefits: Easier coordination, one less tool to manage
```

---

### 📚 Documentation Issues

**Found unclear docs or missing info?**
1. Open an issue: https://github.com/jxandery/claude-code-collab/issues
2. Label it with "documentation"
3. Tell us:
   - Which doc file
   - What was confusing
   - What you expected to find

---

## Common Feature Requests

Here are some features users have requested. Vote or add your thoughts!

### Already Requested

| Feature                                | Status          | Discussion Link                    |
|----------------------------------------|-----------------|------------------------------------|
| Download files from server             | ✓ Implemented   | See `download-from-server.sh`      |
| Interactive setup wizard               | ✓ Implemented   | See `start-collaboration.sh`       |
| List active sessions                   | ✓ Implemented   | See `list-sessions.sh`             |
| Windows/WSL support                    | 🔄 In Progress  | #TBD                               |
| Web UI instead of terminal             | 💭 Under Review | #TBD                               |
| Session recording/playback             | 💭 Under Review | #TBD                               |
| Slack/Discord bot integration          | 💭 Under Review | #TBD                               |
| Built-in voice chat                    | 💭 Under Review | #TBD                               |
| Auto-reconnect on disconnect           | 💭 Under Review | #TBD                               |
| Multiple cursor support                | 💭 Under Review | #TBD                               |

Legend:
- ✓ Implemented
- 🔄 In Progress
- 💭 Under Review
- 🚫 Not Planned

---

## Request a New Feature

Don't see your idea? Here's how to request it:

### 1. Check Existing Discussions

Search first: https://github.com/jxandery/claude-code-collab/discussions

Your idea might already be discussed!

### 2. Create a New Discussion

If not found:
1. Go to Discussions
2. Click "New Discussion"
3. Choose "Ideas" category
4. Use this template:

```markdown
**Problem Statement**
Describe the problem or pain point you're experiencing.

**Proposed Solution**
How would you solve it? Be specific if possible.

**Alternatives Considered**
Any other ways you thought about solving this?

**Additional Context**
Screenshots, examples, or use cases that help explain the idea.

**Who Benefits?**
Who would use this feature? (hosts, collaborators, everyone)
```

---

## Submitting Code

Want to implement a feature yourself? Amazing!

### Steps:

1. **Check if it's been discussed**
   - Look at open issues and discussions
   - Comment on relevant threads to coordinate

2. **Fork the repository**
   - Fork: https://github.com/jxandery/claude-code-collab

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make your changes**
   - Follow existing code style
   - Add comments where helpful
   - Update documentation if needed

5. **Test thoroughly**
   - Test on your own setup
   - Try both split-pane and simple modes
   - Test error cases

6. **Submit a Pull Request**
   - Clear title describing the feature
   - Link to related issue/discussion
   - Describe what changed and why
   - Include screenshots/examples if relevant

### PR Template:

```markdown
**What does this PR do?**
Brief description of the feature/fix

**Related Issue/Discussion**
Link to the issue or discussion that prompted this

**How to test**
Steps to test the changes

**Checklist**
- [ ] Code tested locally
- [ ] Documentation updated
- [ ] No breaking changes (or breaking changes documented)
```

---

## Documentation Contributions

Help improve the docs!

### What we need:

- **Tutorials** - Step-by-step guides for specific use cases
- **Troubleshooting** - Solutions to problems you've encountered
- **Examples** - Real-world collaboration workflows
- **Translations** - Docs in other languages
- **Clarifications** - Making complex topics simpler

### How to contribute:

1. Fork the repo
2. Edit docs in `/docs` folder
3. Submit a PR with your changes

---

## Community Guidelines

### Be Respectful

- Everyone is learning
- Assume good intentions
- No harassment or discrimination

### Be Constructive

- Focus on solutions, not just problems
- Provide specific examples
- Be patient with maintainers (this is volunteer work!)

### Be Helpful

- Answer questions from other users
- Share your use cases and workflows
- Help improve documentation

---

## Quick Links

| Purpose                    | Link                                                                 |
|----------------------------|----------------------------------------------------------------------|
| Report a bug               | https://github.com/jxandery/claude-code-collab/issues                |
| Request a feature          | https://github.com/jxandery/claude-code-collab/discussions           |
| View existing issues       | https://github.com/jxandery/claude-code-collab/issues                |
| Join discussions           | https://github.com/jxandery/claude-code-collab/discussions           |
| Submit code (Pull Request) | https://github.com/jxandery/claude-code-collab/pulls                 |
| Main documentation         | https://github.com/jxandery/claude-code-collab/tree/main/docs        |

---

## Examples of Great Feedback

### Good Bug Report
```
Title: Cannot detach from tmux on Ubuntu 20.04

Steps to reproduce:
1. SSH to server (Ubuntu 20.04)
2. Create tmux session: tmux new-session -s test
3. Try to detach: Ctrl+B, D
4. Nothing happens, D just types into terminal

Expected: Should detach from session
Actual: Types "D" character

Workaround: Using `tmux detach` command works

Environment:
- OS: Ubuntu 20.04
- tmux version: 3.0a
- SSH client: OpenSSH 8.2
```

### Good Feature Request
```
Title: Add automatic file sync between local and server

Problem:
When collaborating, we often need to share local files with the
server. Currently requires manual scp commands.

Proposed Solution:
Add a command like `sync-files.sh` that:
- Watches local directory
- Automatically uploads changes to server
- Shows sync status in split-pane mode

Use Case:
When pair programming, we want to quickly share code snippets,
images, or data files without breaking flow.

Target Users: Both hosts and collaborators

Alternative Approaches:
- Use shared git repo (but requires commits)
- Manual scp (current approach, slow)
- Mount remote filesystem (complex setup)
```

---

## Thank You!

Your feedback makes this project better. Whether you report a bug, suggest a feature, or contribute code - we appreciate you taking the time to help improve Claude Code collaboration for everyone.

**Happy collaborating! 🚀**

---

**Back to:** [REMOTE-QUICK-START.md](REMOTE-QUICK-START.md)
