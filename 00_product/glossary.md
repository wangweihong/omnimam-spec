# OmniMAM 全局业务术语

本文档是跨领域术语的 S1 事实源。领域文档可以补充本领域约束，但不得改变下列基本含义。

## 应用与能力

| 术语 | 定义 | 主要事实源 |
| --- | --- | --- |
| CapabilityDefinition | 平台统一的业务能力分类及基础输入输出语义，不包含供应商实现细节 | application-platform |
| ProviderCapability | 系统启动时从只读 YAML 目录加载的平台、模型、Operation、Variant 和参数约束事实；加载失败时按能力隔离 | application-platform |
| CapabilityVariant | 一个有效平台、Operation、模型及参数约束组合；不存在的组合表示不支持 | application-platform |
| Application | 面向用户和画布的业务应用身份，聚合所有者、可见性和版本 | application-platform |
| ApplicationTemplate | 描述底层能力、参数映射、固定参数和输出提取的应用模板 | application-platform |
| ComfyUIWorkflow | 用户私有、非版本化的 ComfyUI 工作流导入资源；用于解析、实例兼容性校验及一次性转换模板首版，不等于 ApplicationTemplate | application-platform |
| ComfyUIWorkflowValidation | 工作流针对一个 ComfyUI EngineInstance 的不可变兼容性校验快照；不提交 prompt，不覆盖历史结果 | application-platform |
| ApplicationVersion | Application 的不可变发布契约，定义稳定的业务输入输出并引用底层模板 | application-platform |
| RuntimeFormSchema | 根据应用版本、能力约束、权限和运行时可用性派生的临时业务表单 | application-platform |

ProviderCapability 使用文件中的稳定 `id` 与 `revision`，不建立管理员可写数据库版本实体；运行快照保存实际使用的 revision。`ProviderCapabilityVersion` 不作为独立全局术语。

## 执行环境与运行

| 术语 | 定义 | 主要事实源 |
| --- | --- | --- |
| ApplicationEngineType | 一类执行平台的产品级注册信息，必须有真实注册的执行能力 | application-platform |
| ApplicationEngineInstance | 某执行平台的真实账号或运行环境，包含连接引用、激活状态和健康状态 | application-platform |
| EngineCapabilityBinding | Engine 实例与平台能力之间的绑定及实例级收紧限制 | application-platform |
| Operation | 可由执行平台完成的一项标准业务操作；标识格式仍待 application-platform 确认 | application-platform |
| OperationExecutor | 某项 Operation 在特定平台上的真实执行能力 | application-platform |
| ApplicationRun | 一次应用运行的业务输入、版本和执行环境快照，以及 AtomicTask 的只读投影 | application-platform |
| AtomicTask | 一次异步执行的状态、进度、重试、超时和取消事实源 | task-center |
| TaskAttempt | AtomicTask 的一次具体执行尝试及其失败、外部任务和恢复信息 | task-center |
| TaskGroup | 多个 AtomicTask 的 SERIAL 或 PARALLEL 组合及其汇总视图 | task-center |
| DAGTaskGroup | 多个 AtomicTask 节点及有向无环依赖组成的编排资源 | task-center |
| TaskSchedule | 周期或单次触发 AtomicTask、TaskGroup 或 DAGTaskGroup 的计划资源 | task-center |
| Worker | 由 WorkflowRuntime 分发并执行已注册 AtomicTask handler 的工作器 | task-center |

`EngineAdapter` 负责平台级连接、鉴权和公共协议，`OperationExecutor` 负责具体 Operation；旧 `ProviderAdapter` catalog 名称不再作为 application-platform 的正式能力事实源。

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
