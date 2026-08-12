# Changelog

## Unreleased

- AppStudio 初始化新增应用级四阶段安全诊断与显式恢复：查询当前 DAG、0..1 总进度、阶段状态/Attempt/失败时间/本地化安全错误；`ERROR` reservation 按 Application ID 与 retry 幂等键稳定派生新 DAG，复用既有 Project、Hook、Repository、Workspace、Agent、Session、Message 和 Invocation。
- 新增 `GET /api/v1/studio-applications/{id}/initialization`、`POST /api/v1/studio-applications/{id}/initialization/retry` 与 `ERR_GITLAB_APPSTUDIO_DEFAULT_SERVER_UNAVAILABLE`；GitLab SourceProvider 保留默认 Server、连接、远端和 projection 的结构化错误，不再统一压缩为 AppStudio Source 错误。
- 初始化投影增加当前 DAG owner fence、条件回滚和运行中不同 retry key 状态门禁；旧 DAG 迟到事件不得覆盖新轮次。无数据库 Schema、权限码或事件变化。
- AppStudio 第三阶段：创建接口改为持久化 `CREATING` reservation 后返回 HTTP 200 与初始化 DAG ID；受信 DAG 幂等完成 GitLab Project/Hook、Revision 0、Agent/Session/Bindings 和首次 Invocation。
- 新增 AppStudio GitLab Push/Pipeline Webhook 契约、每 Project token digest、固定 Revision 的 Push -> Snapshot -> Pipeline -> Bundle Artifact -> Preview DAG，并保留 polling 最终一致性与既有 StudioRelease 生产发布权威。
- Task Center 新增受信 `CreateDomainDAGTaskGroup` 边界和 AppStudio 非 Infra handler 门禁；公共 DAG API 仍禁止 `gitlab.pipeline.run` 与 AppStudio 内部 functionRef。
- Infrastructure 补齐既有 `appstudio.preview.web-backend` SourceArchive profile 语义；GitLab CI 只构建受控 Bundle，不直连 Infrastructure 或部署 Production。
- 修正 AppStudio 初始化 reservation 合同：GitLabProject 支持远端调用前的 `CREATING` projection，远端 numeric ID/URL 可在 reservation 阶段为空，成功后切换 `READY`，失败保留 `ERROR` 以支持幂等恢复。
- AppStudio GitLab 第二阶段：GitLab 成为唯一源码正文 Provider，新增 `web-react@v1` Blueprint、默认 GitLabServer、稳定 GitLabProject 引用、Revision CommitSHA、Runtime-scoped Git access、`/workspace` tmpfs clone、Preview/Build archive 注入和 Coding Invocation 单 commit fast-forward 投影；移除 Workspace Tool/BUILT_IN 正文契约，不新增错误码、权限码、事件或公共 AppStudio 创建参数。
- 新增独立 `gitlab` domain 第一阶段 S1/S2：管理员 GitLabServer CRUD/Test、GitLabProject 创建/查询/删除、PAT 只写不读、关联删除保护和可恢复 `gitlab.pipeline.run` 外部 AtomicTask；AppStudio 契约保持不变。
- Agent/AppStudio 新增 Coding Agent Runtime 当前详情、跨 generation 历史、最近 5000 行脱敏日志和投影/实时健康诊断契约；Infrastructure logs/health 固定 `owner_reference` 资源授权、通用健康降级和 Provider/Docker 信息隐藏，新增 `appstudio.agent.runtime.logs.read`。
- AppStudio 新增当前 Coding Agent generation/session 的消息历史 facade，消息按 `(created_at DESC, id DESC)` 稳定分页；Invocation 新增稳定 `user_message_id/assistant_message_id`，供发送响应、历史和流式事件归并。
- AppStudio Invocation SSE 从 raw string 升级为 12 类类型化事件 envelope；`sequence_no` 作为 Invocation 内十进制 SSE ID，`Last-Event-ID` 只重放更大序号，唯一终态事件 flush 后关闭，已终态 Invocation 补完历史后立即关闭。
- Agent Runtime fixture 补齐统一事件 payload、先持久化后推送、无重复重放和终态关闭 release gate；高频 Invocation 事件保持在专用 SSE，不进入通用用户事件流。
- 发布 `spec-v1.19.0`：补齐 Agent MCP Binding PUT/DELETE、活动名称唯一、乐观锁、显式凭证更新模式、不可变 revision、软删除和正式错误码；删除或更新只影响下一次 Runtime 启动、恢复或显式重建。
- Runtime ensure 固定排序后的启用 Binding revision 并持久化精确 AgentRuntimeGrant；Infrastructure 新增 `MCP_SERVER_REF` consumer resolver，禁止 Worker/Infra/Provider 读取 Agent 私表。
- 固化 OpenCode `agent.coding@1.0` 的 tmpfs `/root/.config/opencode/opencode.json`、`0600`、Docker Archive/Exec 和启动门闩合同；空工具白名单拒绝全部，Hermes MCP 注入暂不支持。
- AppStudio 原子创建/回填每代默认平台 Binding；Identity/MCP 新增 `AGENT_WORKLOAD` `aud=mcp`、Agent generation/Application/Runtime/Grant 绑定、最小权限和逐请求 Grant 复核，USER JWT 行为保持不变。
- 补齐 Agent/AppStudio Coding Agent 端到端契约：所有 CHAT/CODING 统一使用 `agent.invocation.execute@1.0`，Task 仅携带 Agent、Session、Invocation、RuntimeBinding、Invocation 类型、短期授权引用、资源版本和恢复游标；消息正文、owner、Workspace、Runtime Endpoint、模型凭据、用户密钥和 Provider 配置不得进入 Task。
- AppStudio 创建请求新增初始需求、用户模型选择、可选 Coding Agent Profile、附件和幂等键，初始化事务原子创建 Application、Repository、Revision 0、Coding Agent、默认 Session、WorkspaceBinding 与 ACTIVE primary ModelBinding；事务后自动创建首条 Message/Invocation。`spec-v1.23.3` 将首次 Task 提交纳入第四初始化阶段，失败时保留 reservation 并投影 Application `ERROR`，由显式 retry 幂等恢复。
- 新增 AppStudio application-level Coding Agent 查询、消息、Invocation 查询/取消/SSE、suspend/resume/replace 契约和 generation 隔离；Invocation 聚合已应用 ChangeSet 的最终源码 Revision，历史阶段恢复继续调用 source restore 并创建新的 Restore ChangeSet/Revision，完整保留 Session、Message、Invocation、原 ChangeSet 与 Revision 历史。
- 固化 Agent Model Access Grant、AppStudio Workspace Tool Grant、Task 终态单调投影和 Hermes/OpenCode 独立协议适配边界；Worker 只执行协议和投影结果，不得代替 Coding Agent 直接调用 AppStudio `ApplyChangeSet`。`agent.invocation.execute@1.0` 正式 digest 为 `sha256:7e076a03a291c331443bc9f8638ab355b2a4ac0c71711a148c9b1065a67e0868`。
- 补齐 Hermes Endpoint 与 RuntimeOutput 契约闭环：AgentRuntimeAdapter 在 Agent、Session、Invocation 和 Runtime Binding 校验后，可用 Agent 工作负载身份调用 Infrastructure 只读 Endpoint resolve；Runtime 生命周期写操作仍统一经过 Task Center，普通 Endpoint 摘要、Agent/Task 数据、事件和日志均不得传播 `base_url`、Host Port 或私网地址。
- Infrastructure 新增 Endpoint resolve、RuntimeOutput 内容流读取与幂等 Artifact 回链 API；Docker Service 只发布 RuntimeProfile 声明的命名容器端口并绑定平台内部接口，映射与健康检查完成后 Endpoint 才进入 READY。
- Docker Job 必须从受控输出根读取声明普通文件的实际字节，拒绝目录、符号链接逃逸和根外路径，计算 `size_bytes` 与 `sha256:<64 hex>` 并复制到 Infra staging 后生成非 bearer `infra-output://<output_id>`；新增 `ERR_INFRA_ENDPOINT_NOT_READY` 与输出收集、内容不可用、完整性不一致错误码 `240804..240807`。
- `appstudio.build.execute@1.1` 成为 ACTIVE，固定 `bundle.tar.gz` 输出和 `infra.output.collect`、`infra.output.content.read` 能力；Task Worker 按 Infra 流读取、Asset Library `create -> upload -> complete`、大小/digest 双重校验和 attach 流程交付 Artifact。`1.0` 保留为 RETAINED 且历史 digest 不改写；上述 Hermes Endpoint 与 RuntimeOutput 契约闭环已由 `spec-v1.17.2` 发布。
- 将 Agent 当前完整 S1/S2 与 Asset Library/AppStudio StudioBuild producer 契约一起确认为 `spec-v1.17.1` Release；修正三域 Context、Global Context 与 Context Map 的发布状态。Agent 本身不新增或改写产品语义、API、Schema、错误码、权限码、事件和模块边界；StudioBuild producer 变更按该版本 implementation gate 作为正式实现、合并和验收依据。
- 统一 Asset Library Artifact producer 契约，新增共享 `ArtifactProducerType=application_run|canvas_run|atomic_task|studio_build` 并同步 OpenAPI 四个入口与 SQL CHECK；StudioBuild Bundle 固定使用 `producer_id=StudioBuild.id` 和 `studio-build:<studio_build_id>:bundle`，不新增重复 `studio_build_id` 或跨域外键。
- 明确 StudioBuild Artifact owner 取 `StudioBuild.owner_user_id`，仅受信 `appstudio.build.execute` 执行链路可携带服务身份与原任务 `authorization_ref` 创建；自动 TaskAttempt 重试复用同一 Artifact，新逻辑 Build 必须创建新 ID，Build 协作者、管理员角色和服务身份均不得绕过 Artifact owner-only 权限。
- AppStudio 新增 `POST /api/v1/studio-builds/batch-summaries`：每批 1..200 项、保持请求顺序，仅投影 `id/owner_user_id/name/status`，不存在或不可见统一返回 null；Asset Library 列表/详情按当前调用者批量解析并禁止读取 AppStudio 私表或产生 N+1。
- 将 `model-management` 重构为 `user-model`，产品展示名统一为 User Model；当前 S1/S2、Domain Context 和架构路径同步迁移，历史 `RELEASE.md` 记录保持原样。
- User Model canonical API 立即迁移到 `/api/v1/user-model/`，删除旧 `/model-providers`、`/provider-models`、`/default-models` 和 `/model-options` 路由，不保留别名或重定向；保留对象名、`MODEL_*` 权限、`ERR_MODEL_*`、事件名和 `user_*` 表名。
- 明确 User Model 拥有用户 Provider、模型清单、默认配置、用户模型健康事实和使用资格；Model Gateway 拥有平台 Engine/Binding/健康、Provider Adapter、发现、探测和 Operation 执行。`UserModelProvider` 不转换为 `ApplicationEngineInstance`，Gateway 不读取 User Model 私有表。
- 新增稳定 Provider Type 目录、Gateway 派生能力只读字段、`UserModelExecutionContext`、`PlatformEngineTarget`、`UserModelTarget` 和统一 `ExecuteOperation`；`ResolvedModelRoute` 仅请求级派生，不建表或提供 CRUD。
- AI Chat 通过 User Model 校验执行资格并经 Gateway 执行，保存 GenerationRun 的模型、能力和配置版本快照；Application Platform 只使用 `PlatformEngineTarget`，ApplicationRun 编排和执行快照语义保持不变。
- 上述 User Model 重构与 Model Gateway 融合规格由用户确认为 `spec-v1.17.0` Release，允许按实施门禁作为正式实现、合并和验收依据。
- 修复 AppStudio Outbox 幂等键冲突：七类领域事件统一使用 `<event_type>:<domain_key_components>` 全限定键，保留 `appstudio_outbox.idempotency_key` 单列全局唯一约束；不新增 migration、不改写历史 Outbox，旧键只随既有事件保留。
- 将 Agent/AppStudio Workspace 内化为后端事实：用户侧 Agent 创建固定为 Platform Agent，后端原子创建 AgentWorkspace 和默认 Session；Coding Agent 仅由 AppStudio 通过内部 `CreateCodingAgentForStudio` 创建。Agent 公共 DTO、Workspace Binding API、`agent.workspace.read` 和用户可见 Workspace 错误已移除。
- AppStudio 公共契约改为 StudioApplication 级 Source/Revision：删除 `/api/v1/studio-workspaces/*` 与公开 StudioWorkspace DTO，源码、搜索、ChangeSet、恢复、Snapshot 和 Preview 均以 `studio_application_id` 寻址，公共字段使用 `source_revision`，权限改为 `appstudio.source.read/write`。
- 内部 Agent/AppStudio Schema 继续保留 Workspace 表、字段、Revision 和固定 Binding 约束，不创建 migration；同步 S1、Domain Context、全局导航及 Agent/AppStudio 架构参考，并由用户确认为 `spec-v1.16.0` Release。
- 对齐 Infrastructure 已由 `spec-v1.12.0` 发布的状态元数据：同步 Domain Context、全局上下文、导航、S1 和 6 个 S2 文件，后续以 `spec-v1.15.3` 记录本次正式状态变更。
- 明确内置角色权限基线与物化责任：Identity 必须聚合各 domain `permissions.yaml` 的 `default_roles` 并幂等对账 `RolePermissionGrant`；固化 `ADMIN`/`SUPER_ADMIN` 的 Identity 用户、注册、角色、组、服务账号管理权限和 `platform.overview.read`、`platform.auth_config.read/manage`、`platform.audit.read` 基线，避免授权投影只返回少量 Identity 权限。
- AppStudio 清理未被当前 S1 定义的脚手架模板残留：移除 `StudioApplicationCreateRequest` 和 `studio_applications` Schema 中的 `template_id`、`technology_stack`；不新增模板实体或模板发现接口。
- 完成跨领域权限基线复核：为 `model-management` 4 个权限补充 `USER/ADMIN/SUPER_ADMIN` 默认角色并给全部 16 个 OpenAPI operation 增加 `x-permission`；为 notification-center 收件箱/偏好/管理员接收权限和 SSE 流/历史权限补充默认角色。
- 将 agent、appstudio、mcp、modelgateway 权限中的无效 `REGULAR_USER` 统一为 Identity 内置角色 `USER`。
- Application Platform 新增 `aiapp.comfyui_workflow.manage_all` 与 `aiapp.application.manage_global`，跨 owner 工作流代管和 global Application 变更必须在基础操作权限之外执行条件权限校验，不再按角色名隐式放行；同步 S1、OpenAPI 和 Domain Context。

- 补充素材库用户级权限的默认角色映射：`asset.*` 素材、上传、Collection、标签、引用、Artifact 浏览/登记/删除和 Representation 读取权限默认授予 `USER`、`ADMIN`、`SUPER_ADMIN`；保留 owner 隔离，不新增平台管理员共享素材语义；StorageBackend/Blob 检查继续仅限管理员，Artifact 创建和 Representation 写入继续仅限受信服务/Worker。

- 补齐 `workflow-canvas`、`application-platform`、`task-center` 的管理员/超级管理员默认权限映射，统一使用 Identity 已定义的 `USER`、`ADMIN`、`SUPER_ADMIN` 角色；新增 AI Chat 的 `ai_chat.*` 权限码、OpenAPI 权限标注及 owner 边界说明，允许管理员和超级管理员进入并操作自身聊天工作区，并同步 AI Chat Domain Context。

- Identity 认证迁移到 RFC 9807 OPAQUE：新增注册、登录和改密二阶段 API，使用一次性 exchange 与 base64url 消息；用户只保存 OPAQUE registration record，移除原始密码和 Argon2id PHC 字段契约。

## Unreleased

- 补全 Platform Management S1：定义结构化 PasswordPolicy/LoginFailurePolicy、SystemAuthConfig 单例与 `resource_version` 乐观并发、配置/AuditLog/Outbox 原子提交，以及认证配置页面冲突恢复语义。
- 补齐跨 domain AuditLog 合同：覆盖 Identity 登录、Token、密码、授权、服务账号和跨 owner 敏感操作，新增 `occurred_at`、来源服务主体校验、来源域复合幂等、内容冲突、detail 大小/嵌套限制和完整查询过滤；Identity 可靠事件不再重复充当平台审计写入通道。
- Platform OpenAPI 升级为 `0.2.0-draft`，修正错误响应 `value` 类型和 500 响应，结构化认证策略 DTO，新增审计查询参数与 `ERR_PLATFORM_AUDIT_IDEMPOTENCY_CONFLICT`；overview 错误区间扩展为 `230600-230799`。
- 同步 Platform Schema、权限、事件、模块合同和 Domain Context，并新增 `02_architecture/domains/platform-management.md`；Platform/Identity 协同规格已由用户确认为 `spec-v1.13.0` Release，允许作为正式实现依据。
- 补全 Identity S1 用户投影与管理闭环：登录/Refresh/独立查询统一返回带 `authorizationVersion`、直接/用户组角色来源、权限码和会话限制的当前主体授权投影；补充客户端失效刷新与后端实时鉴权边界。
- 新增 `RegistrationApplication` 审批、拒绝和重新申请语义；ADMIN_APPROVAL 在批准前不创建角色、会话或 Token，并补齐待审批管理、一次性初始密码、会话、资料、RBAC、共享和在线状态页面的动作、失败与恢复结果。
- 补全 ServiceAccount 直接角色、owner 受控摘要、Token 交换、凭据状态/到期/最后使用/轮换历史及一次性 Secret；补充用户删除跨域依赖聚合、短期检查快照、来源不可用 fail closed 和目标 domain 资源转移边界。
- 同步 Identity OpenAPI、设计态 Schema、错误码、权限码、可靠事件、模块合同、Domain Context、领域架构、Global Context 和 Context Map；新增 `BR-IAM-023..030`、`US-IAM-015..020`，并由用户确认为 `spec-v1.12.2` Release。
- 将旧 Workflow Canvas compile-time built-ins release 从冲突的 `spec-v1.12.0` 修正为 `spec-v1.12.1`；合同已合入当前 Task Center function registry 基线，未新增运行时循环、任务组类型、权限、事件或错误码。
- 补齐 Task Center 第一阶段 Infra-backed Function Registry：S1 固定 Agent/AppStudio 七个 canonical functionRef、合同版本冻结规则、`BR-TASK-153` 和 `US-TASK-026`；新增 registry meta-schema 与逐项 I/O、JOB/SERVICE、能力、幂等、重试、取消、超时、Infra 映射、Artifact 登记和结果 transform 合同。
- Task Center AtomicTask 新增 function contract version/digest 设计态字段和 API 投影，调用方 capability 改为 registry 派生；新增输入无效、输出无效、合同不可用和 capability 不可用错误，并同步模块契约、领域架构、Context 与导航。本轮未修改 `RELEASE.md`。
- 收敛 `agent` S1：统一 `AgentInvocation`，固定 `kind/workspace_type/workspace_id`，区分纯 CHAT 与必须关联 AtomicTask 的异步 Invocation，并补齐 Hermes/OpenCode AgentRuntimeProvider、Coding Agent 短期 Workspace Tool 授权、`base_revision` ChangeSet 和 8 条验收标准。
- 收敛 `appstudio` S1：移除旧 `StudioProject/StudioConversation/StudioApp/StudioDeployment` 事实模型，统一为 StudioApplication、Repository、Workspace/Revision/ChangeSet、Snapshot、Version、Build、RuntimeConfig、Release、RuntimeInstance；补齐 Artifact READY/digest 门禁、健康切换、回滚新建 Release 和 12 条验收标准。
- 收敛 `infrastructure` S1：修复 Coding Agent 可写 Workspace 示例，明确 output descriptor 到 Task Worker/Asset Library 的 Artifact 登记边界，固化失败幂等、Endpoint 授权、Provider 超时恢复、孤儿清理和 10 条验收标准。
- 将 Agent/Infrastructure S1 中的 Go interface 改写为产品逻辑能力；同步三个 Domain Context、`GLOBAL_CONTEXT.md` 和 `CONTEXT_MAP.md`。本轮未创建 Release，当前三域 S1/S2 仍不得作为正式实施依据。
- 按当前 S1 草稿全新生成 `agent`、`appstudio`、`infrastructure` 的 S2：OpenAPI、设计态 Schema、错误码、权限码、事件和模块契约。
- 最终一致性复核补齐 Build 成功与 current RuntimeInstance 健康门禁、回滚 Release 自引用、Agent Workspace 双层引用一致性和 Infra 内部请求摘要规则；Endpoint 契约统一为 `visibility=INTERNAL/USER_ACCESSIBLE/PUBLIC`，并记录 SSE `Last-Event-ID` 标准头命名例外。
- 新增 Infrastructure 错误码索引区间 `240200-240999`。
- 本轮不读取、不恢复旧版 Agent/AppStudio S2；三个当前 S1 保留 `US-*-001`/`BR-*-001` 机器锚点，并新增可验收的 `AC-*`，后续 S2 必须按修订后的 S1 重新校验后才能 Release。

## 2026-08-02

- 按第一阶段 Docker-only 约束重新梳理 agent、appstudio、task-center 与 infrastructure：Agent/AppStudio 的 Infra 操作统一经 `Task Center -> Task Worker -> Infra Adapter -> Infra Service`，Task Worker 不拥有业务状态，只回写运行引用、制品引用和脱敏摘要。
- 明确 Workspace 挂载矩阵：AgentWorkspace 按 Agent 授权挂载，StudioWorkspace 只能通过 AppStudio 受控授权访问，Preview 挂载当前 Workspace Revision，Build 只读固定 Snapshot，Production 只读固定 Artifact digest 且禁止可写 Workspace。
- 新增 `infrastructure` Domain Context 和架构参考，补充 Task Center 的 Task Worker/Infra Adapter 产品、模块和架构语义；第一阶段仅保留 DockerRuntimeProvider，未新增 infrastructure S2。
- 移除旧 Agent/AppStudio S2 后同步 Context 入口；两域当前只保留未 Release S1 草稿，本轮不恢复或生成新的 Agent/AppStudio S2。

- 收敛 platform-management 当前范围：移除 Platform 自有在线配置、`platform_settings`、维护模式和系统配置页面/流程；系统概览中的素材、应用、模型、任务和通知统计延期到下一阶段，当前仅保留平台基础信息与最近审计摘要。
- 补全收敛后 Platform S2：新增只读系统概览 OpenAPI、`PlatformOverview` 与 `PlatformAuditLogSummary` schema、overview 权限、230600-230699 错误码和模块查询合同；概览不新增数据库表或领域事件。
- 从 platform-management S1 移除安全与凭据模块：删除 Credential CRUD、凭据存储/加密/验证模型、`/platform/credentials` 路由、相关前端页面、错误码和后端目录候选；外部凭据继续归对应事实 domain。
- 从 platform-management S1 删除归 `asset-library` 的素材配置、归 `task-center` 的任务配置和归 `notification-center` 的通知配置，并清理对应分组与示例。
- 将 `SystemAuthConfig`、`allow_registration` 和跨 domain `AuditLog` 的事实源从 Identity 迁移到 `platform-management`；Identity 保留认证执行、配置消费和脱敏审计提交。
- 新增 platform-management 的 S1 追溯锚点、Domain Context、SystemAuthConfig/AuditLog OpenAPI、设计态 Schema、错误码、权限、事件和模块合同；Identity 删除对应 API、表、权限和审计事件事实。
- 更新全局事实归属、术语、Context Map 和错误码索引；本次迁移仍未登记 `RELEASE.md`，不得作为正式实现依据。
- 补齐 Identity S1/S2 的密码与在线状态语义：用户密码固定使用 Argon2id PHC 不可逆哈希，新增 300 秒在线窗口、有效会话派生规则和 `/api/v1/iam/auth/presence/heartbeat`；同步 Schema、OpenAPI、权限、模块合同、Context 与架构参考。
- 统一 Identity 全部 API 前缀为 `/api/v1/iam`，同步最终保留的 44 个 OpenAPI operation、S1 主要接口示例和路径参数命名；未改变 operation 语义、权限码或错误码。
- 从 Identity S1 推导完整未 Release S2：新增认证/用户/RBAC/PrincipalContext/资源授权/ServiceAccount/配置/审计 OpenAPI、设计态 Schema、错误码、权限码、可靠事件和模块合同；登记 `220200-221399` Identity 错误码区间。
- 为 Identity S1 增加 `BR-IAM-001..020` 和 `US-IAM-001..012` 追溯锚点，使每个 S2 operation、错误码、权限、事件和模块合同可回溯到产品语义。
- 结合 application-platform、asset-library、workflow-canvas、task-center、agent、appstudio、mcp、sse 和 notification-center 的下游依赖，收敛 identity S1 的跨域边界：资源 owner、created_by、visibility、project、namespace 和资源状态归资源 domain，Identity 只提供 PrincipalContext、操作权限、可选 ResourceAccessGrant 和安全审计上下文。
- 补充 USER/SERVICE_ACCOUNT 主体、受控委托 `actor_user_id`、服务主体最小权限和跨域审计语义；明确业务 domain 不得读取 IAM 私有表或信任客户端提交的 owner。
- 将 PAT、LDAP/SSO、角色继承/互斥等与当前下游合同不一致的能力收敛为延期或不支持；MCP v1 继续使用当前用户 Identity JWT，每次请求重新校验授权。
- 同步 `domains/identity/context.md`、`02_architecture/domains/identity.md`、`01_contracts/error-code-index.md`、`GLOBAL_CONTEXT.md` 和 `CONTEXT_MAP.md`；Identity S2 已建立为草稿但尚未 Release。
- Workflow Canvas 新增 `image`、`prompt`、`loop`、`group`、`promptGroup`、`output` 六个 `1.0.0` SYSTEM 内置节点，固定媒体输入、Prompt 合并、画布分组、有限循环和有序结果展示语义。
- NodeDefinition execution binding 新增 `compile_time` 与五个受控 `compiler_key`；未知编译能力不得注册或降级执行，`group` 继续使用 passive。
- `loop` 固定 count 1..99，支持 serial、batch、cascade；只展开唯一直接 Application 节点，批量单值广播，cascade 反馈端口显式且类型兼容，三种模式均使用 all_success。
- 明确有限 loop 在 Canvas 编译期展开为现有 DAGTaskGroup 的静态无环 AtomicTask，复用 1:N task binding 与 shard 顺序；Task Center 不新增任务组、运行时循环或 iteration 状态机。
- 同步 workflow-canvas OpenAPI 1.3.0、设计态 schema、模块契约、workflow-canvas/task-center Context 与 Task Center S1/S2；不新增权限、事件或错误码。

## 2026-08-01

- 原地对齐未发布的 `agent` 与 `appstudio` S1：Agent 只拥有交互、Memory、AgentWorkspace 与 AgentRuntime；AppStudio 独占 StudioApplication 的源码、Revision、Snapshot、Build、Release 与 StudioRuntimeInstance。
- Agent 新增 `workspace_type=agent|studio` 语义；Platform Agent 使用 AgentWorkspace，Coding Agent 创建时固定绑定一个 StudioWorkspace，多个 Agent 通过 ChangeSet `base_revision` 乐观并发控制共享源码。
- AppStudio 直接复用 AgentSession/AgentInvocation，不建立第二套 Agent 执行记录；StudioChangeSet 保存 agent、session、invocation 引用，Agent 删除或挂起不得影响 AppStudio 事实。
- Agent 运行抽象收敛为 `AgentRuntimeProvider`，AppStudio 部署抽象统一为 `StudioDeploymentProvider`；生成应用 Build、Release 和 Runtime 不再由 Agent 维护。
- 将 AgentInvocation 和 AppStudio Build/Deployment 对齐 AtomicTask/TaskGroup，移除 TaskRun、独立 Lease 和 Worker claim 旧语义；周期检查使用 RECONCILE，耗时修复才创建 AtomicTask。
- Build Bundle 由 asset-library 作为 `studio_application_bundle` Artifact 管理，AppStudio 只保存 Artifact ID 与 digest 历史快照，不拥有内容、存储位置、处理或登记状态。
- 将两份 S1 的精确 HTTP 路径和 Go 接口改写为产品动作与组件职责，补齐 Revision、Snapshot、Build、Artifact、Release、回滚和 Secret 失败结果。
- 为 Agent S1 新增 `BR-AGENT-001..014`、`US-AGENT-001..008`，为 AppStudio S1 新增 `BR-APPSTUDIO-001..014`、`US-APPSTUDIO-001..009`，作为结构化合同追溯锚点，不改变既有产品语义。
- 新增 Agent 完整 S2：31 个 REST/SSE operation、10 张设计态表、21 个业务错误、8 个权限码、7 个可靠领域事件和模块合同；固定 Session/Invocation/AtomicTask、AgentWorkspace、AgentRuntimeProvider 与 AppStudio Tool 边界。
- 新增 AppStudio 完整 S2：31 个 REST operation、15 张设计态表、27 个业务错误、9 个权限码、7 个可靠领域事件和模块合同；固定 Workspace/Revision、Snapshot/Version、Build/Artifact、Preview、RuntimeConfig、Release/RuntimeInstance 链路。
- 登记 Agent `200200-201199` 和 AppStudio `210200-211399` 错误码区间，所有普通业务失败继续使用 HTTP 200 和稳定 code/value；全部 API 使用 `/api/v1`。
- 新增 `domains/agent/context.md`、`domains/appstudio/context.md`，同步 Global Context、Context Map 和全局术语；两域 S1/S2 仍未 Release，且本次不新增领域架构或正式 migration。
- 将 `00_product/domains/mcp/product-spec.md` 的 S0 Draft 原位整理为 `mcp` 领域 S1 草案，协议基线为 MCP `2026-07-28`；新增 Domain Context、全局领域导航和 MCP 术语。
- MCP v1 固定为 Capability 只读发现、Application 查询/运行、ApplicationRun 查询/取消和 Asset 查询/受控上传；异步执行只映射既有 ApplicationRun/AtomicTask，不新增 CapabilityInvocation、泛化 Invocation 或独立任务队列。
- 新增 MCP 完整 S2：OpenAPI 3.1 固化 `POST /mcp`、8 个协议 method、11 个固定 Tool、6 类 Resource URI 和 Tasks 扩展；`/mcp` 作为用户确认的标准协议路径例外，不使用 `/api/v1`。
- 新增 `McpTaskBinding` 设计态 Schema、27 个 `190xxx` 错误码、5 个 MCP 权限、显式无领域事件合同、模块合同和领域架构；下游业务错误与权限继续保留源领域 code/value 和权限码。
- MCP 接入复用 Identity JWT/RBAC、ApplicationRun/AtomicTask 和 Asset Library UploadSession；OAuth/PAT、独立 MCP Scope、`input_required`/`tasks.update`、动态 Tool、直接 StorageBackend 上传继续延期。
- 上述 MCP S1/S2、Context 与架构由用户确认为 `spec-v1.9.2`，允许作为正式实现依据；Identity JWT/Audit 的精确合同仍受 Identity S2 门禁。
- 新增 `modelgateway` 领域，将 CapabilityDefinition、ProviderCapability、ApplicationEngineType、ApplicationEngineInstance、EngineCapabilityBinding、EngineAdapter、OperationExecutor、Runtime Registry、健康检测和 ComfyUI 当前 `object_info` 从 application-platform 原样迁移。
- 保留既有 API 路径、DTO、`AIAPP` BR/US/AC、`ERR_AIAPP_*` code/value、`aiapp.*` 权限、`aiapp_*` 表、事件名和调度 key；仅调整事实源文件、`owning_domain` 与事件 producer/consumer 归属。
- ApplicationExecutor、ComfyUIWorkflow、应用模板/版本、RuntimeFormSchema 与 ApplicationRun 继续归 application-platform，并通过受控模块边界消费 Model Gateway。
- 移动 Runtime Registry 与 ProviderCapability Schema/清单，拆分 OpenAPI、设计态 Schema、错误码、权限、事件、模块契约和领域架构；同步全局 Context、导航、术语和错误码索引。
- 删除未完成且未形成 S1 文件的 `model-integration` Context 草稿；用户模型事实继续归 model-management。本次不修改 `RELEASE.md`。

## 2026-07-30

- 新增 `GLOBAL_CONTEXT.md`，以轻量摘要说明 OmniMAM 目标、Spec 分层、实际领域、核心对象、事实归属、跨域边界和最小读取规则；Context 不构成新的事实层。
- 新增 `CONTEXT_MAP.md`，建立单领域关键词、跨域任务和全局入口到最小文档集合的映射；`application-engine`、`capability-catalog`、`mcp-server` 因无独立正式目录而标记为规划中。
- 为 ai-chatting、application-platform、asset-library、identity、model-management、notification-center、sse、task-center、workflow-canvas 新增根级 Domain Context，并明确 identity 尚缺 S2。
- 新增根 `README.md` 的 AI Context 入口，并更新 `AGENTS.md` 的仓库边界、按需加载顺序和 Context 维护触发条件；本次不修改 S1/S2、架构参考或 Release。
- 上述上下文导航层由用户确认为 `spec-v1.8.1` release；该版本不包含 S1/S2 变更，不能作为正式实现依据。

## 2026-07-29

- 优化 notification-center S1 草案，移除活动语义中的 TaskRun、通知私有 SSE 和业务领域直写 Notification 表设计，统一为所属领域事实与 Outbox、通知候选、通知收件箱、Notification Outbox、SSE UserEvent 的可靠链路。
- 建立 `source_event`、`notification_topic`、`UserEvent` 三层事件语义，并增加跨 task-center、asset-library、application-platform、workflow-canvas、model-management 的接入状态矩阵；前瞻扫描、存储、安全、Agent 和多渠道能力继续保留并显式标记。
- 将通知收件箱状态与处理状态正交化，补充稳定去重、聚合、手动重试解决关联、接收者来源、管理员角色和结构化导航目标规则。
- 站内实时通知统一复用 `/api/v1/events/stream`，目标 REST 示例对齐从 0 开始的分页、`total + items` 列表与对象数组批量请求；正式 release 仍待后续确认。
- 为 notification-center S1 增加 `BR-NOTIFY-001..024`、`US-NOTIFY-001..007` 和验收标准，补齐标记未读与取消归档的生命周期接口语义。
- 新增 notification-center 完整 S2：10 个站内收件箱/偏好 operation、8 张设计态表、13 个业务错误、6 个权限、4 个可靠出站事件和模块边界契约。
- 登记 notification-center `180200-180999` 错误码区间，并固化 ACTIVE、CONTRACT_GAP、FUTURE notification topic 的默认严重程度、接收者、聚合和 mandatory in-app 策略。
- SSE OpenAPI 升级为 0.2.0，增加 `notification.created/updated/deleted/unread_count_changed` UserEvent、Notification payload、存储引用和 notification-center 跨域投影边界。
- 新增 notification-center 领域架构并更新全局依赖图，明确独立 Notification Worker、双 Outbox、收件箱计数和统一 SSE 恢复链路；上述协调变更由用户确认为 `spec-v1.8.0` release。

## 2026-07-28

- 明确 Canvas Application execution：DAG 内唯一 `application-platform.run` AtomicTask 在输入解析后幂等创建并绑定 ApplicationRun，补齐发布事件消费、实时可用性校验和 Artifact 输出投影。
- Application 详情新增按应用分页读取持久化 ApplicationRun 历史的契约，默认按创建时间倒序并复用现有运行权限和可见性边界。
- 明确 AtomicTask 终态持久化后按 resource version 单调、幂等投影 ApplicationRun 状态、输出和 Artifact 引用；Application Platform OpenAPI 升级为 1.7.0。
- Asset Library 增加单项与批量删除模式：默认软删除，显式 `hard_delete=true` 可从 active、archived 或 deleted 直接硬删除并绕过回收站。
- 新增 `POST /api/v1/assets/batch-delete` 与 `POST /api/v1/assets/trash/empty`；批量请求最多 200 个唯一素材 ID，清空回收站逐项处理当前用户全部 deleted 素材。
- Asset Library OpenAPI 升级为 0.7.0，扩展 `asset.delete` 权限并新增批量请求无效与删除执行失败错误码；schema 和事件目录不变。
- TaskSchedule 新增立即执行一次能力，ACTIVE/PAUSED 的 MATERIALIZED 与 RECONCILE 计划均可运行，且不改变未来 cron、runAt、暂停状态或 nextTriggerAt。
- 新增 `POST /api/v1/task-schedules/{task_schedule_id}/run`，请求要求计划内幂等键，响应返回完整 ScheduleExecution；SYSTEM 计划只允许系统管理员运行。
- ScheduleExecution 新增 trigger_source、triggered_by、idempotency_key，并增加 MANUAL 部分唯一索引；手动与周期轮次共用重叠锁和恢复机制。
- Task Center OpenAPI 升级为 1.5.0，扩展 schedule 权限、执行记录事件、模块契约和领域架构。

## 2026-07-27

- ApplicationEngineInstance 名称明确为全局唯一；创建或更新为已有名称时返回专用业务错误 `ERR_AIAPP_ENGINE_INSTANCE_NAME_DUPLICATED`，不再误报为鉴权配置错误。

## 2026-07-24

- ComfyUI 模板转换改为直接选择当前可用 EngineInstance 并实时校验，不再选择历史 compatible Validation；所有 API-ready 工作流均可转换，同一工作流可使用不同幂等键创建多个独立模板。
- 移除 ComfyUIWorkflow 的 converted 状态、单一模板引用和转换筛选，移除 TemplateVersion 的 source_workflow_validation_id；转换幂等事实改由新建 ApplicationTemplate 内部字段承担，不提供转换历史接口。
- ApplicationEngineType 以 `operation_executors` key 为能力 value，并按 key 字典序返回 `capability_definitions.zh-CN/en-US` 名称数组；Application Platform OpenAPI 升级为 1.6.0。
- 本次契约要求 Application Platform 全量破坏性重建，不迁移或回填旧 aiapp 数据；Task Center、Asset Library 等其他领域数据不在删除范围。
- ProviderCapability 增加 `kind`、只读 `origin` 和 `binding_policy` 三个正交维度，区分模型目录能力、绑定专用能力、内置/目录来源及 manual/required_immutable 绑定策略。
- 新增内置 `comfyui-workflow-runtime` engine_binding；所有现有及新建 ComfyUI EngineInstance 必须拥有不可变系统绑定，新建实例与绑定原子提交，启动时幂等回填。
- 外部目录不得覆盖内置保留 ID；目录不可读时 registry 保持 degraded，但内置 ComfyUI 能力继续可用。Application Platform OpenAPI 升级为 1.5.0，并新增系统绑定保护错误码与级联删除契约。
- ComfyUI 单文件导入与 EngineInstance 解耦：导入不再接收或保存来源实例，也不读取 object_info；Visual Workflow 只保存源画布并保持 pending。
- Visual Workflow 显式转换请求新增必填 `engine_instance_id`，仅允许使用 enabled、online 且当前 object_info 未过期的 ComfyUI 实例，转换实例不持久化到工作流。
- Application Platform OpenAPI 升级为 1.4.0，设计态工作流表删除 `source_engine_instance_id`，新增 `BR-AIAPP-186..187` 与 `AC-AIAPP-047-04`。

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
