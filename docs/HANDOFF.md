# OmniMAM Spec Handoff

## 当前目标与状态

- 目标：发布 AppStudio Coding Agent 持久化消息历史 facade、稳定消息 ID 归并和类型化 Invocation SSE 重放/关闭契约。
- 状态：`spec-v1.20.0` 已发布；发布分支与 annotated tag 已推送到 `origin`，可作为 Server/Web 正式实现依据。
- 基线：annotated tag `spec-v1.19.0`，release commit `aa3f843e6ad4987f0441d882bfa0d05e02e05065`。

## 本次已完成

- 已读取 Spec S1/S2 工作流规则，并确认只处理 Agent/AppStudio 当前 S1、S2、module contract 和直接相关 runtime protocol fixture。
- 已确认 Coding Agent 仍只允许由 AppStudio facade 暴露，不进入公共 Agent API。
- 已确认发布门禁：目标校验和草案提交完成后，必须取得用户明确确认，才能写入 release 元数据和创建 `spec-v1.20.0` tag。
- 已补齐 Agent S1 的 12 类统一 Invocation 事件 payload、持久化序号、恢复游标、无重复重放和终态关闭语义。
- 已补齐 AppStudio 当前 generation/session 消息 facade、稳定 `(created_at DESC, id DESC)` 分页和 Message ID 归并语义。
- 已新增 AppStudio GET 消息接口、消息 DTO/列表、Invocation `user_message_id/assistant_message_id` 和 12 类可判别 SSE envelope。
- 已同步 Agent/AppStudio module contract、Agent runtime protocol fixture 和 Unreleased changelog。
- 已完成目标 YAML/OpenAPI、本地引用、事件集合、S1 追溯和格式校验；`RELEASE.md` 未修改。
- 已创建 `feat(spec): define appstudio realtime agent stream` 草案提交；既有未跟踪内容未暂存。
- 用户已明确确认发布 `spec-v1.20.0`；已写入 `RELEASE.md` 正式发布记录。
- 已创建 release commit 与 annotated `spec-v1.20.0` tag，并推送发布分支和标签。

## 当前进行中

- 无；下游 Server/Web 正在更新 SSOT pin 并实施。

## 文件变化

- 内容提交 `7903d5d` 修改 Agent/AppStudio `product-spec.md`、`module-contract.md`，AppStudio `openapi.yaml`，Agent `runtime-protocol-fixtures.yaml`，`CHANGELOG.md`、`docs/HANDOFF.md`。
- 发布提交包含 `RELEASE.md` 和本 handoff 更新。
- 保留且不纳入提交：`archive/`、`docs/identity_fix.md`、`设计图/`。

## 关键决定

- 消息历史由 Agent Service 继续作为唯一事实来源，AppStudio 只提供当前应用、当前 Coding Agent generation/session 的受限 facade。
- 消息列表按 `(created_at DESC, id DESC)` 稳定分页；Invocation 通过 `user_message_id`、`assistant_message_id` 与历史和流式消息归并。
- SSE `id` 使用 Invocation 内递增十进制 `sequence_no`；`Last-Event-ID` 只接受非负十进制，并只重放更大序号。
- 终态事件发送并 flush 后关闭；已终态 Invocation 补完重放后立即关闭。

## API、Schema、依赖或配置变化

- 已新增 `GET /api/v1/studio-applications/{studio_application_id}/agent/messages`。
- 已定义 AppStudio 消息 DTO、分页响应、Invocation 稳定消息 ID 和 12 类类型化 SSE envelope。
- 不新增错误码、权限码、数据库表、公共 Agent API 或通用事件流事件。

## 验证与风险

- 已通过目标 YAML 解析、AppStudio OpenAPI 90 个本地 `$ref` 解析、消息/稳定 ID/cursor/12 类事件结构断言、S1 引用追溯、Redocly 目标 lint 和 `git diff --check`。
- Redocly 默认规则仍报告既有 `StudioBuildBatchSummaryItem` nullable error 和全文件 license/tag/4xx warnings；这些与本次变更无关，未修改。排除这些既有规则后的 Agent/AppStudio 目标 lint 通过。
- 风险：Agent S1 的 runtime payload 与 AppStudio SSE DTO 必须保持单一语义，不能复制出冲突协议。

## 未完成事项

- 下游 Server/Web 更新 submodule 和版本标记并实施。

## 推荐下一步

在 Server 更新 `ssot` submodule 到 `spec-v1.20.0`，生成目标类型并实现 AppStudio facade 与 SSE。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
