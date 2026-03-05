# Evidence Pack: consistency-audit v2 (CONS-01/CONS-07)

- mode: routine
- captured_at_utc: 2026-03-05T08:45:15Z
- main_sha: 225b570901abb0a2f6b35cd8edd29b10af03c498

## (1) git ls-remote refs/heads/main
```text
225b570901abb0a2f6b35cd8edd29b10af03c498	refs/heads/main
```

## (2) gh api commits/main --jq .sha
```text
225b570901abb0a2f6b35cd8edd29b10af03c498
```

## Findings

### CONS-01 — Result: PASS
Sources (SHA-pinned raw):
- https://raw.githubusercontent.com/Hello-Pork-Belly/1click/225b570901abb0a2f6b35cd8edd29b10af03c498/docs/PHASES.yml
- https://raw.githubusercontent.com/Hello-Pork-Belly/1click/225b570901abb0a2f6b35cd8edd29b10af03c498/docs/SSOT/一键安装流程机制.md

Excerpt A: docs/PHASES.yml lines 1-20 (sed -n ,p)
```text
# docs/PHASES.yml is the only truth for phases in 1click.
# updated_at only changes when current_phase changes.
version: 1
repo: Hello-Pork-Belly/1click
truth_file: docs/PHASES.yml

phases:
  - id: PLAN
    name: Planning
    description: Define scope, constraints, and acceptance criteria.
  - id: IMPLEMENT
    name: Implementation
    description: Execute approved changes within file allowlist and risk bounds.
  - id: VERIFY
    name: Verification
    description: Validate with remote reality checks and required evidence.
  - id: RELEASE
    name: Release
    description: Merge, publish evidence pack, and close loop.
```

Excerpt B: docs/SSOT/一键安装流程机制.md lines 26-45 (sed -n ,p)
```text
- 本文件是流程与门禁的唯一细则载体（Blueprint 仅保留原则；Framework 仅保留落地入口与路径）。
- 本文件负责：Phase 门禁、Stop/Go、DoD、Evidence Pack 执行口径、审计与回滚闭环。

## Phases (execution order is mandatory)

- 执行顺序 MUST 固定为：Phase0 → Phase1 → Phase2。
- 最小纵向切片 MUST 固定为：安装 → 配置 → 验收 → 回滚/恢复 → 证据落盘。

### Phase0: Governance/Foundation Ready
- Entry Criteria
  - SSOT Fixed Read Set (19) 可发现。
  - Evidence Pack 模板可用。
  - RRC 可通过 Evidence-by-file 跑通。
  - Workflow Hygiene 全绿。
  - required checks 稳定（若存在）。
- DoD
  - Foundation Ready 必须可验收：基线合同可读、门禁可执行、任务输入可审计复现（不引入新政策）。
- Evidence
  - Evidence MUST 落盘到 `docs/SSOT/EVIDENCE/`。
  - 文件命名 MUST 为 `<captured_at_utc>_<mode>_<main_sha>_<topic>.md`。
```

Conclusion: Playbook Phase0/1/2 is explicitly documented as execution gates, while docs/PHASES.yml remains repo lifecycle phase truth; conflict rule is stated (PHASES.yml wins). Therefore CONS-01 PASS.

### CONS-07 — Result: PASS
Source (SHA-pinned raw):
- https://raw.githubusercontent.com/Hello-Pork-Belly/1click/225b570901abb0a2f6b35cd8edd29b10af03c498/docs/AUDIT-CHECKLIST.md

Excerpt: docs/AUDIT-CHECKLIST.md lines 2-21 (sed -n ,p)
```text

Use this checklist for auditable PR review in `Hello-Pork-Belly/1click`.

## 1) Remote Reality Check (required)

- Evidence-by-file is allowed: if an evidence file has been merged into `main`, auditors MAY treat the SHA-pinned raw content of that evidence file as Hard Truth input.
- If any required item is missing from the evidence inputs, it MUST be marked as `UNKNOWN + Evidence Gaps` (do not fabricate).
- GitHub UI MUST NOT replace Hard Truth; UI links are weak/supporting evidence only.

Collect and paste URLs/output for:

```bash
gh api repos/Hello-Pork-Belly/1click/commits/main --jq '{sha:.sha, html_url:.html_url, msg:.commit.message}'
gh pr list -R Hello-Pork-Belly/1click --state open --limit 50
gh pr checks -R Hello-Pork-Belly/1click <PR_NUMBER> || true
gh run list -R Hello-Pork-Belly/1click --limit 20 || true
gh release list -R Hello-Pork-Belly/1click --limit 20 || true
gh api repos/Hello-Pork-Belly/1click/tags?per_page=10
```
```

Conclusion: Audit checklist explicitly allows evidence-by-file via SHA-pinned raw, requires UNKNOWN+Evidence Gaps on missing items, and forbids GitHub UI as Hard Truth. Therefore CONS-07 PASS.
