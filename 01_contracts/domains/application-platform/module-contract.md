# Application Platform Module Contract

本契约实现 `product-spec.md` 当前草案。S1 引用：`US-AIAPP-039..050`、`BR-AIAPP-130..180`。

## 1. 模块边界

| 模块 | 职责 | 非职责 | S1 引用 |
| --- | --- | --- | --- |
| engine-type-registry | 从 `runtime-registry.yaml` 注册 CapabilityDefinition、ApplicationEngineType、EngineAdapter 和 OperationExecutor | 不保存账号、Provider 模型清单或管理员配置 | BR-AIAPP-140、151 |
| provider-capability-loader | 从单一目录原子加载 YAML、验证 Schema 和执行依赖、建立只读注册表与诊断 | 不递归、不覆盖、不写库、不热加载、不阻止服务启动 | US-AIAPP-039、040；BR-AIAPP-130..139 |
| engine-instance | 管理真实连接环境、鉴权配置、手动/周期健康检测、ComfyUI 当前 object_info 和安全失败摘要，并向应用创建者提供无凭证只读发现 | 不声明平台模型、扩张系统执行能力、维护 object-info 历史或向普通用户暴露凭证及原始上游失败载荷 | US-AIAPP-041、044、045、049；BR-AIAPP-140、162、163、169、170、175、176 |
| engine-binding | 绑定实例与当前加载能力并应用收紧限制 | 不复制能力清单，不允许 restrictions 扩张能力 | US-AIAPP-041；BR-AIAPP-135、137、141 |
| comfyui-workflow | 单文件导入双来源工作流、显式生成 API、按目标实例当前目录派生解析结果、兼容校验和一次性模板转换 | 不维护 object-info/解析缓存、版本树、lifecycle、共享工作流、节点编辑或后续模板版本 | US-AIAPP-044..047；BR-AIAPP-153、156、159、160、164、165、169、171..174、176 |
| comfyui-workflow-test-run | 保存试运行快照并通过 Task Center 创建三节点 DAG，聚合任务投影和受控临时预览 | 不持久化媒体正文、不登记 Artifact/Asset、不拥有任务状态机 | US-AIAPP-048；BR-AIAPP-166..168 |
| application-template | 维护 ProviderCapability 或 ComfyUI workflow 来源的模板草稿与不可变模板版本 | 不执行外部任务，不把 ComfyUI 伪装为 ProviderCapability，不绕过工作流转换创建 ComfyUI 首版 | US-AIAPP-042、046；BR-AIAPP-142、144、145、147、159、161 |
| application | 管理 private/global Application、独立能力开关与不可变语义版本 | 不原地修改已发布版本，普通用户不得设置 global | US-AIAPP-042；BR-AIAPP-142、147、148 |
| runtime-form | 按联合能力来源计算 ApplicationVersion、Engine 约束和权限的字段交集、修正与违规 | 不持久化 RuntimeFormSchema，不信任前端选项范围 | US-AIAPP-043；BR-AIAPP-135、137、142、145、146 |
| application-run | 创建不可变执行快照、幂等创建 AtomicTask、维护状态投影、Artifact 处理生命周期和登记状态 | 不拥有 AtomicTask 状态机、Attempt 或重试；不拥有 UserAsset | US-AIAPP-043、050；BR-AIAPP-138、143、149、150、177..180 |

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

- application-platform 向 Task Center ReconcileRegistry 注册 `application-platform.engine-health`；Task Center 以同名唯一 system_key 原子确保 SYSTEM RECONCILE TaskSchedule。
- 计划默认为六段 `*/30 * * * * *`、`UTC`、`max_parallelism=16`、`max_items_per_run=1000`、单实例超时 4 秒和整轮超时 5 秒；管理员可在受控范围内修改，启动补建不覆盖已保存值。
- 巡检器以稳定 EngineInstance ID 为 checkpoint，分批读取 `enabled=true` 实例并直接并发探测；每轮不创建 Planner DAGTaskGroup 或健康 AtomicTask，未完成分块下轮重试。
- 上一轮未终态时 ScheduleExecution 记录 `SKIPPED_OVERLAP`；轮次历史仅保存 Task Center 定义的有限轻量摘要。
- 每次成功落库的检测更新 `last_health_check_at`；成功清空 `unhealthy_reason`，失败保存最多 512 个 UTF-8 字符的安全摘要。
- 多副本通过 TaskSchedule 活动锁和 WorkflowRuntime 持久化执行去重；resource version 冲突不得覆盖新结果，也不得重复发布状态变化事件。
- 仅健康状态变化且更新成功后发布 `engine_instance_health_changed`；列表、详情和手动检测结果返回一致的检测时间与失败摘要。

### 3.2 ComfyUI object_info 当前目录契约

- application-platform 向 Task Center ReconcileRegistry 注册 `application-platform.comfyui-object-info-refresh`；Task Center 以同名唯一 system_key 原子确保 SYSTEM RECONCILE TaskSchedule。
- 默认使用六段 `0 0 3 * * *`、`UTC`，只扫描 `application_engine_type_id=comfyui`、`enabled=true`、`health_status=online` 的实例；跳过项不创建 action、TaskGroup 或 AtomicTask。
- 每个实例只在 `aiapp_comfyui_engine_object_info` 保存一份当前目录；成功时完整校验后原子 upsert，失败保留旧行；实例删除通过外键 cascade 删除目录。
- 定时和手动刷新复用同一串行化边界，较早请求不得覆盖较新成功结果；不保存 checksum、尝试历史、目录版本或刷新状态机。
- `refreshed_at` 超过 48 小时即动态视为 stale；读取可返回 stale 目录，导入、解析、校验、转换、模板发布、RuntimeFormSchema 和运行必须拒绝使用。
- `GET /engine-instances/{id}/object-info` 返回当前原始目录并支持 gzip 内容协商；`POST /engine-instances/{id}/object-info/refresh` 只返回轻量状态，不在工作流、校验、模板或运行响应中复制目录。

## 4. 数据与一致性

- ProviderCapability、ApplicationEngineType、加载结果和 RuntimeFormSchema 不建表。
- Binding 保存稳定能力 ID 与绑定时 revision，但每次解析和运行仍读取当前注册表；能力不可用时 Binding 保留且不生效。
- ComfyUIWorkflow 是 owner 私有的非版本化导入资源；内容和来源实例不可修改，重新导入创建新 ID，不定义 archive、restore 或 lifecycle。
- API Workflow 使用 RFC 8785 JSON Canonicalization Scheme 计算 SHA-256，重复 checksum 查询限制在 owner 范围内；object_info 不计算或保存 checksum。
- 节点、输入候选、输出候选和依赖按请求中的目标实例当前目录计算，不写入工作流表。
- ComfyUIWorkflowValidation 读取目标实例当前目录，只保存不可变结果、摘要、诊断和时间；不保存目录正文或 checksum，不提交 prompt。
- 工作流转换在单事务内创建 ApplicationTemplate、version=1 draft ApplicationTemplateVersion 和固定关系；owner 范围幂等键唯一，同一工作流只能成功转换一次。
- 转换在事务内按所选 validation 对应实例当前目录重新校验；首版模板版本只深拷贝 API Workflow 和模板契约，revision 不包含 object_info 或派生依赖；通用模板创建 API 不接受 ComfyUI 首版原始 Workflow。
- ApplicationTemplateVersion 和 ApplicationVersion 通过显式 publish 动作发布，发布后不可变；ApplicationVersion 使用同一应用内唯一语义版本字符串。
- ApplicationRun 固定联合能力来源 revision、EngineInstance、模板版本、输入和输出映射快照；ProviderCapability 字段只在 provider_capability 分支存在。
- AtomicTask 是执行状态事实源，ApplicationRun 只接受更高 `task_resource_version` 的投影。
- ApplicationRun 先以 `task_creation_status=pending` 保存，再使用 `application_run_id + idempotency_key` 调用 task-center；成功绑定唯一 AtomicTask，失败保留快照并可恢复。
- Artifact 由 application-platform 按 `application_run_id + output_key` 唯一保存；处理状态为 `created/transferring/processing/ready/failed/deleted`，预览就绪独立记录，只有 ready 且有 `content_ref` 时可请求登记。
- asset-library 只负责将 ready Artifact 幂等登记为 UserAsset；登记失败不改变 AtomicTask 终态，Artifact 删除不级联删除 UserAsset。
- Artifact 每次处理、预览或登记变化与 outbox 同事务提交；SSE 投影按 `artifact_id + resource_version` 幂等，事件不携带正文、凭证或长期公开 URL。

## 5. 权限边界

- `aiapp.provider_capability.read` 可查看公开目录与状态，不返回文件路径和完整诊断。
- `aiapp.provider_capability.read_diagnostics` 仅管理员可用。
- 不定义 ProviderCapability import/create/update/enable/delete/reload 权限或接口。
- `aiapp.engine_instance.read` 允许应用创建者发现无凭证基础状态并读取可见 ComfyUI 实例当前目录；`auth_config`、连接详情和所有实例写操作仍由管理员权限保护。
- Engine、Binding、Application 和 Run 分别执行其 S2 权限码；任何能力有效性都不能替代用户权限校验。
- ComfyUI 工作流没有 global 可见性；普通用户只能访问本人资源。管理员和超级管理员可以代管，但每次代管操作必须记录 actor_user_id 与 owner_user_id。
- 跨所有者代管读取或操作必须向 identity 审计能力写入 action、actor_user_id、owner_user_id、workflow_id、结果和时间；审计记录不由工作流表替代。
- 工作流读取、管理、校验和转换分别执行专属权限；转换还必须同时通过 `aiapp.application.manage`。
- 工作流试运行、取消和预览执行 `aiapp.comfyui_workflow.test`；预览不得接受客户端上游定位信息。

## 6. 跨域与事件边界

- task-center 拥有 AtomicTask、TaskAttempt、重试、取消和最终执行状态；application-platform 调用 `POST /api/v1/atomic-tasks` 时传递 `application_run_id` 与幂等键，task-center 的后续事件必须回传 application_run_id。
- asset-library 拥有 UserAsset；application-platform 输出并保存 Artifact，通过 `POST /api/v1/artifact-registrations` 幂等登记，登记成功后才形成 UserAsset。
- workflow-canvas 固定引用已发布 ApplicationVersion，不保存 ProviderCapability 可变副本。
- ProviderCapability 加载仅是进程内启动步骤，不发布 `catalog_changed` 事件；运行中不存在目录变化事件。
- 对外事件包括 Engine 健康、工作流转换、应用版本发布、ApplicationRun/AtomicTask 协作、Artifact 处理/登记变化、状态投影和平台能力纠正事项。工作流转换事务提交后通过 outbox 发布 `comfyui_workflow_converted`；object-info 刷新不发布目录正文事件，事件失败不回滚转换事实。
- WorkflowTestRun 只向 Task Center 提交已注册的 comfyui.submit、comfyui.poll、comfyui.collect_preview，任务参数只携带 test_run_id 和父节点输出映射。Application Platform 保存不可变的 EngineInstance 非敏感快照与参数覆盖快照；列表可按 detail=false 省略复杂快照、步骤和输出，但不得通过逐行查询 EngineInstance 拼装历史名称。

## 7. 非目标

- 管理端导入或编辑 ProviderCapability。
- 多目录优先级、覆盖、远程抓取或热加载。
- ProviderCapability 数据库修订历史。
- ComfyUI object-info 历史、checksum 或独立状态机；工作流版本树、lifecycle、global 或跨用户共享、普通 Workflow 自动转 API Workflow、自定义节点前端 JS、节点编辑、自动修复和校验阶段真实运行。
- 在本仓库维护正式实现代码、实际 migration 或部署配置文件。
- application-platform 不拥有 Canvas、CanvasVersion、CanvasRun、CanvasNodeRun 或 DAG 编译；这些能力由已发布的 workflow-canvas S1/S2 定义。
