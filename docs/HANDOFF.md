# OmniMAM Spec Handoff

## 当前目标与状态

- 当前目标：修复 AppStudio Outbox 全局唯一键与事件幂等键之间的已发布冲突，发布 `spec-v1.16.1`，并为 Server 实现提供正式依据。
- 状态：Release 记录编制中。契约修复提交为 `7ec33b70abbbe15b1295fb4fb5ae14423e49422d`，用户已明确要求发布、打 annotated tag 并推送。

## 本次已完成

- 已读取 `skills/spec-workflow/SKILL.md` 与 `S2.md`，并按最小上下文读取 AppStudio Context、`events.yaml`、`schema.sql`、`CHANGELOG.md` 和 `RELEASE.md`。
- 已确认 `studio_application_lifecycle_changed` 与首次 `studio_source_revision_changed` 都可能生成 `studio_application_id:1`，违反 `appstudio_outbox.idempotency_key` 的单列全局 `UNIQUE` 约束。
- 已确定修复规则：七类事件键统一为 `<event_type>:<domain_key_components>`，保留现有全局唯一约束。
- 已确定不修改 S1、不新增数据库字段或 migration、不回填历史 Outbox；旧键只随既有事件保留。
- 已将七类 AppStudio 事件幂等键改为以事件名开头的全限定键。
- 已在 `schema.sql` 补充全局唯一语义注释，保留现有 `TEXT NOT NULL UNIQUE` 定义。
- 已更新 `CHANGELOG.md`、AppStudio Domain Context、`GLOBAL_CONTEXT.md` 和 `CONTEXT_MAP.md`，修正 Agent/AppStudio 已由 `spec-v1.16.0` 发布的状态。
- 已通过 PyYAML 解析并断言七个事件键的事件名前缀和领域组件完全匹配计划。
- 已断言 `appstudio_outbox.idempotency_key TEXT NOT NULL UNIQUE` 仍仅出现一次，并通过 `git diff --check`。
- 已创建契约修复提交 `7ec33b70abbbe15b1295fb4fb5ae14423e49422d`，仅包含本任务七个文件，无关未跟踪内容未暂存。
- 已编制 `spec-v1.16.1` Release 记录，覆盖 AppStudio `events.yaml`、`schema.sql` 和 `permissions.yaml`，并写明无 migration、无历史 Outbox 改写门禁。

## 当前进行中

- 校验 Release 记录和 Context，创建 Release 提交、annotated tag 并推送。

## 文件变化

- 已修改：`01_contracts/domains/appstudio/events.yaml`、`01_contracts/domains/appstudio/schema.sql`、`domains/appstudio/context.md`、`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、`CHANGELOG.md`、`docs/HANDOFF.md`。
- Release 阶段已修改：`RELEASE.md`、`docs/HANDOFF.md`、`domains/appstudio/context.md`、`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`。
- 不修改：S1、实际 migration、正式前后端实现代码和无关领域。

## 关键决定

- `appstudio_outbox.idempotency_key` 继续保持跨事件类型全局唯一。
- 事件类型是幂等键命名空间的一部分，避免不同事件类型复用相同领域组件时冲突。
- `spec-v1.16.1` implementation gate 明确无 migration、无历史 Outbox 改写，新旧键允许共存。
- `permissions.yaml` 内容不改，但纳入本次 Release，作为 Server 权限资源映射的正式实施依据。

## API、Schema、依赖或配置变化

- 仅调整事件幂等键契约和 Schema 注释，不改变表结构、约束、API、依赖或运行时配置。

## 验证与风险

- 已执行：目标 YAML 解析、七个键格式与组件断言、Outbox `UNIQUE` 保留断言、过期状态检查和 `git diff --check`，全部通过。
- 风险：历史 Outbox 不回填，新旧键并存；消费者必须按事件行自身携带的幂等键处理。
- 后续风险：`SourceContentStore` 与数据库的跨存储原子性不在本次范围内，禁止通过失败后直接删除 Revision 目录处理。

## 未完成事项

- 创建 Release 提交、annotated tag `spec-v1.16.1` 并推送。
- 使用 Release 提交更新 Server 的 `ssot` pin 和 `SSOT_VERSION`。

## 推荐下一步

- 校验 Release 记录与 Context，创建 Release 提交并打 annotated tag `spec-v1.16.1`。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
