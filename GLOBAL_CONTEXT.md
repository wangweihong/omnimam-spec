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
| `identity` | 统一认证、注册审批、会话、版本化 JWT/RBAC 投影、服务主体与跨域用户删除检查协调。 |
| `platform-management` | 管理平台级只读信息、SystemAuthConfig、跨 domain 脱敏 AuditLog 与平台入口。 |
| `modelgateway` | 管理能力目录、执行引擎、能力绑定、平台适配与 Operation 执行。 |
| `model-management` | 管理当前用户私有的模型提供商、模型清单、健康状态与默认模型。 |
| `ai-chatting` | 管理话题、消息、助手、生成运行、快捷短语与翻译。 |
| `application-platform` | 管理 ComfyUIWorkflow、模板、应用版本、运行表单与 ApplicationRun。 |
| `task-center` | 管理 AtomicTask、执行尝试、组合编排、计划调度与执行状态。 |
| `asset-library` | 管理 Artifact、Asset、版本、Representation、Blob 与素材生命周期。 |
| `workflow-canvas` | 管理画布草稿、不可变版本、节点与边、编译和运行投影。 |
| `notification-center` | 消费可靠领域事件并维护用户通知、计数、偏好与聚合。 |
| `sse` | 将已持久业务事实投影为当前用户可短期重放的实时事件。 |
| `agent` | 管理 Agent、Session、Invocation、Memory、内部 Workspace 固定绑定和 AgentRuntime；用户侧只管理 Platform Agent。 |
| `appstudio` | 管理生成式 Web/BFF 应用的源码、Revision、构建、发布和运行实例；内部维护唯一默认 StudioWorkspace。 |
| `infrastructure` | 提供第一阶段单机 Docker Job/Service、InfraRuntime、受控挂载和运行状态对账。 |
| `mcp` | 将已发布应用、能力目录和素材通过标准 MCP 协议提供给受权 Agent。 |

当前工作区已将 Engine、Adapter、Executor、`ProviderCapability`、Binding、健康检测与 ComfyUI 当前 `object_info` 迁移到 `modelgateway`，但本次迁移尚未写入 `RELEASE.md`，不能作为新的正式实现依据。用户私有模型事实继续由 `model-management` 承载。`mcp` 已形成 S1、完整 S2 和架构参考，并由 `spec-v1.9.2` 允许按实施门禁作为正式实现依据。

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
| `Agent` | 持久化 platform/coding 智能代理；公共管理只覆盖 Platform Agent，Coding Agent 由 AppStudio 内部创建；归 agent。 |
| `AgentInvocation` | AgentSession 中的一轮交互；异步执行时保存 AtomicTask 业务投影；归 agent。 |
| `AgentWorkspace` | Platform Agent 的后端持久化与固定绑定事实，不作为公共资源；归 agent。 |
| `AgentRuntime` | 按需运行 Hermes/OpenCode 的执行实例；归 agent。 |
| `StudioApplication` | Agent 辅助开发的生成式 Web/BFF 应用身份；归 appstudio，独立于 AI 能力 Application。 |
| `StudioApplicationVersion` | 固定 StudioSourceSnapshot 的生成应用版本；归 appstudio。 |
| `StudioWorkspace` | StudioApplication 唯一默认编辑上下文的后端 canonical 事实；公共投影为应用级源码和 Revision；归 appstudio。 |
| `StudioSourceSnapshot` | 供正式构建使用的不可变源码版本；归 appstudio。 |
| `StudioBuild` | Snapshot 到 Build Artifact 的业务投影；归 appstudio，执行状态引用 task-center。 |
| `RuntimeConfig` | StudioApplicationVersion 按环境使用的公开配置和 Secret/Integration 引用；归 appstudio。 |
| `StudioRelease` | 固定 Artifact digest 和环境的发布事实；归 appstudio。 |
| `StudioRuntimeInstance` | StudioRelease 当前部署实例和访问入口事实；归 appstudio。 |
| `McpTaskBinding` | MCP Task 到已持久化 ApplicationRun 的协议映射；归 mcp，不拥有执行状态。 |
| `SystemAuthConfig` | 平台注册模式、密码/登录保护、在线窗口和 Token 生命周期配置；归 platform-management，Identity 负责消费。 |
| `AuditLog` | 跨 domain 的脱敏管理审计记录、查询和可靠事件；归 platform-management，来源 domain 提交上下文。 |

## 5. 全局事实归属

当前工作区事实中，能力目录、Engine 配置、Binding、Adapter 和 OperationExecutor 归 `modelgateway`；ComfyUIWorkflow、AI 能力应用、模板、版本、RuntimeFormSchema 和 ApplicationRun 归 `application-platform`；模型服务配置归 `model-management`。异步执行、重试、取消和 Task Worker 分发归 `task-center`；Docker Job/Service、InfraRuntime、Endpoint、基础设施挂载和 Provider 对账归 `infrastructure`；Artifact 处理、登记和 Asset 生命周期归 `asset-library`；画布结构、不可变版本和编译归 `workflow-canvas`；通知收件箱与已读状态归 `notification-center`；用户实时事件投影归 `sse`；对话和助手会话归 `ai-chatting`；Agent、Session、Invocation、Memory、内部 AgentWorkspace 和 AgentRuntime 归 `agent`；StudioApplication、StudioApplicationVersion、内部 StudioWorkspace、Revision、ChangeSet、Snapshot、Build、RuntimeConfig、Release 和 StudioRuntimeInstance 归 `appstudio`。Agent/AppStudio 的公共 API、页面、通知和 SSE 不投影 Workspace ID。用户、认证流程、会话、授权和服务主体归 `identity`；平台级只读信息、`SystemAuthConfig` 和 `AuditLog` 归 `platform-management`。平台概览中的素材、应用、模型、任务和通知统计仍归各事实 domain，下一阶段再通过受控摘要接入。MCP Tool、Resource、Task 映射和协议审计上下文归 `mcp`，但 MCP 不复制上述领域事实。

跨域只能通过稳定 ID、权限裁剪的一跳摘要、不可变快照、受控模块接口或可靠事件协作，不得读取其他领域私有表，也不得用投影替代源领域事实。

## 6. 核心跨域关系

- Application 执行由 application-platform 固定版本和运行快照，通过 modelgateway 解析能力并执行 Operation，再由 task-center 管理 AtomicTask；ApplicationRun 不拥有底层状态机。
- Artifact 由受信任执行方交付给 asset-library，登记后形成或关联 Asset/AssetVersion；AtomicTask 成功不等于素材 ready。
- workflow-canvas 固定 CanvasVersion 和 ApplicationVersion，将合法 DAG 编译到 task-center，并只保存运行映射与素材引用。
- notification-center 消费已登记的可靠 source event，不从低层任务终态猜测上层 Application、Asset 或 Canvas 结果。
- sse 只发送变化提示；客户端仍通过各事实源 REST API 重查完整状态。AI Chat token/delta 流属于 ai-chatting 请求协议，不进入通用 UserEvent 历史。
- mcp 使用固定 Tool 和 Resource URI 向受权 Agent 投影领域事实；Capability 只读发现，异步执行只通过已发布 Application 创建 ApplicationRun，并将其 AtomicTask 映射为 MCP Task。
- 用户侧 `CreateAgent` 固定创建 Platform Agent，并由后端原子创建 AgentWorkspace、默认 Session 和固定 Binding；Coding Agent 仅由 AppStudio 通过内部 `CreateCodingAgentForStudio` 创建并固定引用唯一默认 StudioWorkspace。Session、Invocation 和 Runtime 不得切换内部绑定，所有源码写入通过当前 Invocation 的短期 Tool 授权和带 `base_revision` 的 ChangeSet 完成。
- `CreateStudioApplication` 不接受 Workspace 输入；后端创建 Repository、唯一默认编辑上下文、Coding Agent 和 Session。用户只通过 StudioApplication 级 Source/Revision、Snapshot 和 Preview 接口操作源码。
- 纯 CHAT 且不启动 Runtime、工具或后台工作的 AgentInvocation 可以不创建 AtomicTask；其他 Invocation 和所有 Runtime 生命周期操作必须关联 AtomicTask。
- agent 和 appstudio 的所有 Infra-backed 操作都通过 `Task Center -> Task Worker -> Infra Adapter -> Infra Service`；Task Worker 只回写稳定运行引用和小型结果，不拥有来源领域状态。
- Task Center 使用版本化只读 Function Registry 校验第一阶段七个 Agent/AppStudio Infra-backed functionRef，并在 AtomicTask 创建时固定合同 version/digest；调用方不能覆盖执行模式、能力或 Infra 映射，registry 升级不能改写历史任务。
- appstudio 通过 task-center 执行 Preview、Build 和 Production 发布/升级/回滚，并只保存 asset-library Artifact 的稳定 ID 与不可变 digest 快照；Build 只有在 Artifact READY 且 digest 一致后成功。
- 新 StudioRuntimeInstance 健康后才能切换当前入口；回滚基于历史不可变内容创建新的 StudioRelease 和候选 RuntimeInstance，不修改或重新激活旧 Release。
- AgentRuntimeProvider 只承载 Hermes/OpenCode；StudioDeploymentProvider 只承载 StudioApplication Release。两者可以复用 infrastructure 的受控 Docker 适配，但不得形成共享业务状态或直接调用 Infra。

## 7. 当前重要约束

- Task Center 当前以 `AtomicTask` 为唯一执行单元；旧 `TaskRun`、`ExecutionLease`、Worker claim 和自研 Dispatcher 路径已废弃。
- `ProviderCapability` 来自只读目录，管理员手工导入和编辑能力的旧方案已废弃。
- Application Platform 只能通过受控边界消费 Model Gateway，不能读取其私有表或复制可变 Registry 事实。
- 已发布版本和历史快照不得被后续可变资源改写；跨域摘要最多展开一跳并执行同等权限过滤。
- S2 `schema.sql` 是设计态 Schema，不是 migration；本仓库不保存正式实现代码、运行时配置或 CI/CD 实现。
- 文档头部版本或状态可能滞后，是否可作为正式实现依据必须核对 `RELEASE.md` 的具体记录和门禁。
- MCP v1 复用 Identity JWT/RBAC 和 PrincipalContext，不提供直接 Capability 执行、OAuth/PAT、交互式 Task 或直接 StorageBackend 上传；资源 owner/visibility 仍由目标 domain 定义。
- `Application` 专指 application-platform 的 AI 能力应用；`StudioApplication` 专指 appstudio 的生成式 Web/BFF 应用，不得互换或共享版本对象。
- `agent` 和 `appstudio` 的当前 S1/S2 已由 `spec-v1.16.0` 发布并允许作为正式实现依据；`infrastructure` 的 S1/S2 已由 `spec-v1.12.0` 发布并允许作为正式实现依据。三域使用各自的 `US-*-001`、`BR-*-001` 追溯锚点关联既有 `R-*` 规则。
- `infrastructure` 的当前 S2 只覆盖 Docker-only 第一阶段；挂载策略为 AgentWorkspace 授权、StudioWorkspace 受控授权、Preview 当前 Revision、Build 固定 Snapshot、Production 固定 Artifact 且禁止可写 Workspace。
- Infrastructure 只返回 Runtime output descriptor，Artifact 登记由 Task Worker 使用来源任务 producer context 调用 asset-library；`USER_ACCESSIBLE` Endpoint 必须受权解析，`PUBLIC` 第一阶段默认禁用。

## 8. 非目标与延期范围

本次迁移不创建正式数据库 migration、不重命名兼容标识；Model Gateway 迁移仍需后续 Release。`mcp` 已由 `spec-v1.9.2` 发布；MCP 语境中的 Agent 仍是协议调用端，而 `agent` 是管理 OmniMAM 持久化 Agent 资源的独立事实域。`agent` 和 `appstudio` 当前 S1/S2 已由 `spec-v1.16.0` 发布，`infrastructure` S1/S2 已由 `spec-v1.12.0` 发布；未发布领域或各领域标记为草稿、延期、未来或 CONTRACT_GAP 的能力不得由摘要提升为已支持能力。

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
