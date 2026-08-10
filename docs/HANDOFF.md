# OmniMAM Spec Handoff

## 当前目标与状态

- 目标：发布 Agent Runtime 详情、历史、日志和健康诊断契约，供 omnimam-server 正式实施。
- 状态：契约草稿完成并通过基础 YAML/格式/唯一性校验；尚未创建内容提交、release 记录和 tag。
- 基线：`spec-v1.20.0`，release commit `0e6300c8e776df08972a229f48775ed71ad5bff9`。

## 本次已完成

- 新增 Agent Runtime 诊断 S1 语义、owner/Application/Agent/generation 可见性、当前 Invocation、运行时长和脱敏边界。
- 新增 AppStudio 当前 Runtime、跨 generation 历史、最近 5000 行日志和投影/实时健康 facade 语义。
- 新增 Infrastructure owner-scoped Runtime logs/health、通用健康结果和 Docker/Provider 信息隐藏语义。
- AppStudio OpenAPI 新增四个 GET；Infrastructure logs 增加必填 `owner_reference`，并新增 health GET。
- 新增 `appstudio.agent.runtime.logs.read`，默认授予 USER、ADMIN、SUPER_ADMIN。
- 同步 Agent、AppStudio、Infrastructure module contract 和 Unreleased changelog。

## 当前进行中

- 创建 SSOT 内容提交，写入正式 release 记录，创建并推送 `spec-v1.21.0` release commit/tag。

## 文件变化

- 修改三个 Domain 的 `product-spec.md` 和 `module-contract.md`。
- 修改 AppStudio `openapi.yaml`、`permissions.yaml`，Infrastructure `openapi.yaml`。
- 修改 `CHANGELOG.md` 和 `docs/HANDOFF.md`。
- 未修改 schema、errors、events、architecture 或其他 Domain。

## 关键决定

- Runtime 历史经 AgentRuntimeGrant 关联 Application/generation，按 Runtime Binding 去重并稳定排序。
- 当前任务是最新非终态 AgentInvocation，不是 AtomicTask。
- 日志仅返回 occurred_at/level/message；健康只返回通用状态、来源、时间和稳定原因。
- 共享服务 Token 只做服务认证；Infrastructure 仍必须校验 owner_reference 和 Agent Runtime 范围。

## API、Schema、依赖或配置变化

- 新增四个 AppStudio Agent Runtime GET 和一个 Infrastructure Runtime health GET。
- Infrastructure Runtime logs 新增必填 `owner_reference`。
- 新增一个 AppStudio 权限码；不新增错误码、表、字段、事件、依赖或运行配置。

## 验证与风险

- 已通过 `yq` 解析三个修改的 YAML、operationId 重复检查和 `git diff --check`。
- Redocly 首次检查发现并已修正新增 `current_task` 的 OpenAPI 3.0 `$ref`/nullable sibling；AppStudio 仍有既有 `StudioBuildBatchSummaryItem` nullable error 和全文件通用 warnings，本任务不修改无关 schema。
- 尚需完成 release 后 pin 验证；server 实现不得早于该步骤。
- OpenAPI `StudioAgentRuntime` 与 server DTO 必须保持 Endpoint/Infra/容器/Provider 信息不可见。

## 未完成事项

- 完成 `spec-v1.21.0` release 并推送分支/tag。
- 下游 server 更新 submodule 和 `SSOT_VERSION` 后实施。

## 推荐下一步

复核目标 diff，创建 SSOT 内容提交；随后用该提交 ID 写入 `RELEASE.md` 并创建 `spec-v1.21.0` release commit/tag。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
