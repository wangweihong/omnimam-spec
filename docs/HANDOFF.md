# OmniMAM Spec Handoff

## 当前目标与状态

- 当前目标：统一 `StudioBuild` 作为 Asset Library Artifact 的正式受信 producer，并补齐 AppStudio owner/一跳摘要投影契约。
- 状态：已完成。正式 S1/S2、Context 与变更记录已更新，定向结构化校验与差异检查均已通过。

## 本次已完成

- 已读取 `skills/spec-workflow/SKILL.md`、`S1.md` 和 `S2.md`。
- 已确认 `Task Center function-registry.yaml` 已使用 `producer_type: studio_build`、`arguments.studio_build_id` 与 `studio-build:{arguments.studio_build_id}:bundle`，本任务不修改该文件。
- 已确认 Asset Library 当前 OpenAPI 枚举与数据库 CHECK 缺少 `studio_build`，AppStudio 当前没有 Build 批量摘要 API。
- 已确认 `studio_builds.owner_user_id` 是 canonical Artifact owner 来源。
- 已更新 Asset Library S1 的 Artifact 定义、创建流程、第一阶段验收、`BR-USER-ASSET-66/67/80` 和 `US-USER-ASSET-42`，明确 StudioBuild producer、owner、幂等与 owner-only 可见性。
- 已更新 AppStudio S1 的 StudioBuild 字段、Build 流程、权限模型、Artifact 集成、`R-STUDIO-018` 和既有验收项，明确受控批量摘要与委托授权链路。
- 已更新 Asset Library OpenAPI 的共享 `ArtifactProducerType`、StudioBuild 字段语义和 SQL CHECK，并同步 module contract 与 `asset.artifact.create/read` enforcement。
- 已新增 AppStudio `POST /api/v1/studio-builds/batch-summaries` 及严格字段投影 schema，并同步 module contract、`appstudio.build.manage` enforcement 和 schema 注释。
- 已更新 `domains/asset-library/context.md`、`domains/appstudio/context.md`、`CONTEXT_MAP.md` 与 `CHANGELOG.md`；`GLOBAL_CONTEXT.md`、`RELEASE.md` 保持不变。
- 已完成目标 YAML 解析、本地 `$ref`、producer 枚举、SQL CHECK、批量摘要 API、Task Center 锚点、六个权限/幂等场景及差异范围校验。

## 当前进行中

- 无。

## 文件变化

- 已修改：`docs/HANDOFF.md`；Asset Library 与 AppStudio 的 S1 product spec、S2 OpenAPI/module contract/permissions；Asset Library schema；AppStudio schema 注释；两个 Domain Context；`CONTEXT_MAP.md`；`CHANGELOG.md`。
- 明确不修改：`GLOBAL_CONTEXT.md`、`RELEASE.md`、Task Center Function Registry、实现代码、数据库 migration。
- 未处理的原有未跟踪内容：`archive/`、`docs/identity_fix.md`、`设计图/`。

## 关键决定

- `producer_type=studio_build`，`producer_id=StudioBuild.id`，幂等键为 `studio-build:<studio_build_id>:bundle`。
- Artifact owner 取 `StudioBuild.owner_user_id`；Artifact 继续 owner-only，Build `authorized_editor` 不继承 Artifact 权限。
- 自动 TaskAttempt 重试复用同一 producer key；新的逻辑构建必须创建新的 StudioBuild ID。
- AppStudio 提供受控批量 Build producer 投影；Asset Library 禁止读取 AppStudio 私表。
- producer 不存在或不可见时保留 `producer_id` 并返回 `producer=null`，不得泄露原因差异。

## API、Schema、依赖或配置变化

- 已新增 `POST /api/v1/studio-builds/batch-summaries`，请求 1 至 200 项并保持响应顺序；不存在或对委托用户不可见的项返回 `studio_build=null`。
- 投影字段限制为 `id`、`owner_user_id`、`name`、`status`。
- Asset Library `ArtifactProducerType` 已统一为 `application_run | canvas_run | atomic_task | studio_build`，由四个 producer 类型入口复用。
- Asset Library schema 仅扩展 `producer_type` CHECK，不建立跨域外键。
- Task Worker 创建 Artifact 时携带受信服务身份和原任务 `authorization_ref`；Asset Library 使用 AppStudio 投影解析 canonical owner。

## 验证与风险

- PyYAML 已成功解析 5 个目标 YAML。
- Asset Library OpenAPI 的 256 个本地 `$ref` 和 53 个唯一 `operationId` 校验通过；AppStudio OpenAPI 的 149 个本地 `$ref` 和 34 个唯一 `operationId` 校验通过。
- 四个 OpenAPI producer 类型入口与 SQL CHECK 的枚举一致，且未新增重复的 `studio_build_id` 字段。
- AppStudio 批量摘要 API 的 1/200 边界、顺序保持、nullable 结果和字段白名单均通过。
- Task Center Function Registry 锚点和六个 owner、伪造拒绝、幂等重试、新 Build、新旧权限、不可见摘要场景静态核对通过。
- 首次静态场景检查因检查脚本定位错误而失败；修正检查定位后首次重试通过，规格文件无需因此修改。
- `git diff --check`、变更范围检查及目标 S1/S2 最终人工差异审查通过；按约束未运行全仓测试。
- 已知风险：这些 S1/S2 变更尚未经用户 release 确认，不能作为正式实现或发布依据。

## 未完成事项

- 无。本任务未包含提交、发布或更新 `RELEASE.md`。

## 推荐下一步

- 由用户评审本次 S1/S2 差异；确认后按 Release 流程更新 `RELEASE.md`，再进入实现仓库适配。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
