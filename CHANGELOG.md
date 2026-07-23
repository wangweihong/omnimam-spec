# Changelog

## 2026-07-23

- 收紧 ComfyUI `output-candidates.extractable`：仅 `object_info.output_node=true` 的终端输出节点可标记为可提取；普通中间端口不能用于应用模板或试运行输出，试运行进一步只接受图片/文本预览候选。
- 应用平台试运行参数扩展为输入覆盖与输出候选选择：创建请求要求至少一个 `node_id + output_index` 输出候选，详情返回不可变 `output_snapshot`，历史再次运行需重新校验输入与输出。
- `comfyui.collect_preview` 只收集输出选择快照中 node_id 对应的图片/文本轻量预览；同节点多端口选择按节点去重，仍不登记 Artifact/Asset。
- Application Platform OpenAPI 升级为 1.3.0，设计态试运行表增加 `output_snapshot_json`；复用 `ERR_AIAPP_COMFYUI_TEST_PARAMETER_INVALID` 表达输入或输出候选校验失败。
- 新增 `US-USER-ASSET-48`、`BR-USER-ASSET-82..83`，定义管理员从 AssetRepresentation 检查 Blob 与 StorageBackend 物理存储链路的能力及敏感字段边界。
- Asset Library OpenAPI 升级为 0.6.0：新增 Blob/StorageBackend 详情，将现有 StorageBackend 列表、创建、更新纳入正式契约，并统一限制为 `ADMIN`、`SUPER_ADMIN`。
- 新增 `asset.storage.read/manage` 权限与 `150610..150612` 业务错误；管理员响应按确认原样返回 object key、root 和完整 config。
- StorageBackend 设计态 schema 对齐运行态 type/root/config/enabled/readonly/quota 字段，列表新增规范 `items` 并保留等值 `backends` 兼容字段。
- 新增 `US-TASK-024`、`BR-TASK-142` 及验收标准，明确系统提供任务名称使用稳定 key 与受控参数持久化，用户自定义名称不翻译、不猜测。
- Task Center OpenAPI 升级为 1.4.0：保留 `name`，为 AtomicTask、TaskGroup、DAGTaskGroup、TaskSchedule 及 retry/owner/target/schedule source/timeline 摘要增加只读多语言名称映射，首期必含 `zh-CN` 和 `en-US`。
- Task Center 设计态 schema 为四类资源增加 `name_source`、`system_name_key` 和 `system_name_params_json`；旧数据默认为 `USER`，不执行文本启发式回填。
- 增加 name-catalog 模块边界与架构说明，后续语言通过 BCP 47 键扩展，不改变 API 结构。

## 2026-07-22

- 新增 `US-TASK-023`、`BR-TASK-133..141`，补齐 DAG 运行工作台所需的详情投影、动态节点确定性聚合、node_key 子任务过滤、规范化事件/时间线、管理员 executor 摘要、Artifact 一跳摘要与增强日志语义。
- Task Center OpenAPI 升级为 1.3.0：全部 DAG operation 统一使用已存在的 `task.group.operate`，详情返回 `DAGTaskGroupDetail`，新增 DAG events/timeline、日志 cursor/筛选/下载，并扩展 TaskAttempt、ArtifactRef 与节点执行 DTO。
- Task Center 设计态 schema 增加 DAG 执行时间、触发快照、`dag_node_key`、executor 快照和运行时投影查询索引；用户事件与时间线继续从既有 `runtime_projection_events` 生成，不新增第二套历史表。
- 新增 `US-USER-ASSET-47`、`BR-USER-ASSET-81`，Asset Library OpenAPI 升级为 0.5.0，并增加 `POST /api/v1/artifacts/batch-summaries`，为 Task Center 提供最多 200 项、owner 裁剪且不泄露不可见性差异的 Artifact 摘要。
- 同步更新 Task Center/Asset Library 权限、事件追溯、模块契约与领域架构，明确无跨域私表访问、无 N+1、无永久内容 URL 和普通用户不可见内部 Worker 标识。
- 新增 `US-TASK-022`、`BR-TASK-129..132` 与验收标准，明确运行中 Attempt 日志、Task Center 授权代理、Conductor retention、双重脱敏和 best-effort 写入语义。
- Task Center OpenAPI 升级为 1.2.0，新增 `GET /api/v1/atomic-tasks/{atomic_task_id}/attempts/{task_attempt_id}/logs`、稳定 `logs_ref`、分页日志 DTO 和 `ERR_TASK_ATTEMPT_LOG_UNAVAILABLE`。
- 扩展 Task Center 权限、WorkflowRuntime 模块契约和领域架构；执行日志不新增业务表或 SSE 事件，也不复用 Asset Library 媒体存储。

## 2026-07-21

- 整理 `workflow-canvas` S1 草案，保留多流、局部运行、结果复用、节点一对多任务、渐进制品和交互式控制节点设计，并恢复 `BR-WORKFLOW-001..016`、`US-WORKFLOW-001..004` 的已发布追溯。
- 新增 `BR-WORKFLOW-017..034` 与 `US-WORKFLOW-005..009`，补齐 NodeDefinition 注册、共享节点去重、复用资格、Artifact 所有权、用户级 SSE、必需输出、流级取消、自动/手动重试、安全和故障恢复语义。
- Canvas 执行统一对齐 AtomicTask/TaskAttempt/DAGTaskGroup：多流和复合节点展平到每个 CanvasRun 唯一 DAGTaskGroup，移除 TaskRun、DAGFlowTask、ExecutionLease、Canvas 专属 SSE 和 Canvas 自有 Artifact 事实；本轮只修改 S1，不修改或发布 S2。
- 基于新版 `workflow-canvas` S1 重写 S2 草案：22 个 OpenAPI operation 覆盖 NodeDefinition 注册/下线、Canvas 草稿/预检/发布、五种首期 scope、三种复用策略、FlowRun/NodeRun 查询、整次取消与五种手动重跑意图；成功响应改为直接业务对象，分页从 `page_num=0` 开始。
- 重构 workflow-canvas 设计态 schema，新增 NodeDefinition、CanvasFlowRun、NodeRun 多流引用、NodeRun 1:N AtomicTask 绑定、渐进输出绑定、复用来源、可靠 outbox 与对账游标，并保持 Task Center 和 Asset Library 仅通过跨域 ID/版本协作。
- 扩展 workflow-canvas 错误码、权限码、领域事件与模块契约，明确首期禁用 `selected_subgraph`、`best_effort`、`min_success`、流/分片级取消和分片手动重跑；错误码继续使用已登记的 `160200-160999` 区间。
- 解决 SSE S1/S2 与新版 Canvas 首期范围冲突：将既有 15 个 `canvas.run.*`/`canvas.node.*` 事件纳入用户级单 SSE 首期目录，`canvas.run.progressed` 携带变化 FlowRun 摘要，不新增独立 FlowRun event type，也不复制 Artifact 生命周期事实。
- 同步 workflow-canvas 与全局架构参考：编译器保留真实直接 DAG 依赖和节点最早释放，不再使用同层整体等待；列表关联摘要使用 Task Center/Asset Library 有界批量读取，禁止跨域私有表和 N+1。
- 上述 Workflow Canvas S2 与 SSE Canvas 事件同步已由用户确认为 `spec-v1.7.0`，允许作为正式实现依据；Server/Web 实施仍受 API 兼容、跨域批量接口、权限绑定和旧数据迁移门禁约束。
- 新增全局关联资源可读投影规则 `BR-GLOBAL-001..005`：保留稳定 ID，同时在列表和详情中返回权限裁剪的一跳轻量摘要，历史资源优先使用快照，跨域不得穿透私有表，列表禁止 N+1。
- 在 `skills/spec-workflow/S2.md` 增加强制评审规则：所有响应资源 ID 必须定义关联摘要或明确豁免原因，并在 release 前检查权限、缺失引用、递归边界、客户端生成和查询预算。
- Task Center OpenAPI 升级为 1.1.0，新增 `AtomicTaskSummary`、`TaskOwnerSummary`、`TaskScheduleSummary`，并为 AtomicTask root/retry/owner、TaskAttempt 所属任务、Group/DAG retry 来源和 ScheduleExecution 所属计划增加只读摘要。
- 新增 `BR-TASK-128`，同步 Task Center module contract 与架构，明确同域关联摘要的批量查询和访问控制边界。
- 新增 `BR-AIAPP-185` 与 ApplicationRun 关联摘要：创建与详情同时返回 Application、ApplicationVersion、ApplicationTemplateVersion、ProviderCapability、非敏感 EngineInstance 和 AtomicTask 一跳投影；跨域任务信息通过 Task Center 服务边界解析，内嵌 Artifact 投影禁止客户端逐项补查。
- 新增 `BR-WORKFLOW-016` 与 Canvas 运行链关联摘要：CanvasVersion、CanvasRun、重跑来源、DAGTaskGroup 和 CanvasNodeRun AtomicTask 均返回一跳投影，Task Center 关系使用受控批量读取。
- 新增 `BR-AICHAT-25`：Topic、Assistant 与助手级 QuickPhrase 返回 Assistant/ProviderModel 一跳摘要；Message 快照和当前 Topic 上下文引用明确豁免递归展开。
- 新增 `BR-USER-ASSET-80` 与 Asset Library 一跳摘要：UserAsset 当前版本、Artifact 来源/任务/运行/登记结果、Collection 父级/固定版本和 AssetRelation 两端素材均返回可读投影，并明确审计 ID 的上下文豁免与固定批次预算。
- 新增 `BR-USER-MODEL-32`：ProviderModel 的 `provider_name` 成为稳定必返投影，默认模型和健康检测关联 ID 明确复用内嵌模型或当前动作上下文，不产生补查。

## 2026-07-20

- 补齐 asset-library S1 第 23 章全部 41 个显式 endpoint 的 OpenAPI 覆盖：新增普通/分片/批量上传、Asset 详情与版本操作、Representation 内容读取、Collection、Label/Tag 单项管理、Artifact 删除、来源/引用/使用位置和完整回收站契约；保留 4 个既有扩展 operation。
- 为 asset-library 全部 45 个 operation 绑定可追溯权限，新增 Asset、内容读取、上传、Collection、标签、引用和 Artifact 删除权限；新增 upload、collection 错误码区间，并补充素材访问、版本、内容与永久删除错误。
- 对齐设计态 schema：上传会话统一使用 `sha256` 并记录模式、目标 Asset 与版本信息；Collection 表补充父子层级，成员关系补充 pinned version、role、metadata 与 created_by。
- 上述 asset-library S2 补齐已由用户确认为 `spec-v1.5.1`，允许作为正式实现依据。
- 将 Artifact、Blob、AssetVersion 与 AssetRepresentation 的事实源从 application-platform 迁移到 asset-library；application-platform 仅保留 ApplicationRun 输出引用投影，Task Center 仅保留任务与小型制品引用。
- 为 Artifact 受控内容完成增加幂等 `asset-library.artifact.process` AtomicTask；登记事务复用 Blob 同步创建 original Representation，并以 `asset_version_representation_requested` 触发 Representation build DAG。
- 增加 `asset-library.representation-backfill` SYSTEM RECONCILE 周期巡检，只为缺失、可重试或可重建的 Representation 创建幂等 `asset-library.representation.generate` AtomicTask，健康 AssetVersion 不物化任务。
- SSE 的 Artifact 生命周期事件改由 asset-library 源事件投影，并新增 `asset_version.processing_started/progressed/ready/ready_with_warnings/processing_failed` 客户端事件；AtomicTask 成功不代表 AssetVersion ready。
- 同步更新四个领域的 S1/S2、glossary、错误码区间、模块契约与架构参考；领域源事件使用下划线命名，SSE 客户端事件使用点号命名。
- 整理 SSE S1 草案，保留原有连接、信封、断线恢复、顺序、前端缓存、网关和降级设计，新增 `BR-SSE-001..016`、`US-SSE-001..005` 与验收编号。
- 将 SSE 任务事件从已废弃 TaskRun 迁移为 AtomicTask、TaskAttempt、TaskGroup 和 DAGTaskGroup，对齐 Task Center 当前状态、自动/手动重试和事实源边界。
- 补全 Artifact `created/transferring/processing/preview_ready/ready/processing_failed/registration_succeeded/registration_failed/deleted` 事件，明确 application-platform 拥有处理状态、asset-library 拥有 UserAsset，处理与登记状态独立。
- 扩展 application-platform Artifact S1/S2，新增 `BR-AIAPP-177..180`、`US-AIAPP-050`、处理/预览字段、错误码和可靠源事件。
- 扩展 task-center S1/S2，新增 `BR-TASK-120`、`US-TASK-018` 和独立 TaskAttempt 变化事件，任务事件携带所有者、项目、命名空间与 `resource_version`。
- 生成 SSE OpenAPI、设计态 schema、错误码、权限、事件目录、模块契约和领域架构参考，登记 `170200-170999` 错误码区间。
- 上述 SSE 与 Artifact 跨域修订已由用户确认为 `spec-v1.5.0`，允许作为正式实现依据；实际服务切换仍受数据回填、事件切换和兼容退役门禁约束。

## spec-v1.5.0

- 将 Artifact、Blob、AssetVersion 和 AssetRepresentation 的事实源统一迁移到 asset-library，ApplicationPlatform 仅保留可重建的 ApplicationRun 输出引用投影。
- 以 `artifact_content_completed` 和 `asset_version_representation_requested` 建立 Artifact 处理、original Representation 与首次 Representation build DAG 的可靠任务链路。
- 增加 `asset-library.representation-backfill` SYSTEM RECONCILE 周期补全，仅为真实缺口创建幂等修复 AtomicTask。
- 对齐 Task Center 的引用输出和自动重试幂等语义，并由 asset-library 向 SSE 提供 Artifact 与 AssetVersion 状态事实。
- 本版本为跨域 coordinated release；正式实现前仍需完成数据迁移、事件消费者切换、投影重建与旧路径退役验证。

## spec-v1.4.0

- 将 ComfyUI `object_info` 所有权集中到 EngineInstance 一对一当前目录；目录随实例级联删除，不保存 checksum、历史、状态机或递增版本。
- 新增每日 `application-platform.comfyui-object-info-refresh` SYSTEM RECONCILE 刷新和管理员手动刷新语义，只处理 enabled、online 的 ComfyUI 实例，失败保留最后成功目录。
- 新增 EngineInstance 当前 object-info 读取与刷新 OpenAPI；原始 JSON 支持 gzip 内容协商，实例摘要返回 available、refreshed_at 和派生 stale。
- Workflow、Validation、TemplateVersion、WorkflowTestRun 和 ApplicationRun 不再持久化或返回 object-info 正文/checksum；模板 revision 仅覆盖 API Workflow 与模板契约。
- 保留 nodes、input-candidates、output-candidates 和 dependencies，四个接口改为必须指定 EngineInstance 并按其当前目录即时派生；移除工作流 archive/restore 与 lifecycle 契约。
- 新增 `BR-AIAPP-169..176`、`US-AIAPP-049` 及验收标准，旧快照、归档和历史 compatible 权威规则显式 deprecated。

## spec-v1.3.0

- TaskSchedule 新增 MATERIALIZED/RECONCILE 执行模式、USER/SYSTEM 管理模式、ReconcileRegistry、ScheduleReconcileState、受控修复动作、轻量历史与运行时 retention 契约。
- 新增 `US-TASK-017` 与 `BR-TASK-107..119`，扩展 TaskSchedule/OpenAPI/schema/错误码/权限/事件/模块契约，并明确 SYSTEM 计划的受限操作。
- EngineInstance 周期健康检测迁移为 `application-platform.engine-health` RECONCILE 计划，不再为每轮创建 Planner DAGTaskGroup 或健康 AtomicTask。

## spec-v1.2.0

- WorkflowTestRun 新增 EngineInstance 非敏感快照、参数覆盖数量和可选完整参数快照。
- 试运行列表支持 `detail=false` 轻量投影，历史详情支持使用原配置重新确认并创建独立任务。

## 2026-07-18

- 新增 ComfyUI 单文件双来源导入、visual Workflow 显式 API 转换、WorkflowTestRun、临时预览代理与三节点 Task Center DAG 契约，新增 BR-AIAPP-164..168、US-AIAPP-047..048、BR-TASK-105..106 和 US-TASK-016。
- WorkflowRuntime 增加 `IN_PROGRESS + callbackAfterSeconds` 延迟回调语义，ComfyUI poll 等待期间不得占用 Worker；工作流试运行不登记 Artifact/Asset。
- EngineInstance 列表摘要新增 `base_url`，使实例列表直接返回执行端点，同时继续禁止列表返回 `auth_config` 等鉴权信息。
- 补充 TaskSchedule、ScheduleExecution 与实际 AtomicTask/TaskGroup/DAGTaskGroup 的双向可见关联：调度目标继承计划归属，计划与执行历史返回轻量目标摘要，全局运行列表返回来源计划摘要。
- 明确执行历史按目标类型批量补充摘要，失败、重叠跳过或目标不可用时使用模板摘要降级；禁止逐行 N+1 查询、伪造 targetId 或复制大型输入输出。
- 新增 `BR-TASK-101..104` 与 `AC-TASK-011-04..05`，同步更新 task-center OpenAPI、模块契约和架构参考。
- 修正 AtomicTask owner/childKey 唯一索引范围：仅约束 TaskGroup/DAGTaskGroup 子任务，允许周期 Schedule 每轮复用同一模板 key。
- 修正 `schedule_source` OpenAPI 所属，将其从 AtomicTask 创建请求移至只读 AtomicTask 响应。

## 2026-07-17

- 发布 `spec-v1.0.0` 任务中心破坏性重构：AtomicTask 成为唯一执行单元，TaskGroup/DAGTaskGroup 只组合 AtomicTask，TaskSchedule 统一周期与单次触发，并以 TaskAttempt、ScheduleExecution 和汇总查询保留完整历史。
- 引入 Conductor OSS 的 WorkflowRuntime 边界以及 Watermill + PostgreSQL outbox 可靠事件边界，删除新实现对 TaskRun、ExecutionLease、Worker claim、watchdog、自研 Dispatcher 和自研 DAG 状态机的依赖。
- 新增 workflow-canvas S1/S2，定义 Canvas 草稿、不可变 CanvasVersion、CanvasRun、CanvasNodeRun、拓扑分层编译、Dynamic Fork、任意无环图校验和 SSRF/RCE 防护。
- application-platform 的 ApplicationRun 绑定从 `task_run_id` 迁移为 `atomic_task_id`；Engine 健康检测改为 TaskSchedule → Planner DAGTaskGroup → Dynamic Fork，并记录重叠跳过。
- asset-library 上传完成使用事务 outbox 发布 `asset_uploaded`，task-center 按 `thumbnail:<asset_id>:<profile_version>` 幂等创建缩略图 AtomicTask。
- 新增 task-center Schedule 错误码区间与 workflow-canvas 全域错误码区间；旧 TaskRun/Lease 错误码保留并标记 deprecated。本次变更由用户于 2026-07-17 明确要求直接修改 SSOT 并发布。
- 将 application-platform 升级为 v0.9.1，补充 EngineInstance 启动即检、默认 30 秒可配置周期、仅检测启用实例、并发 5 秒超时和多副本乐观锁尽力去重语义。
- EngineInstance 列表摘要新增 `last_health_check_at` 与 `unhealthy_reason`；统一手动/周期检测的时间、状态、失败摘要持久化和返回规则，并明确敏感信息脱敏及 512 字符限制。
- 新增 `BR-AIAPP-163` 与 `AC-AIAPP-041-04..06`，同步更新 OpenAPI、模块契约和领域架构；本次变更由用户于 2026-07-17 明确确认实施。

## 2026-07-16

- 收紧 application-platform EngineInstance 鉴权契约：auth_type 与 auth_config 改为严格联合类型，none 禁止提交配置，api_key、bearer_token、ak_sk 仅接受各自必填非空凭证字段，鉴权 PATCH 必须成组提交，并同步 Runtime Registry 与设计态 schema 说明；本次仍为未 Release 草稿。
- 将 application-platform 升级为 v0.9.0-draft，新增用户私有且不带版本树的 ComfyUIWorkflow 导入管理、派生解析结果、不可变 EngineInstance 兼容性校验历史，以及一次性转换 ApplicationTemplate 首个 draft 版本的产品语义。
- 新增 `BR-AIAPP-153..162`、`US-AIAPP-044..046` 及验收标准，固化导入原子性、服务端 object_info 快照、归档恢复、管理员代管审计、无凭证实例发现、转换幂等与模板快照解耦规则。
- 新增 ComfyUI 工作流导入、列表详情、元数据更新、归档恢复、节点/输入/输出/依赖查询、兼容性校验历史和模板转换 OpenAPI；通用模板创建接口不再接受 ComfyUI 首版原始 Workflow。
- 新增 ComfyUI 工作流与校验设计态表、四项权限、`comfyui_workflow_converted` 事件、`131200-131399` 错误码区间及模块/架构契约；本次仍为未 Release 草稿，不写入 RELEASE.md。

## 2026-07-15

- 补齐 task-center S1 中 TaskCenter 从系统启动、Worker 注册、接收 ApplicationRun 运行请求、TaskRun/TaskAttempt/ExecutionLease 转换到状态回写的端到端产品语义流程，并新增 `BR-TASK-063..067`。
- 修复 application-platform v0.8.0-draft 的 S1/S2 缺口：新增 `BR-AIAPP-145..152`，统一 ProviderCapability/ComfyUI 联合能力来源、RuntimeFormSchema 数组字段与 changes/violations、模板版本显式发布、Application 语义开关和语义版本号。
- 新增 application-platform `runtime-registry.yaml`，登记 CapabilityDefinition、ApplicationEngineType、EngineAdapter、OperationExecutor、鉴权结构和映射，并覆盖 BytePlus Seedance、DeepSeek 与 ComfyUI 清单引用。
- 修复 ApplicationRun 强制 ProviderCapability 的冲突；新增可恢复 TaskRun 创建状态、联合能力快照、Artifact 持久化和 Artifact→UserAsset 独立登记状态。
- 对齐 task-center application.execute 协作：TaskRun API、SQL 和事件新增 `application_run_id` 与幂等键，应用任务不再依赖旧 adapter/operation 字段路由。
- 对齐 asset-library Artifact 登记：新增 `POST /api/v1/artifact-registrations`、`application_output` 来源、成功登记映射、权限、事件和 150800-150999 错误码区间。
- 明确 workflow-canvas 本次仍为 deferred：application-platform S1 第 10～14 章保留产品设计但不作为当前实现、验收或 Release 依据；本次不写 RELEASE.md。
- 将 application-platform S1 升级为 v0.8.0-draft：ProviderCapability 改为服务启动时从单一可配置目录加载的只读 YAML 事实源，移除管理员导入、编辑、启用、删除与热加载语义。
- 新增 `BR-AIAPP-130..144`、`US-AIAPP-039..043` 及验收标准，固化文件原子加载、重复 ID 全部失败、目录失败服务降级启动、Binding/Run revision 快照和能力不可用隔离规则。
- 在 application-platform S2 新增 YAML 表达的 JSON Schema 2020-12，以及基于 2026-07-15 官方资料核验的 Seedance 2.0/2.0 Fast、DeepSeek V4 Pro/Flash 平台能力清单。
- 重建 application-platform OpenAPI、设计态 SQL、错误码、权限码、事件和模块契约；ProviderCapability、ApplicationEngineType、加载诊断与 RuntimeFormSchema 不建表，不提供能力写入或重新加载 API。
- 同步更新应用平台架构、全局术语、端类型、task-center 协作说明和错误码区间；本次仍为未 Release 草稿，不写入 RELEASE.md。
- 增加 S1 实现细节处置规则：发现 HTTP 路径、Go 接口、前端实现细节或其他 S2 实现细节时，必须保留原文并向用户询问处理指示；未经明确指示不得删除、修改、迁移或仅作记录后视为已处理。
- 修复 S1 规则文档的标题、列表与代码围栏格式，不改变规则语义。

## 2026-07-14

- 将 application-platform S1 重构为 v0.7.0-draft，按 S1 标准模板补齐文档信息、原型来源、领域模型、实体关系、类型差异、数据来源、生命周期、领域不变量、业务规则、领域流程、用户故事、端矩阵、验收标准、非目标和待确认问题。
- 使用 INV-AIAPP-001..010、BR-AIAPP-090..129、PF-AIAPP-001..010、US-AIAPP-026..038 和对应 AC 建立追溯链；旧草稿编号保持 deprecated，不复用。
- 将 Adapter 职责、ComfyUI 能力前置对象、固定/多 Engine、不可变版本继承扩张、模板版本、SaaS 模板、画布事实源和凭证归属等冲突集中为 Q-AIAPP-001..012；全部问题关闭前禁止 S2 推导和 Release。
- 补充全局 glossary 和端类型定义，并同步 task-center 的 TaskRun 状态事实源边界、asset-library 的 Artifact → UserAsset 所有权、幂等和失败语义；未修改 application-platform S2 与架构参考。
- 对 application-platform `product-spec.md` 进行无产品语义变更的章节层级、连续编号和核心数据结构引用关系整理。
- 将现有总体组件关系、EngineType 注册、EngineAdapter、OperationExecutor、ApplicationExecutor、画布执行流程和前端实现边界迁移至领域架构参考，并将可执行代码改写为等价伪代码。
- 在 `review-notes.md` 记录命名不统一、引用但未定义、定义关系不完整及语义冲突；所有问题仅报告、未自动修正，S1/S2 定义未新增或变更。

## 2026-07-13

- 将 application-platform S1 升级为 v0.6.0-draft，以更新后的应用平台、能力注册与画布编排设计为主事实输入，统一管理员能力注册、固定 Engine、应用模板版本、应用版本和画布固定版本主线。
- 新增 CapabilityDefinition、CapabilityTemplate、CapabilityTemplateVersion、CapabilityVariant、EngineCapabilityBinding、EngineInstance、ApplicationTemplateVersion、RuntimeFormSchema 和 CapabilityCorrectionRequired 产品语义。
- 明确 CapabilityTemplateVersion、ApplicationTemplateVersion、ApplicationVersion 发布后不可变；能力变化通过新版本、人工验证和影响分析处理，系统不得自动抓取、发现、修改或发布能力事实。
- 将 providers/ 下 ModelScope、OpenAI、Seedance 清单定位为管理员录入结构示例，不把示例中的易变模型、参数和平台能力直接视为运行事实。
- 将第一阶段执行范围收敛为固定 EngineInstance，移除 ProviderOperation 绕过模板版本直建正式应用及多 Engine 自动路由语义。
- 补充 ComfyUI 普通 Workflow/API Workflow 双文件、object_info 解析、人工配置、模板快照深拷贝和输出 Asset 登记规则。
- 补充 ApplicationNode 固定已发布 ApplicationVersion、端口类型校验、DAGFlowTask 编译、ApplicationRun 与 TaskRun 运行树的跨域语义。
- 同步修订 task-center S1，统一 Worker → AppEngine → ProviderAdapter → EngineInstance 调用链，并明确 TaskRun 是状态唯一事实源、TaskAttempt/Lease/retry/cancel/externalJobId 的职责边界。
- 新增 BR-AIAPP-050..089、US-AIAPP-013..025 与 BR-TASK-051..060；旧 application-platform v0.5 编号统一标记 deprecated，不复用表达新语义。
- 更新 application-platform 计划归档；当前 application-platform 与 task-center S2 尚未对齐 v0.6.0-draft，不得 release。

## 2026-07-11

- 修正 `application-platform` 的 SaaS 与模板边界：AppTemplate 仅支持 ComfyUI 工作流；SaaS 能力由系统依据官方文档预置为版本化 ProviderOperation，并直接创建 Application，不允许用户或管理员定义 SaaS Operation schema。

## 2026-07-10

- 重构 `application-platform` 第一阶段为 ProviderAdapter/Operation 目录、工作流模板、统一输入输出端口、应用、AppEngine 路由、真实测试和 TaskRun 异步执行链路。
- 新增 CapabilityGraph、CapabilityNode、PortDefinition、InputMapping、OutputMapping 和 ApplicationOutputValue 产品及 S2 契约，ComfyUI 保留多节点图，direct SaaS Operation 直接创建应用。
- 新增 ByteDance Seedance 2.0 文生视频、图生视频、多模态参考视频 Operation，以及 OpenAI `gpt-image-2` 图像生成和编辑 Operation 语义。
- 为内置 ProviderOperation catalog 补齐外部版本口径的 `operation_version`，Seedance 使用 `seedance-2.0`，GPT Image 2 使用 `gpt-image-2`。
- 新增 `GET /api/v1/applications/{application_id}/available-engines`；无匹配项时成功返回空列表，用户可指定有使用权的匹配引擎，也可使用自动路由。
- 明确 AppEngine 只保存运行实例配置和状态，ProviderAdapter 承担平台调用协议，Worker 承担 TaskRun、Lease、重试和结果回写。
- 明确 TaskRun 是执行状态唯一事实源，AppRun 仅保存业务快照和按 `task_run_id + resource_version` 幂等更新的状态、进度与标准输出投影。
- 增加应用真实测试 `run_mode=test`、异步外部任务 `external_job_id` 恢复、引擎并发占用和大型媒体结果引用规则。
- 同步更新应用平台 S1/S2、任务中心协作语义、领域/全局架构、错误码索引和计划归档；独立 Secret Vault 继续作为后续能力，当前明文凭证风险保持不变。
- 收敛 `asset-library` 双层标签 S1 语义：Labels/Tags trim 后区分大小写，明确字段长度、Label key 保留字符、来源、数量上限和批量部分成功规则。
- 将统一选择器的分组谓词从 `group=<分组名>` 调整为 `@group=<分组名>`，保留 `group` 作为合法自定义 Label key，并固化 AND/OR 优先级、引号转义、空值与复杂度限制。
- 新增素材列表标签查询与 `POST /api/v1/assets/batch-labels` OpenAPI 契约，返回自然语言解析模式及逐素材批量结果。
- 明确自然语言仅在“无结构化意图”时降级搜索显示名、原始文件名和描述；解析异常、非法 selector 或查询失败不执行降级查询。
- 新增素材查询、标签写入和访问边界错误码及全局区间登记；补充规范化 `user_asset_labels`、`user_asset_tags` 设计态 schema 和索引建议。
- 同步更新素材库模块契约与架构参考，明确 selector AST、参数化查询、当前用户范围、标签事实源、批量事务和旧标签 JSON 回填边界。

## 2026-07-09

- 补全 `application-platform` S1/S2 设计，保留 `kind=comfyui|saas_api`，并在 `kind=saas_api` 分支新增 SaaS 平台类型和能力类型。
- 曾将 AppTemplate 用于第三方平台接口参数；该设计已在 2026-07-11 修正，SaaS 应用改为直接基于系统预置 ProviderOperation 创建。
- 收敛 AppEngine SaaS 平台配置，移除用户维护的支持能力类型、能力标签和通用健康检测配置；非 `custom_http` 平台的健康检测方式、能力矩阵、官方 endpoint 和具体接口调用规则由系统预置。
- 新增只读 SaaS 平台元数据契约，用于返回官方默认 endpoint、预置能力矩阵、是否允许 endpoint 覆盖以及是否需要 `custom_http_config`。
- 为 `custom_http` 增加独立 `custom_http_config`，至少包含 `api_path`；运行 Application 时要求 AppEngine 与 Application 的 `kind` 匹配，SaaS 分支还需平台类型匹配，并由平台预置能力矩阵支持能力类型。
- 移除 AppTemplate、Application、AppRun 和 TaskRun.input 中的操作契约/操作标识语义，模板不再承担平台 API 路径、调用方法或底层接口选择职责。
- 新增模板详情页转换成应用能力和 `POST /api/v1/app-templates/{template_id}/convert-to-application` 契约，转换结果与基于模板创建正式应用一致。
- 新增 AppRun S1/S2 契约和应用运行 API，application-platform 创建 AppRun 并通过 task-center 创建 TaskRun，TaskRun 生命周期仍归 task-center 管理。
- 增加 AppEngine 删除功能，明确未被 AppRun 引用的引擎可删除，已存在运行引用的引擎只能停用以保留历史链路。
- 扩展 AppEngine 健康检测契约，支持通过 `app_engine_id` 检测并写回已保存引擎，也支持直接传递 endpoint、认证方式和 `custom_http_config` 执行不持久化临时检测。
- 补齐 Application 与 AppRun 历史引用保护，已产生 AppRun 的 Application 禁止物理删除，并补充 CustomHttpConfig / HealthCheckResult 的 S1 模型说明。
- 同步更新 `application-platform` OpenAPI、设计态 SQL schema、错误码、权限码、事件、模块契约、错误码索引和架构参考。

## 2026-07-08

- 补充 `application-platform` 用户级 AppEngine S1/S2 契约，支持普通用户维护自己的应用引擎，管理员和超级管理员管理全量应用引擎。
- 明确 AppEngine 支持 `bearer_token`、`api_key`、`ak_sk`、`none` 认证方式，凭证明文保存和返回，前端仅做可见/不可见展示控制。
- 补充 task-center 周期性触发未停用 AppEngine 健康检测的协作语义，健康检测连接、明文凭证携带和状态写回由 application-platform 负责。
- 补充 `application-platform` 模板详情 S1 语义：支持点击模板进入详情，ComfyUI 模板基于 API JSON 展示只读节点依赖图；原 SaaS 模板设计已在 2026-07-11 移除。
- 明确 ComfyUI 模板节点依赖图仅用于查看模板结构，不执行工作流、不编辑模板内容、不还原原画布坐标；API JSON 缺少坐标时使用自动布局。
- 将 `application-platform` 应用引擎基础管理重新纳入 S1 产品事实源，当前阶段仅覆盖 AppEngine 管理和健康查看。
- 将 `EngineClass`、`EngineClaim`、`EngineProvision`、资源规格、预算确认、Worker 绑定和引擎供给流程继续保留为后续开发能力。
- 基于现有 S1/S2 补充 `02_architecture/global-architecture.md`，明确领域划分、依赖方向、运行链路、数据与事件原则以及当前架构缺口。
- 补齐领域架构参考文档：`ai-chatting`、`model-management`、`asset-library`、`application-platform`、`task-center`、`identity`、`workflow-canvas`。
- 将空的 `02_architecture/domains/ai-chat.md` 调整为按 `domain_id` 命名的 `02_architecture/domains/ai-chatting.md`。
- 调整 `application-platform` S1/S2，按最新 `identity` 内置角色补充普通用户、管理员、超级管理员能力矩阵，移除应用草稿/启用/归档生命周期，改为创建即正式应用并通过删除退出。
- 收敛 `application-platform` 模板语义，要求创建时解析模板，解析失败不创建模板，模板内容和解析变量创建后不可修改，模板名称在同一用户下唯一。
- 同步更新 `application-platform` OpenAPI、设计态 SQL schema、错误码、权限码、事件、模块契约、错误码索引和架构参考，要求创建应用时提交完整字段映射，并移除应用状态与启用接口。
- 进一步收敛 `application-platform`，移除模板归档状态和模板状态契约，明确资源创建后归属创建者本人，字段映射请求不再提交 `required`，公共应用仅作为权限范围说明且不展示业务入口。
- 为 `application-platform`、`model-management`、`task-center` 的核心列表接口补充 `sort_field` 与 `sort_order` 查询参数，覆盖名称、创建时间、更新时间、类型、状态及业务时间字段排序。

## 2026-07-06

- 收敛 `identity` S1 当前阶段能力边界，明确邮箱验证、MFA、可信设备、OAuth2/OIDC 暂不支持，并补充个人信息/邮箱修改、系统级认证配置、Token 失效和用户删除资源约束规则。
- 收敛 S2 OpenAPI 参数命名规则，要求 path/query/header 参数、请求 DTO 和响应 DTO 字段使用 `lower_snake_case`，第三方原始结构或特殊场景需显式说明例外。
- 同步迁移现有非空 `openapi.yaml` 的运行时参数和 DTO 字段命名，避免继续使用 camelCase 字段。
- 对齐 S2 SQL 通用资源元数据字段，要求资源表包含 `id`、`name`、`created_at`、`updated_at`、`description`、`extend_shadow`、`resource_version`。
- 将现有 S2 `schema.sql` 资源表的 `created_at` / `updated_at` 类型统一为 `TIMESTAMPTZ NOT NULL`，并为资源表补齐 `resource_version INTEGER DEFAULT 0`。
- 基于 `asset-library` S1 生成素材库 S2 设计态 SQL schema；`workflow-canvas` 因缺少 S1 产品事实源暂不生成业务表。
- 收敛 S2 SQL 设计态 schema 字段命名规则，要求 `schema.sql` 列名使用 `lower_snake_case`，JSON / OpenAPI 字段不强制。
- 补充 `identity` S1 用户名全局唯一且不可修改、首次登录引导标志、密码修改后强制重新登录、REGULAR_USER 删除限制和相关非目标范围。
- 补充 `identity` S1 内置角色层级，新增 ADMIN 角色，并明确初始 `admin` 账号、SUPER_ADMIN、ADMIN、REGULAR_USER 的用户删除权限边界。
- 补充 `identity` S1，新增已登录 LOCAL 用户修改当前密码规则，并明确首次启动默认创建 `admin` / `admin` 初始管理员且首次登录必须修改密码和邮箱。
- 强化 S2 元数据字段规则，明确资源创建时间和更新时间只能使用 `createdAt` / `updatedAt`，不得另建别名或重复字段。
- 修复 `ai-chatting` 和 `model-management` S2 元数据字段，将 `updateAt` 统一更正为 `updatedAt`，对齐 S1 与 S2 规则。
- 基于当前 S1 生成 `ai-chatting` 和 `model-management` S2 契约，新增 OpenAPI、设计态 SQL schema、错误码、权限码、事件和模块边界，并登记全局错误码区间。
- 收敛 `ai-chatting` 模型来源语义，明确 AI 聊天只读取 `model-management` 中当前用户自己的模型设置，不维护独立模型配置或模型清单。
- 收敛 S2 HTTP 状态码规则，仅允许 `200`、`404`、`500` 和真实重定向 `3xx`，业务成功或失败统一通过 `code` / `value` 判断。
- 同步将 `application-platform` 与 `task-center` 现有业务错误码契约改为 HTTP `200`，避免继续使用 `400`、`403`、`409` 表达业务错误。
- 收敛 `application-platform` 第一阶段 S1 产品规格，仅保留模板管理、应用管理和参数/字段映射能力。
- 将 `EngineClaim`、`EngineProvision`、Webhook、应用审核上架、公共应用/应用市场、执行、任务、订单、结果回调、引擎和基础设施编排等机制移出第一阶段事实源，并归档至 `00_product/domains/application-platform/plan-archive.md`。
- 同步收敛 `application-platform` S2 契约，更新 OpenAPI、设计态 SQL schema、错误码、权限码、事件、模块边界和错误码索引，避免 S1/S2 冲突。
- 基于 `task-center` S1 生成任务中心 S2 契约草稿，新增 OpenAPI、设计态 SQL schema、错误码、权限码、事件和模块边界文档，并登记全局错误码区间。
- 为 `task-center` S1 用户故事和核心业务规则补充稳定追溯编号，便于 S2 契约引用。

## 2026-07-05

- 调整 `application-platform` S1 产品规格中的角色语义，移除 `业务使用者`、`外部系统`、`应用创建者`、`平台管理员` 等旧角色表达，统一收敛为 `普通用户` 和 `系统管理员`。
- 更新 `application-platform` 功能适配矩阵、用户故事、业务规则、系统呈现策略和待确认问题，避免旧四角色模型继续作为产品事实源。
- 基于收敛后的 `application-platform` S1 生成 S2 契约草稿，新增 OpenAPI、设计态 SQL schema、错误码、权限码、事件和模块边界文档，并登记全局错误码区间。
# spec-v0.9.2

- 使用 Task Center 周期任务与 PARALLEL TaskGroup 执行 AppEngine 健康检测。
- 补充动态 TaskGroup 展开、并发、聚合、取消、超时、重试和通用幂等契约。
# spec-v0.9.3

- 修正通用 `idempotency_scope` 与 TaskRun 数据库 CHECK 约束的一致性。
