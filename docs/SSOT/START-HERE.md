# START HERE

本仓库 SSOT 的默认审计模式为 **mode=routine**。只有当 **Commander 明确声明 `mode=milestone`** 时，才触发 **P0 对齐审计**（milestone-gated）。

Hard Truth 只认 **本次 Evidence Pack 的原样命令输出**（verbatim outputs）。  
若 Evidence Pack 缺失某项硬输出，则该项结论必须标为 **UNKNOWN**，不得用 GitHub 网页 UI 作为替代真值来源。

Truth validation 只认 **SHA-pinned raw**（`raw/<MAIN_SHA>/...`）。  
`raw(main)` 仅可用于导航/发现，不得作为真值校验形式。

## Core naming
- Blueprint = docs/SSOT/一键安装构思.md
- Playbook = docs/SSOT/一键安装流程机制.md
- Framework = docs/SSOT/1click核心执行框架 + 必要文档.md

## Fixed Read Set (19)
1. docs/SSOT/一键安装构思.md  (Blueprint)
2. docs/SSOT/一键安装流程机制.md  (Playbook)
3. docs/SSOT/1click核心执行框架 + 必要文档.md  (Framework)
4. docs/SSOT/START-HERE.md
5. docs/SSOT/EVIDENCE-PACK.template.md
6. docs/SSOT/STATE.md
7. docs/SSOT/DECISIONS.md
8. docs/SSOT/SPEC-TEMPLATE.md
9. docs/SSOT/JOURNAL.md
10. docs/PHASES.yml
11. docs/SSOT/ROLES/COMMANDER.md
12. docs/SSOT/ROLES/PLANNER.md
13. docs/SSOT/ROLES/EXECUTOR.md
14. docs/SSOT/ROLES/AUDITOR.md
15. docs/SSOT/ROLES/SENTINEL.md
16. docs/SSOT/ROLES/INSPECTOR.md
17. docs/RULES.yml
18. docs/AUDIT-CHECKLIST.md
19. docs/SSOT/EVIDENCE/  (directory; read latest evidence file)

## New conversation handoff
- 当前阶段的 resume anchor：`docs/SSOT/readset-20260309.md`。  
  / The current resume anchor for this stage is `docs/SSOT/readset-20260309.md`.
- 先读 Fixed Read Set 1–19（按序）
- 再读 `docs/SSOT/readset-20260309.md`
- 再读 docs/SSOT/EVIDENCE/ 中最新 evidence（按文件名 UTC/main_sha 排序取最新）
- 任何 readset / handoff snapshot 都必须先用本轮 `(1)(2)` 重新锚定到 then-current `MAIN_SHA`；历史 SHA 只表示当时快照，不是当前真值。

## Flow entry clarification / 流程入口澄清
- docs-only governance repair flow：仅当任务目标是修补 SSOT / governance 文案、模板或流程说明时进入。  
  / docs-only governance repair flow applies only when the task is limited to SSOT / governance wording, templates, or workflow clarification.
- project execution flow：仅当任务目标是实现、验证、合并或关闭项目执行项时进入。  
  / project execution flow applies only when the task is about implementation, verification, merge-closeout, or task closure for project execution.
- docs-only governance repair 合并后，默认返回 Commander / START-HERE 重新判定下一轮项目入口。  
  / After a docs-only governance repair is merged, the default return target is Commander / START-HERE for the next project entry decision.
- 当明确调用御史时，读 `docs/SSOT/ROLES/INSPECTOR.md`，并保持该角色只读、只向尚书房汇报。  
  / When Inspector is explicitly invoked, read `docs/SSOT/ROLES/INSPECTOR.md` and keep the role read-only and reporting only to 尚书房.

## Entry Points
- STATE: [docs/SSOT/STATE.md](./STATE.md)
- DECISIONS: [docs/SSOT/DECISIONS.md](./DECISIONS.md)
- SENTINEL: [docs/SSOT/ROLES/SENTINEL.md](./ROLES/SENTINEL.md)
- COMMANDER: [docs/SSOT/ROLES/COMMANDER.md](./ROLES/COMMANDER.md)
- INSPECTOR: [docs/SSOT/ROLES/INSPECTOR.md](./ROLES/INSPECTOR.md)

## How to use
- 复制模板并填写 Evidence Pack：见 [docs/SSOT/EVIDENCE-PACK.template.md](./EVIDENCE-PACK.template.md)

## Canonical Docs
- [一键安装流程机制](./一键安装流程机制.md)
- [一键安装构思](./一键安装构思.md)
- [1click核心执行框架 + 必要文档](./1click核心执行框架%20+%20必要文档.md)

## Emergency Reset (RRC-RESET)

If any conversation/model appears to drift, type: `RRC-RESET`.

Then immediately re-anchor on this-run `(1)(2)` and follow the Sentinel contract in SHA-pinned raw form:
- `https://raw.githubusercontent.com/Hello-Pork-Belly/1click/<MAIN_SHA>/docs/SSOT/ROLES/SENTINEL.md`
- `raw(main)` may be used only to discover the path before `MAIN_SHA` is established.
