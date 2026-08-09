# Release Records

## spec-v1.20.0

- commit: 7903d5d
- status: released
- confirmed_by: user（2026-08-09 请求发布 spec-v1.20.0 并实施 Server 与 Web 的实际 SSE 接入）
- allowed_as_formal_implementation_basis: true
- domains:
  - agent
  - appstudio
- S1:
  - 00_product/domains/agent/product-spec.md
  - 00_product/domains/appstudio/product-spec.md
- S2:
  - 01_contracts/domains/agent/module-contract.md
  - 01_contracts/domains/agent/runtime-protocol-fixtures.yaml
  - 01_contracts/domains/appstudio/openapi.yaml
  - 01_contracts/domains/appstudio/module-contract.md
- implementation_gate: AppStudio 仅通过 application facade 暴露当前 Coding Agent generation/session 的消息历史，按 `(created_at DESC, id DESC)` 稳定分页，并使用 `user_message_id`、`assistant_message_id` 归并发送结果、历史和流式消息。Invocation SSE 使用 Invocation 内从 1 开始单调递增的十进制 `sequence_no` 作为事件 ID，支持严格校验 `Last-Event-ID`、仅重放更大序号、12 类 Agent S1 类型化事件、注释心跳和终态 flush 后关闭；Coding Agent 不进入公共 Agent API，事件不进入通用事件流。

## spec-v1.19.0

- commit: 6e994e2
- status: released
- confirmed_by: user（2026-08-08 请求实施 Agent MCP 全链路修复方案）
- allowed_as_formal_implementation_basis: true
- domains:
  - agent
  - appstudio
  - infrastructure
  - identity
  - mcp
- S1:
  - 00_product/domains/agent/product-spec.md
  - 00_product/domains/appstudio/product-spec.md
  - 00_product/domains/infrastructure/product-spec.md
  - 00_product/domains/identity/product-spec.md
  - 00_product/domains/mcp/product-spec.md
- S2:
  - 01_contracts/domains/agent/openapi.yaml
  - 01_contracts/domains/agent/schema.sql
  - 01_contracts/domains/agent/errors.yaml
  - 01_contracts/domains/agent/module-contract.md
  - 01_contracts/domains/agent/runtime-protocol-fixtures.yaml
  - 01_contracts/domains/appstudio/module-contract.md
  - 01_contracts/domains/infrastructure/openapi.yaml
  - 01_contracts/domains/infrastructure/module-contract.md
  - 01_contracts/domains/identity/openapi.yaml
  - 01_contracts/domains/identity/module-contract.md
  - 01_contracts/domains/mcp/openapi.yaml
  - 01_contracts/domains/mcp/module-contract.md
- implementation_gate: Agent MCP Binding 支持 owner 隔离的 List/Create/PUT/Delete、活动名称唯一、资源版本乐观锁、KEEP/SET/CLEAR 凭证语义、不可恢复软删除和不可变 revision。Runtime ensure 只固定启用且未删除的最多 50 个 revision，并在任务入队前持久化与 Agent/generation/Application/Runtime/请求绑定的短期 Grant。Infrastructure 只接受 `MCP_SERVER_REF + authorizationRef`，不得读取 Agent 私表；OpenCode `agent.coding@1.0` 配置必须通过 Docker Archive/Exec 写入 tmpfs `/root/.config/opencode/opencode.json`、设为 `0600` 后释放启动门闩，凭证不得进入 Task、持久化、日志、Env、Cmd 或 inspect。AppStudio 首次创建、既有当前代幂等回填和代际替换遵守默认平台 Binding 原子规则；删除后同代不重建。MCP 可接受 `aud=mcp` 的 `AGENT_WORKLOAD` JWT，每请求重新校验 Grant 和对象/工具范围，普通 USER JWT 保持原行为。Hermes MCP 注入不属于本 release。

## spec-v1.18.0

- commit: 9726555
- status: released
- confirmed_by: user（2026-08-07 请求直接基于现有代码实施 AppStudio Coding Agent 全流程）
- allowed_as_formal_implementation_basis: true
- domains:
  - agent
  - appstudio
  - infrastructure
  - task-center
  - user-model
- S1:
  - 00_product/domains/agent/product-spec.md
  - 00_product/domains/appstudio/product-spec.md
  - 00_product/domains/infrastructure/product-spec.md
  - 00_product/domains/task-center/product-spec.md
  - 00_product/domains/user-model/product-spec.md
- S2:
  - 01_contracts/domains/agent/openapi.yaml
  - 01_contracts/domains/agent/schema.sql
  - 01_contracts/domains/agent/errors.yaml
  - 01_contracts/domains/agent/permissions.yaml
  - 01_contracts/domains/agent/events.yaml
  - 01_contracts/domains/agent/module-contract.md
  - 01_contracts/domains/agent/runtime-protocol-fixtures.yaml
  - 01_contracts/domains/appstudio/openapi.yaml
  - 01_contracts/domains/appstudio/schema.sql
  - 01_contracts/domains/appstudio/errors.yaml
  - 01_contracts/domains/appstudio/permissions.yaml
  - 01_contracts/domains/appstudio/events.yaml
  - 01_contracts/domains/appstudio/module-contract.md
  - 01_contracts/domains/infrastructure/module-contract.md
  - 01_contracts/domains/task-center/function-registry.schema.yaml
  - 01_contracts/domains/task-center/function-registry.yaml
  - 01_contracts/domains/task-center/module-contract.md
  - 01_contracts/domains/user-model/openapi.yaml
  - 01_contracts/domains/user-model/schema.sql
  - 01_contracts/domains/user-model/module-contract.md
- implementation_gate: All CHAT and CODING AgentInvocation instances use the canonical `agent.invocation.execute@1.0` Task contract with stable references, short-lived authorization references, resource-version fencing and recovery cursors only. AppStudio creation atomically provisions the selected model binding, Coding Agent generation and first invocation; failed first Task submission preserves the READY application for idempotent retry. Coding Agent operations are exposed only through the application-level AppStudio Agent facade. Runtime execution uses profile-specific Hermes JSON-RPC/WebSocket and OpenCode REST/SSE adapters, Attempt-scoped Model Access Grants and Workspace Tool Grants, monotonic Task terminal projection, and source restore through a new Restore ChangeSet/Revision while preserving history.

## spec-v1.17.2

- commit: 64435e32db213bf4483d057039036375ee545183
- status: released
- confirmed_by: user（2026-08-05 请求“发布并提交”）
- allowed_as_formal_implementation_basis: true
- domains:
  - agent
  - infrastructure
  - task-center
  - asset-library
- S1:
  - 00_product/domains/agent/product-spec.md
  - 00_product/domains/infrastructure/product-spec.md
- S2:
  - 01_contracts/domains/agent/module-contract.md
  - 01_contracts/domains/infrastructure/openapi.yaml
  - 01_contracts/domains/infrastructure/schema.sql
  - 01_contracts/domains/infrastructure/errors.yaml
  - 01_contracts/domains/infrastructure/permissions.yaml
  - 01_contracts/domains/infrastructure/events.yaml
  - 01_contracts/domains/infrastructure/module-contract.md
  - 01_contracts/domains/task-center/function-registry.schema.yaml
  - 01_contracts/domains/task-center/function-registry.yaml
  - 01_contracts/domains/task-center/module-contract.md
  - 01_contracts/domains/asset-library/module-contract.md
- architecture:
  - 02_architecture/domains/infrastructure.md
- context:
  - domains/agent/context.md
  - domains/infrastructure/context.md
  - domains/task-center/context.md
  - domains/asset-library/context.md
  - GLOBAL_CONTEXT.md
- implementation_gate: Runtime 生命周期创建、启动、停止、取消、删除与其他写操作仍必须经 `Task Center -> Task Worker -> Infra Adapter`；AgentRuntimeAdapter 只有在完成 Agent、Session、Invocation 与 Runtime Binding 校验后，才可用 Agent 工作负载身份调用只读 Endpoint resolve，并且短时 `base_url` 不得进入 Agent/Task 数据、普通摘要、事件或日志。Docker Service 只发布 RuntimeProfile Revision 声明的命名容器端口并绑定平台内部接口，映射建立且健康检查通过后 Endpoint 才能进入 READY。Docker Job 必须从受控输出根读取声明普通文件的实际字节，拒绝目录、符号链接逃逸和根外路径，计算大小与 SHA-256 并复制到 Infra staging 后生成非 bearer `infra-output://<output_id>`。Task Worker 仅可通过受控内容接口流式读取并双重校验大小/digest，再执行 Asset Library `create -> upload -> complete` 并幂等 attach；内容缺失、读取中断或完整性不一致不得产生 ready Artifact。`appstudio.build.execute@1.1` 为 ACTIVE，`1.0` 为 RETAINED 且历史 digest 不变。本版本不实现 Docker Provider 代码或数据库 migration，不引入 Gateway、公共域名或 PUBLIC Endpoint，也不自动把 Artifact 登记为长期 Asset。

## spec-v1.17.1

- commit: ed413ea46a279de2a3c556d5f35a46c8485f3813
- status: released
- confirmed_by: user（2026-08-05 请求“发布agent 的release”，随后明确“一起发布”当前 StudioBuild producer 契约）
- allowed_as_formal_implementation_basis: true
- domains:
  - agent
  - appstudio
  - asset-library
- S1:
  - 00_product/domains/agent/product-spec.md
  - 00_product/domains/appstudio/product-spec.md
  - 00_product/domains/asset-library/product-spec.md
- S2:
  - 01_contracts/domains/agent/openapi.yaml
  - 01_contracts/domains/agent/schema.sql
  - 01_contracts/domains/agent/errors.yaml
  - 01_contracts/domains/agent/permissions.yaml
  - 01_contracts/domains/agent/events.yaml
  - 01_contracts/domains/agent/module-contract.md
  - 01_contracts/domains/appstudio/openapi.yaml
  - 01_contracts/domains/appstudio/schema.sql
  - 01_contracts/domains/appstudio/permissions.yaml
  - 01_contracts/domains/appstudio/module-contract.md
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/schema.sql
  - 01_contracts/domains/asset-library/permissions.yaml
  - 01_contracts/domains/asset-library/module-contract.md
- context:
  - domains/agent/context.md
  - domains/appstudio/context.md
  - domains/asset-library/context.md
  - GLOBAL_CONTEXT.md
  - CONTEXT_MAP.md
- implementation_gate: 本版本正式确认当前完整 Agent S1/S2，并同时发布 AppStudio/Asset Library 的 StudioBuild Artifact producer 契约。用户侧只创建和管理 Platform Agent，后端原子创建并固定绑定 AgentWorkspace、默认 Session 和 Binding；Coding Agent 只能由 AppStudio 通过内部 `CreateCodingAgentForStudio` 创建。公共 API、页面、通知、SSE 和用户可见错误不得要求、返回或展示 Workspace 类型、ID 或绑定状态；纯 CHAT 且不启动 Runtime、工具或后台工作时可以不创建 AtomicTask，其他 Invocation 与 AgentRuntime 生命周期操作必须委托 Task Center。AgentRuntimeProvider 只承载 Hermes/OpenCode，不得与 StudioDeploymentProvider 或 Infrastructure RuntimeProvider 混用业务状态。StudioBuild Bundle 必须使用 `producer_type=studio_build`、`producer_id=StudioBuild.id`、`producer_idempotency_key=studio-build:<studio_build_id>:bundle` 和 `StudioBuild.owner_user_id`；仅受信 `appstudio.build.execute` Task Worker 可携带服务身份和原任务 `authorization_ref` 创建。同一 StudioBuild 的自动 TaskAttempt 重试复用同一 Artifact，新逻辑 Build 必须创建新 StudioBuild ID。AppStudio 批量摘要每批 1..200 项、保持顺序，仅返回 `id/owner_user_id/name/status`，不存在或不可见统一为 null；Asset Library 禁止读取 AppStudio 私表和 N+1 查询。Build 协作者、管理员角色、服务身份或仅持有 producer ID 均不得绕过 Artifact owner-only 权限。

## spec-v1.17.0

- commit: f7f43b2f42ac961441e2227b7c9117baf122aa00
- status: released
- confirmed_by: user（2026-08-05 请求“提交并发布”）
- allowed_as_formal_implementation_basis: true
- domains:
  - agent
  - ai-chatting
  - application-platform
  - appstudio
  - infrastructure
  - modelgateway
  - notification-center
  - user-model
- S1:
  - 00_product/domains/agent/product-spec.md
  - 00_product/domains/ai-chatting/product-spec.md
  - 00_product/domains/application-platform/product-spec.md
  - 00_product/domains/appstudio/product-spec.md
  - 00_product/domains/infrastructure/product-spec.md
  - 00_product/domains/modelgateway/product-spec.md
  - 00_product/domains/notification-center/product-spec.md
  - 00_product/domains/user-model/product-spec.md
- S2:
  - 01_contracts/domains/agent/module-contract.md
  - 01_contracts/domains/ai-chatting/module-contract.md
  - 01_contracts/domains/ai-chatting/openapi.yaml
  - 01_contracts/domains/ai-chatting/schema.sql
  - 01_contracts/domains/application-platform/module-contract.md
  - 01_contracts/domains/modelgateway/module-contract.md
  - 01_contracts/domains/modelgateway/runtime-registry.yaml
  - 01_contracts/domains/notification-center/events.yaml
  - 01_contracts/domains/notification-center/module-contract.md
  - 01_contracts/domains/user-model/openapi.yaml
  - 01_contracts/domains/user-model/schema.sql
  - 01_contracts/domains/user-model/errors.yaml
  - 01_contracts/domains/user-model/permissions.yaml
  - 01_contracts/domains/user-model/events.yaml
  - 01_contracts/domains/user-model/module-contract.md
- architecture:
  - 02_architecture/domains/ai-chatting.md
  - 02_architecture/domains/application-platform.md
  - 02_architecture/domains/modelgateway.md
  - 02_architecture/domains/user-model.md
  - 02_architecture/global-architecture.md
- context:
  - domains/ai-chatting/context.md
  - domains/application-platform/context.md
  - domains/modelgateway/context.md
  - domains/notification-center/context.md
  - domains/user-model/context.md
  - GLOBAL_CONTEXT.md
  - CONTEXT_MAP.md
- supporting:
  - 00_product/glossary.md
  - 01_contracts/error-code-index.md
- retired_paths:
  - 00_product/domains/model-management/
  - 01_contracts/domains/model-management/
  - 02_architecture/domains/model-management.md
  - domains/model-management/
- implementation_gate: `user-model` 正式接替 `model-management`，客户端必须在同一发布批次切换到 `/api/v1/user-model/...`，旧 `/model-providers`、`/provider-models`、`/default-models` 和 `/model-options` 不提供别名、重定向或兼容期。User Model 独占用户 Provider、模型清单、默认配置、用户模型健康事实以及 owner、enabled、health、默认值和使用资格校验；Model Gateway 独占 `ApplicationEngineInstance`、`EngineCapabilityBinding`、平台健康、Provider Adapter、模型发现、探测和 Operation 执行。用户只能选择稳定 `providerType`，不得读取或提交内部 Adapter/Executor ID；Gateway 只接受 User Model 签发、绑定 principal/能力/配置版本且未过期的 `UserModelExecutionContext`，不得读取 User Model 私有表或保存用户模型事实。`UserModelProvider` 不转换为 `ApplicationEngineInstance`，`ResolvedModelRoute` 仅请求级派生且不建表。AI Chat 必须经 User Model 校验后通过 Gateway 执行并保存 GenerationRun 模型、能力和配置版本快照；Application Platform 只使用 `PlatformEngineTarget`，ApplicationRun 编排仍归 Application Platform。本版本不改变 Agent Runtime 既有 ModelAccessSpec/直连模型架构，不得据此推断 Agent 已切换到统一 Gateway 执行入口。

## spec-v1.16.1

- commit: 7ec33b70abbbe15b1295fb4fb5ae14423e49422d
- status: released
- confirmed_by: user（2026-08-04 请求完整实施 AppStudio Outbox 冲突修复方案，包括发布、tag 和推送）
- allowed_as_formal_implementation_basis: true
- domains:
  - appstudio
- S1: []
- S2:
  - 01_contracts/domains/appstudio/events.yaml
  - 01_contracts/domains/appstudio/schema.sql
  - 01_contracts/domains/appstudio/permissions.yaml
- context:
  - domains/appstudio/context.md
  - GLOBAL_CONTEXT.md
  - CONTEXT_MAP.md
- implementation_gate: 所有新 AppStudio Outbox 事件的 `idempotency_key` 必须使用 `<event_type>:<domain_key_components>` 全限定格式，并继续满足 `appstudio_outbox.idempotency_key` 单列跨事件类型全局唯一约束。生命周期、Revision、Snapshot、Build、Preview、Release 和 RuntimeInstance 分别使用本版本 `events.yaml` 定义的领域组件；Revision 必须使用 `current_revision`。本版本不创建 migration、不新增数据库字段、不改写历史 Outbox；旧键只随既有事件保留，新旧键允许共存，消费者继续按事件行自身的幂等键处理。

## spec-v1.16.0

- commit: 61bcc52b9286cdca807e42b710e4a06670667546
- status: released
- confirmed_by: user（2026-08-04 请求“提交发布并推送到远端”）
- allowed_as_formal_implementation_basis: true
- domains:
  - agent
  - appstudio
- S1:
  - 00_product/domains/agent/product-spec.md
  - 00_product/domains/appstudio/product-spec.md
- S2:
  - 01_contracts/domains/agent/openapi.yaml
  - 01_contracts/domains/agent/schema.sql
  - 01_contracts/domains/agent/errors.yaml
  - 01_contracts/domains/agent/permissions.yaml
  - 01_contracts/domains/agent/events.yaml
  - 01_contracts/domains/agent/module-contract.md
  - 01_contracts/domains/appstudio/openapi.yaml
  - 01_contracts/domains/appstudio/schema.sql
  - 01_contracts/domains/appstudio/errors.yaml
  - 01_contracts/domains/appstudio/permissions.yaml
  - 01_contracts/domains/appstudio/events.yaml
  - 01_contracts/domains/appstudio/module-contract.md
- architecture:
  - 02_architecture/domains/agent.md
  - 02_architecture/domains/appstudio.md
  - 02_architecture/domains/infrastructure.md
  - 02_architecture/global-architecture.md
- context:
  - domains/agent/context.md
  - domains/appstudio/context.md
  - GLOBAL_CONTEXT.md
  - CONTEXT_MAP.md
- implementation_gate: Workspace 仅作为 Agent/AppStudio 后端 canonical 持久化、Revision、Runtime 和固定绑定事实；公共 API、页面、导航、通知、SSE 和用户可见错误不得要求、返回或展示 Workspace 类型、ID 或绑定状态。用户侧 Agent 只创建和管理 Platform Agent，后端必须原子创建并固定绑定 AgentWorkspace；Coding Agent 只能由 AppStudio 通过内部 `CreateCodingAgentForStudio` 创建。StudioApplication 创建不接受 Workspace 输入，后端必须创建唯一默认 StudioWorkspace、Coding Agent 和 Session；公共源码、Revision、ChangeSet、Snapshot 和 Preview 均按 StudioApplication 寻址。内部 Workspace 表、字段和约束继续保留，本版本不创建 migration。

## spec-v1.15.3

- commit: 58d2d62b4337f5fdea5bad9736eb48630d666f33
- status: released
- confirmed_by: user（2026-08-04 请求“发布release并推送到远端”）
- allowed_as_formal_implementation_basis: true
- domains:
  - infrastructure
- S1:
  - 00_product/domains/infrastructure/product-spec.md
- S2:
  - 01_contracts/domains/infrastructure/openapi.yaml
  - 01_contracts/domains/infrastructure/schema.sql
  - 01_contracts/domains/infrastructure/errors.yaml
  - 01_contracts/domains/infrastructure/permissions.yaml
  - 01_contracts/domains/infrastructure/events.yaml
  - 01_contracts/domains/infrastructure/module-contract.md
- context:
  - domains/infrastructure/context.md
  - GLOBAL_CONTEXT.md
  - CONTEXT_MAP.md
- implementation_gate: 本版本仅同步 Infrastructure 已由 `spec-v1.12.0` 发布的状态元数据；产品语义、API、Schema、错误码、权限码、事件、模块边界和 Docker-only 第一阶段门禁保持不变。Infrastructure 可按 `spec-v1.12.0` 的实现门禁作为正式实现、合并和验收依据。

## spec-v1.15.2

- commit: 868326b6b877011295a333ff1c9c3d21b48c5632
- status: released
- confirmed_by: user（2026-08-04 请求“补充缺失权限，补充结束提交代码并发布一个小版本推送到远端”）
- allowed_as_formal_implementation_basis: true
- domains:
  - identity
  - platform-management
- S1:
  - 00_product/domains/identity/product-spec.md
  - 00_product/domains/platform-management/product-spec.md
- S2:
  - 01_contracts/domains/identity/permissions.yaml
  - 01_contracts/domains/identity/module-contract.md
  - 01_contracts/domains/identity/schema.sql
  - 01_contracts/domains/platform-management/permissions.yaml
- context:
  - domains/identity/context.md
  - domains/platform-management/context.md
- implementation_gate: 各 domain ACTIVE 权限的 `default_roles` 必须由 Identity 聚合并幂等物化为内置角色 `RolePermissionGrant`，不能只登记 `PermissionDefinition`。`ADMIN` 必须获得 Identity 用户/注册/组/服务账号读取管理权限以及 `platform.overview.read`、`platform.auth_config.read`、`platform.audit.read`；`SUPER_ADMIN` 额外获得 `identity.role.manage`、`identity.service_account.manage`、`platform.auth_config.manage`。现有数据库必须执行一次受控补偿对账，并递增受影响主体 `authorization_version`、失效权限缓存。

## spec-v1.15.1

- commit: 7d290e80d8f47334d9e3f52b8372c638df22c5ba
- status: released
- confirmed_by: user（2026-08-04 请求“提交代码并发布一个小版本”）
- allowed_as_formal_implementation_basis: true
- domains:
  - appstudio
- S1: []
- S2:
  - 01_contracts/domains/appstudio/openapi.yaml
  - 01_contracts/domains/appstudio/schema.sql
- context:
  - domains/appstudio/context.md
- implementation_gate: AppStudio 创建请求只接受 `name` 和可选 `description`；实现不得依赖 `template_id`、`technology_stack` 或任何脚手架模板/模板发现能力。

## spec-v1.15.0

- commit: 0d5954609215da7bce01fe82b351e7d57e8018da
- status: released
- confirmed_by: user（2026-08-03 明确要求“提交，发布release并且推送”及“直接发布推送”）
- allowed_as_formal_implementation_basis: true
- domains:
  - agent
  - ai-chatting
  - application-platform
  - appstudio
  - asset-library
  - mcp
  - model-management
  - modelgateway
  - notification-center
  - sse
  - task-center
  - workflow-canvas
- S1:
  - 00_product/domains/ai-chatting/product-spec.md
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/agent/permissions.yaml
  - 01_contracts/domains/ai-chatting/module-contract.md
  - 01_contracts/domains/ai-chatting/openapi.yaml
  - 01_contracts/domains/ai-chatting/permissions.yaml
  - 01_contracts/domains/application-platform/module-contract.md
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/permissions.yaml
  - 01_contracts/domains/appstudio/permissions.yaml
  - 01_contracts/domains/asset-library/permissions.yaml
  - 01_contracts/domains/mcp/permissions.yaml
  - 01_contracts/domains/model-management/openapi.yaml
  - 01_contracts/domains/model-management/permissions.yaml
  - 01_contracts/domains/modelgateway/permissions.yaml
  - 01_contracts/domains/notification-center/permissions.yaml
  - 01_contracts/domains/sse/permissions.yaml
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/workflow-canvas/permissions.yaml
- context:
  - domains/ai-chatting/context.md
  - domains/application-platform/context.md
- implementation_gate: 面向用户的权限默认角色只允许使用 Identity 内置 `USER`、`ADMIN`、`SUPER_ADMIN`；管理员默认权限不得绕过 owner、scope、visibility、状态或资源引用校验。Application Platform 跨 owner 工作流操作必须同时校验具体操作权限与 `aiapp.comfyui_workflow.manage_all`，global Application 变更必须同时校验 `aiapp.application.manage_global`，禁止按角色名隐式放行。内部服务权限继续只授予受信服务主体。

## spec-v1.14.2

- commit: 102a4477672f05b223e3bcff19b7df61e9cdc8e8
- status: released
- confirmed_by: user（2026-08-03 请求继续实现 OPAQUE 密码认证方案）
- allowed_as_formal_implementation_basis: true
- domains:
  - identity
- S1:
  - 00_product/domains/identity/product-spec.md
- S2:
  - 01_contracts/domains/identity/openapi.yaml
  - 01_contracts/domains/identity/schema.sql
  - 01_contracts/domains/identity/errors.yaml
  - 01_contracts/domains/identity/module-contract.md
- implementation_gate: OpenAPI YAML is validated; Identity clients must use only the OPAQUE two-step operations and the administrator registration/reset operations.

## spec-v1.14.1

- commit: 8190bfcec6da343ab833b0fddcc716f21ff00cc4
- status: released
- confirmed_by: user（2026-08-03 请求继续实现 OPAQUE 密码认证方案）
- allowed_as_formal_implementation_basis: true
- domains:
  - identity
- S1:
  - 00_product/domains/identity/product-spec.md
- S2:
  - 01_contracts/domains/identity/openapi.yaml
  - 01_contracts/domains/identity/schema.sql
  - 01_contracts/domains/identity/errors.yaml
  - 01_contracts/domains/identity/module-contract.md
- implementation_gate: OPAQUE change-password start includes both old-password KE1 and new-password registration request; administrator registration and initial-password reset use the same two-step registration semantics. No raw password field is accepted or returned.

## spec-v1.14.0

- commit: 4047f8326e4f2b1365990c9487e0ad3cb4b9f505
- status: released
- confirmed_by: user（2026-08-03 请求实现 OPAQUE 密码认证方案）
- allowed_as_formal_implementation_basis: true
- domains:
  - identity
- S1:
  - 00_product/domains/identity/product-spec.md
- S2:
  - 01_contracts/domains/identity/openapi.yaml
  - 01_contracts/domains/identity/schema.sql
  - 01_contracts/domains/identity/errors.yaml
  - 01_contracts/domains/identity/module-contract.md
  - 01_contracts/error-code-index.md
- implementation_gate: Web and Server must use RFC 9807 OPAQUE with the pinned implementations and configuration. Only OPAQUE messages and account metadata may cross the Identity API; exchange state is short-lived, one-time and password-free. HTTPS remains mandatory and the OPAQUE setup is a stable deployment secret.

## spec-v1.13.0

- commit: 56907857c38992c16ae272b20aff957aae366490
- status: released
- confirmed_by: user（2026-08-03 明确要求“发布”）
- allowed_as_formal_implementation_basis: true
- domains:
  - platform-management
  - identity
- S1:
  - 00_product/domains/platform-management/product-spec.md
  - 00_product/domains/identity/product-spec.md
- S2:
  - 01_contracts/domains/platform-management/openapi.yaml
  - 01_contracts/domains/platform-management/schema.sql
  - 01_contracts/domains/platform-management/errors.yaml
  - 01_contracts/domains/platform-management/permissions.yaml
  - 01_contracts/domains/platform-management/events.yaml
  - 01_contracts/domains/platform-management/module-contract.md
  - 01_contracts/domains/identity/events.yaml
  - 01_contracts/domains/identity/module-contract.md
  - 01_contracts/error-code-index.md
- architecture:
  - 02_architecture/domains/platform-management.md
  - 02_architecture/domains/identity.md
- context:
  - domains/platform-management/context.md
- implementation_gate: SystemAuthConfig 仅允许 `id=default` 单例并使用 `resource_version` 乐观并发；配置新版本、`platform.auth_config.update` AuditLog 和 Outbox 必须在 Platform 边界内原子提交，配置变更事件只提示版本失效，Identity 必须重新读取完整配置。Identity 登录、Token、密码、授权、服务账号和跨 owner 敏感操作必须通过受控同步接口确认 AuditLog，审计失败时必须回滚、撤销或补偿，不得留下可用效果并返回成功；Identity 领域事件不得重复承担平台审计写入。审计来源必须绑定已登记服务主体，幂等范围固定为 `source_domain + source_module + idempotency_key`，相同 key 的规范化内容指纹不一致必须拒绝。Platform 不得读取 Identity 私有表，Identity 不得维护重复的 SystemAuthConfig、AuditLog 或平台审计查询 API；PlatformOverview 仅展示最近 10 条 `platform.auth_config.update`，不得扩展为 Identity 高频审计或跨 domain 统计。

## spec-v1.12.2

- commit: a56f84d60f14fe6251dcac9c1e1d2b2faa432bd5
- status: released
- confirmed_by: user（2026-08-03 明确要求“远端已经更新了v1.12.1.本地提交后发布v1.12.2然后推送”）
- allowed_as_formal_implementation_basis: true
- domains:
  - identity
- S1:
  - 00_product/domains/identity/product-spec.md
- S2:
  - 01_contracts/domains/identity/openapi.yaml
  - 01_contracts/domains/identity/schema.sql
  - 01_contracts/domains/identity/errors.yaml
  - 01_contracts/domains/identity/permissions.yaml
  - 01_contracts/domains/identity/events.yaml
  - 01_contracts/domains/identity/module-contract.md
- architecture:
  - 02_architecture/domains/identity.md
- context:
  - domains/identity/context.md
  - GLOBAL_CONTEXT.md
  - CONTEXT_MAP.md
- implementation_gate: Identity 登录、Refresh 和独立授权查询必须返回同一版本化授权投影，包含有效角色来源、权限码和会话限制；角色摘要只用于展示解释，完整角色/权限不得写入 JWT，后端仍按当前主体状态、凭据和权限码实时鉴权。`ADMIN_APPROVAL` 注册在批准前不得分配角色、创建会话或签发 Token，审批/拒绝/重新申请历史必须不可变且敏感操作审计失败时 fail closed。ServiceAccount 只允许直接角色授权，owner 必须通过受控批量投影校验，owner 不可用时拒绝凭据交换，初始密码和 Secret 只返回一次。用户删除必须使用完整、未过期并在提交前重验的跨 domain 依赖检查；任何来源不可用或存在阻塞项都不得删除，资源转移仍由目标 domain 完成。SystemAuthConfig 和 AuditLog 继续归 platform-management，Identity 不得维护重复配置、审计表或查询 API。LDAP/SSO、OAuth2/OIDC、MFA、PAT、角色继承/互斥和其他未发布能力保持禁用。

## spec-v1.12.1

- commit: 261ef2aa56d1c7d141c1ebda8b7d04b3371fb5bf
- status: released
- confirmed_by: user（2026-08-03 明确要求“将旧的workflow canvas更改为v1.12.1发布然后推送到远端”）
- allowed_as_formal_implementation_basis: true
- release_correction: 原 Workflow Canvas `spec-v1.12.0` release 改以 `spec-v1.12.1` 发布；合并后保留当前 Task Center function registry 合同
- domains:
  - workflow-canvas
  - task-center
- S1:
  - 00_product/domains/workflow-canvas/product-spec.md
  - 00_product/domains/task-center/product-spec.md
- S2:
  - 01_contracts/domains/workflow-canvas/openapi.yaml
  - 01_contracts/domains/workflow-canvas/schema.sql
  - 01_contracts/domains/workflow-canvas/module-contract.md
  - 01_contracts/domains/task-center/module-contract.md
- context:
  - domains/workflow-canvas/context.md
  - domains/task-center/context.md
- implementation_gate: Server/Web 只能使用六个已登记的 `1.0.0` SYSTEM 内置 NodeDefinition；`compile_time` 只能引用五个注册 compiler key。`image`、`prompt`、`promptGroup` 必须在任务创建前完成受控常量折叠，`group` 保持 passive，`output` 只收集有序结果。`loop` count 只允许 1..99，只展开唯一直接 Application 节点；serial、batch、cascade 均编译为现有 DAGTaskGroup 的有限无环 AtomicTask，并使用 `all_success`。禁止隐式/嵌套/条件/无界循环、运行时循环、新 Task Center group 类型、私有 API、权限、事件或错误码。

## spec-v1.12.0

- commit: 2f71a836006d5f35f48144fa03d1176232ea70c6
- status: released
- confirmed_by: user（2026-08-03 明确要求“直接发布，不要检验”）
- allowed_as_formal_implementation_basis: true
- domains:
  - agent
  - appstudio
  - infrastructure
  - task-center
- S1:
  - 00_product/domains/agent/product-spec.md
  - 00_product/domains/appstudio/product-spec.md
  - 00_product/domains/infrastructure/product-spec.md
  - 00_product/domains/task-center/product-spec.md
  - 00_product/glossary.md
- S2:
  - 01_contracts/domains/agent/openapi.yaml
  - 01_contracts/domains/agent/schema.sql
  - 01_contracts/domains/agent/errors.yaml
  - 01_contracts/domains/agent/permissions.yaml
  - 01_contracts/domains/agent/events.yaml
  - 01_contracts/domains/agent/module-contract.md
  - 01_contracts/domains/appstudio/openapi.yaml
  - 01_contracts/domains/appstudio/schema.sql
  - 01_contracts/domains/appstudio/errors.yaml
  - 01_contracts/domains/appstudio/permissions.yaml
  - 01_contracts/domains/appstudio/events.yaml
  - 01_contracts/domains/appstudio/module-contract.md
  - 01_contracts/domains/infrastructure/openapi.yaml
  - 01_contracts/domains/infrastructure/schema.sql
  - 01_contracts/domains/infrastructure/errors.yaml
  - 01_contracts/domains/infrastructure/permissions.yaml
  - 01_contracts/domains/infrastructure/events.yaml
  - 01_contracts/domains/infrastructure/module-contract.md
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/errors.yaml
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/events.yaml
  - 01_contracts/domains/task-center/module-contract.md
  - 01_contracts/domains/task-center/function-registry.schema.yaml
  - 01_contracts/domains/task-center/function-registry.yaml
- architecture:
  - 02_architecture/domains/infrastructure.md
  - 02_architecture/domains/task-center.md
- context:
  - domains/agent/context.md
  - domains/appstudio/context.md
  - domains/infrastructure/context.md
  - domains/task-center/context.md
  - GLOBAL_CONTEXT.md
  - CONTEXT_MAP.md
- implementation_gate: Agent 第一阶段只允许 platform/coding、Hermes/OpenCode 和 Rootless Docker AgentRuntimeProvider；Agent 创建时固定一个类型匹配的 Workspace，Session、Invocation 和 Runtime 不得切换。纯 CHAT 且不启动 Runtime、工具或后台工作的 Invocation 可以不创建 AtomicTask，其余 Invocation 与 Runtime 生命周期必须委托 Task Center；Coding Agent 只能使用绑定 Principal、Agent、Session、Invocation、StudioWorkspace、动作和有效期的短期 Tool 授权，并通过带 base_revision 的原子 ChangeSet 修改源码。AppStudio 正式 Build 只能读取不可变 Source Snapshot，只有 AtomicTask 成功、Artifact READY 且 digest 一致后才能成功；Release 必须固定 Version、RuntimeConfig、Artifact ID/digest 和环境，新 RuntimeInstance 健康前不得切换 current，回滚必须创建新 Release，Preview 停止必须使用已登记异步合同。Task Center 第一阶段只允许 `agent.runtime.ensure`、`agent.runtime.stop`、`appstudio.preview.ensure`、`appstudio.preview.stop`、`appstudio.build.execute`、`appstudio.production.reconcile` 和 `appstudio.production.stop` 七个 canonical Infra-backed functionRef；新任务只能选择唯一 ACTIVE 合同并固定 version/digest，RETAINED 仅恢复历史，DISABLED 不得执行，同版本摘要不得漂移。Task Worker 必须按 registry 校验 I/O、能力、幂等、重试、取消、超时和 Infra 映射；Infra request ID 使用 `atomic_task_id:attempt_no`，同 Attempt 恢复重放，新 Attempt 使用新 ID。Infrastructure 第一阶段只允许 Docker Job/Service、受控挂载、Endpoint 授权、Provider 超时恢复和安全孤儿清理；所有 Agent/AppStudio Infra 操作必须经过 `Task Center -> Task Worker -> Infra Adapter -> Infra Service`，来源领域不得直接调用 Infra。只有 `appstudio.build.execute` 可由 Task Worker 使用 producer context 登记 Artifact；Production 只能读取固定 Artifact ID/digest，Secret 只能保存引用并在部署边界短期解析。Kubernetes Provider、多 Workspace、Workspace 热迁移、复杂自动合并、外部 Git Provider、PUBLIC Endpoint 和其他 S1/S2 未发布能力保持禁用。

## spec-v1.11.0

- commit: 1939166284c94e68bab731aeaddd8bba01ed9384
- status: released
- confirmed_by: user（2026-08-02 明确要求“发布” Identity 与 Platform Management S1/S2）
- allowed_as_formal_implementation_basis: true
- domains:
  - identity
  - platform-management
- S1:
  - 00_product/domains/identity/product-spec.md
  - 00_product/domains/platform-management/product-spec.md
  - 00_product/glossary.md
- S2:
  - 01_contracts/domains/identity/openapi.yaml
  - 01_contracts/domains/identity/schema.sql
  - 01_contracts/domains/identity/errors.yaml
  - 01_contracts/domains/identity/permissions.yaml
  - 01_contracts/domains/identity/events.yaml
  - 01_contracts/domains/identity/module-contract.md
  - 01_contracts/domains/platform-management/openapi.yaml
  - 01_contracts/domains/platform-management/schema.sql
  - 01_contracts/domains/platform-management/errors.yaml
  - 01_contracts/domains/platform-management/permissions.yaml
  - 01_contracts/domains/platform-management/events.yaml
  - 01_contracts/domains/platform-management/module-contract.md
  - 01_contracts/error-code-index.md
- architecture:
  - 02_architecture/domains/identity.md
- context:
  - domains/identity/context.md
  - domains/platform-management/context.md
  - GLOBAL_CONTEXT.md
  - CONTEXT_MAP.md
- implementation_gate: Identity 仅允许实现当前已发布的本地认证、JWT/Refresh Token、会话、用户、RBAC、PrincipalContext、ResourceAccessGrant、ServiceAccount 和脱敏审计协作；密码必须使用 Argon2id PHC 哈希，在线状态按有效会话活动时间派生，presence heartbeat 不得延长 Token 或会话期限。Platform Management 仅允许实现只读 PlatformOverview、SystemAuthConfig 和脱敏 AuditLog；跨 domain 统计、通用 Credential CRUD、维护模式和其他延期入口保持禁用。Identity 不得拥有 SystemAuthConfig/AuditLog 的私有表或管理 API，Platform 不得读取 Identity 私有表；跨 domain 只能通过稳定 ID、受控内部接口、权限裁剪摘要和可靠事件协作。LDAP/SSO、OAuth2/OIDC、MFA、PAT、角色继承/互斥及其他 S1/S2 未发布能力保持禁用。

## spec-v1.10.0

- commit: 28ceccbb623dea1387719958f953416585b83bd6
- status: superseded
- confirmed_by: user（2026-08-02 已移除旧版 Agent/AppStudio S2，并要求按 Task Worker 与 Docker-only 约束重新作为草稿修订）
- allowed_as_formal_implementation_basis: false
- superseded_by: 当前工作区未 Release 的 Agent/AppStudio S1 草稿；当前不提供 Agent/AppStudio S2 实施依据
- domains:
  - agent
  - appstudio
- S1:
  - 00_product/domains/agent/product-spec.md
  - 00_product/domains/appstudio/product-spec.md
  - 00_product/glossary.md
- S2: []（旧版文件已移除，仅保留本条历史发布记录）
- architecture: []
- context:
  - domains/agent/context.md
  - domains/appstudio/context.md
  - GLOBAL_CONTEXT.md
  - CONTEXT_MAP.md
- implementation_gate: Agent 首期只允许 platform/coding、Hermes/OpenCode 和 Rootless Docker AgentRuntimeProvider；每个 Agent 固定一个 Workspace，Session/Invocation 不得切换，Invocation 执行、重试、取消与超时必须委托 Task Center。Coding Agent 只能使用绑定 Principal、Agent、Session、Invocation、StudioWorkspace、动作和有效期的短期 Tool 授权，并通过带 base_revision 的原子 ChangeSet 修改源码。AppStudio 正式 Build 只能读取不可变 Source Snapshot，Build/Deployment 执行状态归 Task Center，Bundle Artifact 内容与生命周期归 Asset Library；Release 必须固定 artifact_id/digest 和 RuntimeConfig 引用，新 RuntimeInstance 健康前不得切换当前入口，回滚必须创建新 Release。AgentRuntimeProvider 与 StudioDeploymentProvider 不得共享业务状态；StudioWorkspace 不得直接挂载到 AgentRuntime；Secret 只能保存引用并在部署边界短期解析。Kubernetes AgentRuntimeProvider、多 Workspace、热迁移、复杂自动合并、外部 Git Provider 和其他技术栈保持禁用，除非后续 S1/S2 Release 明确开放。

## spec-v1.9.2

- commit: 45ea82d4fd42b1697f4cd9af24c2ccb1ac965373
- status: released
- confirmed_by: user（2026-08-01 明确要求“提交并发布” MCP S1/S2）
- allowed_as_formal_implementation_basis: true
- domains:
  - mcp
- S1:
  - 00_product/domains/mcp/product-spec.md
  - 00_product/glossary.md
- S2:
  - 01_contracts/domains/mcp/openapi.yaml
  - 01_contracts/domains/mcp/schema.sql
  - 01_contracts/domains/mcp/errors.yaml
  - 01_contracts/domains/mcp/permissions.yaml
  - 01_contracts/domains/mcp/events.yaml
  - 01_contracts/domains/mcp/module-contract.md
  - 01_contracts/error-code-index.md
- architecture:
  - 02_architecture/domains/mcp.md
  - 02_architecture/global-architecture.md
- context:
  - domains/mcp/context.md
  - GLOBAL_CONTEXT.md
  - CONTEXT_MAP.md
- implementation_gate: Server 只能实现 MCP `2026-07-28` 的 `POST /mcp`、已登记 8 个 method、11 个固定 Tool、6 类 Resource 和 `tasks/get|cancel`；Capability 仅只读发现，所有异步执行必须通过已发布且 `run_enabled=true` 的 Application。每请求必须重新校验 Identity JWT、MCP 权限、目标领域权限和对象可见性；ApplicationRun、AtomicTask 与 McpTaskBinding 全部持久化后才能返回 MCP Task，TTL 只清理 Binding。素材二进制必须使用 Asset Library 受控内容端点，不得经过 JSON-RPC 或直传 StorageBackend。Identity JWT 验签、撤销和 platform-management AuditLog 的精确实现仍需补齐对应 S2，实施不得自行发明该合同；OAuth/PAT、直接 Capability 执行、泛化 Invocation、`input_required`、`tasks/update`、动态 Tool、Prompts、Apps 和 Sampling 均保持禁用。

## spec-v1.8.1

- commit: 183895c654529707f590c923ba1e64ec5104138d
- status: released
- confirmed_by: user（2026-07-30 明确要求直接发布 `spec-v1.8.1`）
- allowed_as_formal_implementation_basis: false
- release_kind: context-navigation
- domains:
  - ai-chatting
  - application-platform
  - asset-library
  - identity
  - model-management
  - notification-center
  - sse
  - task-center
  - workflow-canvas
- context:
  - GLOBAL_CONTEXT.md
  - CONTEXT_MAP.md
  - domains/ai-chatting/context.md
  - domains/application-platform/context.md
  - domains/asset-library/context.md
  - domains/identity/context.md
  - domains/model-management/context.md
  - domains/notification-center/context.md
  - domains/sse/context.md
  - domains/task-center/context.md
  - domains/workflow-canvas/context.md
- S1: []
- S2: []
- implementation_gate: 本版本只发布 AI/开发者的上下文摘要与读取导航，不修改产品语义或实现合同。Context 必须让位于对应 S1/S2；任何实现、合并、验收和正式发布仍须使用已有或后续经用户确认且 `allowed_as_formal_implementation_basis: true` 的 Spec release。

## spec-v1.8.0

- commit: 0c9bfbf4ff42a1856f54d2201b267b47739c7188
- status: released
- confirmed_by: user（2026-07-29 明确要求提交并发布 release）
- allowed_as_formal_implementation_basis: true
- domains:
  - notification-center
  - sse
- S1:
  - 00_product/domains/notification-center/product-spec.md
  - 00_product/domains/sse/product-spec.md
- S2:
  - 01_contracts/domains/notification-center/openapi.yaml
  - 01_contracts/domains/notification-center/schema.sql
  - 01_contracts/domains/notification-center/errors.yaml
  - 01_contracts/domains/notification-center/permissions.yaml
  - 01_contracts/domains/notification-center/events.yaml
  - 01_contracts/domains/notification-center/module-contract.md
  - 01_contracts/domains/sse/openapi.yaml
  - 01_contracts/domains/sse/schema.sql
  - 01_contracts/domains/sse/events.yaml
  - 01_contracts/domains/sse/module-contract.md
  - 01_contracts/error-code-index.md
- architecture:
  - 02_architecture/domains/notification-center.md
  - 02_architecture/global-architecture.md
- implementation_gate: 首期只启用 standalone `atomic_task_status_changed` 与 `canvas_run_status_changed` 对应 ACTIVE topic；Group、Asset、Application、Engine、ProviderModel 的 CONTRACT_GAP 以及全部 FUTURE topic 必须保持禁用。Server 必须实现 Notification/recipient counter/Notification Outbox 原子提交、独立 Worker 幂等聚合和双 Outbox 恢复；Web 只复用 `/api/v1/events/stream` 获取提示并通过 Notification REST API 重查完整事实，不得建立通知私有 SSE。

## spec-v1.7.14

- commit: ca64ac47cae099886c3216d5f7eb02d3b6f92d7d
- status: released
- confirmed_by: user（2026-07-28 明确要求实现 Canvas Application execution、发布联动与 Artifact 输出闭环）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
  - workflow-canvas
  - task-center
  - sse
- S1:
  - 00_product/domains/application-platform/product-spec.md
  - 00_product/domains/workflow-canvas/product-spec.md
  - 00_product/domains/sse/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
  - 01_contracts/domains/workflow-canvas/module-contract.md
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md
  - 02_architecture/domains/workflow-canvas.md
- implementation_gate: Canvas 只创建 DAG 内唯一 `application-platform.run` AtomicTask；Worker 在最终输入解析后以 CanvasRun 与 execution key 幂等创建并绑定 ApplicationRun，禁止第二个任务。ApplicationVersion 发布必须可靠驱动节点目录登记，发布/运行实时复核受控可用性；ApplicationRun Artifact 引用必须单调投影为 Canvas READY 输出。

## spec-v1.7.13

- commit: e9814d0
- status: released
- confirmed_by: user（2026-07-28 明确授权修复应用任务已执行但运行记录和运行结果不可见的问题）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md
- implementation_gate: Server 必须提供按 Application 分页读取运行历史的接口，并仅在 AtomicTask 终态持久化后按递增 resource version 单调、幂等投影状态、输出和 Artifact 引用；Web 必须直接读取该同域接口展示持久化运行记录，不得通过 Task Center 扇出或降级拼装。

## spec-v1.7.12

- commit: 03b5dc8
- status: released
- confirmed_by: user（2026-07-28 明确要求增加素材批量删除、单项/批量直接硬删除和回收站清空功能）
- allowed_as_formal_implementation_basis: true
- domains:
  - asset-library
- S1:
  - 00_product/domains/asset-library/product-spec.md
- S2:
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/errors.yaml
  - 01_contracts/domains/asset-library/permissions.yaml
  - 01_contracts/domains/asset-library/module-contract.md
- architecture:
  - 02_architecture/domains/asset-library.md
- implementation_gate: Server 必须保持单删默认软删除，只有显式 hard_delete 才绕过回收站；批量删除最多 200 个唯一 ID，批量和清空回收站均逐项隔离并返回结果；所有硬删除路径复用强引用检查且只清理无共享引用 Blob。Web 必须对不可逆操作进行明确确认并读取逐项结果。

## spec-v1.7.11

- commit: 00b78aa
- status: released
- confirmed_by: user（2026-07-28 明确要求实现 TaskSchedule 立即执行能力并提交代码）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
- S1:
  - 00_product/domains/task-center/product-spec.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/events.yaml
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md
- implementation_gate: Server 必须使用固定手动控制工作流异步执行 MATERIALIZED/RECONCILE，按请求键和 ScheduleExecution ID 双层幂等并复用活动锁；Web 只对受权 ACTIVE/PAUSED 计划展示立即执行，确认后进入返回的执行记录。

## spec-v1.7.10

- commit: d0c773a
- status: released
- confirmed_by: user（2026-07-27 明确授权新增并发布 ApplicationEngineInstance 同名专用错误码）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/errors.yaml
- implementation_gate: Server 必须将 EngineInstance 创建和更新的名称唯一索引冲突映射为 `ERR_AIAPP_ENGINE_INSTANCE_NAME_DUPLICATED`，不得继续映射为鉴权配置错误。

## spec-v1.7.9

- commit: 0c89181
- status: released
- confirmed_by: user（2026-07-24 明确要求 ComfyUI API-ready 工作流直接选择引擎并支持多次模板转换，同时删除重建 Application Platform 数据）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
  - 01_contracts/domains/application-platform/runtime-registry.yaml
- architecture:
  - 02_architecture/domains/application-platform.md
- implementation_gate: Server 必须删除重建全部 Application Platform 表，不回填旧数据；转换直接选择当前可用 ComfyUI EngineInstance 实时校验，同一 API-ready 工作流可用不同幂等键创建多个模板。Web 必须使用引擎资源选择器和 `operation_executors` 派生的多语言能力下拉。

## spec-v1.7.8

- commit: cff0403
- status: released
- confirmed_by: user（2026-07-24 明确要求实施 ComfyUI 系统内置 ProviderCapability、不可变默认绑定及字段文档）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/module-contract.md
  - 01_contracts/domains/application-platform/provider-capabilities/provider-capability.schema.yaml
  - 01_contracts/domains/application-platform/provider-capabilities/comfyui.yaml
  - 01_contracts/domains/application-platform/provider-capabilities/deepseek.yaml
  - 01_contracts/domains/application-platform/provider-capabilities/seedance.yaml
- architecture:
  - 02_architecture/domains/application-platform.md
- implementation_gate: Server 必须将 comfyui-workflow-runtime 编译进服务，为全部现有及新建 comfyui EngineInstance 原子维护 required_immutable 系统绑定，并拒绝外部保留 ID 覆盖和系统绑定写操作；ComfyUI workflow contract 仍是具体模板与运行能力事实源。

## spec-v1.7.7

- commit: a26b029
- status: released
- confirmed_by: user（2026-07-24 明确要求 ComfyUI 工作流导入移除实例依赖，并在 Visual Workflow 转 API 时显式选择可用实例）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md
- implementation_gate: 工作流导入不得接收、保存或查询 EngineInstance/object_info；Visual Workflow 显式转换必须提交 engine_instance_id，并使用 enabled、online 且当前目录未过期的 ComfyUI 实例。

## spec-v1.7.6

- commit: ce3538e（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-23 明确要求参考 ComfyUI 应用逻辑，只采集输出节点结果）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md
- implementation_gate: output-candidates 只有所属节点在目标实例当前 object_info 中声明 output_node=true 时才可标记 extractable；普通中间端口不得用于应用模板或试运行输出，试运行进一步只接受 image/text 候选。

## spec-v1.7.5

- commit: 3e166a5（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-23 明确确认 ComfyUI 试运行仍保持临时预览，并仅按选定输出节点采集）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md
- implementation_gate: Server 必须持久化并重新校验输出候选选择快照，collect_preview 只读取选择快照中 node_id 对应的轻量预览并按节点去重；Web 必须同时提交输入覆盖与至少一个输出候选。试运行不得登记 Artifact/Asset。

## spec-v1.7.4

- commit: 81e6cfd（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-23 确认继续实施管理员 Blob/StorageBackend 独立详情接口，并明确管理员全量返回物理定位与配置）
- allowed_as_formal_implementation_basis: true
- domains:
  - asset-library
- S1:
  - 00_product/domains/asset-library/product-spec.md
- S2:
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/schema.sql
  - 01_contracts/domains/asset-library/errors.yaml
  - 01_contracts/domains/asset-library/permissions.yaml
  - 01_contracts/domains/asset-library/module-contract.md
- architecture:
  - 02_architecture/domains/asset-library.md
- implementation_gate: Server 必须对 Blob 详情及 StorageBackend 列表/详情/创建/更新执行 ADMIN/SUPER_ADMIN 鉴权，管理员响应原样返回 object_key、root 与 config，普通素材和跨域摘要不得传播这些字段；StorageBackend 列表的 items/backends 必须来自同一次查询且内容相同。

## spec-v1.7.3

- commit: ab677e7（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-23 明确要求实施系统任务名称多语言方案，且方案要求先发布 SSOT）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
- S1:
  - 00_product/domains/task-center/product-spec.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md
- implementation_gate: Server 必须保留原 `name`，仅对持久化为 SYSTEM 且具有有效 name key/参数的新资源返回至少包含 `zh-CN` 和 `en-US` 的多语言映射；公开请求不得注入系统名称元数据，历史资源不得按文本或 createdBy 启发式回填。

## spec-v1.7.2

- commit: 4d601ce（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-22 明确要求直接补充缺失 S1/S2 并发布 spec-v1.7.2）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
  - asset-library
- S1:
  - 00_product/domains/task-center/product-spec.md
  - 00_product/domains/asset-library/product-spec.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/events.yaml
  - 01_contracts/domains/task-center/module-contract.md
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/permissions.yaml
  - 01_contracts/domains/asset-library/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md
  - 02_architecture/domains/asset-library.md
- implementation_gate: Server 必须先实现 DAG trigger/时间与 dag_node_key migration、确定性节点聚合、规范化事件/时间线、日志 cursor/筛选/下载、admin-only executor 裁剪及 Asset Library 有界批量摘要，再允许 Web 以本 release 作为 DAG 运行工作台正式契约；不得新增第二套运行历史、暴露运行时 payload/Worker 内部标识、跨域读取私表或形成 Artifact N+1。

## spec-v1.7.1

- commit: 865741c（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-22 明确要求实施 Task Center 执行日志修复方案并先发布 SSOT）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
- S1:
  - 00_product/domains/task-center/product-spec.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/errors.yaml
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md
- implementation_gate: Server 必须通过 WorkflowRuntime 消费方接口代理 Conductor task log，执行 AtomicTask/Attempt 归属授权、双重脱敏、分页排序和 best-effort 写入；不得新增日志业务表、复用 Asset Library 媒体存储、暴露 Conductor API/UI 或把日志写入失败变成任务失败。

## spec-v1.7.0

- commit: 467abaa（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-22 明确要求发布 Canvas release 并推送到远端仓库）
- allowed_as_formal_implementation_basis: true
- domains:
  - workflow-canvas
  - sse
- S1:
  - 00_product/domains/workflow-canvas/product-spec.md
  - 00_product/domains/sse/product-spec.md
- S2:
  - 01_contracts/domains/workflow-canvas/openapi.yaml
  - 01_contracts/domains/workflow-canvas/schema.sql
  - 01_contracts/domains/workflow-canvas/errors.yaml
  - 01_contracts/domains/workflow-canvas/permissions.yaml
  - 01_contracts/domains/workflow-canvas/events.yaml
  - 01_contracts/domains/workflow-canvas/module-contract.md
  - 01_contracts/domains/sse/openapi.yaml
  - 01_contracts/domains/sse/events.yaml
  - 01_contracts/domains/sse/module-contract.md
  - 01_contracts/error-code-index.md
- architecture:
  - 02_architecture/domains/workflow-canvas.md
  - 02_architecture/global-architecture.md
- implementation_gate: 正式 Server/Web 实施前仍需完成人工 API 兼容评审、Task Center 内容寻址 DAG 注册/批量摘要协作、Asset Library producer context 协作、identity 权限绑定和旧 DTO/schema 迁移门禁。

## spec-v1.6.5

- commit: 9de8a07
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - model-management
- S1:
  - 00_product/domains/model-management/product-spec.md
- S2:
  - 01_contracts/domains/model-management/openapi.yaml
  - 01_contracts/domains/model-management/module-contract.md
- architecture:
  - 02_architecture/domains/model-management.md

## spec-v1.6.4

- commit: 6b4a112
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - asset-library
- S1:
  - 00_product/domains/asset-library/product-spec.md
- S2:
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/module-contract.md
- architecture:
  - 02_architecture/domains/asset-library.md

## spec-v1.6.3

- commit: 5fb52fbc91c4d8611d99e48894617a24a8450972
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - ai-chatting
- S1:
  - 00_product/domains/ai-chatting/product-spec.md
- S2:
  - 01_contracts/domains/ai-chatting/openapi.yaml
  - 01_contracts/domains/ai-chatting/module-contract.md
- architecture:
  - 02_architecture/domains/ai-chatting.md

## spec-v1.6.2

- commit: 73f37510a92d6b697773188a85a449a2cb06183e
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - workflow-canvas
- S1:
  - 00_product/domains/workflow-canvas/product-spec.md
- S2:
  - 01_contracts/domains/workflow-canvas/openapi.yaml
  - 01_contracts/domains/workflow-canvas/module-contract.md
- architecture:
  - 02_architecture/domains/workflow-canvas.md

## spec-v1.6.1

- commit: 47948e29dd208a6f4c73a22a15636114da5f15aa
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md

## spec-v1.6.0

- commit: 81d9788e2ca4b772e93e735d4e5663caf6fc5996
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - global
  - task-center
- S1:
  - 00_product/global-business-rules.md
  - 00_product/domains/task-center/product-spec.md
- S2:
  - skills/spec-workflow/S2.md
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md

## spec-v1.5.1

- commit: 069a43778d82de87ab69b0885148f74c177a85ee
- status: released
- confirmed_by: user（2026-07-20 明确要求提交代码、发布小版本并推送）
- allowed_as_formal_implementation_basis: true
- domains:
  - asset-library
- S1:
  - 00_product/domains/asset-library/product-spec.md
- S2:
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/schema.sql
  - 01_contracts/domains/asset-library/errors.yaml
  - 01_contracts/domains/asset-library/permissions.yaml
  - 01_contracts/domains/asset-library/events.yaml
  - 01_contracts/domains/asset-library/module-contract.md
  - 01_contracts/error-code-index.md

## spec-v1.5.0

- commit: ecd9381adb1afff5dd5acaf3d705814acd43ca8c
- status: released
- confirmed_by: user（2026-07-20 明确要求推送并发布 Artifact-to-asset-library coordinated release）
- allowed_as_formal_implementation_basis: true
- implementation_gate: 正式服务端切换前必须完成 Artifact/Representation 数据回填、领域源事件切换、ApplicationPlatform 引用投影重建、兼容消费者验证和旧处理路径退役方案。
- domains:
  - asset-library
  - task-center
  - application-platform
  - sse
  - workflow-canvas
- S1:
  - 00_product/domains/asset-library/product-spec.md
  - 00_product/domains/task-center/product-spec.md
  - 00_product/domains/application-platform/product-spec.md
  - 00_product/domains/sse/product-spec.md
  - 00_product/glossary.md
- S2:
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/schema.sql
  - 01_contracts/domains/asset-library/errors.yaml
  - 01_contracts/domains/asset-library/permissions.yaml
  - 01_contracts/domains/asset-library/events.yaml
  - 01_contracts/domains/asset-library/module-contract.md
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/events.yaml
  - 01_contracts/domains/task-center/module-contract.md
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
  - 01_contracts/domains/sse/openapi.yaml
  - 01_contracts/domains/sse/schema.sql
  - 01_contracts/domains/sse/events.yaml
  - 01_contracts/domains/sse/module-contract.md
  - 01_contracts/domains/workflow-canvas/module-contract.md
  - 01_contracts/error-code-index.md
- architecture:
  - 02_architecture/domains/asset-library.md
  - 02_architecture/domains/task-center.md
  - 02_architecture/domains/application-platform.md
  - 02_architecture/domains/sse.md
  - 02_architecture/domains/workflow-canvas.md
  - 02_architecture/global-architecture.md

## spec-v1.4.0

- commit: 9819f0e6eebbd06ae04a8c81393bf63bedad21a8
- status: released
- confirmed_by: user（2026-07-19 明确要求基于 EngineInstance 当前 object_info 方案修改 SSOT 并发布）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/permissions.yaml
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md

## spec-v1.3.0

- commit: 82b59cf0baf5d147052676b42d4903f554ae14e9
- status: released
- confirmed_by: user（2026-07-18 明确要求发布 release 并完成后端与前端实现）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
  - application-platform
- S1:
  - 00_product/domains/task-center/product-spec.md
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/errors.yaml
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/events.yaml
  - 01_contracts/domains/task-center/module-contract.md
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md
  - 02_architecture/domains/application-platform.md

## spec-v1.1.0

- commit: b3c402b
- status: released
- confirmed_by: user（2026-07-18 明确要求执行 ComfyUI 双来源导入、API 转换和任务中心试运行计划）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
  - task-center
- S1:
  - 00_product/domains/application-platform/product-spec.md
  - 00_product/domains/task-center/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/permissions.yaml
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md
  - 02_architecture/domains/task-center.md

## spec-v1.0.4

- commit: bdfc39c987a23ff00b585f5cb1b02669a95f64e2
- status: released
- confirmed_by: user（2026-07-18 明确要求 EngineInstance 列表返回 endpoint）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml

## spec-v1.0.3

- commit: aa900201ac82ab01a8bc85f0f4953e12a92decab
- status: released
- confirmed_by: user（2026-07-18 明确要求实施调度运行关联，客户端生成校验发现并修正响应字段归属）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
- S2:
  - 01_contracts/domains/task-center/openapi.yaml

## spec-v1.0.2

- commit: a1d86a592c7e41cf95b55b71867198b4c54644eb
- status: released
- confirmed_by: user（2026-07-18 明确要求实施调度目标关联，实施校验发现并修正周期轮次唯一索引冲突）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
- S2:
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/module-contract.md

## spec-v1.0.1

- commit: 19c02f9a837dd1f49cf90d98404dfb1e439fed40
- status: released
- confirmed_by: user（2026-07-18 明确要求实施调度计划目标与运行历史关联修复）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
- S1:
  - 00_product/domains/task-center/product-spec.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md

## spec-v1.0.0

- commit: b928ab5e13d809f837da81ee362b9218c4629fdb
- status: released
- confirmed_by: user（2026-07-17 明确要求直接修改 SSOT 并发布）
- allowed_as_formal_implementation_basis: true
- implementation_gate: 正式服务端切换前仍须完成 Conductor/Go Worker/重启恢复/幂等与禁止重叠 PoC。
- domains:
  - task-center
  - workflow-canvas
  - application-platform
  - asset-library
  - ai-chatting
- S1:
  - 00_product/domains/task-center/product-spec.md
  - 00_product/domains/workflow-canvas/product-spec.md
  - 00_product/domains/application-platform/product-spec.md
  - 00_product/domains/asset-library/product-spec.md
  - 00_product/glossary.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/errors.yaml
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/events.yaml
  - 01_contracts/domains/task-center/module-contract.md
  - 01_contracts/domains/workflow-canvas/openapi.yaml
  - 01_contracts/domains/workflow-canvas/schema.sql
  - 01_contracts/domains/workflow-canvas/errors.yaml
  - 01_contracts/domains/workflow-canvas/permissions.yaml
  - 01_contracts/domains/workflow-canvas/events.yaml
  - 01_contracts/domains/workflow-canvas/module-contract.md
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/permissions.yaml
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/events.yaml
  - 01_contracts/domains/asset-library/module-contract.md
  - 01_contracts/domains/ai-chatting/module-contract.md
  - 01_contracts/error-code-index.md
- architecture:
  - 02_architecture/domains/task-center.md
  - 02_architecture/domains/workflow-canvas.md
  - 02_architecture/domains/application-platform.md
  - 02_architecture/domains/asset-library.md
  - 02_architecture/global-architecture.md

## spec-v0.9.1

- commit: 339cc89c1060389ea7d18715af11ab60b1481fa4
- status: released
- confirmed_by: user（2026-07-17 明确要求实施 AppEngine 周期健康检测计划）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/permissions.yaml
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
# spec-v0.9.2

- AppEngine 健康检测迁移至 Task Center 与 PARALLEL TaskGroup。
- TaskGroup 运行机制和动态子任务契约完成 release。
# spec-v0.9.3

- 修复系统周期任务通用幂等作用域的 schema 约束。
## spec-v1.2.0

- commit: 4edf0a34359fcb743c1262a78fc7b1848ddcd817
- status: released
- confirmed_by: user（2026-07-18 明确要求实施试运行配置快照、详情与再次运行计划）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md
