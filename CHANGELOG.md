# Changelog

## 2026-07-09

- 补全 `application-platform` S1/S2 设计，保留 `kind=comfyui|saas_api`，并在 `kind=saas_api` 分支新增 SaaS 平台类型和能力类型。
- 明确 AppTemplate 可表示第三方平台某个接口参数总和，Application 从 AppTemplate 中抽取并固化特定参数，ModelScope z-image / klein 作为 SaaS 生图模板派生应用示例。
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
- 补充 `application-platform` 模板详情 S1 语义：支持点击模板进入详情，ComfyUI 模板基于 API JSON 展示只读节点依赖图，SaaS API 模板展示只读配置与解析变量。
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
