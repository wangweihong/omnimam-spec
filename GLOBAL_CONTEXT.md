# OmniMAM Global Context

## 1. 项目目标

OmniMAM 是连接 AI 能力、执行环境、素材、异步任务和无限画布的应用平台，面向艺术创作、模型管理、应用执行与可视化编排场景。平台支持 ComfyUI、本地推理、第三方 SaaS 和 OpenAI Compatible 服务，并通过统一应用语义隔离不同 Provider 的参数与协议差异。

上层用户主要选择并运行 `Application`，不直接面对底层工作流、Provider 参数、鉴权信息或任务运行时。系统通过不可变版本、受控能力目录、异步执行、素材登记和实时投影，让应用、画布与 Agent 等入口共享同一组业务事实。

## 2. 当前实施阶段

仓库使用三阶段 Spec 分层：S0 是前端交互原型和探索输入；S1 是产品语义、业务规则和验收标准的事实源；S2 是 API、设计态 Schema、错误码、权限码、事件和模块边界的实施合同。只有 `RELEASE.md` 中经用户确认且允许作为正式实现依据的 S1/S2 才能用于正式实现、合并和验收。

Context 文件只是摘要与导航，不构成 S3 或新的事实层。产品语义冲突时检查 S1，实现合同冲突时检查 S2；S1 与 S2 不一致必须修复并重新 release。Context、架构参考或 handoff 与正式 Spec 冲突时，必须让位于相应事实源。

## 3. 系统核心领域

| 领域 | 一行职责 |
| --- | --- |
| `identity` | 统一认证、会话、Token、RBAC、权限资源与安全审计。 |
| `modelgateway` | 管理能力目录、执行引擎、能力绑定、平台适配与 Operation 执行。 |
| `model-management` | 管理当前用户私有的模型提供商、模型清单、健康状态与默认模型。 |
| `ai-chatting` | 管理话题、消息、助手、生成运行、快捷短语与翻译。 |
| `application-platform` | 管理 ComfyUIWorkflow、模板、应用版本、运行表单与 ApplicationRun。 |
| `task-center` | 管理 AtomicTask、执行尝试、组合编排、计划调度与执行状态。 |
| `asset-library` | 管理 Artifact、Asset、版本、Representation、Blob 与素材生命周期。 |
| `workflow-canvas` | 管理画布草稿、不可变版本、节点与边、编译和运行投影。 |
| `notification-center` | 消费可靠领域事件并维护用户通知、计数、偏好与聚合。 |
| `sse` | 将已持久业务事实投影为当前用户可短期重放的实时事件。 |
| `mcp` | 将已发布应用、能力目录和素材通过标准 MCP 协议提供给受权 Agent。 |

当前工作区已将 Engine、Adapter、Executor、`ProviderCapability`、Binding、健康检测与 ComfyUI 当前 `object_info` 迁移到 `modelgateway`，但本次迁移尚未写入 `RELEASE.md`，不能作为新的正式实现依据。用户私有模型事实继续由 `model-management` 承载。`mcp` 已形成未 Release 的 S1、完整 S2 和架构参考；当前可用于产品与合同评审，但不能作为正式实现、合并或验收依据。

## 4. 核心业务对象

| 对象 | 含义与事实归属 |
| --- | --- |
| `ApplicationTemplate` | 底层能力、参数映射和输出提取蓝图；归 application-platform。 |
| `Application` | 面向用户和画布的稳定业务应用身份；归 application-platform。 |
| `ApplicationVersion` | 已发布应用的不可变输入输出与执行契约；归 application-platform。 |
| `RuntimeFormSchema` | 按应用版本、能力、权限和可用性派生的运行表单；归 application-platform。 |
| `ApplicationEngineInstance` | 一个真实执行账号或运行环境；归 modelgateway。 |
| `ProviderCapability` | 从只读目录加载的平台、模型、Operation 和参数约束事实；归 modelgateway。 |
| `EngineCapabilityBinding` | Engine 实例与平台能力的绑定及实例级收紧；归 modelgateway。 |
| `UserModelProvider` | 当前用户私有模型连接；归 model-management。 |
| `UserProviderModel` | 当前用户私有 Provider 下的模型清单与特征；归 model-management。 |
| `ApplicationRun` | 应用运行快照及 AtomicTask 状态的只读投影；归 application-platform。 |
| `AtomicTask` | 一次异步执行的状态、进度、重试、超时和取消事实；归 task-center。 |
| `Artifact` | 执行产生、尚未登记为正式素材的受控制品；归 asset-library。 |
| `Asset` | 已纳入素材库的长期素材身份与版本树；归 asset-library。 |
| `ApplicationNode` | 固定引用已发布 ApplicationVersion 的画布节点；归 workflow-canvas。 |
| `Notification` | 面向用户的事件投影、已读状态和处理入口；归 notification-center。 |
| `UserEvent` | 业务事实的短期实时提示与恢复游标；归 sse。 |
| `McpTaskBinding` | MCP Task 到已持久化 ApplicationRun 的协议映射；归 mcp，不拥有执行状态。 |

## 5. 全局事实归属

当前工作区事实中，能力目录、Engine 配置、Binding、Adapter 和 OperationExecutor 归 `modelgateway`；ComfyUIWorkflow、应用、模板、版本、RuntimeFormSchema 和 ApplicationRun 归 `application-platform`；模型服务配置归 `model-management`。异步执行及重试状态归 `task-center`；Artifact 处理、登记和 Asset 生命周期归 `asset-library`；画布结构、不可变版本和编译归 `workflow-canvas`；通知收件箱与已读状态归 `notification-center`；用户实时事件投影归 `sse`；对话和助手会话归 `ai-chatting`；身份、会话和授权归 `identity`。MCP Tool、Resource、Task 映射和协议审计上下文归 `mcp`，但 MCP 不复制上述领域事实。

跨域只能通过稳定 ID、权限裁剪的一跳摘要、不可变快照、受控模块接口或可靠事件协作，不得读取其他领域私有表，也不得用投影替代源领域事实。

## 6. 核心跨域关系

- Application 执行由 application-platform 固定版本和运行快照，通过 modelgateway 解析能力并执行 Operation，再由 task-center 管理 AtomicTask；ApplicationRun 不拥有底层状态机。
- Artifact 由受信任执行方交付给 asset-library，登记后形成或关联 Asset/AssetVersion；AtomicTask 成功不等于素材 ready。
- workflow-canvas 固定 CanvasVersion 和 ApplicationVersion，将合法 DAG 编译到 task-center，并只保存运行映射与素材引用。
- notification-center 消费已登记的可靠 source event，不从低层任务终态猜测上层 Application、Asset 或 Canvas 结果。
- sse 只发送变化提示；客户端仍通过各事实源 REST API 重查完整状态。AI Chat token/delta 流属于 ai-chatting 请求协议，不进入通用 UserEvent 历史。
- mcp 使用固定 Tool 和 Resource URI 向受权 Agent 投影领域事实；Capability 只读发现，异步执行只通过已发布 Application 创建 ApplicationRun，并将其 AtomicTask 映射为 MCP Task。

## 7. 当前重要约束

- Task Center 当前以 `AtomicTask` 为唯一执行单元；旧 `TaskRun`、`ExecutionLease`、Worker claim 和自研 Dispatcher 路径已废弃。
- `ProviderCapability` 来自只读目录，管理员手工导入和编辑能力的旧方案已废弃。
- Application Platform 只能通过受控边界消费 Model Gateway，不能读取其私有表或复制可变 Registry 事实。
- 已发布版本和历史快照不得被后续可变资源改写；跨域摘要最多展开一跳并执行同等权限过滤。
- S2 `schema.sql` 是设计态 Schema，不是 migration；本仓库不保存正式实现代码、运行时配置或 CI/CD 实现。
- 文档头部版本或状态可能滞后，是否可作为正式实现依据必须核对 `RELEASE.md` 的具体记录和门禁。
- MCP v1 复用 Identity JWT/RBAC，不提供直接 Capability 执行、OAuth/PAT、交互式 Task 或直接 StorageBackend 上传。

## 8. 非目标与延期范围

本次迁移不创建正式数据库 migration、不重命名兼容标识，也不修改 `RELEASE.md`；用户后续确认 Release 前，历史 Release 仍是正式实施门禁。`mcp` 当前 S1/S2 均未 Release；Agent 是端类型但不是独立事实域。各领域标记为草稿、延期、未来或 CONTRACT_GAP 的能力不得由摘要提升为已支持能力。

## 9. 上下文读取规则

1. 首先读取 `GLOBAL_CONTEXT.md`。
2. 根据任务关键词查询 `CONTEXT_MAP.md`。
3. 读取 `CONTEXT_MAP.md` 给出的一个具体 Domain Context 路径。
4. 只读取 Domain Context 中列出的 1～3 个必要正式文档。
5. 发现明确跨域依赖时才加载直接相关的第二个领域。
6. 不得默认递归读取整个仓库、全部 S1/S2、归档文档或无关 handoff 历史。

## 10. 相关入口

- 任务导航：`CONTEXT_MAP.md`
- 产品事实：`00_product/`
- 实现合同：`01_contracts/`
- 架构参考：`02_architecture/`
- 正式发布：`RELEASE.md`
- 工作流规则：`skills/spec-workflow/SKILL.md`
- 当前检查点：`docs/HANDOFF.md`
