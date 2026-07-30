# OmniMAM Spec

本仓库维护 OmniMAM 的 S1 产品语义、S2 实现合同和架构参考。仓库规则入口见 `AGENTS.md` 与 `skills/spec-workflow/SKILL.md`。

## AI Context Entry

AI 或开发者处理 Spec 任务时，按以下顺序读取：

1. `GLOBAL_CONTEXT.md`
2. `CONTEXT_MAP.md`
3. `CONTEXT_MAP.md` 给出的目标领域具体 Context
4. `context.md` 指向的 1～3 个必要正式 Spec 文件

除非任务明确涉及全局重构，否则不要递归读取整个仓库、全部领域或归档文档。

## Context Files Are Not SSOT

`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md` 和各领域 `context.md` 仅用于导航和摘要，不是新的事实层。

- 产品语义和业务规则以对应 S1 为准。
- API、设计态 Schema、错误码、权限码、事件和模块边界以对应 S2 为准。
- S1 与 S2 冲突时必须修复正式 Spec，不能由 Context 选择一方覆盖另一方。
- 架构参考、Domain Context、Global Context 和 handoff 都不得替代 S1/S2。
- 是否允许作为正式实现依据以 `RELEASE.md` 的用户确认记录为准。

## Repository Layout

| 路径 | 用途 |
| --- | --- |
| `00_product/` | S1 产品语义事实源 |
| `01_contracts/` | S2 实现契约事实源 |
| `02_architecture/` | 架构参考 |
| `domains/` | 领域上下文摘要与导航 |
| `GLOBAL_CONTEXT.md` | 全局稳定上下文 |
| `CONTEXT_MAP.md` | 任务到最小文档集合的映射 |
| `RELEASE.md` | 用户确认的正式版本记录 |
| `CHANGELOG.md` | 已发布和未发布变更记录 |
