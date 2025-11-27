# Future Enhancements

This document tracks planned features and improvements for Claude Code Collaboration.

---

## In Progress / To Be Implemented

### 1. Session Lifecycle Management (HIGH PRIORITY)

**Status:** Documentation Complete, Script Implementation Pending

**Goal:** Provide clear guidance and automated tools for managing session lifecycles, preventing resource waste and accidental data loss.

**Problem:**
Users don't know when to end sessions vs keep them running, leading to:
- Cluttered server with abandoned sessions
- Accidental data loss when killing sessions without saving
- Uncertainty about whether sessions are still in use
- Wasted resources from forgotten sessions

#### Documentation Added (✓ Complete):

- **HOST-INSTRUCTIONS.md:** Full "Managing Session Lifecycle" section
  - When to keep sessions running vs ending them
  - Resource cost guidance (5-10MB per session)
  - Pre-shutdown checklist
  - How to properly end sessions
  - What happens when you kill a session (Claude context loss)
  - Resuming after killing sessions

- **TROUBLESHOOTING.md:** Session Management Issues section
  - Cleaning up old sessions
  - Recovering from forgotten save
  - Checking if session is in use
  - Handling unexpected session endings
  - Descriptive session naming best practices

#### Scripts to Build:

##### A. Graceful Shutdown Script

**File: `end-session.sh`**

Interactive session shutdown with safety checks:

```bash
end-session.sh claude-collab

# Prompts:
# 1. "Are all collaborators done? Checking who's connected..."
#    Shows: tmux list-clients -t claude-collab
#
# 2. "Have you saved/downloaded all work?"
#    Lists: Recently modified files in working directory
#    Offers: "Download files now? [y/n]"
#    Offers: "Create git commit? [y/n]"
#
# 3. "Where did you leave off?"
#    Prompts for note/comment (saved to session metadata)
#
# 4. "Kill session 'claude-collab'?"
#    Requires typing session name to confirm (safety check)
#
# 5. Kills session and displays summary:
#    "Session ended. Files remain at: /home/user/project"
#    "To resume: Follow HOST-INSTRUCTIONS Step 2"
```

Features:
- Shows who's still connected before allowing kill
- Lists recently modified files
- Integrates with `download-from-server.sh` for easy downloads
- Offers git commit creation
- Saves session notes for future reference
- Requires confirmation to prevent accidents
- Clear next steps after shutdown

##### B. Session Status/Info Script

**File: `session-info.sh`**

Display detailed information about a session:

```bash
session-info.sh claude-collab

# Output:
# Session: claude-collab
# Status: Active
# Created: 2 days ago (2025-11-25 14:30:22)
# Last Activity: 30 minutes ago
# Working Directory: /home/claudeteam/my-project
# Connected Clients: 2
#   - john (192.168.1.100) - 30 min ago
#   - sarah (192.168.1.105) - 5 min ago
#
# Recent Files Modified:
#   - output.md (5 min ago)
#   - server.js (30 min ago)
#   - README.md (2 hours ago)
#
# Actions:
#   [J]oin  [E]nd  [D]ownload files  [I]nfo (refresh)  [Q]uit
```

Features:
- Shows creation time and last activity
- Lists all connected clients with IPs
- Shows working directory
- Lists recently modified files
- Interactive menu for common actions

##### C. Session Cleanup Helper

**File: `cleanup-old-sessions.sh`**

Find and clean up abandoned sessions:

```bash
cleanup-old-sessions.sh

# Scans all sessions and shows:
#
# Active Sessions Analysis:
#
# [1] claude-collab
#     Created: 2 hours ago
#     Last Activity: 5 min ago
#     Clients: 2 connected
#     Status: ✓ ACTIVE
#
# [2] bug-fixes
#     Created: 3 days ago
#     Last Activity: 3 days ago
#     Clients: None
#     Status: ⚠ ABANDONED (3 days idle)
#
# [3] old-experiment
#     Created: 14 days ago
#     Last Activity: 14 days ago
#     Clients: None
#     Status: 🚨 STALE (14 days idle)
#
# Recommendations:
#   - Keep session #1 (active)
#   - Consider ending #2 (abandoned 3 days)
#   - Should end #3 (stale 14 days)
#
# Actions:
#   [K]ill session  [I]nfo  [R]efresh  [Q]uit
```

Features:
- Automatic detection of abandoned sessions
- Categorizes: Active, Abandoned (>1 day), Stale (>7 days)
- Interactive cleanup workflow
- Safety checks before killing

#### Implementation Checklist:

- [x] Add session lifecycle documentation to HOST-INSTRUCTIONS.md
- [x] Add session management troubleshooting to TROUBLESHOOTING.md
- [ ] Create `end-session.sh` script
  - [ ] Check connected clients
  - [ ] List modified files
  - [ ] Integrate file download option
  - [ ] Integrate git commit option
  - [ ] Save session notes
  - [ ] Confirmation prompt
- [ ] Create `session-info.sh` script
  - [ ] Display session metadata
  - [ ] Show connected clients
  - [ ] List recent file modifications
  - [ ] Interactive actions menu
- [ ] Create `cleanup-old-sessions.sh` script
  - [ ] Scan all sessions
  - [ ] Categorize by activity
  - [ ] Interactive cleanup workflow
- [ ] Update `install.sh` to include new scripts
- [ ] Update REMOTE-QUICK-START.md to mention session management
- [ ] Test end-to-end workflows

---

### 2. Feedback System with Slash Commands

**Status:** Design Complete, Ready for Implementation

**Goal:** Allow collaborators to easily report bugs and suggest features during collaboration sessions, with automatic screenshot capture and upload.

#### Components to Build:

##### A. Slash Commands (in `~/claude-code-collab/.claude/commands/`)

**File: `report-bug.md`**
- Prompts user for bug details:
  1. What were you trying to do?
  2. What happened (the bug)?
  3. What did you expect to happen?
  4. Any error messages?
- Automatically captures context:
  - Current project directory
  - Current tmux session name
  - All collaborators in session
  - Server IP
  - Timestamp
- Offers to capture screenshot via utility script
- Saves to: `~/claude-collab-feedback/bugs/[timestamp]_[username]_[project].md`
- Notifies user that bug report is saved and visible to all collaborators

**File: `suggestion-box.md`**
- Prompts user for feature suggestion:
  1. What problem does this solve?
  2. How would it work?
  3. Who would benefit from this?
- Automatically captures same context as bug reports
- Offers screenshot option
- Saves to: `~/claude-collab-feedback/suggestions/[timestamp]_[username]_[project].md`
- Notifies user about review process

##### B. Screenshot Utility Script

**File: `take-bug-screenshot.sh`**
- Runs on LOCAL machine (not server)
- Detects OS (macOS/Linux/Windows)
- Takes screenshot:
  - macOS: Uses `screencapture` command
  - Linux: Uses `scrot` or `gnome-screenshot`
  - Windows: Uses PowerShell screenshot
- Auto-uploads to server: `~/claude-collab-feedback/screenshots/[timestamp]_[username].png`
- Returns server path to reference in bug report
- Handles errors gracefully (missing tools, connection issues)

##### C. Feedback Organization

**Server Directory Structure:**
```
~/claude-collab-feedback/
├── README.md                                    # Instructions for reviewers
├── project-metadata.json                        # Tracks project info
├── bugs/
│   ├── 2025-11-27_143022_john_project-alpha.md
│   ├── 2025-11-27_150315_sarah_api-project.md
│   └── screenshots/
│       ├── 2025-11-27_143022_john.png
│       └── 2025-11-27_150315_sarah.png
└── suggestions/
    ├── 2025-11-27_144533_bob_project-alpha.md
    └── screenshots/
        └── 2025-11-27_144533_bob.png
```

**Bug Report Format:**
```markdown
---
Project: claude-collab-project
Project Path: /home/claudeteam/projects/claude-collab-project
Session: claude-collab
Server: 68.183.159.246
Date: 2025-11-27 14:30:22
Reporter: john
Collaborators in Session: john, sarah, bob
---

## What I was trying to do
[user's answer]

## What happened (the bug)
[user's answer]

## What I expected
[user's answer]

## Error messages / details
[user's answer]

## Screenshot
~/claude-collab-feedback/bugs/screenshots/2025-11-27_143022_john.png

---
Status: Pending Review
GitHub Issue: [To be created]
```

##### D. Review and Sync Script (Optional)

**File: `sync-feedback-to-github.sh`**
- Lists all pending bug reports and suggestions
- Shows summary of each
- Prompts: "Post to GitHub? [y/n]"
- Uses GitHub CLI (`gh`) to create issues/discussions
- Updates the feedback file with GitHub issue number
- Marks as "Posted to GitHub"

**Usage:**
```bash
# On server, review feedback
cd ~/claude-collab-feedback
./sync-feedback-to-github.sh

# Or manually review:
ls -la bugs/
cat bugs/2025-11-27_143022_john_project-alpha.md
```

#### Design Decisions Made:

1. **Location of slash commands:** Server's `~/claude-code-collab/.claude/commands/`
   - Accessible to all collaborators
   - Consistent across sessions

2. **Feedback storage:** Server at `~/claude-collab-feedback/`
   - Visible to all collaborators
   - Persists across sessions
   - Easy to review and sync to GitHub

3. **Screenshot approach:** Option D - Built-in utility script
   - Runs on local machine
   - Auto-uploads to server
   - References server path in reports
   - Most seamless for users

4. **Context capture:** Automatic
   - Project directory and path
   - Session name
   - All active collaborators
   - Server info
   - Timestamp

5. **Visibility:** Public to all collaborators on server
   - Encourages transparency
   - Everyone can see what's been reported
   - Reduces duplicate reports

6. **GitHub sync:** Manual review process
   - Maintainer reviews before posting
   - Can filter/combine similar reports
   - Can add additional context
   - Prevents spam/duplicates on GitHub

#### Implementation Checklist:

- [ ] Create `report-bug.md` slash command
- [ ] Create `suggestion-box.md` slash command
- [ ] Create `take-bug-screenshot.sh` utility script
  - [ ] macOS support (screencapture)
  - [ ] Linux support (scrot/gnome-screenshot)
  - [ ] Windows/WSL support (PowerShell)
  - [ ] Auto-upload to server via scp
  - [ ] Error handling and fallbacks
- [ ] Create feedback directory structure on server
- [ ] Add instructions in `~/claude-collab-feedback/README.md`
- [ ] Create `sync-feedback-to-github.sh` (optional)
- [ ] Update `install.sh` to include new scripts
- [ ] Update documentation to mention feedback system
- [ ] Test end-to-end workflow

---

## Backlog / Future Ideas

### 2. Auto-reconnect on Disconnect

**Problem:** If internet drops briefly, split-pane mode crashes instead of reconnecting.

**Proposed Solution:**
- Detect connection loss
- Attempt reconnection with exponential backoff
- Show "Reconnecting..." message
- Restore session when connection returns

**Who Benefits:** All users, especially those with unstable connections

---

### 3. Session Recording / Playback

**Problem:** Hard to review what happened during a collaboration session.

**Proposed Solution:**
- Record all Claude interactions to a file
- Command: `record-session.sh start/stop`
- Playback: `replay-session.sh [session-file]`
- Shows timestamped messages and responses

**Who Benefits:** Teams wanting to review decisions or onboard new members

---

### 4. Web UI

**Problem:** Terminal-based interface is intimidating for non-technical users.

**Proposed Solution:**
- Web interface showing Claude output
- Text box for input (auto-prefixed with username)
- Shows all collaborators online
- Built-in file upload/download
- No terminal knowledge required

**Who Benefits:** Non-technical collaborators (designers, PMs, etc.)

**Complexity:** High - requires web server, auth, real-time updates

---

### 5. Built-in Voice Chat

**Problem:** Teams always use separate app (Zoom/Discord) for coordination.

**Proposed Solution:**
- WebRTC-based voice chat
- Integrated into split-pane mode or web UI
- Push-to-talk or always-on
- Shows who's speaking

**Who Benefits:** All users

**Complexity:** High - requires WebRTC, may have latency issues

---

### 6. Multiple Cursor Support

**Problem:** Only one person can type at a time effectively.

**Proposed Solution:**
- Show what each person is typing in real-time
- Separate input areas per user
- Merge into single Claude prompt
- Visual indicator of who's typing

**Who Benefits:** Teams wanting more fluid collaboration

**Complexity:** Medium - requires real-time sync

---

### 7. Slack/Discord Bot Integration

**Problem:** Team communication happens in Slack/Discord, collaboration in terminal.

**Proposed Solution:**
- Bot that mirrors Claude interactions to Slack/Discord
- Users can send messages via bot
- Bot posts Claude responses to channel
- Maintains attribution

**Who Benefits:** Teams heavily using Slack/Discord

**Complexity:** Medium - requires bot hosting, auth

---

### 8. Windows Native Support (non-WSL)

**Problem:** WSL required for Windows users.

**Proposed Solution:**
- Native Windows scripts using PowerShell
- Windows-compatible tmux alternative (maybe GNU Screen)
- Or use web UI (see #4)

**Who Benefits:** Windows users without WSL

**Complexity:** Medium - requires testing and alternate tools

---

### 9. File Sync Between Local and Server

**Problem:** Manual scp needed to share files.

**Proposed Solution:**
- `sync-files.sh` utility
- Watches local directory
- Auto-uploads changes to server
- Shows sync status in split-pane mode

**Who Benefits:** Anyone sharing code/data frequently

**Complexity:** Low-Medium - can use rsync or similar

---

### 10. Smart Session Discovery

**Problem:** Users need to know session names to join.

**Proposed Solution:**
- `find-sessions.sh` that shows:
  - All active sessions
  - Who's in each session
  - What project they're working on
  - How long session has been active
- Interactive: "Which session do you want to join?"

**Who Benefits:** New collaborators joining mid-session

**Complexity:** Low - extension of existing `list-sessions.sh`

---

### 11. Collaboration Analytics

**Problem:** Hard to know who contributed what.

**Proposed Solution:**
- Track messages per user
- Track response times
- Generate session summary:
  - Who participated
  - How many questions each asked
  - Time spent
  - Files created/modified

**Who Benefits:** Team leads, for tracking engagement

**Complexity:** Low - just parsing and aggregation

---

### 12. Persistent Session History

**Problem:** Session history is lost when tmux session ends.

**Proposed Solution:**
- Auto-save all interactions to:
  `~/claude-collab-history/[session]/[date].log`
- Command to search history: `search-history.sh "authentication"`
- Resume from history when restarting session

**Who Benefits:** Everyone, for continuity

**Complexity:** Low - just logging

---

## Contributing

Have an idea? See [FEEDBACK-AND-FEATURES.md](FEEDBACK-AND-FEATURES.md) for how to:
- Suggest a feature
- Report a bug
- Submit code

---

## Priority Guide

| Priority | Features                                                          |
|----------|-------------------------------------------------------------------|
| High     | Session lifecycle management (#1), Feedback system (#2)           |
| Medium   | Auto-reconnect (#3), Session recording (#4)                       |
| Low      | Web UI (#5), Voice chat (#6), Bots (#8)                           |
| Future   | Analytics (#12), File sync (#10), Windows native support (#9)    |

---

**Last Updated:** 2025-11-27
**Recent Changes:** Added session lifecycle management as #1 priority with complete documentation

**Maintainer Notes:**
- Review this document quarterly
- Move items from "Backlog" to "In Progress" as needed
- Update priority based on user feedback
- Link GitHub issues/PRs as features are implemented
