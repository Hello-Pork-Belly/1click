# Audit Checklist (Executable)

Use this checklist for auditable PR review in `Hello-Pork-Belly/1click`.

## 1) Remote Reality Check (required)

Collect and paste URLs/output for:

```bash
gh api repos/Hello-Pork-Belly/1click/commits/main --jq '{sha:.sha, html_url:.html_url, msg:.commit.message}'
gh pr list -R Hello-Pork-Belly/1click --state open --limit 50
gh pr checks -R Hello-Pork-Belly/1click <PR_NUMBER> || true
gh run list -R Hello-Pork-Belly/1click --limit 20 || true
gh release list -R Hello-Pork-Belly/1click --limit 20 || true
gh api repos/Hello-Pork-Belly/1click/tags?per_page=10
```

Evidence rule:
- Every status claim must have a clickable GitHub URL.

## 2) RULES Gate (forbidden tree entries)

Run:

```bash
find . -maxdepth 3 -type d \( -name 'archive' -o -name 'archive*' -o -name 'upstream*' -o -name 'snapshot*' -o -name 'vendor-dump*' -o -name 'backup*' \) -print
find . -maxdepth 3 -type f \( -name '*upstream*' -o -name '*snapshot*' -o -name '*vendor-dump*' -o -name '*backup*' \) -print
```

PASS:
- Both commands print no entries for active tree PRs.

## 3) SSOT Consistency Gate

Check:
- `docs/PHASES.yml` exists and is declared phase truth.
- `docs/SSOT/STATE.md` references remote-verifiable PR/commit URLs.
- `docs/RULES.yml` truth sources point to existing files and no contradictions with STATE.

## 4) Allowlist Gate (docs-only PRs)

Run:

```bash
git diff --name-only main...HEAD
```

PASS:
- Changed files are within the PR allowlist.

## 5) Verification Command Gate

Preferred:

```bash
make check; echo "exit=$?"
```

If `make check` is unavailable, define and run a repository-specific smoke command and record exit code.

## 6) Evidence Pack (must include)

- PR URL
- Base SHA + URL
- Head SHA + URL
- Checks result URL (or `gh pr checks` raw output)
- Actions run URL list (or explicit none + evidence)
- Merge commit SHA + URL
- Post-merge main HEAD SHA + URL
- Allowlist diff output
- Key verification log with exit code
