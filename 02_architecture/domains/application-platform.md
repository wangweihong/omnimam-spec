# AI 应用平台领域架构参考

本文是 application-platform v1.1.0 的架构参考。产品语义以 S1 为准，实现接口与数据结构以 S2 为准。

## 1. 架构目标

- 将 ApplicationEngineType、EngineAdapter、OperationExecutor 与易变的平台能力清单分离。
- 以启动目录中的 YAML 作为 ProviderCapability 唯一事实源，不创建数据库副本。
- 任何单个能力文件失败只导致能力级降级，不阻止应用平台服务启动。
- ProviderCapability 与 ComfyUI workflow 使用联合能力来源；ComfyUI 节点能力只由 EngineInstance 当前 object_info 提供，不复制到工作流、校验、模板或运行。
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
    E --> OI["Current ComfyUI object_info"]
    B --> F["RuntimeForm Resolver"]
    E --> WI["ComfyUI Workflow Import"]
    OI --> WI
    WI --> WV["Workflow Validation History"]
    OI --> WV
    WV --> CT["Atomic Template Conversion"]
    OI --> CT
    CT --> TV["ApplicationTemplateVersion v1 draft"]
    TV --> V["ApplicationVersion"]
    V["ApplicationVersion"] --> F
    F --> U["RuntimeFormSchema"]

    U --> AR["ApplicationRun"]
    R --> AR
    CW["TemplateVersion API Workflow + Contract"] --> AR
    OI --> AR
    E --> AR
    AR --> TR["AtomicTask / task-center"]
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
- AtomicTask、Attempt、WorkflowRuntime 或重试策略事实。

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
| ComfyUI Engine object_info | application-platform 数据库中的 EngineInstance 一对一当前目录 | 是，仅当前一份 |
| EngineCapabilityBinding | application-platform 数据库 | 是 |
| ComfyUIWorkflow | application-platform 数据库中的用户私有非版本化导入资源 | 是 |
| ComfyUIWorkflowValidation | application-platform 数据库中的不可变实例校验结果与诊断 | 是，不含 object_info |
| ApplicationTemplateVersion | application-platform 数据库 | 是 |
| ApplicationVersion | application-platform 数据库 | 是 |
| RuntimeFormSchema | 请求时计算结果 | 否 |
| ApplicationRun | application-platform 数据库 | 是 |
| Artifact | application-platform 数据库 | 是，处理状态与登记状态独立 |
| UserAsset / Artifact 登记映射 | asset-library 数据库 | 是 |
| AtomicTask / Attempt / Group / Schedule | task-center | 是 |

Binding 中的 ProviderCapability ID 没有数据库外键，创建、解析和运行时通过注册表校验。ApplicationRun 按能力来源保存 ProviderCapability revision 或 ComfyUI API Workflow、模板 revision 与实际参数执行快照，但不保存 object_info；ComfyUI 运行可执行性始终按所选实例当前目录重新判断。

ComfyUIWorkflow 不维护版本树或 lifecycle。每次导入生成新资源，只保存源文件、API Workflow、来源实例和元数据；单文件由服务端识别 visual 或 API 来源，visual 来源显式转换后才形成 API 执行事实。节点、候选项和依赖按目标实例当前目录即时计算。兼容性校验只保存结果与诊断；一次性模板转换只把 API Workflow 和模板契约深拷贝到首个 draft ApplicationTemplateVersion。

WorkflowTestRun 归 application-platform 所有，通过 Task Center 创建 `submit -> poll -> collect_preview` DAG。输出正文不落库，预览经 EngineAdapter 使用服务端 output ID 受控代理。

WorkflowTestRun 同时保存本次 EngineInstance 的非敏感身份快照和参数覆盖快照。列表投影默认只携带快照摘要、状态和进度，完整参数、步骤与输出按 detail=true 或单条详情读取；历史配置再次运行仍通过标准创建链路重新校验并创建新的 DAG。

## 7. ComfyUI 工作流导入与转换时序

```mermaid
sequenceDiagram
    participant User as 用户或代管管理员
    participant Workflow as ComfyUI Workflow Module
    participant Source as Source EngineInstance
    participant Catalog as Current object_info Store
    participant Target as Target EngineInstance
    participant Template as Application Template Module
    participant Outbox as Outbox/Audit

    User->>Workflow: 上传 API Workflow 与可选普通 Workflow
    Workflow->>Catalog: 读取来源实例当前且未过期目录
    Catalog-->>Workflow: object_info 与 refreshed_at
    Workflow->>Workflow: 原子校验与 workflow checksum
    Workflow-->>User: 私有 ComfyUIWorkflow

    User->>Workflow: 指定目标实例创建兼容性校验
    Workflow->>Catalog: 读取目标实例当前且未过期目录
    Catalog-->>Workflow: 当前目录
    Workflow->>Workflow: 保存不含目录正文的不可变 Validation
    Workflow-->>User: compatible / incompatible / failed

    User->>Workflow: 选择 compatible Validation 并提交模板契约
    Workflow->>Catalog: 重新读取 Validation 对应实例当前目录
    Workflow->>Workflow: 校验当前兼容、API ready、未转换、所有权和幂等键
    Workflow->>Template: 同一事务创建 Template 与 v1 draft
    Template-->>Workflow: 模板、版本和服务端 revision
    Workflow->>Workflow: 固定唯一转换关系
    Workflow->>Outbox: comfyui_workflow_converted
    Workflow-->>User: 原子转换结果
```

转换后的重新校验只追加诊断记录，不进入 TemplateVersion 更新路径。模板后续变化必须显式创建新版本；目录刷新只改变实时兼容性，不改写任何模板版本。

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
    App->>Task: application_run_id + idempotency_key 幂等创建 AtomicTask
    Task-->>App: 返回唯一 atomic_task_id
    App->>App: 绑定 AtomicTask，task_creation_status=created
    Task->>Worker: Conductor 分发 AtomicTask handler
    Worker->>Exec: 使用执行快照提交
    Exec->>Provider: 调用供应商 API
    Provider-->>Exec: 任务或结果
    Exec-->>Task: 状态、进度、标准输出
    Task-->>App: resource_version 投影事件
    App->>App: 标准输出形成 Artifact
    App->>App: 传输、处理、预览并进入 ready
    App->>Asset: 以 artifact_id 幂等登记 UserAsset
```

Artifact 处理事实以 application-platform 为准，状态为 `created/transferring/processing/ready/failed/deleted`；预览就绪是独立事实。处理、预览或登记变化通过 outbox 发布给 SSE 等投影消费者，投影失败不回滚 Artifact、UserAsset 或已终态 AtomicTask。

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

## 10.1 EngineInstance 周期健康检测

Application Platform 注册 `application-platform.engine-health` ReconcileHandler，Task Center 以同名 system_key 原子确保唯一 SYSTEM RECONCILE TaskSchedule。计划使用固定可复用的内部 workflow definition `task_center_reconcile_controller` 版本 1，按六段 cron 启动轻量 runtime execution，不为每轮注册 definition。

巡检器以稳定 EngineInstance ID 为 checkpoint，按 max_parallelism 分块读取已启用实例并直接探测，不创建 Planner DAGTaskGroup 或健康 AtomicTask。默认并发 16、每轮 1000 项、单实例 4 秒和整轮 5 秒；只在整块完成后推进 checkpoint。前一轮非终态时当前 ScheduleExecution 记录 `SKIPPED_OVERLAP`。

检测结果通过 EngineInstance resource version 乐观更新，旧结果不得覆盖新事实。健康状态变化时在同一业务事务中更新 EngineInstance 并写 outbox；状态未变时只更新最近检测时间与监控指标。

状态映射为：协议请求成功是 `online`，网络、超时或上游不可用是 `offline`，Adapter/协议配置异常是 `degraded`。失败详情先归一化为安全摘要再持久化和返回，禁止包含凭证、签名、完整 URL、Header 或未经处理的上游载荷。

## 10.2 ComfyUI object_info 周期刷新

Application Platform 注册 `application-platform.comfyui-object-info-refresh` ReconcileHandler，Task Center 以同名 system_key 原子确保唯一 SYSTEM RECONCILE TaskSchedule。默认计划每日 `03:00 UTC` 运行，以 EngineInstance ID 为 checkpoint，只读取 `comfyui + enabled + online` 实例；其他实例计入轻量 skipped 统计但不创建逐实例执行记录。

刷新器通过 EngineAdapter 请求 `/object_info`，完成 JSON 结构与最低节点定义校验后，在单个实例串行化边界内原子 upsert 一对一当前目录。失败不删除或部分覆盖旧目录；多副本和手动刷新并发时，较早请求不能覆盖较新成功结果。目录表只保存正文、ComfyUI 版本和 `refreshed_at`，不保存 checksum、尝试历史、版本号或状态机。

读取侧根据 `refreshed_at` 动态计算 48 小时 stale。原始目录读取允许返回 stale 数据用于诊断，并通过 HTTP `Accept-Encoding` 协商 gzip；导入、派生解析、校验、转换、模板发布、RuntimeFormSchema 和运行在读取目录后统一执行 freshness 与实例资格检查。

## 11. 安全与可见性

- 普通能力目录不暴露磁盘路径、完整加载失败详情或 Engine 凭证。
- 文件级加载诊断仅管理员可见。
- ProviderCapability 无任何写 API 或重新加载 API。
- AppEngine 认证配置仍按当前 S1/S2 权限边界管理；ProviderCapability 文件不得包含凭证。
- 应用创建者可以发现 EngineInstance 基础状态并读取可见 ComfyUI 实例当前 object_info；base URL 的可见性沿用 EngineInstance 契约，auth_config、凭证和实例写操作仍由管理员权限保护。
- Application 默认 private，只有管理员可设置 global；运行、画布、复制与预设开关独立校验。
- ComfyUIWorkflow 始终为 owner 私有资源，不存在 global 或跨用户共享；管理员代管记录 actor 与 owner。
- 管理员跨所有者读取或操作必须写入 identity 安全审计，至少记录 action、actor、owner、workflow、结果和时间。
- object_info 只能由服务端刷新到 EngineInstance 当前目录，客户端不能注入；工作流、校验、模板和运行 API 不重复内嵌目录正文，所有 API 均不返回 Engine 凭证。
- workflow-canvas 拥有 Canvas、不可变版本、DAG 编译和运行视图；application-platform 只提供已发布 ApplicationVersion 与 ApplicationRun/Artifact 协作。
