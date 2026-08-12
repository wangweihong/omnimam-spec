# OmniMAM Spec Handoff

## 当前目标与状态

- 目标：定义并发布 AppStudio 第三阶段正式契约 `spec-v1.23.2`。
- 状态：进行中。第三阶段 S1/S2 已落盘，正在执行定向验证；尚未提交、打 tag 或推送。

## 本次已完成

- 基于已发布 `spec-v1.23.1` 和第三阶段方案完成差异分析。
- 锁定异步创建 DAG、GitLab Push/Pipeline Webhook、自动 Build/Artifact/Preview、生产 Release 权威和破坏性迁移边界。
- 确认创建成功保持 HTTP 200；Webhook token 只保存不可逆摘要；Snapshot 必须关联 canonical Revision。
- 已更新四个目标 Domain 的 Context/S1/S2，定义创建响应、Webhook API、Schema 字段、受信 DAG handler 和 web-backend profile 边界。

## 当前进行中

- 验证当前契约并发布 `spec-v1.23.2`。

## 文件变化

- Modified: AppStudio/GitLab/Task Center/Infrastructure 的直接相关 Context、S1、S2，`CHANGELOG.md` 和 `docs/HANDOFF.md`。
- 现有无关未跟踪目录和文档保持不变。

## 关键决定

- AppStudio 内部可提交含 `gitlab.pipeline.run` 的受信任 DAG，公共 Task Center DAG API 的门禁不变。
- GitLab CI 只负责构建 Bundle；Preview 由 Task Worker 使用固定 Revision SourceArchive 调用 Infrastructure。
- Production 继续使用 StudioRelease、Artifact 完整性门禁与 `appstudio.production.reconcile`。
- 不开放 `WEB_WITH_LIGHT_BACKEND`，只补齐已有 `appstudio.preview.web-backend` profile。

## API、Schema、依赖或配置变化

- 新增 `POST /api/v1/appstudio/webhook`、`dag_task_group_id` 创建响应、Snapshot Git 字段、Build Pipeline 字段、GitLab Project Hook ID/token digest，以及两个 Webhook 业务错误码。

## 验证与风险

- 已通过 `git diff --check`；其余定向校验待运行。
- 发布前必须确保无新增未定义 Blueprint、错误码、权限码或事件类型。

## 未完成事项

- 完成定向验证、提交、创建并推送 `spec-v1.23.2` tag。

## 推荐下一步

解析变更后的 YAML/OpenAPI，检查正式文件一致性，然后创建内容提交与 release 提交/tag。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
