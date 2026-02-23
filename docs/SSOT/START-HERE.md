# START HERE

本仓库 SSOT 的默认审计模式为 **mode=routine**。只有当 **Commander 明确声明 `mode=milestone`** 时，才触发 **P0 对齐审计**（milestone-gated）。

Hard Truth 只认 **本次 Evidence Pack 的原样命令输出**（verbatim outputs）。  
若 Evidence Pack 缺失某项硬输出，则该项结论必须标为 **UNKNOWN**，不得用 GitHub 网页 UI 作为替代真值来源。

## Entry Points
- STATE: [docs/SSOT/STATE.md](./STATE.md)
- DECISIONS: [docs/SSOT/DECISIONS.md](./DECISIONS.md)
- SENTINEL: [docs/SSOT/ROLES/SENTINEL.md](./ROLES/SENTINEL.md)
- COMMANDER: [docs/SSOT/ROLES/COMMANDER.md](./ROLES/COMMANDER.md)

## How to use
- 复制模板并填写 Evidence Pack：见 [docs/SSOT/EVIDENCE-PACK.template.md](./EVIDENCE-PACK.template.md)
