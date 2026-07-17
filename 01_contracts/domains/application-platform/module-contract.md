# Application Platform Module Contract

本契约实现 `product-spec.md` v1.0.0。S1 引用：`US-AIAPP-039..046`、`BR-AIAPP-130..163`。

## 1. 模块边界

| 模块 | 职责 | 非职责 | S1 引用 |
| --- | --- | --- | --- |
| engine-type-registry | 从 `runtime-registry.yaml` 注册 CapabilityDefinition、ApplicationEngineType、EngineAdapter 和 OperationExecutor | 不保存账号、Provider 模型清单或管理员配置 | BR-AIAPP-140、151 |
| provider-capability-loader | 从单一目录原子加载 YAML、验证 Schema 和执行依赖、建立只读注册表与诊断 | 不递归、不覆盖、不写库、不热加载、不阻止服务启动 | US-AIAPP-039、040；BR-AIAPP-130..139 |
| engine-instance | 管理真实连接环境、鉴权配置、手动/周期健康检测和安全失败摘要，并向应用创建者提供无凭证只读发现 | 不声明平台模型、扩张系统执行能力或向普通用户暴露凭证及原始上游失败载荷 | US-AIAPP-041、044、045；BR-AIAPP-140、162、163 |
| engine-binding | 绑定实例与当前加载能力并应用收紧限制 | 不复制能力清单，不允许 restrictions 扩张能力 | US-AIAPP-041；BR-AIAPP-135、137、141 |
| comfyui-workflow | 导入用户私有工作流、保存来源 object_info、派生解析结果、创建不可变实例校验并一次性转换模板首版 | 不维护工作流版本树、不共享工作流、不执行 prompt、不编辑节点、不管理后续模板版本 | US-AIAPP-044..046；BR-AIAPP-153..161 |
| application-template | 维护 ProviderCapability 或 ComfyUI workflow 来源的模板草稿与不可变模板版本 | 不执行外部任务，不把 ComfyUI 伪装为 ProviderCapability，不绕过工作流转换创建 ComfyUI 首版 | US-AIAPP-042、046；BR-AIAPP-142、144、145、147、159、161 |
| application | 管理 private/global Application、独立能力开关与不可变语义版本 | 不原地修改已发布版本，普通用户不得设置 global | US-AIAPP-042；BR-AIAPP-142、147、148 |
| runtime-form | 按联合能力来源计算 ApplicationVersion、Engine 约束和权限的字段交集、修正与违规 | 不持久化 RuntimeFormSchema，不信任前端选项范围 | US-AIAPP-043；BR-AIAPP-135、137、142、145、146 |
| application-run | 创建不可变执行快照、幂等创建 AtomicTask、维护状态投影、Artifact 和登记状态 | 不拥有 AtomicTask 状态机、Attempt 或重试；不拥有 UserAsset | US-AIAPP-043；BR-AIAPP-138、143、149、150 |

## 2. ProviderCapability 启动契约

- 配置输入：`provider_capability_directory`，默认 `./provider-capabilities`。
- 扫描范围：目录第一层 `.yaml` / `.yml` 普通文件；按文件名排序只用于产生稳定诊断，不产生覆盖优先级。
- 加载顺序：YAML 解析 → `schema_version` → JSON Schema → ID 去重 → model/operation/variant 引用 → EngineType/Adapter/Executor 一致性。
- 原子性：任一步失败时整个文件为 `unavailable`；其他文件继续加载。
- 目录失败：注册表为 `degraded` 且能力集合为空，服务启动继续。
- 运行期：注册表不可变；修改文件后必须重启。运行态诊断不写回文件或数据库。
- `runtime-registry.yaml` 是内置类型与执行映射契约；`provider-capabilities/provider-capability.schema.yaml` 是清单结构事实源；`seedance.yaml` 和 `deepseek.yaml` 是当前内置平台清单。清单中的 EngineType 和 CapabilityDefinition 必须能在 Registry 中解析。

## 3. 适配器与执行器契约

`EngineAdapter` 负责 base URL、鉴权、公共 Header、上传、平台级健康检测和公共错误映射。`OperationExecutor` 负责某个 `CapabilityDefinition` 的输入校验、供应商请求转换、提交、查询、取消和结果提取。

ProviderCapability 只能声明已由对应 ApplicationEngineType 注册的 Operation。清单不得定义可执行代码、覆盖 Adapter 或通过未知参数绕过 Executor。

### 3.1 EngineInstance 健康检测契约

- Task Center 启动后立即创建 `application-platform.engine-health-plan`，之后按全局配置周期创建；默认 30 秒，0 表示关闭自动检测。
- Task Center 使用 TaskSchedule 每轮创建 `application-platform.engine-health-plan` DAGTaskGroup；Planner 只选择 `enabled=true` 且从未检测或已超过一个周期的实例，并通过 Dynamic Fork 创建健康 AtomicTask。
- 动态任务 `max_parallelism=16`、整轮超时 5 秒，单实例超时 4 秒；上一轮未终态时 ScheduleExecution 记录 `SKIPPED_OVERLAP`。
- 每次成功落库的检测更新 `last_health_check_at`；成功清空 `unhealthy_reason`，失败保存最多 512 个 UTF-8 字符的安全摘要。
- 多副本通过 TaskSchedule 活动锁、AtomicTask 幂等和 WorkflowRuntime 持久化执行去重；resource version 冲突不得覆盖新结果，也不得重复发布状态变化事件。
- 仅健康状态变化且更新成功后发布 `engine_instance_health_changed`；列表、详情和手动检测结果返回一致的检测时间与失败摘要。

## 4. 数据与一致性

- ProviderCapability、ApplicationEngineType、加载结果和 RuntimeFormSchema 不建表。
- Binding 保存稳定能力 ID 与绑定时 revision，但每次解析和运行仍读取当前注册表；能力不可用时 Binding 保留且不生效。
- ComfyUIWorkflow 是 owner 私有的非版本化导入资源；内容、来源实例和解析结果不可修改，重新导入创建新 ID。归档只改变生命周期，不物理删除。
- API Workflow、object_info 和首版模板执行快照均使用 RFC 8785 JSON Canonicalization Scheme 生成 UTF-8 规范字节后计算 SHA-256，格式固定为 `sha256:<64 位小写十六进制>`；重复 checksum 查询必须限制在 owner 范围内。
- ComfyUIWorkflowValidation 每次重新读取目标 comfyui 实例 object_info；成功时保存不可变快照，读取失败时保存无快照的 failed 诊断记录；不提交 prompt，转换后复检不回写模板首版。
- 工作流转换在单事务内创建 ApplicationTemplate、version=1 draft ApplicationTemplateVersion 和固定关系；owner 范围幂等键唯一，同一工作流只能成功转换一次。
- 首版模板版本深拷贝 API Workflow、所选 validation 的 object_info、依赖和模板契约并由服务端计算 revision；通用模板创建 API 不接受 ComfyUI 首版原始 Workflow。
- ApplicationTemplateVersion 和 ApplicationVersion 通过显式 publish 动作发布，发布后不可变；ApplicationVersion 使用同一应用内唯一语义版本字符串。
- ApplicationRun 固定联合能力来源 revision、EngineInstance、模板版本、输入和输出映射快照；ProviderCapability 字段只在 provider_capability 分支存在。
- AtomicTask 是执行状态事实源，ApplicationRun 只接受更高 `task_resource_version` 的投影。
- ApplicationRun 先以 `task_creation_status=pending` 保存，再使用 `application_run_id + idempotency_key` 调用 task-center；成功绑定唯一 AtomicTask，失败保留快照并可恢复。
- Artifact 由 application-platform 按 `application_run_id + output_key` 唯一保存；asset-library 只负责将其幂等登记为 UserAsset，登记失败不改变 AtomicTask 终态。

## 5. 权限边界

- `aiapp.provider_capability.read` 可查看公开目录与状态，不返回文件路径和完整诊断。
- `aiapp.provider_capability.read_diagnostics` 仅管理员可用。
- 不定义 ProviderCapability import/create/update/enable/delete/reload 权限或接口。
- `aiapp.engine_instance.read` 允许应用创建者发现无凭证基础状态；`auth_config`、连接详情和所有实例写操作仍由管理员权限保护。
- Engine、Binding、Application 和 Run 分别执行其 S2 权限码；任何能力有效性都不能替代用户权限校验。
- ComfyUI 工作流没有 global 可见性；普通用户只能访问本人资源。管理员和超级管理员可以代管，但每次代管操作必须记录 actor_user_id 与 owner_user_id。
- 跨所有者代管读取或操作必须向 identity 审计能力写入 action、actor_user_id、owner_user_id、workflow_id、结果和时间；审计记录不由工作流表替代。
- 工作流读取、管理、校验和转换分别执行专属权限；转换还必须同时通过 `aiapp.application.manage`。

## 6. 跨域与事件边界

- task-center 拥有 AtomicTask、TaskAttempt、重试、取消和最终执行状态；application-platform 调用 `POST /api/v1/atomic-tasks` 时传递 `application_run_id` 与幂等键，task-center 的后续事件必须回传 application_run_id。
- asset-library 拥有 UserAsset；application-platform 输出并保存 Artifact，通过 `POST /api/v1/artifact-registrations` 幂等登记，登记成功后才形成 UserAsset。
- workflow-canvas 固定引用已发布 ApplicationVersion，不保存 ProviderCapability 可变副本。
- ProviderCapability 加载仅是进程内启动步骤，不发布 `catalog_changed` 事件；运行中不存在目录变化事件。
- 对外事件包括 Engine 健康、工作流转换、应用版本发布、ApplicationRun/AtomicTask 协作、状态投影和平台能力纠正事项。工作流转换事务提交后通过 outbox 发布 `comfyui_workflow_converted`；事件失败不回滚转换事实。

## 7. 非目标

- 管理端导入或编辑 ProviderCapability。
- 多目录优先级、覆盖、远程抓取或热加载。
- ProviderCapability 数据库修订历史。
- ComfyUI 工作流版本树、global 或跨用户共享、普通 Workflow 自动转 API Workflow、自定义节点前端 JS、节点编辑、自动修复和校验阶段真实运行。
- 在本仓库维护正式实现代码、实际 migration 或部署配置文件。
- application-platform 不拥有 Canvas、CanvasVersion、CanvasRun、CanvasNodeRun 或 DAG 编译；这些能力由已发布的 workflow-canvas S1/S2 定义。
