# JOURNAL (auto)

Purpose:
- Continuous, append-only activity log to support handoff across new chats.
- Primary use: explain “why two observers saw different repo reality” by recording time + hard anchors.

Rules:
- This file is appended automatically by repo hooks and/or CI. Humans do not manually edit existing entries.
- If an entry needs to reference the operator, use the stable identifier: Pork-Belly. Do not use other personal identifiers or app/model labels.
- Historical `Pork- Belly` should be interpreted as the same operator, but it must not be used for new entries.
- Entries must include at least: ts_utc, mode, event, actor, main_head, and, when applicable, pr and merge_commit.

Format (append-only):
- ts_utc: 0000-00-00T00:00:00Z
  mode: routine|milestone
  actor: Pork-Belly|<other-stable-id>
  role: sentinel|commander|planner|executor|auditor|unknown
  event: <short verb phrase or task-closeout label>
  main_head: <40-hex>
  pr: <#n|EMPTY>
  merge_commit: <40-hex|EMPTY>
  evidence: <repo-path|url|EMPTY>
  note: <one-line|EMPTY>

--- 
## Entries

- ts_utc: 2026-02-28T10:05:57Z
  mode: routine
  actor: Pork- Belly
  role: unknown
  event: git-commit
  main_head: c8070d14c1c38ec9effa438698405b75832fcb7a
  pr: 
  merge_commit: 
  evidence: 
  note: 

- ts_utc: 2026-03-08T08:50:11Z
  mode: routine
  actor: Pork- Belly
  role: executor
  event: t1-2-closeout
  main_head: 87691ecae9761e5f88ff966ba65a6fa5c75506d9
  pr: #112
  merge_commit: ab2a6080124c0d6cb7a9c4c3b753d43aec782e8f
  evidence: docs/SSOT/EVIDENCE/T-1.2-closeout-PR109.md
  note: T-1.2 implementation merged in PR #109; docs-only closeout PR #112 opened after main verification.
