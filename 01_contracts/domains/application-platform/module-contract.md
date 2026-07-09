# Application Platform Module Contract

本文档定义 `application-platform` 第一阶段 S2 模块边界。产品语义以 `00_product/domains/application-platform/product-spec.md` 为准。

## 1. 模块边界

### template

- 负责 ComfyUI 工作流模板和 SaaS API 请求模板的创建、解析、查询、元数据更新、删除和引用关系查询。
- 负责维护模板解析变量和模板引用计数。
- 模板创建后不允许修改模板类型、模板内容或解析变量。
- 不负责调用 SaaS API、运行 ComfyUI 工作流或管理任何运行资源。

### application

- 负责基于模板创建正式应用、承接模板详情页转换应用、维护应用元数据、整体保存字段映射和删除应用。
- 创建应用时必须一次性提交完整字段映射，且字段映射必须来自模板解析变量。
- 当应用基于 `kind=saas_api` 的模板创建时，负责继承模板的 SaaS 平台类型和能力类型，并保存应用固化参数。
- 应用不维护业务状态字段；应用存在即为正式应用，删除后不保留历史查看。
- 删除应用前必须确认不存在 AppRun 引用；无 AppRun 引用时删除应用必须删除字段映射并更新模板引用关系。
- 负责创建 AppRun、渲染运行参数快照、校验运行所选 AppEngine，并委托 task-center 创建 TaskRun。
- 不负责后续阶段的交付、共享、通知、订单、计费或资源编排能力。

### app-engine

- 负责用户级 AppEngine 的创建、查询、更新、停用、删除和健康状态展示。
- 负责保存和返回 AppEngine 明文认证配置；前端仅做可见/不可见展示控制。
- 负责根据 `auth_type` 解释 `auth_config`，并在健康检测时携带对应明文凭证连接 AppEngine 平台。
- 负责提供系统预置的 SaaS 平台元数据，包括官方默认 endpoint 和能力矩阵。
- 当 `engine_type=saas_api` 时，负责保存 SaaS 平台类型、endpoint 和 `custom_http` 专用配置；非 `custom_http` SaaS 平台不保存用户自定义健康检测配置。
- 删除 AppEngine 前必须确认不存在 AppRun 引用；存在引用时禁止物理删除，只允许停用。
- 负责接收 task-center 周期性健康检测任务触发，按平台预置策略或 `custom_http_config` 执行具体连接检测并写回健康状态。
- 负责支持两类健康检测：使用 `app_engine_id` 的已保存引擎检测会写回健康状态；直接提交 endpoint、认证方式和 `custom_http_config` 的临时检测只返回检测结果，不保存凭证、不创建或更新 AppEngine。
- 不负责 EngineClass、EngineClaim、EngineProvision、资源供给、预算确认或 Worker 绑定。

### application-run

- 负责 AppRun 查询、状态展示、输出摘要和失败原因展示。
- 负责根据 task-center TaskRun 状态变化同步 AppRun 状态。
- 负责保存用户输入快照和渲染后的运行参数快照，运行开始后不受模板、应用或引擎后续修改影响。
- 不负责 TaskRun 状态机、Worker 领取、Lease、重试、取消和故障恢复。
- 第一阶段不提供 AppRun 取消或重试入口；如需取消或重试运行，由 task-center 的 TaskRun 能力表达。

### access

- 负责普通用户、管理员和超级管理员在模板、应用、字段映射和应用引擎上的可见性与管理边界。
- 普通用户只能管理自己的模板、应用和应用引擎；管理员和超级管理员可以管理全部用户的模板、应用和应用引擎。
- 管理员或超级管理员修改他人应用时，不得改变应用 owner_user_id。
- 管理员或超级管理员修改他人应用引擎时，不得改变应用引擎 owner_user_id。
- 公共应用本阶段仅作为权限范围说明，不展示业务入口。

## 2. 输入输出边界

| 模块 | 输入 | 输出 |
| --- | --- | --- |
| template | 模板名称、描述、类型、原始配置 | 模板记录、解析变量、引用关系 |
| application | 模板引用、应用名称、描述、完整字段映射、固化参数、运行输入和 AppEngine 选择 | 正式应用、字段映射、AppRun、TaskRun 创建请求、删除结果 |
| app-engine | 引擎名称、类型、SaaS 平台类型、访问地址、明文认证配置、custom_http_config、已保存引擎健康检测触发、临时健康检测参数、删除请求 | 应用引擎记录、平台元数据、健康状态、临时健康检测结果、删除结果 |
| application-run | TaskRun 状态变化、运行查询条件 | AppRun 状态、输出摘要、失败原因 |
| access | 当前用户身份、资源归属、内置角色 | 可访问资源范围、权限拒绝 |

## 3. 依赖关系

- `application` 依赖 `template` 提供模板和解析变量。
- `template` 依赖 `application` 提供引用关系，用于删除预检。
- `app-engine` 依赖 task-center 提供周期性健康检测任务调度；健康检测业务语义、明文凭证携带和状态写回由 `app-engine` 负责。
- `template` 和 `application` 依赖 `app-engine` 提供系统预置 SaaS 平台元数据，用于校验平台能力矩阵和默认 endpoint。
- `application` 依赖 `app-engine` 校验运行时所选引擎的 `engine_type`、SaaS 平台类型、平台预置能力、启用状态和健康状态。
- `application` 依赖 task-center 创建 Application 运行对应的 TaskRun；TaskRun 生命周期由 task-center 负责。
- `application-run` 消费 task-center TaskRun 状态变化，用于同步 AppRun 状态、输出摘要和失败原因。
- `access` 被 `template`、`application` 和 `app-engine` 调用以校验资源归属、ADMIN 身份和 SUPER_ADMIN 身份。

## 4. 一致性要求

- 创建模板前必须完成模板解析，解析失败不得创建模板。
- `kind=saas_api` 的模板必须保存 SaaS 平台类型和能力类型；模板不得保存平台操作标识或操作契约。
- 同一 owner_user_id 下模板名称必须唯一。
- 更新模板时只能修改名称和描述。
- 创建应用时必须确认模板存在。
- 基于 SaaS API 模板创建应用时，应用必须继承模板的 SaaS 平台类型和能力类型。
- 创建应用和保存字段映射时必须确认用户已选择可填字段的映射完整，且映射路径和字段类型属于关联模板解析变量。
- 删除模板前必须确认不存在引用该模板的应用。
- 删除应用前必须确认不存在引用该应用的 AppRun；删除应用后必须删除其字段映射，并更新模板引用关系。
- 删除 AppEngine 前必须确认不存在引用该引擎的 AppRun。
- 跨用户修改应用不得改变应用归属。
- 跨用户修改应用引擎不得改变应用引擎归属。
- 每个用户创建的资源属于创建者自己，不支持管理员或超级管理员代其他用户创建资源。
- Application 与 AppEngine 独立管理；创建或更新 Application 不指定 app_engine_id。
- AppEngine 健康检测只监听未停用应用引擎；认证方式需要凭证时必须携带明文凭证。
- 非 `custom_http` SaaS 平台的健康检测方式由 application-platform 按平台预置策略实现，用户不得提交通用健康检测配置。
- `custom_http` 平台必须使用 `custom_http_config.api_path` 表达自定义 HTTP API 路径。
- 使用 `app_engine_id` 的健康检测必须读取已保存 AppEngine 配置并写回健康状态、最近检测时间和不健康原因。
- 使用 endpoint、auth_type、auth_config 和 custom_http_config 的临时健康检测不得创建或更新 AppEngine，也不得产生 `app_engine_health_changed` 事件。
- 运行 Application 时必须指定 app_engine_id；该绑定只属于本次 AppRun，不写回 Application。
- 运行 Application 时必须校验 Application.kind 与 AppEngine.engine_type 一致。
- 运行 SaaS API Application 时必须校验 Application.saas_platform_type 与 AppEngine.saas_platform_type 一致，并校验 SaaS 平台预置能力矩阵支持 Application.capability_type。
- disabled、unknown 或 unhealthy 的 AppEngine 不得用于创建新的 AppRun。
- AppRun 必须保存用户输入快照和渲染后的运行参数快照。
- TaskRun.input 必须包含 application_id、application_run_id、app_template_id、app_engine_id、kind、saas_platform_type、capability_type 和 rendered_payload。
- 已存在 AppRun 引用的 Application 不允许物理删除，避免运行历史断链。
- 已存在 AppRun 引用的 AppEngine 不允许物理删除，避免运行历史断链。

## 5. 权限边界

- 普通用户只能读取和维护自己的模板、应用、字段映射和应用引擎。
- 普通用户只能运行自己可访问的应用和引擎，并只能查看自己的 AppRun。
- 管理员可以读取和维护全部用户的模板、应用、字段映射和应用引擎。
- 超级管理员可以读取和维护全部用户的模板、应用、字段映射和应用引擎。
- 管理员和超级管理员可以查看全部 AppRun，但不得改变运行发起用户归属。
- 普通用户只能读取和操作自己的应用；公共应用是例外的可读权限范围，但第一阶段不展示公共应用业务入口。
- 第一阶段不提供公共应用创建、审核、上架、市场或下架能力。

## 6. 事件边界

- `template` 生产 `app_template_changed`。
- `application` 生产 `application_changed` 和 `field_mapping_changed`。
- `app-engine` 生产 `app_engine_changed` 和 `app_engine_health_changed`。
- `application-run` 生产 `application_run_created` 和 `application_run_status_changed`。
- 事件用于模块内一致性维护，不表达后续阶段交付、共享、通知或资源编排语义。

## 7. 非目标范围

第一阶段模块契约不包含计划存档中的后续能力。归档内容不作为当前 S2 契约来源。
