# JOURNAL (auto)

Purpose:
- Continuous, append-only activity log to support handoff across new chats.
- Primary use: explain “why two observers saw different repo reality” by recording time + hard anchors.

Rules:
- This file is appended automatically by repo hooks and/or CI. Humans do not manually edit existing entries.
- If an entry needs to reference the operator, use the stable identifier: Pork-Belly. Do not use other personal identifiers or app/model labels.
- Historical spaced variants should be interpreted as the same operator, but they must not be used for new entries.
- Entries must include at least: ts_utc, mode, event, actor, main_head, and, when applicable, pr and merge_commit.
- When acting app/model traceability matters, use either `event: model-switch` or fill the optional `actor_app`, `model_family`, and `model_version` fields on the relevant entry.

Format (append-only):
- ts_utc: 0000-00-00T00:00:00Z
  mode: routine|milestone
  actor: Pork-Belly|<other-stable-id>
  role: sentinel|commander|planner|executor|auditor|unknown
  actor_app: <concrete app/tool label|EMPTY>
  model_family: <GPT|Gemini|Claude|EMPTY>
  model_version: <provider model id/version|EMPTY>
  event: <short verb phrase|model-switch|task-closeout label>
  main_head: <40-hex>
  pr: <#n|EMPTY>
  merge_commit: <40-hex|EMPTY>
  evidence: <repo-path|url|EMPTY>
  note: <one-line|EMPTY>

--- 
## Entries

- ts_utc: 2026-02-28T10:05:57Z
  mode: routine
  actor: Pork-Belly
  role: unknown
  event: git-commit
  main_head: c8070d14c1c38ec9effa438698405b75832fcb7a
  pr: 
  merge_commit: 
  evidence: 
  note: 

- ts_utc: 2026-03-08T08:52:47Z
  mode: routine
  actor: Pork-Belly
  role: executor
  event: t1-2-closeout
  main_head: 34b828c46a6b07fb41b97cf8d05c52eef2fc5d97
  pr: #112
  merge_commit: 34b828c46a6b07fb41b97cf8d05c52eef2fc5d97
  evidence: docs/SSOT/EVIDENCE/T-1.2-closeout-PR109.md
  note: T-1.2 closure_pr=#112 closure_merge_commit=34b828c46a6b07fb41b97cf8d05c52eef2fc5d97; implementation PR #109 merged earlier at ab2a6080124c0d6cb7a9c4c3b753d43aec782e8f after main verification.
