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
| ApplicationRun | 一次应用运行的业务输入、版本和执行环境快照，以及 TaskRun 的只读投影 | application-platform |
| TaskRun | 一次异步执行的状态、进度、重试、超时和取消事实源 | task-center |
| TaskAttempt | TaskRun 的一次具体执行尝试及其失败、外部任务和恢复信息 | task-center |
| Worker | 从 task-center 领取 TaskRun、维护 Lease 并写回执行结果的工作器 | task-center |

`EngineAdapter` 负责平台级连接、鉴权和公共协议，`OperationExecutor` 负责具体 Operation；旧 `ProviderAdapter` catalog 名称不再作为 application-platform 的正式能力事实源。

## 画布与素材

| 术语 | 定义 | 主要事实源 |
| --- | --- | --- |
| Workflow | 可执行步骤和依赖的描述；供应商底层 Workflow 不等于 OmniMAM 业务画布 | 对应工作流领域 |
| Canvas | 组合业务节点和数据依赖的保存态对象；正式事实源尚待 workflow-canvas S1 建立 | workflow-canvas（缺失） |
| ApplicationNode | 画布中固定引用一个已发布 ApplicationVersion 的业务节点 | workflow-canvas（缺失） |
| Artifact | ApplicationRun 产生、尚待或已经登记为 Asset 的标准输出引用 | application-platform |
| Asset | 属于当前用户、由 asset-library 管理的素材身份、内容引用和 metadata | asset-library |

Artifact 只有在 asset-library 成功登记后才成为 Asset；TaskRun 结果中的媒体和文件引用不替代 Asset。
