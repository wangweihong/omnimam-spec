# OmniMAM 全局业务术语

本文档是跨领域术语的 S1 事实源。领域文档可以补充本领域约束，但不得改变下列基本含义。

## 平台与身份

| 术语 | 定义 | 主要事实源 |
| --- | --- | --- |
| SystemAuthConfig | 平台统一维护的注册模式、密码策略、登录失败保护、在线窗口和 Token 生命周期配置；Identity 只消费当前生效版本。 | platform-management |
| allow_registration | `SystemAuthConfig.registration_mode` 的只读兼容派生值；`OPEN` 为 true，`ADMIN_APPROVAL` 为 false。 | platform-management |
| AuditLog | 跨 domain 的脱敏管理审计记录；平台管理负责追加、查询、Outbox 和可靠事件，来源 domain 只提交审计上下文。 | platform-management |

## 应用与能力

| 术语 | 定义 | 主要事实源 |
| --- | --- | --- |
| CapabilityDefinition | 平台统一的业务能力分类及基础输入输出语义，不包含供应商实现细节 | modelgateway |
| ProviderCapability | 系统启动时从只读 YAML 目录加载的平台、模型、Operation、Variant 和参数约束事实；加载失败时按能力隔离 | modelgateway |
| CapabilityVariant | 一个有效平台、Operation、模型及参数约束组合；不存在的组合表示不支持 | modelgateway |
| Application | 面向用户和画布的业务应用身份，聚合所有者、可见性和版本 | application-platform |
| ApplicationTemplate | 描述底层能力、参数映射、固定参数和输出提取的应用模板 | application-platform |
| ComfyUIWorkflow | 用户私有、非版本化的 ComfyUI 工作流导入资源；用于解析、实例兼容性校验及一次性转换模板首版，不等于 ApplicationTemplate | application-platform |
| ComfyUIWorkflowValidation | 工作流针对一个 ComfyUI EngineInstance 的不可变兼容性校验快照；不提交 prompt，不覆盖历史结果 | application-platform |
| ApplicationVersion | Application 的不可变发布契约，定义稳定的业务输入输出并引用底层模板 | application-platform |
| RuntimeFormSchema | 根据应用版本、能力约束、权限和运行时可用性派生的临时业务表单 | application-platform |
| UserModelProvider | 当前用户私有模型服务连接和非敏感配置；不等于 ProviderCapability 或 ApplicationEngineInstance | user-model |
| UserProviderModel | 用户 Provider 下的远端模型标识、展示字段、特征标签、启用范围和 Gateway 派生能力投影 | user-model |
| UserModelExecutionContext | User Model 完成 owner、启用、健康、能力和配置版本校验后签发的请求级执行上下文；不包含凭证明文且不建表 | user-model |

ProviderCapability 使用文件中的稳定 `id` 与 `revision`，不建立管理员可写数据库版本实体；运行快照保存实际使用的 revision。`ProviderCapabilityVersion` 不作为独立全局术语。

## 执行环境与运行

| 术语 | 定义 | 主要事实源 |
| --- | --- | --- |
| ApplicationEngineType | 一类执行平台的产品级注册信息，必须有真实注册的执行能力 | modelgateway |
| ApplicationEngineInstance | 某执行平台的真实账号或运行环境，包含连接引用、激活状态和健康状态 | modelgateway |
| EngineCapabilityBinding | Engine 实例与平台能力之间的绑定及实例级收紧限制 | modelgateway |
| Operation | 可由执行平台完成的一项标准业务操作；标识格式仍待 modelgateway 确认 | modelgateway |
| OperationExecutor | 某项 Operation 在特定平台上的真实执行能力 | modelgateway |
| PlatformEngineTarget | Application Platform 使用的 Gateway 执行目标，引用平台 Engine、Binding、ProviderCapability revision 和运行快照 | modelgateway |
| UserModelTarget | 使用 User Model 签发执行上下文的 Gateway 执行目标；不把用户 Provider 转换为平台 Engine | modelgateway |
| ResolvedModelRoute | Gateway 按执行目标、能力和 Runtime Registry 在单次请求内派生的路由；不建表、不提供 CRUD | modelgateway |
| ApplicationRun | 一次应用运行的业务输入、版本和执行环境快照，以及 AtomicTask 的只读投影 | application-platform |
| AtomicTask | 一次异步执行的状态、进度、重试、超时和取消事实源 | task-center |
| TaskAttempt | AtomicTask 的一次具体执行尝试及其失败、外部任务和恢复信息 | task-center |
| TaskGroup | 多个 AtomicTask 的 SERIAL 或 PARALLEL 组合及其汇总视图 | task-center |
| DAGTaskGroup | 多个 AtomicTask 节点及有向无环依赖组成的编排资源 | task-center |
| TaskSchedule | 周期或单次触发 AtomicTask、TaskGroup 或 DAGTaskGroup 的计划资源 | task-center |
| Task Worker | 由 WorkflowRuntime 分发并执行已注册 AtomicTask handler 的工作器；Infra-backed handler 通过 Infra Adapter 调用基础设施，不拥有业务状态 | task-center |
| Infra Adapter | Task Worker 内将已授权业务引用转换为受控 Infra 请求并映射幂等、取消、超时和恢复的适配边界 | task-center / infrastructure |
| InfraRuntime | Docker Job 或 Service 的基础设施运行事实；只保存运行状态和稳定关联，不等于 AgentRuntime 或 StudioRuntimeInstance | infrastructure |
| RuntimeMount | InfraRuntime 使用的受控挂载记录，包含来源引用、目标路径、只读标志和授权上下文 | infrastructure |
| source_ref | 由来源领域授权生成的不可变或受控资源引用；不得解释为宿主机路径 | infrastructure |

Gateway Adapter 负责 Provider 连接、鉴权应用、发现、探测和公共协议，`OperationExecutor` 负责具体 Operation；稳定 `providerType` 可对外展示，内部 `adapter_id` 和 `operation_executor_id` 不能由客户端选择。

## Agent 与生成应用

| 术语 | 定义 | 主要事实源 |
| --- | --- | --- |
| Agent | 持久化 platform 或 coding 智能代理；固定引用一个 Workspace，但不等于运行容器 | agent |
| AgentSession | 用户与 Agent 的持续交互会话；继承 Agent 的固定 Workspace 引用 | agent |
| AgentInvocation | AgentSession 中的一轮用户交互；纯 CHAT 可不建 Task，异步、工具、Coding 与 Runtime 操作必须关联 AtomicTask | agent |
| AgentWorkspace | Platform Agent 使用的独立持久化工作区，保存受权输入、产物和可恢复本地状态 | agent |
| AgentRuntime | 按需运行 Hermes 或 OpenCode 的 Agent 执行实例，不承载 StudioApplication | agent |
| AgentRuntimeProvider | 创建、恢复、检查 AgentRuntime 的系统注册组件 | agent |
| StudioApplication | Agent 辅助开发的生成式 Web/BFF 应用身份；独立于 AI 能力 Application | appstudio |
| StudioWorkspace | StudioApplication 的可编辑源码、当前 Revision 和预览关联事实 | appstudio |
| StudioChangeSet | Coding Agent 或用户基于 `base_revision` 提交的原子文件变更及校验结果 | appstudio |
| StudioSourceSnapshot | 从一个 Workspace Revision 创建、供正式 Build 使用的不可变源码版本 | appstudio |
| StudioApplicationVersion | 固定 StudioSourceSnapshot 的生成应用版本 | appstudio |
| StudioBuild | StudioSourceSnapshot 到可运行 Bundle 的业务投影，引用 AtomicTask 和 Artifact | appstudio |
| StudioPreviewRuntime | 基于当前 StudioWorkspace Revision 的编辑态快速预览，不可直接发布 | appstudio |
| RuntimeConfig | StudioApplicationVersion 按环境使用的公开配置、Secret/Integration 引用和乐观版本事实 | appstudio |
| StudioRelease | 固定 StudioBuild、StudioApplicationVersion、RuntimeConfig、Artifact ID/digest 和环境的发布事实 | appstudio |
| StudioRuntimeInstance | StudioRelease 当前部署实例、健康状态与访问入口事实 | appstudio |
| StudioDeploymentProvider | 从固定 Artifact 部署 StudioRuntimeInstance 的系统注册组件 | appstudio |
| WorkspaceRevision | StudioWorkspace 在某一时点的可授权源码版本；Preview 可挂载当前 Revision | appstudio |
| WorkspaceSnapshot | `StudioSourceSnapshot` 的已废弃别名；新规格不得继续作为独立对象使用 | appstudio |

`Application` 和 `StudioApplication` 是不同产品对象：前者封装可运行 AI 能力，后者表示 Agent 辅助开发的 Web/BFF 应用。Coding Agent 可以固定引用一个 StudioWorkspace，但不能拥有其源码、Build、Release 或 Runtime 生命周期。

## Agent 协议访问

| 术语 | 定义 | 主要事实源 |
| --- | --- | --- |
| MCP Server | OmniMAM 面向受权 Agent 的标准协议访问层；只做协议适配、授权、结果转换和任务映射，不拥有业务执行事实 | mcp |
| MCP Tool | 固定注册的 Agent 命令界面；当前只覆盖 Capability 发现、Application 查询/运行、ApplicationRun 查询/取消和 Asset 查询/上传 | mcp |
| MCP Resource | 通过 `omnimam://` URI 读取领域对象权限裁剪投影的协议资源，不替代源领域事实或动态搜索 | mcp |
| MCP Task | ApplicationRun 所绑定 AtomicTask 的协议级长任务投影，不是独立任务系统 | mcp |
| McpTaskBinding | `mcp_task_id` 到已持久化 ApplicationRun 的稳定映射；不复制 ApplicationRun 或 AtomicTask 状态 | mcp |

CapabilityDefinition 在 MCP v1 中只读发现；Agent 只能通过已发布且允许直接运行的 Application 创建异步业务执行，不存在独立 CapabilityInvocation 或泛化 Invocation。

## 实时事件

| 术语 | 定义 | 主要事实源 |
| --- | --- | --- |
| UserEvent | 由已持久业务事实投影出的当前用户短期可重放事件；不替代原业务事实 | sse |
| event_id | 当前用户事件流中唯一、有序的恢复与去重游标 | sse |
| aggregate_version | 来自业务聚合 `resource_version` 的单调版本，用于防止乱序事件覆盖较新投影 | 业务资源所属领域 |
| SSE Event Stream | 通过 HTTP `text/event-stream` 向当前登录 Web 用户推送 UserEvent 和连接控制事件的单向通道 | sse |

AI Chat 单次生成的 token/delta 流属于 ai-chatting 请求协议，不是 UserEvent，不进入 SSE 用户事件历史。

## 画布与素材

| 术语 | 定义 | 主要事实源 |
| --- | --- | --- |
| Workflow | 可执行步骤和依赖的描述；供应商底层 Workflow 不等于 OmniMAM 业务画布 | 对应工作流领域 |
| Canvas | 组合业务节点和数据依赖的可编辑保存态对象 | workflow-canvas |
| CanvasVersion | Canvas 发布后形成的不可变图、输入输出与编译摘要 | workflow-canvas |
| CanvasRun | 固定 CanvasVersion 和输入并关联一个 DAGTaskGroup 的运行视图 | workflow-canvas |
| CanvasNodeRun | Canvas 节点到 AtomicTask 的只读运行映射 | workflow-canvas |
| ApplicationNode | 画布中固定引用一个已发布 ApplicationVersion 的业务节点 | workflow-canvas |
| Artifact | 应用、画布或 AtomicTask 产生、尚未登记为正式素材的执行制品；asset-library 维护其受控内容、处理、保留和登记状态 | asset-library |
| Asset | 属于当前用户、由 asset-library 管理的素材身份、版本、Representation 和 metadata；跨域语境中的 UserAsset 是其用户归属称谓 | asset-library |
| AssetVersion | 同一 Asset 的不可变内容版本；处理状态由 expected AssetRepresentation 的完成情况汇总 | asset-library |
| AssetRepresentation | AssetVersion 的 original、thumbnail、preview、playback、manifest 等技术表现形式 | asset-library |

Artifact 的处理状态与登记状态独立；登记成功后形成或关联 Asset/AssetVersion。Task Center 只保存 Artifact、AssetVersion 和 AssetRepresentation 的小型引用，不保存媒体正文，也不从 AtomicTask 终态推断素材 ready。
