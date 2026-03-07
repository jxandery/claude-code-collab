# Session Notes

Last updated: 2026-03-07

## Current State

**16 uncommitted files** on `main` branch — commit and push before next session.

## What Was Done

1. **UX overhaul** — interactive setup wizard, one-command server bootstrap, health checks on join, diagnostics tool, cleanup tool, doc rewrites with TL;DR sections
2. **Custom prefix** — `--prefix` flag on join scripts, `COLLAB_PREFIX` env var, wizard integration
3. **Self-service SSH** — collaborators run `ssh-copy-id claudeteam@IP` with a password to add their own key
4. **Dynamic password management** — `server-bootstrap.sh` auto-generates a password; `start-collaboration.sh` lets hosts generate/set one interactively; stored in `~/.claude-collab-config`
5. **All 12 doc files updated** for the above features

## Live Droplet (if still active)

- **IP:** 137.184.185.154
- **User:** claudeteam
- **Password:** RM6AlZUgszoscG3s
- **Cost:** $12/mo (billed while it exists, even when off)
- **Destroy:** `doctl compute droplet delete claude-collab-server --force`

## Where to Pick Up

1. Commit and push the 16 modified files
2. Test with a real collaborator (ssh-copy-id + custom prefix)
3. Destroy droplet when no longer needed
4. See `docs/FUTURE-ENHANCEMENTS.md` for next feature ideas
