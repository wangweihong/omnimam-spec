# OmniMAM Spec Handoff

## 当前项目目标

`spec-v1.7.3` 已发布，Task Center 系统任务名称多语言兼容契约已成为 Server 实现 `name_i18n` 与名称来源持久化的正式依据。

## 本次完成

1. 新增 `US-TASK-024`、`BR-TASK-142` 和 4 项验收标准，定义系统名称与用户名称的边界。
2. Task Center OpenAPI 升级到 1.4.0，增加可扩展 `LocalizedName` 及资源本体/一跳摘要的多语言字段。
3. 四类任务资源增加名称来源、系统 key 和参数设计态字段及一致性约束。
4. 模块契约和架构增加 name-catalog，明确统一投影和传递边界。
5. 更新 CHANGELOG；用户原有 `AGENTS.md` 修改保持不变，不纳入本次发布。
6. 规格变更提交为 `ab677e7`，用户确认的 `spec-v1.7.3` release 记录、标签和远端分支已同步。

## 文件变化

- 修改 Task Center S1、OpenAPI、schema、module contract 和领域架构。
- 修改 `CHANGELOG.md`、`RELEASE.md` 和本文件。
- 无错误码、权限码或事件契约变化。

## 关键设计决策

- 原 `name` 继续保留；系统名称的 `name` 使用 `en-US` 兼容值。
- 系统名称以稳定 key 和小型受控字符串参数保存，查询时生成当前目录的全部 BCP 47 语言。
- 首期 `name_i18n` 必含 `zh-CN` 和 `en-US`，不依赖 `Accept-Language`。
- 用户自定义名称及无元数据的历史资源不返回译文；不按文本或 createdBy 启发式回填。

## API、Schema 与配置变化

- Task Center OpenAPI 版本为 1.4.0。
- 新增 `LocalizedName`，资源与摘要增加可选 `name_i18n`。
- `ScheduleSourceSummary` 增加 `schedule_name_i18n`；`DAGTimelineRow` 增加 `atomic_task_name_i18n`。
- `atomic_tasks`、`task_groups`、`dag_task_groups`、`task_schedules` 增加 `name_source`、`system_name_key`、`system_name_params_json`。

## 待办与风险

- Server 尚需 pin 新 release，实现 name catalog、migration、内部创建元数据传递和所有查询摘要投影。
- 旧资源不会自动获得多语言名称，这是已确认的安全兼容策略。
- 公开创建请求必须无法注入系统名称 key/参数。

## 推荐下一任务

在 `omnimam-server` 更新 spec submodule 与 `SSOT_VERSION`，实现 Task Center 系统名称目录、持久化字段、完整响应投影与兼容测试。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
