

# 1click：导入范围（核心执行框架 + 必要文档）

目标：在新仓库“1click”从零重建时，仅导入“能跑起来的核心执行框架”和“必须的流程/SSOT文档”。
原则：不导入 archive/、upstream-* 快照、历史备份、临时产物；一切可追溯通过 Git 历史/Tag/PR 证据实现。

一、核心执行框架（必须导入）

1) 入口与命令层（CLI/入口脚本）
- hz（主入口/命令分发器）
- bin/（子命令与可执行脚本）

2) 核心库（运行时与基础能力）
- lib/（通用库：日志、错误处理、退出码、解析、模板、网络/ssh封装等）

3) 业务模块/功能单元
- modules/（可复用功能模块：安装、巡检、编排等）
- recipes/（配方/编排定义：组合执行、并行/滚动/分组策略）

4) 目标清单与环境描述
- inventory/（目标主机清单/分组/变量；必须 provider-agnostic）

5) 工具与辅助（仅与执行相关的必要部分）
- tools/（执行所需工具脚本；不含一次性迁移脚本/临时修复脚本）

6) 文档（与使用/运维直接相关的最小集合）
- docs/（用户文档、操作说明、约定；注意去除与旧仓库臃肿相关的历史内容）

二、必要文档（必须导入，作为新仓库的“事实源与门禁合同”）

A) SSOT（Single Source of Truth）
- docs/SSOT/一键安装构思.md（总纲）
- 一键安装流程机制.md（流程机制模板；含哨兵/门禁/证据包/回滚）
- docs/SSOT/STATE.md（Done/Doing/Next；唯一进度账本）
- docs/SSOT/DECISIONS.md（关键决策与契约记录）
- docs/SSOT/SPEC-TEMPLATE.md（任务规格模板：Inputs/Files/DoD/Rollback/Exit codes）

B) ROLES 合同（四角色 + 哨兵）
- docs/SSOT/ROLES/COMMANDER.md
- docs/SSOT/ROLES/PLANNER.md
- docs/SSOT/ROLES/EXECUTOR.md（必须包含 Evidence Pack 必填字段：PR URL/head SHA/checks/actions/tag 证据）
- docs/SSOT/ROLES/AUDITOR.md（常规审计；必须远端核验 + Workflow Hygiene）

C) Phase 真值（必须唯一化）
- docs/PHASES.yml（推荐作为唯一 phase truth）
- 说明：若保留 docs/SSOT/PHASES.md，则必须标注为镜像/Deprecated 并指向 docs/PHASES.yml；不得形成双真值。

D) PR 证据模板
- .github/pull_request_template.md（强制 Evidence + Linked SPEC + Reality Snapshot）

E) 仓库规则（与门禁一致）
- docs/RULES.yml（路径白名单/禁改区/auto-merge 策略等；必须与现实 workflows 策略一致）

三、明确不导入（禁止项）

- archive/（历史归档目录，统一留在旧仓库；新仓库只保留最小可运行资产）
- upstream-* / vendor 快照（上游导入快照、对比快照）
- oneclick/（若为旧版或重复实现，默认不导入；需要时以“模块化迁移任务”单独评估）
- skills/、.codex/skills/、训练材料/过程产物/临时脚本
- 大体积二进制、截图、导出包（如需保留，放 Release assets 或单独 docs-site，而不是主树）

四、导入后必须满足的“初始化门禁”（提醒：不是本步做，但这是验收标准）

- SSOT 真值唯一（PHASES/STATE/DECISIONS 不冲突）
- Workflow Hygiene：Actions 无噪音红叉（含 No jobs were run）
- PR/审计流程可跑通：required checks + 审计 PASS
- 哨兵能输出：Reality Snapshot + SSOT Snapshot + Drift Report + Fix Plan

（EOF）