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

- docs/SSOT/一键安装构思.md（总纲；canonical）
- docs/SSOT/START-HERE.md（SSOT 入口索引：列出真值文件、用途、以及“唯一真值指向”）
- 单一入口声明：以 START-HERE 为准；若存在 docs/SSOT/INDEX.md，则仅作为 redirect/deprecated 使用（不作为并行真值入口）。
- docs/SSOT/EVIDENCE-PACK.template.md（Evidence Pack 模板：verbatim 证据块结构）
- docs/SSOT/一键安装流程机制.md（流程机制模板；含哨兵/门禁/证据包/回滚；canonical）
- docs/SSOT/STATE.md（Done/Doing/Next；唯一进度账本）
- docs/SSOT/DECISIONS.md（关键决策与契约记录）
- docs/SSOT/SPEC-TEMPLATE.md（任务规格模板：Inputs/Files/DoD/Rollback/Exit codes）
- docs/SSOT/JOURNAL.md（auto, append-only；新对话接手必读，配合 STATE/DECISIONS 做漂移归因）
- docs/BASELINE.md（硬要求清单：支持矩阵/第三方白名单/备份口径/日志口径/危险操作确认；作为门禁依据）
- docs/SSOT/EVIDENCE/（RRC 证据产物落盘目录；用于保存每次 Evidence Pack 文件，不计入固定必读集合）

B) ROLES 合同（四角色 + 哨兵）
- docs/SSOT/ROLES/COMMANDER.md
- docs/SSOT/ROLES/PLANNER.md
- docs/SSOT/ROLES/EXECUTOR.md（必须包含 Evidence Pack 必填字段：PR URL/head SHA/checks/actions/tag 证据）
- docs/SSOT/ROLES/AUDITOR.md（常规审计；必须远端核验 + Workflow Hygiene）

C) Phase 真值（必须唯一化）
- docs/PHASES.yml（唯一 phase truth）
- 说明：若保留 docs/SSOT/PHASES.md，则必须标注为镜像/Deprecated 并指向 docs/PHASES.yml；不得形成双真值。

D) PR 证据模板
- .github/pull_request_template.md（强制 Evidence + Linked SPEC + Reality Snapshot）

E) 门禁细则引用（避免与 Playbook 重复）
- 本文件不重复定义阶段门禁、Stop/Go、DoD、Release Blockers 细则。
- 上述执行细则统一以《docs/SSOT/一键安装流程机制.md》为准，本文件仅保留入口与落地路径。
- docs/RULES.yml、required checks、审计口径如需调整，也由 Playbook + DECISIONS 统一收敛后回引。

F) JOURNAL 自动机制（必须启用）
- hooks + 脚本：`.githooks/post-commit` 与 `scripts/journal_append.sh` 自动追加 `docs/SSOT/JOURNAL.md`（append-only）。
- JOURNAL 旧条目禁止手工修改；如需记录操作者身份，统一映射为 `Pork- Belly`（不得出现 `freeman`）。

G) RRC 证据落地（执行口径）
- 每次 RRC 证据文件落盘路径：`docs/SSOT/EVIDENCE/`。
- 文件命名与双锚定判定规则遵循 Playbook 与 EVIDENCE-PACK.template，不在本文件重复展开。
- 新对话接手时：先读 START-HERE 指向的必读集合，再读取最新一份 evidence 文件。

三、明确不导入（禁止项）

- archive/（历史归档目录，统一留在旧仓库；新仓库只保留最小可运行资产）
- upstream-* / vendor 快照（上游导入快照、对比快照）
- oneclick/（若为旧版或重复实现，默认不导入；需要时以“模块化迁移任务”单独评估）
- skills/、.codex/skills/、训练材料/过程产物/临时脚本
- 大体积二进制、截图、导出包（如需保留，放 Release assets 或单独 docs-site，而不是主树）

四、导入后验收（引用 Playbook）
- 初始化验收是否通过，统一按《docs/SSOT/一键安装流程机制.md》的 Phase 门禁与 DoD 判定。
- 本文件只负责“导入什么、放在哪、从哪里开始接手”，不承担门禁细则定义。

（EOF）
