# OmniMAM Spec Agent Rules

本仓库是 OmniMAM 的规格仓库，负责维护 S0、S1、S2 相关制品。

详细规则不写在顶层 `AGENTS.md` 中，避免顶层规则过长。


## 必读 Skill

任何修改本仓库内容前，必须读取：

```text
skills/spec-workflow/SKILL.md
```

该 Skill 定义：

```text
S0 原型沉淀规则
S1 产品语义事实源规则
S2 实现契约事实源规则
目录结构
编号规范
Mermaid 可视化规则
Release 规则
冲突处理规则
禁止事项
```

## 仓库边界

本仓库只维护：

```text
00_product/       # S1 产品语义事实源
01_contracts/     # S2 实现契约事实源
02_architecture/  # 架构参考
domains/          # 领域上下文摘要与导航，不是 SSOT
GLOBAL_CONTEXT.md # 全局上下文摘要
CONTEXT_MAP.md    # 任务到最小文档集合的导航
README.md         # 仓库和 AI Context 入口
CHANGELOG.md
RELEASE.md
```

本仓库禁止维护：

```text
正式前端实现代码
正式后端实现代码
实际数据库 migration
运行时配置
CI/CD 实现细节
```

## 输出语言

除代码、路径、字段名、协议名、枚举值、API 路径、SQL、YAML、Mermaid 等技术内容外，说明性文本默认使用中文。

## Spec Context Loading

处理任务时禁止默认读取整个 Spec 仓库，按以下顺序加载最小上下文：

1. 读取 `GLOBAL_CONTEXT.md`。
2. 在 `CONTEXT_MAP.md` 中定位任务涉及的领域。
3. 读取对应的 `domains/<domain_id>/context.md`。
4. 根据 Domain Context 的“正式事实源”读取 1～3 个必要文件。
5. 只有发现明确跨域依赖时，才读取直接相关的第二个领域。
6. 不读取与任务无关的归档、历史文档、全部 S1/S2 或其他领域。
7. Context 文件只用于摘要和导航，不得作为最终事实源。

Context 维护触发条件：

- 正式 Spec 增加、删除或重命名核心对象，或改变领域职责、边界、核心规则、状态和事实源路径时，同步更新对应 Domain Context。
- 项目目标、一级领域、全局架构、跨域事实归属、项目阶段或全局非目标变化时，更新 `GLOBAL_CONTEXT.md`。
- 领域目录、文档入口、常见任务关键词或跨域读取关系变化时，更新 `CONTEXT_MAP.md`。
- 普通字段、文案和示例调整不要求更新 Context。
- 修改 Context 不得反向改变或补造 S1/S2 事实。

## 修改原则

修改任何 domain 时，必须优先定位：

```text
00_product/domains/<domain_id>/product-spec.md
01_contracts/domains/<domain_id>/
02_architecture/domains/<domain_id>.md
```

涉及产品语义时，先改 S1。

涉及接口、schema、错误码、权限码、事件或模块边界时，改 S2。

如果 S2 变更会影响产品语义，必须同步更新 S1。

正式 Spec 变更满足上述 Context 触发条件时，还必须同步更新对应 Context。是否允许作为正式实现依据仍只由 `RELEASE.md` 中的用户确认记录决定。

## 最终规则

```text
顶层 AGENTS.md 只做路由和边界声明。
完整 SSOT / Spec 工作流规则见 skills/spec-workflow/SKILL.md。
```

# Completion & Handoff Rules

These rules are mandatory for every task.

## 1. Handoff Is a Live Checkpoint

`docs/HANDOFF.md` is not only a final summary. It must be updated throughout the task so work can resume after context compression, interruption, or a new session.

Update it:

* At the start of every non-trivial task.
* After each meaningful implementation milestone.
* After important design, API, schema, configuration, or file changes.
* When a blocker, failed approach, risk, or technical debt is discovered.
* Before large or high-risk changes.
* Whenever the context is becoming large or may be compressed.
* Before declaring the task complete.

Do not allow significant completed work to remain undocumented.

## 2. Required Content

Keep `docs/HANDOFF.md` concise and reflect the current project state.

It must contain:

* Current goal and status.
* Work completed in this session.
* Current in-progress work.
* Files added, modified, renamed, or removed.
* Key architectural or design decisions.
* API, schema, dependency, or configuration changes.
* Verification performed and remaining checks.
* Outstanding tasks.
* Known issues and risks.
* Exact recommended next step.

For unfinished work, record the last successful action and the exact next file, command, or implementation step.

Never describe unverified or partial work as completed.

## 3. Task Completion

Before declaring a task complete:

1. Finish the implementation.
2. Run relevant tests, builds, linting, or manual verification.
3. Update affected project documentation.
4. Refresh `docs/HANDOFF.md`.
5. Confirm the handoff matches the actual repository state.

## 4. Handoff Maintenance

Keep the handoff actionable and free of obsolete history:

* Remove outdated information.
* Move finished items out of the in-progress section.
* Preserve unresolved blockers and risks.
* Use exact file paths, function names, commands, and API names.
* Do not claim changes or verification that were not actually performed.

Always end `docs/HANDOFF.md` with:

```text
Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
```
