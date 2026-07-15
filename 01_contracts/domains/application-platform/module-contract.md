# Application Platform Module Contract

本契约实现 `product-spec.md` v0.8.0-draft。S1 引用：`US-AIAPP-039..043`、`BR-AIAPP-130..152`。

## 1. 模块边界

| 模块 | 职责 | 非职责 | S1 引用 |
| --- | --- | --- | --- |
| engine-type-registry | 从 `runtime-registry.yaml` 注册 CapabilityDefinition、ApplicationEngineType、EngineAdapter 和 OperationExecutor | 不保存账号、Provider 模型清单或管理员配置 | BR-AIAPP-140、151 |
| provider-capability-loader | 从单一目录原子加载 YAML、验证 Schema 和执行依赖、建立只读注册表与诊断 | 不递归、不覆盖、不写库、不热加载、不阻止服务启动 | US-AIAPP-039、040；BR-AIAPP-130..139 |
| engine-instance | 管理真实连接环境、鉴权配置和健康状态 | 不声明平台模型或扩张系统执行能力 | US-AIAPP-041；BR-AIAPP-140 |
| engine-binding | 绑定实例与当前加载能力并应用收紧限制 | 不复制能力清单，不允许 restrictions 扩张能力 | US-AIAPP-041；BR-AIAPP-135、137、141 |
| application-template | 维护 ProviderCapability 或 ComfyUI workflow 来源的模板草稿与不可变模板版本 | 不执行外部任务，不把 ComfyUI 伪装为 ProviderCapability | US-AIAPP-042；BR-AIAPP-142、144、145、147 |
| application | 管理 private/global Application、独立能力开关与不可变语义版本 | 不原地修改已发布版本，普通用户不得设置 global | US-AIAPP-042；BR-AIAPP-142、147、148 |
| runtime-form | 按联合能力来源计算 ApplicationVersion、Engine 约束和权限的字段交集、修正与违规 | 不持久化 RuntimeFormSchema，不信任前端选项范围 | US-AIAPP-043；BR-AIAPP-135、137、142、145、146 |
| application-run | 创建不可变执行快照、幂等创建 TaskRun、维护状态投影、Artifact 和登记状态 | 不拥有 TaskRun 状态机、Lease、Attempt 或重试；不拥有 UserAsset | US-AIAPP-043；BR-AIAPP-138、143、149、150 |

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

## 4. 数据与一致性

- ProviderCapability、ApplicationEngineType、加载结果和 RuntimeFormSchema 不建表。
- Binding 保存稳定能力 ID 与绑定时 revision，但每次解析和运行仍读取当前注册表；能力不可用时 Binding 保留且不生效。
- ApplicationTemplateVersion 和 ApplicationVersion 通过显式 publish 动作发布，发布后不可变；ApplicationVersion 使用同一应用内唯一语义版本字符串。
- ApplicationRun 固定联合能力来源 revision、EngineInstance、模板版本、输入和输出映射快照；ProviderCapability 字段只在 provider_capability 分支存在。
- TaskRun 是执行状态事实源，ApplicationRun 只接受更高 `task_resource_version` 的投影。
- ApplicationRun 先以 `task_creation_status=pending` 保存，再使用 `application_run_id + idempotency_key` 调用 task-center；成功绑定唯一 TaskRun，失败保留快照并可恢复。
- Artifact 由 application-platform 按 `application_run_id + output_key` 唯一保存；asset-library 只负责将其幂等登记为 UserAsset，登记失败不改变 TaskRun 终态。

## 5. 权限边界

- `aiapp.provider_capability.read` 可查看公开目录与状态，不返回文件路径和完整诊断。
- `aiapp.provider_capability.read_diagnostics` 仅管理员可用。
- 不定义 ProviderCapability import/create/update/enable/delete/reload 权限或接口。
- Engine、Binding、Application 和 Run 分别执行其 S2 权限码；任何能力有效性都不能替代用户权限校验。

## 6. 跨域与事件边界

- task-center 拥有 TaskRun、TaskAttempt、Lease、重试、取消和最终执行状态；application-platform 调用 `POST /api/v1/task-runs` 时传递 `application_run_id` 与幂等键，task-center 的后续事件必须回传 application_run_id。
- asset-library 拥有 UserAsset；application-platform 输出并保存 Artifact，通过 `POST /api/v1/artifact-registrations` 幂等登记，登记成功后才形成 UserAsset。
- workflow-canvas 固定引用已发布 ApplicationVersion，不保存 ProviderCapability 可变副本。
- ProviderCapability 加载仅是进程内启动步骤，不发布 `catalog_changed` 事件；运行中不存在目录变化事件。
- 对外事件仅包括 Engine 健康、应用版本发布、ApplicationRun/TaskRun 协作、状态投影和平台能力纠正事项。

## 7. 非目标

- 管理端导入或编辑 ProviderCapability。
- 多目录优先级、覆盖、远程抓取或热加载。
- ProviderCapability 数据库修订历史。
- 在本仓库维护正式实现代码、实际 migration 或部署配置文件。
- 在 workflow-canvas S1/S2 完成前实现 Canvas、Node、Edge、CanvasRun、CanvasNodeRun、升级检查或 DAG 编译；这些内容在 application-platform S1 中仅作为 deferred 产品设计保留（BR-AIAPP-152）。
