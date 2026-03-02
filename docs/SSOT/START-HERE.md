# START HERE

本仓库 SSOT 的默认审计模式为 **mode=routine**。只有当 **Commander 明确声明 `mode=milestone`** 时，才触发 **P0 对齐审计**（milestone-gated）。

Hard Truth 只认 **本次 Evidence Pack 的原样命令输出**（verbatim outputs）。  
若 Evidence Pack 缺失某项硬输出，则该项结论必须标为 **UNKNOWN**，不得用 GitHub 网页 UI 作为替代真值来源。

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
10. docs/BASELINE.md
11. docs/PHASES.yml
12. docs/SSOT/ROLES/COMMANDER.md
13. docs/SSOT/ROLES/PLANNER.md
14. docs/SSOT/ROLES/EXECUTOR.md
15. docs/SSOT/ROLES/AUDITOR.md
16. docs/SSOT/ROLES/SENTINEL.md
17. docs/RULES.yml
18. docs/AUDIT-CHECKLIST.md
19. docs/SSOT/EVIDENCE/  (directory; read latest evidence file)

## New conversation handoff
- 先读 Fixed Read Set 1–19（按序）
- 再读 docs/SSOT/EVIDENCE/ 中最新 evidence（按文件名 UTC/main_sha 排序取最新）

## Entry Points
- STATE: [docs/SSOT/STATE.md](./STATE.md)
- DECISIONS: [docs/SSOT/DECISIONS.md](./DECISIONS.md)
- SENTINEL: [docs/SSOT/ROLES/SENTINEL.md](./ROLES/SENTINEL.md)
- COMMANDER: [docs/SSOT/ROLES/COMMANDER.md](./ROLES/COMMANDER.md)

## How to use
- 复制模板并填写 Evidence Pack：见 [docs/SSOT/EVIDENCE-PACK.template.md](./EVIDENCE-PACK.template.md)

## Canonical Docs
- [一键安装流程机制](./一键安装流程机制.md)
- [一键安装构思](./一键安装构思.md)
- [1click核心执行框架 + 必要文档](./1click核心执行框架%20+%20必要文档.md)

## Emergency Reset (RRC-RESET)

If any conversation/model appears to drift, type: `RRC-RESET`.

Then immediately follow the Sentinel contract:
- `docs/SSOT/ROLES/SENTINEL.md` (raw main)
