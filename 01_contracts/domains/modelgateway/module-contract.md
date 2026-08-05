# Model Gateway Module Contract

本契约实现 `modelgateway/product-spec.md` 当前迁移草案。S1 引用：`US-AIAPP-039..041`、`US-AIAPP-049`、`US-AIAPP-051..052` 及其关联业务规则。

## 1. 模块边界

| 模块 | 职责 | 非职责 | S1 引用 |
| --- | --- | --- | --- |
| engine-type-registry | 从 `runtime-registry.yaml` 注册 CapabilityDefinition、ApplicationEngineType、EngineAdapter 和 OperationExecutor | 不保存账号、Provider 模型清单或管理员配置 | BR-AIAPP-140、151 |
| provider-capability-loader | 先严格加载内置 YAML，再从单一目录原子加载外部 YAML，验证 Schema 和执行依赖并建立只读注册表与诊断 | 不递归、不允许目录覆盖内置 ID、不写库、不热加载 | US-AIAPP-039、040；BR-AIAPP-130..139、188 |
| engine-instance | 管理真实连接环境、鉴权配置、手动/周期健康检测、ComfyUI 当前 object_info 和安全失败摘要，并向应用创建者提供无凭证只读发现 | 不声明平台模型、扩张系统执行能力、维护 object-info 历史或向普通用户暴露凭证及原始上游失败载荷 | US-AIAPP-041、044、045、049；BR-AIAPP-140、162、163、169、170、175、176 |
| engine-binding | 管理 manual 绑定，并为匹配 EngineType 的实例原子创建、启动补齐 required_immutable 系统绑定 | 不复制能力清单，不允许 restrictions 扩张能力或修改系统绑定 | US-AIAPP-041；BR-AIAPP-135、137、141、189 |
| provider-type-registry | 维护稳定 ProviderType 到 Adapter、CapabilityDefinition 到 OperationExecutor 的内部映射，并输出不含内部实现 ID 的只读投影 | 不保存用户 Provider，不允许客户端注册 Adapter 或 Executor | US-AIAPP-051；BR-AIAPP-195、196 |
| provider-adapter | 统一应用 Provider 协议、鉴权、连接测试、模型发现、模型探测和安全错误归一化 | 不保存用户模型健康事实，不直接返回凭证明文或未经处理的上游响应 | US-AIAPP-051；BR-AIAPP-196、198、202 |
| model-route-resolver | 按 `PlatformEngineTarget` 或 `UserModelTarget` 派生请求级 `ResolvedModelRoute` | 不建表、不提供 CRUD、不读取 User Model 私有表 | US-AIAPP-052；BR-AIAPP-197..200 |
| operation-executor | 按 CapabilityDefinition 解析并调用已注册 OperationExecutor，返回协议无关结果 | 不拥有 ApplicationRun、GenerationRun、AtomicTask 或用户模型事实 | US-AIAPP-052；BR-AIAPP-201、203、204 |


## 2. ProviderCapability 启动契约

- 内置输入：编译进服务的 `provider-capabilities/*.yaml`；结构或语义无效时服务拒绝启动。
- 目录输入：`provider_capability_directory`，默认 `./provider-capabilities`。
- 扫描范围：目录第一层 `.yaml` / `.yml` 普通文件；按文件名排序只用于产生稳定诊断，不产生覆盖优先级。
- 加载顺序：内置清单 → 目录 YAML 解析 → `schema_version` → JSON Schema → ID 去重/保留 ID → kind 对应语义 → EngineType/Adapter/Executor 一致性。
- 原子性：目录文件任一步失败时整个文件为 `unavailable`；其他目录文件及内置能力继续可用。
- 目录失败：注册表为 `degraded`，目录能力为空但内置能力保留，服务启动继续。
- 运行期：注册表不可变；修改文件后必须重启。运行态诊断不写回文件或数据库。
- `runtime-registry.yaml` 是内置类型与执行映射契约；`provider-capabilities/provider-capability.schema.yaml` 是清单结构事实源；`comfyui.yaml` 是内置 engine_binding，`seedance.yaml` 和 `deepseek.yaml` 是目录 catalog。catalog 的 EngineType、CapabilityDefinition 和 Executor 必须能解析；engine_binding 必须解析 EngineType 与 Adapter。

### 2.1 字段维度与固定组合

- `kind`：`catalog` 提供模型/Operation/Variant；`engine_binding` 只提供引擎身份。
- `origin`：加载器只读派生为 `builtin` 或 `directory`，不接受外部清单声明。
- `binding_policy`：`manual` 允许管理员管理绑定；`required_immutable` 只允许系统创建和维护。
- DeepSeek、Seedance 固定为 `catalog + directory + manual`；ComfyUI 固定为 `engine_binding + builtin + required_immutable`。
- `kind=engine_binding` 不得进入 Provider ApplicationTemplate、RuntimeForm Variant 或 Provider OperationExecutor 路径。

### 2.2 ComfyUI 系统绑定

- 新建 comfyui EngineInstance 与唯一系统绑定在同一数据库事务提交，任一失败必须整体回滚。
- API Server 和 TaskWorker 启动时幂等补齐既有实例；唯一索引与 upsert 保证多副本收敛，并将 revision、enabled 和 restrictions 恢复为当前内置事实。
- 系统绑定的 `system_managed` 为只读派生字段；绑定管理 API 不允许创建、更新、禁用或删除它。
- EngineInstance 删除时绑定通过 `ON DELETE CASCADE` 清理；历史运行继续依赖自身不可变快照。

## 3. 适配器与执行器契约

`EngineAdapter` 负责 base URL、鉴权、公共 Header、上传、平台级健康检测和公共错误映射。`OperationExecutor` 负责某个 `CapabilityDefinition` 的输入校验、供应商请求转换、提交、查询、取消和结果提取。

ProviderCapability 只能声明已由对应 ApplicationEngineType 注册的 Operation。清单不得定义可执行代码、覆盖 Adapter 或通过未知参数绕过 Executor。

### 3.1 EngineInstance 健康检测契约

- Model Gateway 向 Task Center ReconcileRegistry 注册 `application-platform.engine-health`；Task Center 以同名唯一 system_key 原子确保 SYSTEM RECONCILE TaskSchedule。
- 计划默认为六段 `*/30 * * * * *`、`UTC`、`max_parallelism=16`、`max_items_per_run=1000`、单实例超时 4 秒和整轮超时 5 秒；管理员可在受控范围内修改，启动补建不覆盖已保存值。
- 巡检器以稳定 EngineInstance ID 为 checkpoint，分批读取 `enabled=true` 实例并直接并发探测；每轮不创建 Planner DAGTaskGroup 或健康 AtomicTask，未完成分块下轮重试。
- 上一轮未终态时 ScheduleExecution 记录 `SKIPPED_OVERLAP`；轮次历史仅保存 Task Center 定义的有限轻量摘要。
- 每次成功落库的检测更新 `last_health_check_at`；成功清空 `unhealthy_reason`，失败保存最多 512 个 UTF-8 字符的安全摘要。
- 多副本通过 TaskSchedule 活动锁和 WorkflowRuntime 持久化执行去重；resource version 冲突不得覆盖新结果，也不得重复发布状态变化事件。
- 仅健康状态变化且更新成功后发布 `engine_instance_health_changed`；列表、详情和手动检测结果返回一致的检测时间与失败摘要。

### 3.2 ComfyUI object_info 当前目录契约

- Model Gateway 向 Task Center ReconcileRegistry 注册 `application-platform.comfyui-object-info-refresh`；Task Center 以同名唯一 system_key 原子确保 SYSTEM RECONCILE TaskSchedule。
- 默认使用六段 `0 0 3 * * *`、`UTC`，只扫描 `application_engine_type_id=comfyui`、`enabled=true`、`health_status=online` 的实例；跳过项不创建 action、TaskGroup 或 AtomicTask。
- 每个实例只在 `aiapp_comfyui_engine_object_info` 保存一份当前目录；成功时完整校验后原子 upsert，失败保留旧行；实例删除通过外键 cascade 删除目录。
- 定时和手动刷新复用同一串行化边界，较早请求不得覆盖较新成功结果；不保存 checksum、尝试历史、目录版本或刷新状态机。
- `refreshed_at` 超过 48 小时即动态视为 stale；读取可返回 stale 目录，导入、解析、校验、转换、模板发布、RuntimeFormSchema 和运行必须拒绝使用。
- `GET /engine-instances/{id}/object-info` 返回当前原始目录并支持 gzip 内容协商；`POST /engine-instances/{id}/object-info/refresh` 只返回轻量状态，不在工作流、校验、模板或运行响应中复制目录。

### 3.3 User Model Adapter 内部接口

以下接口是 `user-model -> modelgateway` 的受控模块接口，不是面向客户端的公共 HTTP CRUD：

```text
TestProviderConnection(providerType, endpoint, authType, credentialHandle, config)
  -> ProviderProbeResult

DiscoverProviderModels(providerType, endpoint, authType, credentialHandle, config)
  -> DiscoveredModel[]

ProbeProviderModel(providerType, endpoint, authType, credentialHandle, remoteModel, config)
  -> ModelProbeResult
```

- `providerType` 必须解析到 Runtime Registry 中已注册且可用的 Adapter；接口不接受调用方指定 `adapter_id` 或 `operation_executor_id`。
- Gateway 负责应用鉴权、公共 Header、超时、Provider 协议和错误归一化；`credentialHandle` 只能由受信任服务解析，响应不得返回凭证明文。
- 连接测试、发现和探测返回协议无关事实。Gateway 不持久化调用输入或结果；User Model 决定是否保存用户模型健康事实。
- 未保存 Provider 测试不得在任一领域创建 Provider、模型、健康记录或路由事实。

### 3.4 统一 Operation 执行接口

```text
ExecuteOperation(
  principal,
  target: PlatformEngineTarget | UserModelTarget,
  capabilityDefinitionId,
  input,
  executionOptions
) -> OperationExecutionResult
```

`PlatformEngineTarget` 包含平台 Engine、Binding、ProviderCapability revision 及调用方运行快照所需的稳定引用。`UserModelTarget` 只封装 User Model 签发的 `UserModelExecutionContext`；该上下文至少绑定 owner、Provider/模型稳定 ID、远端模型标识、ProviderType、CapabilityDefinition、配置版本、不透明凭证句柄和有效期。

Gateway 必须校验目标类型、Registry 映射、上下文签发者、principal 范围、有效期、能力和配置版本。`UserModelTarget` 不允许客户端直接构造 Provider 地址、凭证、Adapter ID 或 Executor ID。校验通过后，Model Route Resolver 仅在请求内派生：

```text
ResolvedModelRoute
  source_scope: platform | user
  provider_ref
  model_ref
  capability_definition_id
  operation_executor_id
  credential_handle
  config_or_capability_revision
```

`ResolvedModelRoute` 不建表、不缓存为第三份模型事实、不提供 API 或 CRUD。Gateway 返回标准化提交引用、状态、取消结果、输出或安全错误，不创建或更新 `ApplicationRun`、`GenerationRun`、`AtomicTask` 和用户模型健康事实。

## 4. 数据与一致性

- ProviderCapability、ApplicationEngineType 和加载结果不建表，当前事实来自只读 Registry。
- `aiapp_engine_instances`、`aiapp_comfyui_engine_object_info`、`aiapp_engine_capability_bindings` 由 Model Gateway Schema 定义，表名和全部约束保持兼容。
- Binding 保存稳定能力 ID 与绑定时 revision；manual 绑定每次解析读取当前注册表，required_immutable 绑定由启动 reconcile 更新到内置 revision。
- Application Platform、ComfyUIWorkflow 和 ApplicationRun 只保存稳定 Gateway ID、不可变 revision 或非敏感快照，不得查询 Gateway 私有表。
- EngineInstance 删除前通过受控引用检查确认不存在 Application Platform 历史运行引用，现有数据库 FK 继续作为最终一致性保护。
- ApplicationExecutor 将标准 Operation 请求交给 Model Gateway；OperationExecutor 返回归一化提交引用、状态、取消结果、失败或标准输出，不拥有 ApplicationRun、AtomicTask 或 Artifact 生命周期。
- Gateway 不保存 `UserModelProvider`、`UserProviderModel`、`UserDefaultModelConfig`、用户模型健康事实或 `UserModelExecutionContext`，也不查询 User Model 私有表。
- ProviderType、Adapter 与 Executor 的内部映射只来自 `runtime-registry.yaml`；User Model 只消费移除内部 ID 后的稳定 ProviderType 投影。

## 5. 权限边界

- `aiapp.provider_capability.read` 可查看公开目录与状态，不返回文件路径和完整诊断。
- `aiapp.provider_capability.read_diagnostics` 仅管理员和超级管理员可用。
- `aiapp.engine_instance.read` 返回权限裁剪的非敏感 Engine 摘要和可见 ComfyUI 当前目录，不返回 `auth_config`。
- `aiapp.engine_instance.manage` 与 `aiapp.engine_binding.manage` 仅管理员和超级管理员可用。
- 权限字符串保留 `aiapp.*` 兼容标识；迁移不得产生同义新权限码。
- Gateway API 的通用权限失败继续使用 Application Platform 所有的 `ERR_AIAPP_PERMISSION_DENIED`，不复制或重编号。

## 6. 跨域与事件边界

- Application Platform 通过受控模块边界消费 ProviderCapability、Engine、Binding、当前 `object_info` 和 OperationExecutor，不读取 Model Gateway 私有表。
- Application Platform 通过 `PlatformEngineTarget` 调用 `ExecuteOperation`；ApplicationRun 编排和执行快照仍归 Application Platform。
- User Model 通过稳定 ProviderType 调用连接测试、模型发现和模型探测，并为合格用户模型签发执行上下文；Gateway 不读取其私有表。
- AI Chat 使用 User Model 执行上下文构造 `UserModelTarget` 并调用 `ExecuteOperation`；GenerationRun 及模型、能力、配置版本快照仍归 AI Chat。
- Task Center 保持现有 system_key，并调度 Model Gateway 注册的 Engine 健康与 object-info ReconcileHandler。
- `engine_instance_health_changed` 由 `modelgateway.engine-instance` 发布，Application Platform 路由消费者按 EngineInstance ID 查询最新事实。
- `provider_capability_correction_required` 由 `modelgateway.operation-executor` 发布，事件不自动修改能力清单。
- ProviderCapability 加载仍是进程内启动步骤，不发布目录变化事件。
- ApplicationRun、AtomicTask、Artifact 与 ApplicationVersion 事件继续由其原领域拥有。

## 7. 非目标

- 管理端导入、编辑或热加载 ProviderCapability。
- ProviderCapability 数据库修订历史或 ComfyUI object-info 历史。
- Application、Template、ApplicationRun、ComfyUIWorkflow、Task、Artifact、Asset 或 Canvas 所有权。
- 将 User Model 内部协作接口暴露为新的公共 HTTP CRUD，或新增错误码、权限码、表名和调度 key。
- 保存用户 Provider、模型、默认配置、用户模型健康事实或 `ResolvedModelRoute`。
- 正式实现代码、实际 migration 或部署配置。
