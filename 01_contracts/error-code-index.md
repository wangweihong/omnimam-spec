# Error Code Index

本文档登记所有 domain 的错误码文件位置和错误码区间。

## 1. Domain 错误码文件索引

| Domain | 错误码文件 | 说明 |
| --- | --- | --- |
| ai-chatting | `01_contracts/domains/ai-chatting/errors.yaml` | AI 聊天话题、消息、助手、生成、翻译和访问控制错误码 |
| user-model | `01_contracts/domains/user-model/errors.yaml` | 用户 Provider、模型清单、默认模型、健康检测、Gateway 委托映射和访问控制错误码 |
| modelgateway | `01_contracts/domains/modelgateway/errors.yaml` | ProviderCapability 启动加载、引擎、绑定、Adapter/Executor 与 ComfyUI object_info 错误码 |
| application-platform | `01_contracts/domains/application-platform/errors.yaml` | ComfyUI 工作流、应用契约、运行和兼容访问错误码 |
| task-center | `01_contracts/domains/task-center/errors.yaml` | AtomicTask、Group/DAG、Schedule、运行时、Attempt 与权限错误码 |
| asset-library | `01_contracts/domains/asset-library/errors.yaml` | 素材查询、访问、标签、上传、Collection、Artifact、AssetVersion 与 Representation 错误码 |
| workflow-canvas | `01_contracts/domains/workflow-canvas/errors.yaml` | NodeDefinition、Canvas 草稿、不可变版本、scope/复用运行、输出可用性和访问错误码 |
| sse | `01_contracts/domains/sse/errors.yaml` | 实时连接、游标重放、事件投影和访问错误码 |
| notification-center | `01_contracts/domains/notification-center/errors.yaml` | 通知收件箱、偏好、源事件处理和访问控制错误码 |
| mcp | `01_contracts/domains/mcp/errors.yaml` | MCP 协议、Tool/Resource 分发、Task 映射和访问控制错误码 |
| agent | `01_contracts/domains/agent/errors.yaml` | Agent、Session/Invocation、Workspace、Runtime 与访问控制错误码 |
| appstudio | `01_contracts/domains/appstudio/errors.yaml` | StudioApplication、Workspace、源码版本、Build、Release/Runtime 与访问控制错误码 |
| platform-management | `01_contracts/domains/platform-management/errors.yaml` | SystemAuthConfig、平台审计和跨 domain 管理边界错误码 |
| identity | `01_contracts/domains/identity/errors.yaml` | 认证流程、用户、RBAC、资源授权、服务主体和 PrincipalContext 错误码 |
| infrastructure | `01_contracts/domains/infrastructure/errors.yaml` | Docker Runtime、节点资源、挂载配置、Endpoint 和 Provider 对账错误码 |
| gitlab | `01_contracts/domains/gitlab/errors.yaml` | GitLabServer、GitLabProject、Pipeline 和访问控制错误码 |

## 2. 错误码区间分配

| 区间 | Domain | Module | 说明 |
| --- | --- | --- | --- |
| 110200-110399 | ai-chatting | topic | 话题可见性、状态和分支错误 |
| 110400-110599 | ai-chatting | message | 消息输入、版本和可见性错误 |
| 110600-110799 | ai-chatting | assistant | 助手可见性、系统助手保护和唯一性错误 |
| 110800-110999 | ai-chatting | quick-phrase | 快捷短语作用域和校验错误 |
| 111000-111199 | ai-chatting | generation | generation 并发、停止、重生成和可见性错误 |
| 111200-111399 | ai-chatting | translation | 翻译默认模型和翻译状态错误 |
| 111400-111599 | ai-chatting | access | AI 聊天访问和所有权错误 |
| 120200-120399 | user-model | provider | 用户 Provider 可见性、唯一性、Provider Type 和连接检测错误 |
| 120400-120599 | user-model | model | Provider 模型可见性、唯一性、模型标识和执行资格错误 |
| 120600-120799 | user-model | default-model | 默认模型缺失、候选不可用和用途错误 |
| 120800-120999 | user-model | health | 用户模型健康检测错误 |
| 121000-121199 | user-model | access | 用户模型配置访问控制错误 |
| 130200-130399 | modelgateway | provider-capability | 目录、YAML、Schema、重复 ID、执行依赖和能力可用性错误；保留既有数值区间 |
| 130400-130599 | modelgateway | engine | EngineInstance、鉴权、Binding、限制与健康可用性错误；保留既有数值区间 |
| 130600-130799 | application-platform | application | 模板来源、不可变版本、RuntimeForm 和输入校验错误 |
| 130800-130999 | application-platform | application-run | ApplicationRun、AtomicTask 投影和平台能力不匹配错误 |
| 131000-131199 | application-platform | access | Application Platform 与兼容 Gateway 权限访问错误 |
| 131200-131399 | application-platform / modelgateway | comfyui-workflow / engine-object-info | 已发布兼容共享区间：131221、131222、131243、131244 归 modelgateway，其余现有错误归 application-platform |
| 140200-140399 | task-center | orchestration | functionRef、TaskGroup 和 DAGTaskGroup 校验错误 |
| 140400-140599 | task-center | atomic-task | AtomicTask、Group/DAG 状态、幂等和可见性错误 |
| 140600-140799 | task-center | runtime | WorkflowRuntime 可用性和请求错误；140600 保留旧 Worker 错误 |
| 140800-140999 | task-center | legacy-lease | 已废弃 ExecutionLease 错误码保留区间 |
| 141000-141199 | task-center | attempt | TaskAttempt 状态与结果回写错误 |
| 141200-141399 | task-center | access | 任务中心权限与访问控制错误 |
| 141400-141599 | task-center | schedule | TaskSchedule 校验、状态和可见性错误 |
| 150200-150399 | asset-library | query | 统一选择器、自然语言解析与素材列表查询错误 |
| 150400-150599 | asset-library | labeling | Label/Tag 校验、数量限制与批量打标错误 |
| 150600-150799 | asset-library | access | 素材所有权、删除状态与可写性错误 |
| 150800-150999 | asset-library | artifact-registration | Artifact 所有权、受控内容、状态与幂等登记错误 |
| 151000-151199 | asset-library | representation | AssetRepresentation 计划、写入、不可恢复与 backfill 错误 |
| 151200-151399 | asset-library | upload | 普通/分片上传会话、内容校验与 StorageAdapter 错误 |
| 151400-151599 | asset-library | collection | Collection 层级、名称、成员与固定版本错误 |
| 160200-160399 | workflow-canvas | canvas | NodeDefinition、Canvas 草稿、图、控制状态、引用和规模错误 |
| 160400-160599 | workflow-canvas | version | CanvasVersion 查询、编译和发布错误 |
| 160600-160799 | workflow-canvas | run | CanvasRun 状态、scope、输入闭包、复用、输出可用性和幂等错误 |
| 160800-160999 | workflow-canvas | access | 工作流画布权限与访问控制错误 |
| 170200-170399 | sse | stream | 连接上限与实时流可用性错误 |
| 170400-170599 | sse | replay | 恢复游标冲突、不可见与过期错误 |
| 170600-170799 | sse | projection | 上游事件字段与版本投影错误 |
| 170800-170999 | sse | access | 实时流与历史事件访问控制错误 |
| 180200-180399 | notification-center | inbox | 通知查询、状态操作和批量请求错误 |
| 180400-180599 | notification-center | preference | 基础偏好、强制主题和未启用渠道错误 |
| 180600-180799 | notification-center | ingestion | source event、接收者解析和规则处理错误 |
| 180800-180999 | notification-center | access | 通知资源和管理员接收范围访问错误 |
| 190200-190399 | mcp | protocol | MCP 版本、JSON-RPC、传输 Header 和响应协商错误 |
| 190400-190599 | mcp | dispatch | 固定 Tool、参数 Schema、Resource URI 和分页游标错误 |
| 190600-190799 | mcp | task-mapping | MCP Tasks 协商、Binding、可见性、过期和取消错误 |
| 190800-190999 | mcp | access | JWT、MCP 权限、Origin、请求限制、配额和审计错误 |
| 200200-200399 | agent | agent-core | Agent 身份、类型、Workspace 固定绑定、状态和配额错误 |
| 200400-200599 | agent | interaction | Session、Invocation、并发、取消和 Task 映射错误 |
| 200600-200799 | agent | workspace | AgentWorkspace、Snapshot、Owner 和 StudioWorkspace 授权错误 |
| 200800-200999 | agent | runtime | AgentRuntimeProvider、Runtime 状态、操作和脱敏日志错误 |
| 201000-201199 | agent | access | Agent 领域访问控制错误 |
| 210200-210399 | appstudio | application | StudioApplication 状态和初始化模板错误 |
| 210400-210599 | appstudio | workspace | Workspace Tool、文件、ChangeSet、Revision 冲突和安全校验错误 |
| 210600-210799 | appstudio | source-version | Source Snapshot 与 StudioApplicationVersion 错误 |
| 210800-210999 | appstudio | build | StudioBuild、Task 和 Build Artifact 错误 |
| 211000-211199 | appstudio | release-runtime | RuntimeConfig、Preview、Release、部署、健康与回滚错误 |
| 211200-211399 | appstudio | access | AppStudio 领域访问控制错误 |
| 240200-240399 | infrastructure | request | Runtime 请求、Profile、模式和幂等校验错误 |
| 240400-240599 | infrastructure | placement | Docker 节点、CPU/内存/磁盘/GPU 资源错误 |
| 240600-240799 | infrastructure | runtime | InfraRuntime 状态、Provider 操作、停止和对账错误 |
| 240800-240999 | infrastructure | mount-config | 挂载、Secret/ModelAccessSpec 注入和 Endpoint 错误 |
| 250200-250399 | gitlab | server | GitLabServer、连接、credential 检测和关联删除错误 |
| 250400-250599 | gitlab | project | GitLabProject 远端操作与本地投影错误 |
| 250600-250799 | gitlab | pipeline | Pipeline 输入、创建与终态错误 |
| 250800-250999 | gitlab | access | GitLab 管理访问控制错误 |
| 220200-220399 | identity | authn / session | 登录、Token、Refresh Token 和会话错误 |
| 220400-220599 | identity | user | 用户注册、状态、删除和可见性错误 |
| 220600-220799 | identity | rbac / principal | 角色、用户组、权限和 PrincipalContext 错误 |
| 220800-220999 | identity | resource-access | ResourceAccessGrant 和资源域协作错误 |
| 221000-221199 | identity | service-account | 服务主体、凭据和轮换错误 |
| 221200-221299 | identity | principal | PrincipalContext 和跨域主体错误 |
| 230200-230399 | platform-management | auth-config | SystemAuthConfig、注册策略和配置版本错误 |
| 230400-230599 | platform-management | audit | AuditLog 查询、追加、脱敏和可用性错误 |
| 230600-230799 | platform-management | overview | 平台系统概览访问和可用性错误 |

## 3. 分配规则

- 每个模块默认预留连续错误码区间；新增 domain 优先预留 200 个连续错误码。
- 新增 domain 或模块时，必须先在本文件登记区间。
- 新增错误码时，必须确认 value 落在已登记区间内。
- 已 release 的 value 不得复用。
- 废弃错误码必须在 domain `errors.yaml` 中标记 `deprecated: true`。
- 领域迁移不得重编号；既有共享区间必须在说明中列出精确所有权，不能创建同义新 code/value。
