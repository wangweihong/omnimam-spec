# OmniMAM Spec Handoff

## 当前目标与状态

- 目标：补齐 Agent 对话执行、AppStudio Coding Agent 投影、模型授权、删除终结和 Task 投影契约，并发布 `spec-v1.18.0`。
- 状态：上游 S1/S2 内容与聚焦验证已完成，准备创建规格内容提交；尚未写入 `RELEASE.md`、创建 tag 或推送。
- 当前基线：`spec-v1.17.2`；现有未跟踪 `archive/`、`docs/identity_fix.md`、`设计图/` 必须保持不变。

## 本次已完成

- 已读取 Spec Workflow、S1、S2 规则和 Agent/AppStudio/Task Center/User Model/Model Gateway/Infrastructure 最小正式事实源。
- 已确认公共 Agent 管理继续只覆盖 Platform Agent，Coding Agent 必须由 AppStudio 投影。
- 已确认 Workspace 保留、显式 Memory、严格 Workspace 幂等、Enable 不自动启动和 Session Close 不隐式取消均不是缺陷。
- 已确认需要新增 Task-backed Invocation 执行、模型访问 grant、Agent 软删除终态和 AppStudio Agent facade 契约。
- 用户已明确授权直接修改本仓库、发布/tag/推送 SSOT，并随后实现 server。
- 已验证 `nousresearch/hermes-agent:v2026.8.3` 与 `ghcr.io/anomalyco/opencode:1.18.13` 镜像存在并可启动 headless server；Hermes 使用 `/api/ws` JSON-RPC/WebSocket，OpenCode 使用 session REST + `/event` SSE，必须分别适配。
- 已修订 Agent S1：所有 CHAT/CODING 使用 `agent.invocation.execute@1.0`、软删除终结、当前 Task 防乱序、模型 grant 前置门禁、恢复对账、Session Close 与 Disable/Enable 语义，以及 Hermes/OpenCode 固定协议合同。
- 已修订 AppStudio、Task Center、User Model S1：保存当前 Coding Agent/Session generation，新增应用级 Agent facade 语义，登记第八个 canonical functionRef，并增加 `agent.chat`/`agent.coding` 与短期 `AgentModelAccessGrant`。
- 已补齐 AppStudio 创建机器契约：`initial_requirement`、结构化 `coding_model_selection`、可选 profile、附件、创建幂等键，以及返回 Application/当前 Agent/首次 Invocation 的复合响应。
- 已补齐 Invocation 执行/恢复字段：RuntimeBinding、runtime session/invocation refs、事件序号、submission generation、Task 预期资源版本和终态投影并发字段。
- 已明确初始化事务与首次 Invocation 边界：初始化成功后 Application 保持 READY；首次 Task 提交失败复用同一 Message/Invocation 重试，不删除项目或重复初始化对象。
- 已明确 Invocation-to-Revision 聚合和 source restore 新建 Restore ChangeSet/Revision 的历史保留语义。
- 已修正 `agent.invocation.execute@1.0` registry 参数和结果投影，禁止消息、owner、Workspace、Endpoint、密钥、模型凭证和 Provider 配置进入 Task。
- 已为 registry loader 补齐可选 `execution_adapter` 表示并用 RFC8785 规则计算完整摘要；`agent.invocation.execute@1.0` 为 `sha256:7e076a03a291c331443bc9f8638ab355b2a4ac0c71711a148c9b1065a67e0868`，变更后的 `agent.runtime.ensure@1.0` 为 `sha256:5fff8cdcec364fea4c8d833b6c625b43c4e93c6b65bb46fb170f9d951eb8a4ec`。
- 聚焦验证已通过：目标 YAML 全部可解析，Agent/AppStudio/User Model OpenAPI 本地 `$ref` 全部可解析，function registry schema、全部九个 digest 及直接引用错误码 retryability 一致。

## 当前进行中

- 创建规格内容提交，使用其准确 commit 更新 `RELEASE.md`，将发布状态同步到 Context/CHANGELOG/handoff，再创建 annotated `spec-v1.18.0` tag 并推送。

## 文件变化

- Modified: Agent/AppStudio/Infrastructure/Task Center/User Model 的目标 S1/S2 文件、`domains/agent/context.md`、`docs/HANDOFF.md`；新增 `01_contracts/domains/agent/runtime-protocol-fixtures.yaml`。

## 关键决定

- 目标版本为 `spec-v1.18.0`，因为新增跨域 API、Schema 和 canonical functionRef。
- 新 Invocation 执行必须由 Task Center 管理，不能由 API Server 临时 goroutine 执行。
- Agent 删除使用隐藏于公共 DTO 的软删除终态；Workspace 和历史事实保留。
- Coding Agent 替换创建新 generation，旧 Agent 历史不改写。

## API、Schema、依赖或配置变化

- S1/S2 已落地创建 DTO、application-level Agent facade、Agent/AppStudio Schema、错误、权限、事件、短期 grant、Task registry 和模块边界；server migration 与实现必须在新 tag 发布并更新 submodule 后进行。

## 验证与风险

- Hermes 已验证 `session.create`、`prompt.submit`、`session.interrupt` 及 message/tool/error/status 事件；OpenCode 已验证 session create/message/abort、SSE event 与 health API。
- 两个 Runtime Profile 不共享同一协议，S2 必须明确 profile-specific adapter，不得抽象成虚构的公共 REST API。
- 未运行全仓验证；按任务约束只运行了受影响规格的定向结构、引用和 registry digest 校验。
- `git diff --check` 已通过；目标契约内不存在 `agent.coding.execute`、`TBD` digest 或被禁止的 Invocation Task 参数。

## 未完成事项

- 创建规格内容提交、Release 元数据提交、annotated tag `spec-v1.18.0`，推送 master 和 tag。
- 将新 tag 交付 server 仓库消费。

## 推荐下一步

运行 `git diff --check` 和目标 YAML/OpenAPI/registry 最终检查后创建规格内容提交；随后把该 commit 写入 `RELEASE.md` 的 `spec-v1.18.0` 记录。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
