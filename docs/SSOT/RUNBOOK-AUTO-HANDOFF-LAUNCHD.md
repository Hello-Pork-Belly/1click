# RUNBOOK: Auto-Handoff via launchd (hourly, SHA-change only)

## 1. Purpose / Scope

This runbook covers **only** the local machine setup for Auto-Handoff:
- `launchd` runs hourly (`StartInterval=3600`) and executes `handoff_capture.sh --auto-pr`.
- The script checks `main_sha` (Hard Truth via `gh api .../commits/main --jq .sha`).
- **Only when `main_sha` changes**, it generates a new `*_handoff.md` evidence file and opens a **DRAFT** docs-only PR.
- If `main_sha` does not change, it exits silently (no PR, no noise).

Out of scope:
- Any GitHub repository settings changes (branch protection / required checks / auto-merge policies).
- CI/workflow implementation details beyond verifying the local job is running.

## 2. Preconditions

### Worktree layout (example)
- root worktree: `~/Documents/1click/1click`
- exec worktree (launchd WorkingDirectory): `~/Documents/1click-exec/1click`
- audit worktree (read-only): `~/Documents/1click-audit/1click`

### Access and tools
- `gh` is installed, logged in, and can access the repo:
  - `gh auth status`
  - `gh repo view Hello-Pork-Belly/1click`

### Audit worktree hooks disabled
- In audit worktree, hooks must be disabled to prevent JOURNAL contamination:
  - `git config core.hooksPath /dev/null`
  - (Recommended) run `./scripts/audit_guard.sh` before auditing.

### macOS Privacy: Full Disk Access
Launchd jobs can fail due to filesystem/privacy restrictions. Ensure Full Disk Access is granted to:
- Terminal (or your shell host app)
- `/bin/bash`
- `gh` binary (example paths: `/opt/homebrew/bin/gh`, `/usr/local/bin/gh`)
- `git` binary (example paths: `/usr/bin/git`, `/opt/homebrew/bin/git`)

## 3. Install (Enable)

### 3.1 Copy plist
The repo provides the plist:
- `tools/local/launchd/com.1click.handoff.plist`

Install it as a user LaunchAgent:
```bash
mkdir -p ~/Library/LaunchAgents
cp -f tools/local/launchd/com.1click.handoff.plist ~/Library/LaunchAgents/com.1click.handoff.plist
```

### 3.2 Bootstrap (do NOT use load)

```bash
launchctl bootout "gui/$(id -u)/com.1click.handoff" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.1click.handoff.plist
```

### 3.3 Kickstart once (run immediately)

```bash
launchctl kickstart -k "gui/$(id -u)/com.1click.handoff"
```

## 4. Verify (Hard Truth commands)

### 4.1 Agent status

```bash
launchctl print "gui/$(id -u)/com.1click.handoff" | sed -n '1,160p'
```

### 4.2 Logs

```bash
tail -n 200 ~/Library/Logs/1click-handoff.log
```

Interpretation:
- **Log empty / “skip” behavior is normal** when `MAIN_SHA` did not change (no new handoff evidence, no PR).
- **A new DRAFT PR is expected** when `MAIN_SHA` changes (the script opens a draft PR to avoid auto-merge noise).

## 5. Common Failures

### 5.1 Operation not permitted / getcwd / WorkingDirectory errors

Symptoms:
- log contains `Operation not permitted`, `getcwd`, or fails immediately

Checks:
- Confirm Full Disk Access (see Preconditions).
- Confirm `WorkingDirectory` in plist points to the exec worktree and exists.

Fix:
- Grant Full Disk Access to the relevant apps/binaries.
- Update plist `WorkingDirectory`, then:
  - `launchctl bootout ...`
  - `launchctl bootstrap ...`
  - `launchctl kickstart -k ...`

### 5.2 PATH issues / cannot find gh

Symptoms:
- log shows `gh: command not found`

Checks:
- Verify plist sets `EnvironmentVariables/PATH`.
- Verify `gh` exists at expected path:
  - `command -v gh`
  - `ls -l /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh 2>/dev/null`

Fix:
- Add PATH in the plist (or set `GH_BIN` in the script environment).
- Re-bootstrap + kickstart.

### 5.3 PR creation fails

Symptoms:
- log shows `gh pr create` errors, auth failures, or invalid flag errors

Checks:
- `gh --version`
- `gh auth status`
- `gh repo view Hello-Pork-Belly/1click`

Fix:
- Re-auth: `gh auth login`
- Ensure the script is not using deprecated/invalid flags.
- Re-run kickstart after fixing auth/tooling.

## 6. Safe Disable / Uninstall

Disable agent:

```bash
launchctl bootout "gui/$(id -u)/com.1click.handoff" || true
```

Remove plist:

```bash
rm -f ~/Library/LaunchAgents/com.1click.handoff.plist
```

Optional: clear log

```bash
rm -f ~/Library/Logs/1click-handoff.log
```
