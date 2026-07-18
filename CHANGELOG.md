# Changelog

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
