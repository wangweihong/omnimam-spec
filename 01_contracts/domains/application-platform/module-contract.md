# Application Platform Module Contract

本契约实现 `product-spec.md` 当前草案。Gateway S1 引用通过 `modelgateway` 模块边界显式声明。

## 1. 模块边界

| 模块 | 职责 | 非职责 | S1 引用 |
| --- | --- | --- | --- |
| application-orchestration | 维护 ApplicationExecutor、应用模板/版本、RuntimeFormSchema 与 ApplicationRun，并通过 Model Gateway 解析能力和执行 Operation | 不复制 Gateway Registry、Engine、Binding、Adapter 或 Executor 私有事实 | US-AIAPP-042、043；BR-AIAPP-138、142、143 |
| comfyui-workflow | 单文件导入双来源工作流、显式生成 API、按目标实例当前目录派生解析结果、独立兼容校验和可重复模板转换 | 不维护 object-info/解析缓存、版本树、lifecycle、共享工作流、节点编辑、转换历史或后续模板版本 | US-AIAPP-044..047；BR-AIAPP-153、156、164、165、169、174、186、187、190..193 |
| comfyui-workflow-test-run | 保存试运行快照并通过 Task Center 创建三节点 DAG，聚合任务投影和受控临时预览 | 不持久化媒体正文、不登记 Artifact/Asset、不拥有任务状态机 | US-AIAPP-048；BR-AIAPP-166..168 |
| application-template | 维护 ProviderCapability 或 ComfyUI workflow 来源的模板草稿与不可变模板版本 | 不执行外部任务，不把 ComfyUI 伪装为 ProviderCapability，不绕过工作流转换创建 ComfyUI 首版 | US-AIAPP-042、046；BR-AIAPP-142、144、145、147、159、161 |
| application | 管理 private/global Application、独立能力开关与不可变语义版本 | 不原地修改已发布版本，普通用户不得设置 global | US-AIAPP-042；BR-AIAPP-142、147、148 |
| runtime-form | 按联合能力来源计算 ApplicationVersion、Engine 约束和权限的字段交集、修正与违规 | 不持久化 RuntimeFormSchema，不信任前端选项范围 | US-AIAPP-043；BR-AIAPP-135、137、142、145、146 |
| application-run | 创建不可变执行快照、幂等创建 AtomicTask、按 Application 分页读取持久化运行历史，并在 AtomicTask 终态持久化后单调投影状态与 ApplicationRun 输出到 Artifact 的引用映射 | 不拥有 AtomicTask 状态机、Artifact 内容/生命周期、Asset 或 Representation | US-AIAPP-043、050；BR-AIAPP-138、143、149、150、181..184、194 |

## 2. Model Gateway 协作契约

- ProviderCapability、Runtime Registry、ApplicationEngineType、ApplicationEngineInstance、EngineCapabilityBinding、EngineAdapter、OperationExecutor、健康检测和 ComfyUI 当前 object_info 由 `modelgateway` 拥有。
- Application Platform 通过稳定 ID、权限裁剪摘要和受控模块接口解析有效能力、读取 Engine/当前 object_info 并调用 OperationExecutor，不得查询 Gateway 私有表。
- `ApplicationExecutor` 继续归 Application Platform，负责 ApplicationRun 编排、AtomicTask 协作和向 asset-library 受控交付标准输出。
- Application Platform 保留 `ProviderCapabilityRefSummary`、`EngineInstanceRefSummary` 和历史 Engine 快照；这些是运行创建时的不可变非敏感投影，不是 Gateway 当前事实副本。
- 现有 `application-platform.engine-health` 与 `application-platform.comfyui-object-info-refresh` system_key 保持不变，仅由 Model Gateway 注册对应 ReconcileHandler。

## 3. 数据与一致性

- RuntimeFormSchema 不建表；ProviderCapability、ApplicationEngineType、EngineInstance 与 Binding 数据归属见 `modelgateway`。
- ComfyUIWorkflow 是 owner 私有的非版本化导入资源；导入不选择或保存实例，也不读取 object_info。源文件不可修改，重新导入创建新 ID，不定义 archive、restore 或 lifecycle。
- API Workflow 使用 RFC 8785 JSON Canonicalization Scheme 计算 SHA-256，重复 checksum 查询限制在 owner 范围内；object_info 不计算或保存 checksum。
- 节点、输入候选、输出候选和依赖按请求中的目标实例当前目录计算，不写入工作流表。
- visual_workflow 显式转换请求必须携带 EngineInstance；服务端只使用类型为 comfyui、enabled、online 且当前目录未过期的实例完成图解析与 API Workflow 校验，失败不保存部分结果，实例引用不写入工作流。
- ComfyUIWorkflowValidation 读取目标实例当前目录，只保存不可变结果、摘要、诊断和时间；不保存目录正文或 checksum，不提交 prompt。
- 工作流转换在单事务内创建新的 ApplicationTemplate 与 version=1 draft ApplicationTemplateVersion；owner 范围幂等键唯一，相同工作流可用不同幂等键重复转换，工作流不保存转换状态或历史。
- 转换直接选择 ComfyUI EngineInstance，并在事务内按其当前目录重新校验；历史 validation 不作为请求输入。每次转换创建新的模板与首版，版本只深拷贝 API Workflow 和模板契约，revision 不包含 object_info 或派生依赖；通用模板创建 API 不接受 ComfyUI 首版原始 Workflow。
- Application Platform 从 Model Gateway 读取按 `operation_executors` key 字典序派生的能力名称数组，不复制 Runtime Registry。
- ApplicationTemplateVersion 和 ApplicationVersion 通过显式 publish 动作发布，发布后不可变；ApplicationVersion 使用同一应用内唯一语义版本字符串。
- ApplicationRun 固定联合能力来源 revision、EngineInstance、模板版本、输入和输出映射快照；ProviderCapability 字段只在 provider_capability 分支存在。
- ApplicationRun 创建与详情响应返回 Application、ApplicationVersion、ApplicationTemplateVersion、ProviderCapability、EngineInstance 和 AtomicTask 的一跳摘要。同域关系优先从 ApplicationRun 创建快照读取，旧数据缺少快照时才在 owner/visibility 边界内读取当前投影；AtomicTask 通过 Task Center 受控只读服务解析，禁止直接查询 Task Center 私有表。摘要缺失不使 ApplicationRun 响应失败。
- ApplicationRun 的 Artifact 引用是 application-platform 保存的有界只读投影，必须直接提供输出名、媒体类型、处理/登记状态、资源版本及可用的 Asset 导航 ID；客户端禁止按 `artifact_id` 逐项调用 asset-library。需要实时 Artifact 正文或受保护内容时才显式进入 asset-library 单资源流程。
- AtomicTask 是执行状态事实源，ApplicationRun 只接受更高 `task_resource_version` 的投影。
- ApplicationRun 先以 `task_creation_status=pending` 保存，再使用 `application_run_id + idempotency_key` 调用 task-center；成功绑定唯一 AtomicTask，失败保留快照并可恢复。
- 公共 API 创建的独立运行先保存 ApplicationRun，再幂等创建唯一 `application-platform.run` AtomicTask。Canvas Application 节点不得走该任务创建路径。
- Canvas Worker 在 DAG 已解析最终输入后调用内部 `EnsureCanvasApplicationRun`；稳定键为 owner、`canvas_run_id` 与 `execution_key`，返回的 ApplicationRun 必须绑定请求中已经存在的 AtomicTask。
- `EnsureCanvasApplicationRun` 必须校验 AtomicTask functionRef、Canvas/Node 关联、ApplicationVersion、最终输入和当前 Engine/runtime；重复调用修复同一绑定，禁止请求 Task Center 创建新任务。
- `application-platform.run` 是规范 functionRef；`application.execute` 不再是可注册运行时名称。
- Artifact 由 asset-library 按稳定 producer key 保存；application-platform 只维护 `application_run_id + output_key + sequence -> artifact_id` 引用和更高 resource_version 的只读投影。
- ApplicationExecutor 调用 Model Gateway OperationExecutor 并编排归一化输出，只能向 asset-library 交付字节流、受控上传会话或可信存储引用；不得交付凭证、任意 URL、私网地址或原始响应。
- Artifact 每次处理、预览或登记变化由 asset-library 同事务写 outbox；application-platform 不向 SSE 发布竞争性的 Artifact 生命周期事件。

## 4. 权限边界

- ProviderCapability、EngineInstance 和 Binding 权限码由 `modelgateway/permissions.yaml` 定义；Application Platform 调用 Gateway 时必须传递当前主体并接受同等权限裁剪。
- Application 和 Run 执行本领域 S2 权限码；任何 Gateway 能力有效性都不能替代用户权限校验。
- OpenAPI 的 `x-conditional-permissions` 表示在基础 `x-permission` 之外按资源上下文追加校验：`cross_owner` 在目标 owner 与当前主体不同时要求对应权限，`global_visibility` 在创建 global Application 或修改 global 可见性及公开能力开关时要求对应权限；实现不得按角色名替代条件权限校验。
- ComfyUI 工作流没有 global 可见性；普通用户只能访问本人资源。管理员和超级管理员只有同时拥有具体操作权限与 `aiapp.comfyui_workflow.manage_all` 才可代管，每次代管操作必须记录 actor_user_id 与 owner_user_id。
- 跨所有者代管读取或操作必须向 identity 审计能力写入 action、actor_user_id、owner_user_id、workflow_id、结果和时间；审计记录不由工作流表替代。
- 工作流读取、管理、校验和转换分别执行专属权限；转换还必须同时通过 `aiapp.application.manage`。创建或修改 global Application 还必须同时通过 `aiapp.application.manage_global`。
- 工作流试运行、取消和预览执行 `aiapp.comfyui_workflow.test`；预览不得接受客户端上游定位信息。

## 5. 跨域与事件边界

- task-center 拥有 AtomicTask、TaskAttempt、重试、取消和最终执行状态；application-platform 调用 `POST /api/v1/atomic-tasks` 时传递 `application_run_id` 与幂等键，task-center 的后续事件必须回传 application_run_id。
- asset-library 拥有 Artifact、Asset、AssetVersion 和 Representation；application-platform 输出并保存 Artifact 引用，通过 canonical Artifact API 受控交付内容，兼容期可使用旧登记入口。
- workflow-canvas 固定引用已发布 ApplicationVersion，不保存 ProviderCapability 可变副本。
- workflow-canvas 通过消费方接口读取权限裁剪后的 ApplicationVersion Canvas 契约，并在发布/运行时校验 `visibility`、`canvas_enabled`、`run_enabled`、schema 与实时运行能力；禁止读取 `aiapp_*` 私有表。
- `application_version_published` 必须与版本发布事务原子写入 outbox；消费者按 ApplicationVersion ID 幂等登记 NodeDefinition。
- `application_run_artifact_ref_changed` 是 Workflow Canvas 输出投影入口，至少携带 AtomicTask、output key、sequence 和 Artifact resource version。
- Engine 健康和平台能力纠正事项由 Model Gateway 发布；本领域消费健康事件并拥有工作流转换、应用版本发布、ApplicationRun/AtomicTask 协作、ApplicationRun Artifact 引用映射和状态投影事件。Artifact 处理/登记事件由 asset-library 发布。
- WorkflowTestRun 只向 Task Center 提交已注册的 comfyui.submit、comfyui.poll、comfyui.collect_preview，任务参数只携带 test_run_id 和父节点输出映射。Application Platform 保存不可变的 EngineInstance 非敏感快照、输入参数覆盖快照和输出候选选择快照；collect_preview 只能按选择快照中的 node_id 收集轻量预览，不登记 Artifact/Asset。列表可按 detail=false 省略复杂快照、步骤和输出，但不得通过逐行查询 EngineInstance 拼装历史名称。
- output-candidates 的 `extractable` 由目标实例当前 `object_info.output_node` 派生；普通中间节点端口必须为 false。试运行只接受 extractable 且媒体类型为 image/text 的候选，应用模板转换只接受 extractable 候选。

## 6. 非目标

- ProviderCapability、Engine、Binding、Adapter、OperationExecutor 或 ComfyUI object-info 所有权。
- 工作流版本树、lifecycle、global 或跨用户共享、普通 Workflow 自动转 API Workflow、自定义节点前端 JS、节点编辑、自动修复和校验阶段真实运行。
- 在本仓库维护正式实现代码、实际 migration 或部署配置文件。
- application-platform 不拥有 Canvas、CanvasVersion、CanvasRun、CanvasNodeRun 或 DAG 编译；这些能力由已发布的 workflow-canvas S1/S2 定义。
