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

- Fixed Read Set (18) — see docs/SSOT/START-HERE.md
- Core naming:
  - Blueprint = docs/SSOT/一键安装构思.md
  - Playbook = docs/SSOT/一键安装流程机制.md
  - Framework = docs/SSOT/1click核心执行框架 + 必要文档.md
- 唯一入口为 docs/SSOT/START-HERE.md；若存在 docs/SSOT/INDEX.md，则仅为 legacy redirect/deprecated，不作为真值入口。
- docs/SSOT/EVIDENCE-PACK.template.md（Evidence Pack 模板：verbatim 证据块结构）
- docs/SSOT/EVIDENCE/（RRC 证据产物落盘目录；用于保存每次 Evidence Pack 文件，不计入固定必读集合）
- 真值引用形式统一为 SHA-pinned raw（`raw/<MAIN_SHA>/...`）；`raw(main)` 仅可用于导航/发现，不得作为 truth validation。
- 历史 readset / handoff snapshot 只代表当时的 `MAIN_SHA`，不得被当作 evergreen truth 直接沿用到新一轮。

B) ROLES 合同（四角色 + 哨兵）
- docs/SSOT/ROLES/COMMANDER.md
- docs/SSOT/ROLES/PLANNER.md
- docs/SSOT/ROLES/EXECUTOR.md（必须包含 Evidence Pack 必填字段：PR URL/head SHA/checks/actions/tag 证据）
- docs/SSOT/ROLES/AUDITOR.md（常规审计；必须远端核验 + Workflow Hygiene）

## Unified Handoff Footer / 统一交接结尾格式

### A. Fixed Template / 固定模板

```text
STATUS: <PASS|STOP|FAIL|BLOCKED>
NEXT_ROLE: <role name>
NEXT_INPUT: <one-sentence instruction for the next role>
HANDOFF: 交给 <role name> / Hand off to <role name>
```

### B. Field Definitions / 字段说明

- STATUS：本轮状态，只允许 PASS / STOP / FAIL / BLOCKED  
  / Current execution state; only PASS / STOP / FAIL / BLOCKED are allowed.
- NEXT_ROLE：下一个接手角色  
  / The next role that should take over.
- NEXT_INPUT：给下一个角色的一句话输入，必须可直接复制  
  / One-sentence input for the next role; must be copy-paste ready.
- HANDOFF：显式交接提示，降低人工 copy/paste 出错风险  
  / Explicit handoff line to reduce copy/paste mistakes.

### C. Default Role Routing / 默认角色流转表

- Gemini → Planner
- Planner → Codex
- Codex → antigravity
- antigravity（PASS）→ Codex
- Codex（merge-closeout）→ 哨兵
- 哨兵 → 尚书房（GO） / Codex（FAIL or Fix Plan）
- 尚书房 → Gemini / Planner / Freeman（按决策）

这是默认流转，特殊情况可由 Commander/尚书房覆盖。  
/ This is the default handoff chain; exceptional routing may be overridden by Commander/尚书房.

### D. Usage Rules / 使用规则

- 每个角色回复的最后必须追加该 footer  
  / Every role response must end with this footer.
- 若需要人工处理，NEXT_ROLE 必须写 Freeman 或 尚书房  
  / If manual handling is required, NEXT_ROLE must be Freeman or 尚书房.
- 若审计失败，必须显式写回 Codex  
  / If audit fails, handoff must explicitly route back to Codex.

### E. Role-specific Default Routing / 角色默认执行路由

- 该 footer 不只是 generic format，还定义 Planner / antigravity / Sentinel 的默认执行路由。  
  / This footer is not only a generic format; it also defines the default execution routing for Planner / antigravity / Sentinel.
- Planner / antigravity / Sentinel 的输出结尾都 MUST 附上该 footer。  
  / Planner / antigravity / Sentinel outputs MUST end with this footer.
- footer 内容必须 copy/paste ready。  
  / The footer content must be copy-paste ready.

- Planner 默认成功流转如下：  
  / Planner default success routing is:

```text
STATUS: PASS
NEXT_ROLE: Codex
NEXT_INPUT: Execute exactly per SPEC with strict allowlist, Evidence Pack, and rollback.
HANDOFF: 交给 Codex / Hand off to Codex
```

- antigravity / Auditor 默认 PASS 流转如下：  
  / antigravity / Auditor default PASS routing is:

```text
STATUS: PASS
NEXT_ROLE: Codex
NEXT_INPUT: Perform merge-closeout with mergeability check, blocker evidence if blocked, post-merge hard truth, rollback, and handoff to Sentinel.
HANDOFF: 交给 Codex / Hand off to Codex
```

- antigravity / Auditor 默认 FAIL 流转如下：  
  / antigravity / Auditor default FAIL routing is:

```text
STATUS: FAIL
NEXT_ROLE: Codex
NEXT_INPUT: Perform the minimal repair, then return for re-audit.
HANDOFF: 交给 Codex / Hand off to Codex
```

- Sentinel 默认 GO 流转如下：  
  / Sentinel default GO routing is:

```text
STATUS: PASS
NEXT_ROLE: 尚书房
NEXT_INPUT: Decide closeout, next step, or next phase.
HANDOFF: 交给 尚书房 / Hand off to 尚书房
```

- Sentinel 默认 FAIL / STOP 流转如下：  
  / Sentinel default FAIL / STOP routing is:

```text
STATUS: FAIL
NEXT_ROLE: Codex
NEXT_INPUT: Fix according to the Fix Plan and resubmit.
HANDOFF: 交给 Codex / Hand off to Codex
```

这是默认流转，不是唯一可能流转。特殊情况可由 Commander / 尚书房覆盖。  
/ This is the default handoff chain; exceptional routing may be overridden by Commander / 尚书房.

### F. Merge-closeout ownership / 合并收口归属

- antigravity 审计 PASS 后，默认由 Codex 执行 merge-closeout。  
  / After antigravity returns PASS, Codex owns merge-closeout by default.
- merge-closeout 至少包括：mergeability check、normal merge / auto-merge preferred、blocker evidence if blocked、admin bypass only when necessary and explicitly recorded、post-merge hard truth、merge facts、rollback、以及交接给 Sentinel。  
  / Merge-closeout must include at minimum: mergeability check, normal merge / auto-merge preferred, blocker evidence if blocked, admin bypass only when necessary and explicitly recorded, post-merge hard truth, merge facts, rollback, and handoff to Sentinel.

### G. Post-merge routine closeout / 合并后例行收口

- Codex 完成 merge-closeout 后，默认交由 Sentinel 执行 post-merge routine RRC 与 formal closeout。  
  / After Codex completes merge-closeout, Sentinel is the default role for post-merge routine RRC and formal closeout.

### Routing stage separation / 路由阶段分离

- antigravity 是默认的 pre-merge audit 角色。  
  / antigravity is the default pre-merge audit role.

- antigravity 审计 PASS 后，默认交由 Codex 执行 merge-closeout。  
  / After antigravity returns PASS, the default routing is antigravity -> Codex for merge-closeout.

- Codex 默认负责 merge-closeout。  
  / Codex owns merge-closeout by default.

- merge-closeout 至少包括：mergeability handling、normal merge / auto-merge preferred、explicit blocker evidence if blocked、admin bypass only when necessary and explicitly recorded、post-merge hard truth、merge facts、rollback、以及交接给 Sentinel。  
  / Merge-closeout must include at minimum: mergeability handling, normal merge / auto-merge preferred, explicit blocker evidence if blocked, admin bypass only when necessary and explicitly recorded, post-merge hard truth, merge facts, rollback, and handoff to Sentinel.

- Codex 完成 merge-closeout 后，默认交给 Sentinel。  
  / After Codex merge-closeout, the default routing is Codex -> Sentinel.

- Sentinel 是默认的 post-merge routine closeout 角色。  
  / Sentinel is the default post-merge routine closeout role.

### single-PR / dual-PR closeout mode / 单 PR 与双 PR 收口模式

- single-PR is the default execution and closeout mode.  
  / single-PR 是默认的执行与收口模式。

- dual-PR is allowed only when a separate docs-only closeout PR is genuinely needed.  
  / 只有在确实需要单独的 docs-only closeout PR 时，才允许 dual-PR。

- Example: the implementation PR is merged first, but STATE / JOURNAL / EVIDENCE closeout must be recorded in a separate docs-only closeout PR.  
  / 例如：implementation PR 先合并，而 STATE / JOURNAL / EVIDENCE 的收口需要在单独的 docs-only closeout PR 中记录。

- Even in dual-PR mode, both steps remain inside Codex merge-closeout.  
  / 即使在 dual-PR 模式下，这两个步骤仍然都属于 Codex merge-closeout。

- dual-PR does NOT create a new role or a new default routing chain.  
  / dual-PR 不会创建新的角色，也不会创建新的默认流转链。

- antigravity still audits the implementation PR before merge.  
  / antigravity 仍然只在 implementation PR 合并前执行审计。

- Codex then handles: implementation PR merge-closeout; docs-only closeout PR if needed; post-merge hard truth / evidence / rollback; final closeout goes to Sentinel.  
  / 然后由 Codex 负责：implementation PR 的 merge-closeout；如有需要，再处理 docs-only closeout PR；post-merge hard truth / evidence / rollback；最终交给 Sentinel 做 final closeout。

- Regardless of single-PR or dual-PR mode, final closeout goes to Sentinel.  
  / 无论是 single-PR 还是 dual-PR 模式，最终的 routine closeout 都交给 Sentinel。

- Sentinel may append a fixed Commander handoff block only after the full task is fully closed.  
  / Sentinel 只有在整个任务 fully closed 之后，才可以追加固定的 Commander handoff block。

- In dual-PR mode, this means the implementation PR and the docs-only closeout PR (if used) are both merged and aligned.  
  / 在 dual-PR 模式下，这意味着 implementation PR 与 docs-only closeout PR（如果使用）都已经合并并完成对齐。

### Flow boundary clarification / 流程边界澄清

- docs-only governance repair flow 只用于修补 SSOT / governance 文案、truth-entry、模板或流程说明。  
  / docs-only governance repair flow is only for SSOT / governance wording, truth-entry, template, or workflow clarification repairs.

- project execution flow 才用于 implementation / verification / merge-closeout / task closure。  
  / project execution flow is the one used for implementation / verification / merge-closeout / task closure.

- docs-only governance repair 合并后，默认回到 Commander / START-HERE 重新进入 project execution flow。  
  / After a docs-only governance repair is merged, the default return target is Commander / START-HERE before re-entering project execution flow.

### Sentinel routine scope clarification / Sentinel routine 范围澄清

- The default Sentinel routine mode is a narrow single-PR gate review.  
  / 默认的 Sentinel routine 模式是窄范围的单 PR gate review。

- Broader remote-reality inventory is optional, not default.  
  / 更宽的 remote-reality inventory 是可选项，不是默认项。

- The operator may explicitly request broader inventory when needed.  
  / 如有需要，operator 可以显式要求更宽的 inventory。

### H. Minimal failure record / 最小失败记录约定

```text
FAILURE_RECORD:
- context: <task / PR / phase / role>
- step: <which step failed>
- symptom: <what failed>
- cause_status: <confirmed / suspected / unknown>
- cause: <brief cause>
- disposition: <fixed / deferred / wontfix / noise>
- repro: <yes / no>              # optional
- followup: <issue / PR / none>  # optional
```

- 不是每个 failure 都要单独开 issue。  
  / Not every failure needs a separate issue.
- 轻量执行失败可留在 Evidence Pack / audit note / closeout note。  
  / Lightweight execution failures may stay in the Evidence Pack / audit note / closeout note.
- 治理 / 政策 / 安全 / 重复性结构失败应升级为 follow-up。  
  / Governance / policy / security / repeated structural failures should be escalated as follow-up work.

### I. Sentinel GO Continuation Prompt / Sentinel GO 延续提示

- 在 Sentinel GO 结果之后，输出 SHOULD 追加一个固定的 Commander handoff block，而不是 generic free-text continuation。  
  / After a Sentinel GO result, the output SHOULD append a fixed Commander handoff block, not a generic free-text continuation.
- 该 Commander handoff block MUST 使用最新 MAIN_SHA 与最新 handoff evidence 路径。  
  / The Commander handoff block MUST use the latest MAIN_SHA and the latest handoff evidence path.
- 该 Commander handoff block 用于降低操作者 copy/paste 风险，并平滑启动下一轮。  
  / The Commander handoff block is meant to reduce operator copy/paste risk and smoothly start the next round.
- Sentinel GO 的默认流转仍然是尚书房；continuation prompt 只是 operator convenience block，不替代 footer。  
  / Default Sentinel GO routing still goes to 尚书房; the continuation prompt is only an operator convenience block and does not replace the footer.
- 只有在任务 fully closed 后，才可以追加该 Commander handoff block。  
  / This Commander handoff block may be appended only after the task is fully closed.

示例 / Example:

```text
MAIN_SHA=<latest MAIN_SHA>
LATEST_HANDOFF_EVIDENCE=docs/SSOT/EVIDENCE/<latest_handoff_evidence>.md
ROLE: COMMANDER
TASK: Define the next task for Planner from the current main SHA and latest handoff evidence.
STATUS: PASS
NEXT_ROLE: Planner
NEXT_INPUT: Read MAIN_SHA and LATEST_HANDOFF_EVIDENCE above, then define the next task with strict allowlist, verification, and rollback.
HANDOFF: 交给 Planner / Hand off to Planner
```

### J. Commander Final Authority / 尚书房最高裁决权

- 尚书房是该流程的 final authority。  
  / 尚书房 is the final authority in this workflow.
- 尚书房 MAY 在任意步骤 intervene。  
  / 尚书房 MAY intervene at any step.
- 尚书房 MAY override 默认流转链。  
  / 尚书房 MAY override the default routing chain when necessary.
- 除非尚书房明确 override，否则默认流转继续生效。  
  / Default routing still applies unless overridden by 尚书房.
- 正常执行中尚书房不必介入，但其 authority 必须保持显式。  
  / 尚书房 does not need to intervene in normal execution, but its authority must remain explicit.

C) Phase 真值（必须唯一化）
- docs/PHASES.yml（唯一 phase truth）
- 说明：若保留 docs/SSOT/PHASES.md，则必须标注为镜像/Deprecated 并指向 docs/PHASES.yml；不得形成双真值。

D) PR 证据模板
- .github/pull_request_template.md（强制 Evidence + Linked SPEC + Reality Snapshot）
- 如发现 JOURNAL 出现在 git status，MUST 按下文两种路径处理；不得混入无关 PR。

E) 门禁细则引用（避免与 Playbook 重复）
- 本文件不重复定义阶段门禁、Stop/Go、DoD、Release Blockers 细则。
- 上述执行细则统一以《docs/SSOT/一键安装流程机制.md》为准，本文件仅保留入口与落地路径。
- docs/RULES.yml、required checks、审计口径如需调整，也由 Playbook + DECISIONS 统一收敛后回引。

F) JOURNAL 自动机制（必须启用）
- hooks + 脚本：`.githooks/post-commit` 与 `scripts/journal_append.sh` 自动追加 `docs/SSOT/JOURNAL.md`（append-only）。
- JOURNAL 旧条目禁止手工修改；如需记录操作者身份，统一映射为 `Pork-Belly`（不得出现 `freeman`；历史 `Pork- Belly` 仅视为 legacy alias）。

## JOURNAL auto-stage: how to avoid PR contamination

现状说明（MUST 知悉）：
- `.githooks/post-commit` 会自动追加并 `git add docs/SSOT/JOURNAL.md`（append-only）。
- 因此 `docs/SSOT/JOURNAL.md` 可能进入 staged，从而污染 docs-only / 单主题 PR。

路径 1：本 PR 不包含 JOURNAL（最常见，MUST 执行）
- 命令（逐字执行）：
  - `git restore --staged docs/SSOT/JOURNAL.md || true`
  - `git restore docs/SSOT/JOURNAL.md`
  - `git status --porcelain`
- 门禁（MUST）：
  - `git status --porcelain` 必须为空才允许继续 commit/PR。

路径 2：本 PR 专门提交 JOURNAL（仅当明确需要落盘连续性日志）
- MUST 使用单独分支 / 单独 PR / 单主题。
- PR MUST 仅包含 `docs/SSOT/JOURNAL.md`。
- commit message MUST 包含 `captured_at_utc` 与 `role`。
- actor 映射 `Pork-Belly` 的规则 SHALL 保持不变（历史 `Pork- Belly` 仅作 legacy alias；仅陈述，不改机制）。

G) RRC 证据落地（执行口径）
- 每次 RRC 证据文件落盘路径：`docs/SSOT/EVIDENCE/`。
- 文件命名与双锚定判定规则遵循 Playbook 与 EVIDENCE-PACK.template，不在本文件重复展开。
- 新对话接手时：先读 START-HERE 指向的必读集合，再读取最新一份 evidence 文件。
- Evidence MUST be captured via `scripts/ev_capture.sh` (or equivalent) to avoid UI noise; do not paste terminal selections that may include `<user__selection>`.
- 示例：
  - `./scripts/ev_capture.sh /tmp/ev_main_ls.txt -- git ls-remote https://github.com/Hello-Pork-Belly/1click.git refs/heads/main`
  - `./scripts/ev_capture.sh /tmp/ev_pr.json -- gh pr view <N> -R Hello-Pork-Belly/1click --json number,state,mergedAt,mergeCommit,url`

## Auto-Handoff v1 (local, hourly)

- 目的：在 mode=routine 下做定时对账，只有 main_sha 变化时才生成 handoff evidence 并发起 docs-only PR。
- 执行方式：`tools/local/launchd/com.1click.handoff.plist` 每小时触发（`StartInterval=3600`），调用 `scripts/handoff_capture.sh --auto-pr`。
- Runbook: `docs/SSOT/RUNBOOK-AUTO-HANDOFF-LAUNCHD.md`
- 在重启或权限变更后，MUST 先执行 Runbook 的 Verify 命令，再继续项目执行。
- MAIN_SHA 真值来源 MUST 为 `gh api repos/<repo>/commits/main --jq .sha`，并与 `git ls-remote ... refs/heads/main` 一致；不一致则 MUST STOP/BLOCKED。
- 降噪要求：last_sha 状态文件 MUST 存储在 git 外部（`~/.cache/1click/handoff_last_sha`），用于“仅在 MAIN_SHA 变化时”触发。
- 新对话接手顺序 MUST 为：
  1) `docs/SSOT/START-HERE.md`
  2) Fixed Read Set (18)
  3) `docs/SSOT/EVIDENCE/*_handoff.md` 中最新文件（按文件名 UTC + main_sha）
- 读取规则 MUST 使用 SHA-pinned raw（`raw/<MAIN_SHA>/...`）；`/main/` 仅可导航，不得作为验收真值。
- 历史锚点示例（例如 `MAIN_SHA=42b69e8341162d23191946d5cdd72307cbd67ccf`）仅用于说明格式；每次消费时 MUST 先用本轮 `(1)(2)` 重新确定 then-current `MAIN_SHA`，不得把旧 snapshot 当作当前真值。

## Cleanup policy (dry-run first)

- Runbook: `docs/SSOT/RUNBOOK-CLEANUP.md`
- 默认不删除历史；MUST 先执行 `./scripts/cleanup_plan.sh --repo Hello-Pork-Belly/1click` 生成 dry-run 计划与证据，再由 Commander 决定是否进入 apply。
- 当前行为说明：handoff PR 默认以 draft 形式创建，用于降噪与人工决策合并。

## Audit-only preflight guard (MUST)

- 在任何审计动作开始前 MUST 先运行：`./scripts/audit_guard.sh`（在 audit worktree 中执行）。
- 若 guard 输出 FAIL，SHALL 立即停止审计并先修复，再重新运行直到 PASS。
- 最短修复命令（按失败项执行）：
  - `git config core.hooksPath /dev/null`
  - `git restore --staged docs/SSOT/JOURNAL.md || true`
  - `git restore docs/SSOT/JOURNAL.md`
  - `git restore --staged . && git restore .`
  - `git fetch --all --prune`
  - `git reset --hard origin/main`
  - `git checkout wt/audit`

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
