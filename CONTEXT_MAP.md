# OmniMAM Context Map

## 1. 使用方式

先读 `GLOBAL_CONTEXT.md`，再按任务关键词选择一个领域 Context，并从其“正式事实源”中读取 1～3 个必要文件。只有任务确实改变跨域协作时才加载第二个领域。Context 负责导航，不替代 S1、S2 或 `RELEASE.md`。

选择领域时以“谁拥有将被修改的事实”为准，而不是以页面名称、调用方或响应中出现的关联对象为准。例如，画布页面展示任务状态仍先读取 task-center；任务详情展示 Artifact 仍先读取 asset-library。只查询关联摘要、ID 或事件投影时，不自动扩大到关联对象的全部领域文档。

读取正式文件也应按任务类型收敛：产品目标、流程、业务规则和验收标准读取 S1；HTTP 接口读取 `openapi.yaml`；数据结构读取 `schema.sql`；跨模块协作读取 `events.yaml` 与 `module-contract.md`。发现明确冲突、缺失引用或事实归属变化后，再读取架构参考和直接相关领域，不做预防性的全仓加载。

## 2. 领域入口

| 领域 | Context | 核心职责 | 何时读取 |
| --- | --- | --- | --- |
| `identity` | `domains/identity/context.md` | 认证流程、会话、RBAC、主体与资源授权 | 登录、Token、用户、权限、服务主体 |
| `platform-management` | `domains/platform-management/context.md` | 平台级只读信息、SystemAuthConfig、AuditLog 与平台入口 | 平台管理、注册开关、认证策略、审计日志、系统概览 |
| `modelgateway` | `domains/modelgateway/context.md` | 能力目录、执行引擎、绑定与 Operation 执行 | Capability、Engine、Binding、Adapter、Executor |
| `model-management` | `domains/model-management/context.md` | 用户模型提供商和模型配置 | 模型、密钥引用、健康检测 |
| `ai-chatting` | `domains/ai-chatting/context.md` | 会话、消息、助手和生成 | AI 对话、Assistant、翻译 |
| `application-platform` | `domains/application-platform/context.md` | ComfyUIWorkflow、应用、表单和运行 | Application、模板、ApplicationRun |
| `task-center` | `domains/task-center/context.md` | 异步执行、重试、编排和调度 | AtomicTask、DAG、Schedule |
| `asset-library` | `domains/asset-library/context.md` | Artifact、Asset 和派生表现 | 素材、入库、预览、存储 |
| `workflow-canvas` | `domains/workflow-canvas/context.md` | 画布结构、版本、编译和运行 | Canvas、节点、边、部分执行 |
| `notification-center` | `domains/notification-center/context.md` | 通知收件箱、偏好、聚合 | 完成、失败、待处理通知 |
| `sse` | `domains/sse/context.md` | 用户级实时事件投影 | EventSource、断线恢复、重同步 |
| `agent` | `domains/agent/context.md` | Agent、Session、Memory、AgentWorkspace 与 AgentRuntime | Platform Agent、Coding Agent、Hermes、OpenCode |
| `appstudio` | `domains/appstudio/context.md` | 生成应用源码、构建、发布与运行 | StudioApplication、StudioWorkspace、StudioBuild、StudioRelease |
| `mcp` | `domains/mcp/context.md` | Agent 协议访问、固定 Tool/Resource 和 MCP Task 映射 | MCP、Agent 调用应用、stdio、Streamable HTTP |

`modelgateway` 已有迁移后的 S1、S2 和架构参考，但尚未形成新的 Release。Engine、Adapter、Executor、`ProviderCapability`、Binding、健康检测和 ComfyUI 当前 `object_info` 先读 `domains/modelgateway/context.md`；应用与工作流消费行为再读 application-platform。`mcp` 已由 `spec-v1.9.2` 发布 S1、完整 S2、Domain Context 和架构参考；协议、Tool/Resource/Task、错误、权限和持久化任务先读 `domains/mcp/context.md`，再按导航读取必要 S1/S2。

`agent` 与 `appstudio` 当前已有未 Release S1、完整 S2 和 Domain Context，但没有领域架构。Agent 交互、Session、Memory 和 AgentRuntime 先读 `domains/agent/context.md`；StudioApplication、源码 Revision、Build、Release 和 StudioRuntimeInstance 先读 `domains/appstudio/context.md`。Coding Agent 修改生成应用时必须同时读取两者，并按需继续读取 task-center 与 asset-library。两域尚未 Release，不能作为正式实现、合并或验收依据。

如果任务使用规划领域名称，应先映射到当前事实拥有者并检查用户是否要求建立新领域。仅讨论未来方向时可停留在规划状态；一旦要求新增 API、Schema 或业务规则，必须先完成对应 S1 领域决策，不能直接从 Context 推导 S2。

## 3. 任务关键词映射

| 关键词 | 优先读取 | 按需继续 |
| --- | --- | --- |
| Model Gateway、CapabilityDefinition、EngineAdapter、OperationExecutor、ProviderCapability、Binding | `domains/modelgateway/context.md` | 涉及应用消费再读 application-platform |
| 应用、模板、版本、RuntimeFormSchema、ApplicationRun | `domains/application-platform/context.md` | 涉及画布再读 workflow-canvas |
| EngineInstance、ProviderCapability、健康检测、object_info | `domains/modelgateway/context.md` | 涉及 ComfyUIWorkflow 再读 application-platform |
| ComfyUI Workflow、模板转换、试运行 | `domains/application-platform/context.md` | 涉及 Engine 当前事实再读 modelgateway |
| AtomicTask、TaskAttempt、TaskGroup、DAGTaskGroup、TaskSchedule、重试、取消 | `domains/task-center/context.md` | 涉及业务结果再读源领域 |
| TaskRun、ExecutionLease、Worker claim、DAGFlowTask | `domains/task-center/context.md` | 这些是过期检索词，先核对废弃说明 |
| Artifact、Asset、AssetVersion、Representation、Blob、扫描、缩略图 | `domains/asset-library/context.md` | 涉及生成任务再读 task-center |
| Canvas、Node、Edge、ApplicationNode、CanvasRun、局部执行 | `domains/workflow-canvas/context.md` | 涉及应用节点再读 application-platform |
| Notification、未读、偏好、聚合、需要处理 | `domains/notification-center/context.md` | 涉及源状态再读生产事件领域 |
| SSE、UserEvent、event_id、Last-Event-ID、重放 | `domains/sse/context.md` | 再读事件所属事实领域 |
| 用户、登录、JWT、Refresh Token、RBAC、PrincipalContext、服务主体 | `domains/identity/context.md` | 涉及领域权限再读目标领域 |
| SystemAuthConfig、allow_registration、平台认证配置、AuditLog、审计日志 | `domains/platform-management/context.md` | 认证执行再读 identity；来源事件再读对应 domain |
| 模型提供商、ProviderModel、默认模型、用户模型健康检测 | `domains/model-management/context.md` | 平台 Engine 健康检测读 modelgateway；对话使用读 ai-chatting |
| Topic、Message、Assistant、QuickPhrase、生成流 | `domains/ai-chatting/context.md` | 模型配置再读 model-management |
| MCP、server/discover、Streamable HTTP、stdio Proxy、MCP Tool、MCP Resource、MCP Task | `domains/mcp/context.md` | 调用应用再读 application-platform；任务映射再读 task-center |
| AgentSession、AgentInvocation、AgentMemory、Hermes、OpenCode、AgentRuntime | `domains/agent/context.md` | Coding Agent 修改源码再读 appstudio |
| AgentWorkspace、workspace_type、AgentRuntimeProvider | `domains/agent/context.md` | 周期执行再读 task-center |
| StudioApplication、StudioWorkspace、StudioChangeSet、Source Snapshot | `domains/appstudio/context.md` | Agent 修改再读 agent |
| StudioBuild、StudioRelease、StudioRuntimeInstance、StudioDeploymentProvider | `domains/appstudio/context.md` | 执行再读 task-center；Artifact 再读 asset-library |

## 4. 跨域任务映射

| 任务 | 必须读取 | 按需读取 |
| --- | --- | --- |
| Application 执行 | application-platform、modelgateway、task-center | asset-library |
| ComfyUI 工作流转应用 | application-platform、modelgateway | task-center |
| 应用转画布节点 | application-platform、workflow-canvas | task-center |
| 任务结果登记素材 | task-center、asset-library | notification-center |
| Canvas 执行应用节点 | workflow-canvas、application-platform | task-center、asset-library |
| 任务或画布完成通知 | notification-center、对应源领域 | sse |
| AI 对话引用素材 | ai-chatting、asset-library | model-management |
| 实时状态展示 | sse、对应事实领域 | notification-center |
| Agent 通过 MCP 运行应用 | mcp、application-platform | task-center、modelgateway、asset-library |
| Agent 通过 MCP 查询或上传素材 | mcp、asset-library | identity |
| Coding Agent 修改 StudioApplication | agent、appstudio | task-center |
| StudioApplication 构建与发布 | appstudio、task-center | asset-library、notification-center |
| StudioBuild 交付 Artifact | appstudio、asset-library | task-center |
| 迁移认证配置或跨域审计 | platform-management、identity | 涉及来源事件再读对应 domain |

## 5. 全局文档入口

| 文件 | 用途 |
| --- | --- |
| `00_product/glossary.md` | 跨域术语与事实归属 |
| `00_product/global-business-rules.md` | 全局业务规则 |
| `00_product/global-feature-matrix.md` | 端类型和支持度标记 |
| `01_contracts/error-code-index.md` | 错误码文件和区间导航 |
| `02_architecture/global-architecture.md` | 全局依赖和运行链路参考 |
| `RELEASE.md` | 正式发布状态和实施门禁 |
| `skills/spec-workflow/SKILL.md` | S0/S1/S2 工作流入口 |

## 6. 禁止的读取方式

- 禁止任务开始时递归读取整个 `domains/`、全部 S1/S2 或 `archive/`。
- 禁止因为一个对象名称出现就加载所有关联领域；先确认本次行为归属。
- 禁止把 Context、架构参考或 `docs/HANDOFF.md` 当作完整事实源。
- 禁止用过期术语、旧 Release 或归档内容覆盖当前正式 Spec。
- 禁止为生成摘要而修改现有产品语义，或为规划中领域虚构正式文件。
