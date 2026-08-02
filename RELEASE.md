# Release Records

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
