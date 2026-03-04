# RUNBOOK: Cleanup Policy (dry-run first)

## 1) Purpose / Goals / Principles
- Prevent long-term repository bloat and branch residue.
- Default behavior is **dry-run**: produce a plan and evidence, without deleting anything.
- Cleanup must not change SSOT truth, and should be docs-only when possible.
- Any destructive step MUST be reversible and evidence-backed.

## 2) Remote branch cleanup workflow (policy + evidence)
### Identify candidates
- Candidate branches are typically prefixed:
  - `codex/docs/handoff-`
  - `codex/chore/`
  - `codex/fix/`
- Primary risk: deleting a branch without confirming whether it has a PR or contains unmerged work.

### Evidence-first commands (verbatim)
- List PRs for a given head branch:
  - `gh pr list -R Hello-Pork-Belly/1click --head <branch> --state all --json number,state,url,mergedAt,mergeCommit`
- List branches (best-effort):
  - `gh api repos/Hello-Pork-Belly/1click/branches?per_page=100`

### Delete (only when Commander approves)
- Delete remote branch:
  - `gh api -X DELETE repos/Hello-Pork-Belly/1click/git/refs/heads/<branch>`
- Or via git:
  - `git push origin --delete <branch>`

### Evidence standard
- Always preserve verbatim command outputs in an evidence file under `docs/SSOT/EVIDENCE/` before any deletion.

## 3) EVIDENCE directory retention strategy
- `*_handoff.md`:
  - Suggested retention window: keep most recent **N=30** or last **14 days** (choose one when applying).
  - Rationale: handoff files are high-frequency and can bloat history.
- `*_repo-settings.md`:
  - Keep periodic snapshots; suggested cadence weekly/monthly or after governance changes.
- All other evidence:
  - Preserve indefinitely unless Commander declares an archival strategy.

## 4) Evidence Pack policy (verbatim)
- Evidence must be verifiable and verbatim. Prefer capturing outputs to files (anti-noise).
- Minimum useful outputs for cleanup decisions:
  - `gh api repos/<repo>/branches...`
  - `gh pr list --head ...`
  - For evidence file counts: `find docs/SSOT/EVIDENCE -type f -name '*.md' | wc -l`

## 5) Rollback / Recovery
### Accidental file deletion in git
- If deletion is committed:
  - `git revert <merge_commit_sha>`
  - Or restore a file from a prior commit: `git checkout <sha> -- <path>`

### Remote branch deletion risk
- Remote branch deletion is harder to undo:
  - If the branch was deleted but commits still exist in local clones or PR refs, it may be recoverable by pushing the commit SHA to a new branch.
  - Treat remote deletions as high-risk; require Commander explicit approval + evidence.

## 6) Tooling (dry-run plan)
- Use `./scripts/cleanup_plan.sh` to generate a dry-run plan:
  - `./scripts/cleanup_plan.sh --repo Hello-Pork-Belly/1click`
- The plan output should be captured verbatim into an evidence file when executing cleanup as a milestone.
