# AI 应用平台领域架构参考

本文是 application-platform v0.9.0-draft 的架构参考。产品语义以 S1 为准，实现接口与数据结构以 S2 为准。

## 1. 架构目标

- 将 ApplicationEngineType、EngineAdapter、OperationExecutor 与易变的平台能力清单分离。
- 以启动目录中的 YAML 作为 ProviderCapability 唯一事实源，不创建数据库副本。
- 任何单个能力文件失败只导致能力级降级，不阻止应用平台服务启动。
- ProviderCapability 与 ComfyUI workflow 使用联合能力来源，ApplicationVersion、ApplicationRun 和 TaskRun 协作均使用可审计的 revision 与执行快照。
- 将用户私有 ComfyUI 工作流的导入、解析、实例校验和一次性模板转换与 ApplicationTemplate 后续版本演进分离。

## 2. 模块关系

```mermaid
flowchart LR
    C["provider_capability_directory"] --> L["ProviderCapability Loader"]
    S["provider-capability.schema.yaml"] --> L
    L --> R["只读 ProviderCapability Registry"]
    RR["runtime-registry.yaml"] --> T["Runtime Registry"]
    T --> L
    T --> A["EngineAdapter Registry"]
    T --> O["OperationExecutor Registry"]

    R --> B["EngineCapabilityBinding"]
    E["ApplicationEngineInstance"] --> B
    B --> F["RuntimeForm Resolver"]
    E --> WI["ComfyUI Workflow Import"]
    WI --> WV["Workflow Validation History"]
    WV --> CT["Atomic Template Conversion"]
    CT --> TV["ApplicationTemplateVersion v1 draft"]
    TV --> V["ApplicationVersion"]
    V["ApplicationVersion"] --> F
    F --> U["RuntimeFormSchema"]

    U --> AR["ApplicationRun"]
    R --> AR
    CW["TemplateVersion ComfyUI Snapshot"] --> AR
    E --> AR
    AR --> TR["TaskRun / task-center"]
    AR --> AF["Artifact"]
    AF --> AL["UserAsset / asset-library"]
    TR --> W["Worker"]
    W --> O
    O --> A
    A --> P["External Provider"]
```

## 3. 启动注册顺序

```mermaid
flowchart TD
    A["注册 ApplicationEngineType"] --> B["注册 EngineAdapter 与 OperationExecutor"]
    B --> C["读取 provider_capability_directory 第一层 YAML"]
    C --> D{"目录可读"}
    D -->|"否"| E["Registry=degraded；能力集合为空；服务继续启动"]
    D -->|"是"| F["逐文件解析 YAML 与 schema_version"]
    F --> G["JSON Schema 校验"]
    G --> H["ID 去重和 model/operation/variant 校验"]
    H --> I["EngineType/Adapter/Executor 一致性校验"]
    I --> J{"文件全部通过"}
    J -->|"是且 enabled=true"| K["availability=available"]
    J -->|"是且 enabled=false"| L["availability=disabled"]
    J -->|"否"| M["availability=unavailable；记录文件诊断"]
    K --> N["冻结只读注册表"]
    L --> N
    M --> N
```

加载按文件原子执行。文件名排序只保证诊断稳定，不赋予覆盖优先级。重复 ID 的所有文件均不可用。运行中不监听目录；更新文件后必须重启。

## 4. ProviderCapability 边界

ProviderCapability 描述：

- 平台、来源和人工核验日期；
- 模型 ID、供应商模型 ID、生命周期和限制；
- Operation 与 CapabilityDefinition 关系；
- Model × Operation 的有效 Variant；
- 输入输出 JSON Schema、必填项、枚举、范围和跨字段约束。

ProviderCapability 不描述：

- 可执行代码或类名；
- API Key 等实例凭证；
- 管理员可写状态；
- 运行态 availability、失败原因、加载时间或来源文件路径；
- TaskRun、Lease、Attempt 或重试策略事实。

`seedance.yaml` 使用 ByteDance Seed 定义模型能力、BytePlus ModelArk 定义可执行 API 参数；`deepseek.yaml` 只覆盖官方稳定 OpenAI-compatible Chat Completions。

## 5. EngineAdapter 与 OperationExecutor

EngineAdapter 负责平台级公共协议：

- base URL、鉴权和公共 Header；
- 网络、上传和平台级健康检测；
- 公共错误、追踪 ID 和状态映射。

OperationExecutor 负责具体 Operation：

- 标准输入与 ProviderCapability Variant 的双重校验；
- 供应商请求转换；
- 同步或异步提交、查询、取消和恢复；
- 输出提取、Artifact 生成和供应商错误归一化。

YAML 只能声明已注册的 Operation，不能补足缺失的执行器。

## 6. 数据归属

| 对象 | 事实源 | 是否持久化 |
| --- | --- | --- |
| CapabilityDefinition / ApplicationEngineType / Adapter / Executor | `runtime-registry.yaml` 只读契约与运行时注册表 | 否 |
| ProviderCapability | 启动目录 YAML 与进程内只读注册表 | 否 |
| ProviderCapabilityLoadResult | 当前进程加载诊断 | 否 |
| ApplicationEngineInstance | application-platform 数据库 | 是 |
| EngineCapabilityBinding | application-platform 数据库 | 是 |
| ComfyUIWorkflow | application-platform 数据库中的用户私有非版本化导入资源 | 是 |
| ComfyUIWorkflowValidation | application-platform 数据库中的不可变实例校验快照 | 是 |
| ApplicationTemplateVersion | application-platform 数据库 | 是 |
| ApplicationVersion | application-platform 数据库 | 是 |
| RuntimeFormSchema | 请求时计算结果 | 否 |
| ApplicationRun | application-platform 数据库 | 是 |
| Artifact | application-platform 数据库 | 是 |
| UserAsset / Artifact 登记映射 | asset-library 数据库 | 是 |
| TaskRun / Attempt / Lease | task-center | 是 |

Binding 中的 ProviderCapability ID 没有数据库外键，创建、解析和运行时通过注册表校验。ApplicationRun 按能力来源保存 ProviderCapability 或 ComfyUI workflow revision 快照，不随重启后的能力变化。

ComfyUIWorkflow 不维护版本树。每次导入生成新资源并保存来源实例 `object_info`；每次兼容性校验保存目标实例独立快照。一次性转换将执行事实深拷贝到首个 draft ApplicationTemplateVersion，之后模板版本与源工作流生命周期解耦。

## 7. ComfyUI 工作流导入与转换时序

```mermaid
sequenceDiagram
    participant User as 用户或代管管理员
    participant Workflow as ComfyUI Workflow Module
    participant Source as Source EngineInstance
    participant Target as Target EngineInstance
    participant Template as Application Template Module
    participant Outbox as Outbox/Audit

    User->>Workflow: 上传 API Workflow 与可选普通 Workflow
    Workflow->>Source: 校验 comfyui 类型并读取 object_info
    Source-->>Workflow: object_info 与版本信息
    Workflow->>Workflow: 原子解析、checksum、候选项与依赖
    Workflow-->>User: 私有 ComfyUIWorkflow

    User->>Workflow: 指定目标实例创建兼容性校验
    Workflow->>Target: 重新读取 object_info
    Target-->>Workflow: 当前能力快照
    Workflow->>Workflow: 保存不可变 Validation
    Workflow-->>User: compatible / incompatible / failed

    User->>Workflow: 选择 compatible Validation 并提交模板契约
    Workflow->>Workflow: 校验 active、未转换、所有权和幂等键
    Workflow->>Template: 同一事务创建 Template 与 v1 draft
    Template-->>Workflow: 模板、版本和服务端 revision
    Workflow->>Workflow: 固定唯一转换关系
    Workflow->>Outbox: comfyui_workflow_converted
    Workflow-->>User: 原子转换结果
```

转换后的重新校验只追加诊断记录，不进入 TemplateVersion 更新路径。模板后续变化必须显式创建新版本。

## 8. 有效能力计算

```text
RuntimeApplicationCapability
= (available ProviderCapability 当前加载修订 ∩ EngineCapabilityBinding.restrictions)
  或 (ComfyUI workflow contract ∩ 模板 Engine 约束)
∩ ApplicationTemplateVersion 约束
∩ ApplicationVersion 参数策略
∩ EngineInstance 当前健康与激活状态
∩ 用户权限
```

任一来源不可用时不得静默切换模型、扩张参数或修改历史版本。RuntimeFormSchema 只暴露最终交集。

## 9. 运行时序

```mermaid
sequenceDiagram
    participant User as 用户/画布
    participant App as Application Platform
    participant Registry as Capability Registry
    participant Engine as EngineInstance
    participant Task as Task Center
    participant Worker as Worker
    participant Exec as OperationExecutor
    participant Provider as External Provider
    participant Asset as Asset Library

    User->>App: 解析 RuntimeFormSchema
    App->>Registry: 校验 capability、revision、variant
    App->>Engine: 校验 Binding、限制和健康状态
    App-->>User: 返回有效字段与选项
    User->>App: 提交 ApplicationRun
    App->>Registry: 重新校验能力
    App->>Engine: 重新校验并选择实例
    App->>App: 保存不可变执行快照，task_creation_status=pending
    App->>Task: application_run_id + idempotency_key 幂等创建 TaskRun
    Task-->>App: 返回唯一 task_run_id
    App->>App: 绑定 TaskRun，task_creation_status=created
    Task->>Worker: 分配 Attempt / Lease
    Worker->>Exec: 使用执行快照提交
    Exec->>Provider: 调用供应商 API
    Provider-->>Exec: 任务或结果
    Exec-->>Task: 状态、进度、标准输出
    Task-->>App: resource_version 投影事件
    App->>App: 标准输出形成 Artifact
    App->>Asset: 以 artifact_id 幂等登记 UserAsset
```

## 10. 失败隔离

- 目录不可读：注册表 `degraded`，服务继续启动，所有 ProviderCapability 不可执行。
- 单文件失败：只隔离该文件；其他能力正常注册。
- 重复 ID：所有冲突文件不可用，不按顺序覆盖。
- Adapter/Executor 缺失：对应能力不可用，不能由 YAML 补足。
- 运行时供应商拒绝：运行失败并创建 `CapabilityCorrectionRequired`，系统不自动改文件。
- 能力重启后变化：既有 Binding 保留但可能失效；历史 ApplicationRun 快照保持不变。
- ComfyUI 导入失败：不创建工作流；其他工作流与模板不受影响。
- 实例复检失败：追加 failed 或 incompatible 校验，不覆盖旧结果，不修改模板快照。
- 转换失败：模板、首版模板版本和工作流转换标记全部回滚；相同幂等键可安全重试。

## 11. 安全与可见性

- 普通能力目录不暴露磁盘路径、完整加载失败详情或 Engine 凭证。
- 文件级加载诊断仅管理员可见。
- ProviderCapability 无任何写 API 或重新加载 API。
- AppEngine 认证配置仍按当前 S1/S2 权限边界管理；ProviderCapability 文件不得包含凭证。
- 应用创建者只能发现 EngineInstance 的标识、名称、类型、启用和健康状态；base URL、auth_config、凭证和实例写操作仍由管理员权限保护。
- Application 默认 private，只有管理员可设置 global；运行、画布、复制与预设开关独立校验。
- ComfyUIWorkflow 始终为 owner 私有资源，不存在 global 或跨用户共享；管理员代管记录 actor 与 owner。
- 管理员跨所有者读取或操作必须写入 identity 安全审计，至少记录 action、actor、owner、workflow、结果和时间。
- 导入时的 object_info 只能由服务端从 EngineInstance 读取，客户端不能注入；工作流 API 不返回 Engine 凭证。
- workflow-canvas 仍无正式 S1/S2；application-platform S1 第 10～14 章仅保留 deferred 设计，不属于当前实现范围。
