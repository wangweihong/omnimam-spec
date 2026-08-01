# Agent Module Contract

产品语义以 `00_product/domains/agent/product-spec.md` 为准。本合同只覆盖第一阶段 Platform/Coding Agent、Hermes/OpenCode、Rootless Docker AgentRuntimeProvider、AgentWorkspace 和 AppStudio Workspace Tool 协作；Kubernetes Provider、热迁移、多 Workspace 与跨 Provider 自动容灾未开放。

## 1. 模块边界

| 模块 | 拥有 | 不拥有 | S1 引用 |
| --- | --- | --- | --- |
| agent-core | Agent 身份、类型、Provider、固定 Workspace 引用、业务状态与生命周期 | StudioWorkspace、AtomicTask 状态、Runtime 底层实例 | BR-AGENT-001、BR-AGENT-002、BR-AGENT-014；US-AGENT-001、US-AGENT-006 |
| interaction | AgentSession、AgentInvocation、AgentMessage、Session Summary、AgentMemory 与实时轮次流 | TaskAttempt、通用 UserEvent 历史、AppStudio ChangeSet | BR-AGENT-004、BR-AGENT-005、BR-AGENT-006、BR-AGENT-010；US-AGENT-002、US-AGENT-003、US-AGENT-007 |
| workspace | AgentWorkspace、Snapshot、Owner、容量与生命周期 | StudioWorkspace 源码、任意宿主路径、Asset 内容 | BR-AGENT-002、BR-AGENT-003、BR-AGENT-014；US-AGENT-005 |
| runtime | AgentRuntime 业务实例、Provider 选择、代次、状态投影、空闲挂起与重建 | Hermes/OpenCode 内部协议、StudioRuntimeInstance、部署事实 | BR-AGENT-005、BR-AGENT-007、BR-AGENT-008、BR-AGENT-012；US-AGENT-004、US-AGENT-008 |
| provider-adapter | Hermes/OpenCode 启动、恢复、执行、取消和流式事件归一化 | 容器生命周期、用户授权、Workspace Owner | BR-AGENT-001、BR-AGENT-006、BR-AGENT-008；US-AGENT-002、US-AGENT-003、US-AGENT-007 |
| runtime-provider | Rootless Docker 受控创建/启动/停止/删除、状态查询、脱敏日志、健康检测 | Agent 业务决策、Session 恢复、AppStudio Build/Release | BR-AGENT-007、BR-AGENT-008、BR-AGENT-012；US-AGENT-004、US-AGENT-008 |
| appstudio-collaboration | 固定 StudioWorkspace 校验、Invocation 有界 Tool 授权请求、稳定结果引用 | 源码、Revision、ChangeSet、Snapshot、Build、Release | BR-AGENT-002、BR-AGENT-009、BR-AGENT-014；US-AGENT-006 |
| event-outbox | Agent 可靠事件的事务写入、重试与重放 | Notification 收件箱、UserEvent 历史、跨域状态机 | BR-AGENT-011；US-AGENT-001、US-AGENT-002、US-AGENT-004、US-AGENT-005、US-AGENT-008 |

## 2. 数据归属

| 数据 | 所有者 | Agent 保存方式 |
| --- | --- | --- |
| Agent、Session、Invocation、Message、Memory | agent | 完整业务事实 |
| AgentWorkspace、AgentWorkspaceSnapshot | agent | 完整元数据；`storage_ref` 仅 workspace 私有模块可读 |
| AgentRuntime、AgentRuntimeProvider 状态 | agent | 业务状态与受控 Provider 引用 |
| StudioWorkspace、Revision、ChangeSet、Build、Release | appstudio | 只保存稳定 ID、当前操作摘要和必要历史引用 |
| AtomicTask、TaskAttempt、TaskGroup、Schedule | task-center | 只保存 `atomic_task_id` 及权限裁剪一跳摘要 |
| Notification、UserEvent | notification-center、sse | 不保存；只发布可靠源事件 |
| JWT、Principal、RBAC、安全审计 | identity | 当前请求上下文与受控审计调用 |

`workspace_type + workspace_id` 是多态稳定引用。`workspace_type=agent` 在 Agent 模块内解析；`workspace_type=studio` 必须调用 AppStudio 受控接口，不得对 AppStudio 私表建外键或 JOIN。

## 3. Agent 创建与固定 Workspace

- Platform Agent 创建请求可以提供已有 `agent_workspace_id`，也可以省略并由 Agent Service 创建 Owner 为 Agent 的 AgentWorkspace。
- Coding Agent 创建请求必须提供 `studio_workspace_id`；AppStudio 必须同时确认当前 Principal 的可见性、Workspace 可用状态与应用范围。
- 创建成功后 `workspace_type`、`workspace_id` 不可通过 PATCH 修改。处理其他 Workspace 必须创建新的 Agent。
- 响应中的 `workspace` 是一跳权限裁剪摘要。StudioWorkspace 不可见、已归档或被删除时摘要不得泄露名称，Agent 后续 Invocation 以 `ERR_AGENT_STUDIO_WORKSPACE_AUTH_FAILED` 失败。
- Agent 删除只对 `owner_type=agent && owner_id=agent_id` 的 AgentWorkspace执行受控删除；其他 AgentWorkspace 只解除引用，StudioWorkspace 永不由 Agent 删除。

相关引用：BR-AGENT-001、BR-AGENT-002、BR-AGENT-003、BR-AGENT-014；US-AGENT-001、US-AGENT-005、US-AGENT-006。

## 4. Session、Invocation 与 Task Center

创建 Invocation 的事务边界固定为：

```text
validate Agent/Session/Workspace authorization
→ persist user AgentMessage
→ persist AgentInvocation with idempotency key
→ request Task Center AtomicTask
→ bind atomic_task_id
→ return durable Invocation
```

- 未形成可读取的 `atomic_task_id` 时不得返回可执行 Invocation；部分事实必须补偿为 FAILED 或在同一事务边界回滚。
- 同一 `owner_user_id + idempotency_key` 重复请求必须返回同一 Invocation。
- Agent 只把 Invocation 状态作为上层业务投影。Task Center 拥有调度、Attempt、重试、取消、超时和最终任务状态。
- 取消先校验 `agent.invoke`，再校验 `task.atomic.operate` 并调用 Task Center；Agent 不提前把 Invocation 写为 CANCELED。
- `WAITING_USER` 结束当前 Invocation/AtomicTask。用户回复创建新的 Invocation，不保留无限等待任务。
- 一个 Agent 的非终态写入 Invocation 由数据库部分唯一约束和应用层幂等共同保证。

相关引用：BR-AGENT-004、BR-AGENT-005、BR-AGENT-010；US-AGENT-002、US-AGENT-003。

## 5. 实时输出边界

`GET /api/v1/agent-invocations/{invocation_id}/events` 是单一 Invocation 的短期 SSE 流，不是通用 SSE 领域的 `UserEvent` 历史。

- 每次连接重新校验 Invocation 可见性和 `agent.invoke`。
- 只允许 token/delta、状态、Tool 名称和脱敏 Tool 结果摘要；禁止 Secret、源码存储路径、Provider 原始响应和任意基础设施地址。
- `Last-Event-ID` 只在该 Invocation 的短期保留窗口内有效。窗口外客户端通过 Invocation/Message API 重查完整事实。
- 流断开不得改变 Invocation 或 AtomicTask 状态；AgentMessage 与 Invocation 表仍是可恢复事实。

相关引用：BR-AGENT-004、BR-AGENT-006、BR-AGENT-011；US-AGENT-003、US-AGENT-007。

## 6. AgentRuntime 生命周期

- 正常消息自动按需创建或恢复 Runtime；显式 start、suspend、rebuild 使用相同业务编排和稳定 `idempotency_key`。
- 一个 Agent 同时最多存在一个活动 Runtime。重建创建新 `generation`，保留旧 Runtime 历史，成功后才切换 `Agent.current_runtime_id`。
- Provider 创建幂等键至少绑定 `agent_id + generation + action`。TaskAttempt 重试必须复用，不得创建第二个底层实例。
- Runtime 响应不暴露 `provider_runtime_id`、bootstrap endpoint、宿主地址、容器名、Kubernetes UID 或凭证。
- Provider 不可用时新 Invocation 可以保持 `WAITING_RUNTIME` 或以可重试错误失败；不得把所有持久化 Agent 永久写为 ERROR。
- Coding Agent Runtime 不挂载 StudioWorkspace。每次 Invocation 都重新获取 AppStudio Tool 授权。

相关引用：BR-AGENT-005、BR-AGENT-007、BR-AGENT-008、BR-AGENT-012、BR-AGENT-013；US-AGENT-004、US-AGENT-006、US-AGENT-008。

## 7. AppStudio Workspace Tool

Agent 调用 AppStudio Tool 前必须请求绑定以下声明的短期授权：

```text
principal_id
agent_id
agent_session_id
agent_invocation_id
studio_workspace_id
allowed_actions
expires_at
authorization_id
```

- Agent 只能请求 S1 已列出的文件读取、搜索、ChangeSet、预览检查和诊断动作。
- AppStudio 每次调用重新校验声明、Agent 固定 Workspace、当前 Revision 与资源权限；授权 ID 不是永久凭证。
- Tool 授权过期可在不扩大权限的前提下重新签发。Workspace 改变、Invocation 终态、Agent 停用或 Principal 失权后必须拒绝。
- Agent 保存 `StudioChangeSet`、Revision、Preview Check 或 Build 的稳定 ID 与摘要，不复制源码和 AppStudio 状态机。
- AppStudio 返回的 `WORKSPACE_REVISION_CONFLICT` 等错误由 AppStudio 拥有；Agent 在 Tool 结果中保留源领域 code/value，不创建同义 Agent 错误。

相关引用：BR-AGENT-002、BR-AGENT-009、BR-AGENT-014；US-AGENT-006。

## 8. AgentWorkspace 与 Snapshot

- API 永不返回 `storage_ref`、宿主路径、挂载参数或底层 Snapshot 位置。
- Snapshot 只有 READY 且 `content_digest` 存在时可以作为恢复源；恢复失败保持原 Workspace 可用事实，不得把部分内容标记为当前版本。
- 活动 Runtime 写入期间，删除与恢复必须拒绝或等待受控挂起；不得绕过单 Runtime 写入约束。
- `current_snapshot_id` 只指 Agent 域 Snapshot；Snapshot 删除前必须解除该引用。
- 列表与详情通过当前域批量 JOIN `owner_type=agent` 的 Agent 摘要，禁止逐项查询；User/System Owner 不递归展开。

相关引用：BR-AGENT-003、BR-AGENT-005、BR-AGENT-014；US-AGENT-005。

## 9. 健康检查、对账与修复

- Task Center 的 RECONCILE Schedule 触发 Provider/Runtime 批量探测；轻量查询、比较和投影更新不为每项创建 AtomicTask。
- 只有耗时、需重试或有外部副作用的修复才创建 AtomicTask，并使用 `runtime_provider_id + repair_type + observed_generation` 稳定幂等键。
- Provider 有、数据库无的实例标记为孤儿；数据库有、Provider 无的 Runtime 单调更新为 FAILED/DELETED。对账不得读取或改写 AppStudio Runtime。
- `agent.runtime_provider.admin` 只允许管理员查看权限裁剪容量摘要与触发对账，不能提交 Docker Socket、宿主路径、镜像或任意基础设施配置。

相关引用：BR-AGENT-008、BR-AGENT-010、BR-AGENT-012；US-AGENT-008。

## 10. 权限与存在性保护

- 普通用户只访问 `owner_user_id` 属于自己的 Agent、Session、Invocation、Message、Memory 和 AgentWorkspace。
- 管理员范围仍须由 Identity/RBAC 明确授权，不能因管理员角色直接获得 StudioWorkspace 源码或 Secret。
- 资源不存在与不可见统一返回相应 `*_NOT_VISIBLE` 业务错误和 HTTP 200，不泄露存在性。
- 读取关联摘要时最多展开一跳；目标不存在、删除或不可见时摘要为 null，但稳定 ID 按历史/审计需要保留。
- 列表使用本域 JOIN 或目标域批量摘要接口，不允许逐行跨域查询形成 N+1。

相关引用：BR-AGENT-002、BR-AGENT-003、BR-AGENT-008、BR-AGENT-009、BR-AGENT-014；US-AGENT-001、US-AGENT-002、US-AGENT-003、US-AGENT-004、US-AGENT-005、US-AGENT-006、US-AGENT-007、US-AGENT-008。

## 11. 事件边界

- 所有 `events.yaml` 事件与聚合事实在同一数据库事务写入 `agent_outbox`，发布失败不回滚业务事实。
- 事件幂等键使用 `aggregate_id:resource_version`；消费者必须丢弃相同或更低版本。
- Agent 事件只携带 Owner/聚合稳定 ID、状态、资源版本与必要失败分类。禁止消息正文、Memory 内容、Secret、文件路径、源码、provider_runtime_id 和 Provider 原始响应。
- Notification Center 自行决定主题、聚合、已读和渠道；SSE 只投影变化提示。Agent 不维护通知或 UserEvent 事实。

相关引用：BR-AGENT-011、BR-AGENT-012；US-AGENT-001、US-AGENT-002、US-AGENT-003、US-AGENT-004、US-AGENT-005、US-AGENT-008。

## 12. 跨域调用规则

| 目标领域 | 允许调用 | 禁止行为 |
| --- | --- | --- |
| identity | JWT/Principal/RBAC 校验、安全审计 | 读取 Identity 私表、缓存永久授权 |
| task-center | 创建/查询/取消 AtomicTask，注册 RECONCILE Schedule | 写 Task 状态、Attempt、重试或 Lease |
| appstudio | 校验 StudioWorkspace、获取短期 Tool 授权、调用受控 Workspace Tool | 读取私表、挂载存储、创建 Build/Release/Runtime |
| notification-center | 可靠事件消费 | 写收件箱、已读、偏好或聚合 |
| sse | 投影已持久化 Agent 事件 | 把实时 token 流写入通用 UserEvent 历史 |

跨域调用必须携带 `request_id`、`correlation_id`、当前 Principal 和稳定幂等键（有副作用时）。任何跨域依赖失败不得通过直接写目标域数据补偿。

## 13. 保留与删除策略

- Agent 使用 `deleted_at` 保留删除审计；进入 DELETING 后由维护任务停止 Invocation/Runtime 并按 Owner 规则处理 Workspace，不物理级联删除 Session、Message、Memory 或事件历史。
- AgentSession、AgentInvocation、AgentMessage 和 AgentMemory 是交互历史。关闭、终态、superseded 或 deleted 使用状态表达，首期不提供物理删除 API。
- AgentWorkspace 和 Snapshot 使用 DELETING/DELETED 与 `deleted_at`；底层存储删除失败必须保留 ERROR/失败事件，不能只删数据库行。
- AgentRuntime 进入 DELETED 并保留 `deleted_at`、generation 与脱敏诊断；Provider 实例清理不删除历史 Runtime 记录。
- AgentRuntimeProvider 是系统注册资源，只允许 DISABLED，不提供删除。
- `agent_outbox` 成功投递并超过平台审计保留期后可物理清理；清理 outbox 不得删除或改写聚合事实。

相关引用：BR-AGENT-003、BR-AGENT-006、BR-AGENT-007、BR-AGENT-011、BR-AGENT-014；US-AGENT-001、US-AGENT-002、US-AGENT-005、US-AGENT-007。
