# Agent Module Contract

产品语义以 `00_product/domains/agent/product-spec.md` 为准。本合同覆盖当前 S1；旧版 S2 不属于输入。

## 1. 追溯状态

当前 Agent S1 使用 `US-AGENT-001`、`BR-AGENT-001`、`AC-AGENT-001-01..18` 及 `R-AGENT-*` 规则。OpenAPI、Schema、错误、权限和事件必须同时遵守 Workspace 后端内化、固定 Binding、全量 CHAT/CODING Task-backed、软删除终结、模型/MCP grant、Runtime Git workspace access、Invocation 事件持久化重放和 Runtime 脱敏诊断语义。

## 2. 模块边界

| 模块 | 拥有 | 不拥有 |
| --- | --- | --- |
| agent-core | Agent、AgentProfile 可用性投影、类型、状态和内部固定 Workspace 引用 | Docker、StudioWorkspace 内容、Session 事实 |
| interaction | AgentSession、AgentMessage、AgentInvocation、Runtime Adapter 调用编排和短时 Endpoint 解析结果的内存使用 | AtomicTask 状态、InfraRuntime、Endpoint 发布事实、LLM Provider 协议 |
| memory | AgentMemory 的 scope、类型、正文和生命周期 | 向量数据库、跨用户共享记忆、Runtime 文件中的长期记忆 |
| workspace | 内部 AgentWorkspace、固定 Binding、授权摘要和挂载意图 | StudioWorkspace 私表、宿主路径、物理存储、公共 Workspace 页面或 API |
| runtime | AgentRuntimeBinding、AgentRuntimeGrant、AgentRuntimeProvider 状态投影和恢复 | InfraRuntime 运行状态、Docker Provider、业务 Task 状态 |
| mcp-binding | AgentMCPBinding 当前态、不可变 revision、owner 隔离和授权解析 | MCP Server 协议、明文 Secret、Docker 配置文件 |
| access | Agent 所有权、主体范围和权限组合 | Identity 用户/角色生命周期 |
| event-outbox | Agent 可靠事件、重试和重放 | Notification 收件箱、SSE 历史事实 |

## 3. 输入与输出

- 外部输入必须带可信 Principal；请求中的 `user_id` 不参与授权决策。
- 公共 `CreateAgent` 只创建 Platform Agent，不接受 `kind`、`workspace_type` 或 `workspace_id`。Agent Service 必须在同一业务事务中创建 AgentWorkspace、Agent、默认 Session 和唯一 Binding；任一步失败均不得产生可用 Agent。
- 公共 Agent 列表、详情、创建、更新、权限、错误、事件和 SSE 不得返回 Workspace 类型、ID、Binding 或授权摘要，也不得包含 AppStudio 管理的 Coding Agent。
- `CreateCodingAgentForStudio` 是仅供 AppStudio 受信模块调用的内部模块语义，不是公共 HTTP API。输入必须包含稳定 `studio_application_id`、内部 `studio_workspace_id`、`coding_agent_generation`、调用主体和幂等键；Agent Service 校验调用方、Workspace 类型和授权后原子创建 Coding Agent、默认 Session、固定 Workspace/Model Binding 和默认平台 MCP Binding。
- Coding Agent 创建时内部固定 `workspace_type=studio` 和 `workspace_id`；Platform Agent 内部固定 `workspace_type=agent`。Session/Invocation 不得切换；多个 Coding Agent 可引用同一 StudioWorkspace，但 Runtime Git 写入由 AppStudio 的单写事务、base Revision/CommitSHA 和 ChangeSet 投影校验。
- Agent 创建事务必须同时写入 `agents.workspace_type/workspace_id` 和唯一 `agent_workspace_bindings`，两处类型与 ID 必须一致；既有 Agent 不提供修改或重建 Binding 的写接口。
- Runtime 创建、启动、挂起、恢复、停止和删除只能通过 Task Center 的已注册 `functionRef`；Task Worker 再调用唯一 Infra Adapter。
- Agent Runtime 创建/启动/恢复只使用 `agent.runtime.ensure`，挂起/停止/删除只使用 `agent.runtime.stop`；arguments、结果、能力和策略必须符合 Task Center `function-registry.yaml` 固定版本，Agent 不提交 Infra DTO。
- Agent 只保存 `infra_runtime_id`、`endpoint_ref`、状态和脱敏错误。Infra Provider、容器、宿主机路径和明文 Secret 不得进入 Agent API、事件或业务表。
- AgentRuntimeAdapter 在调用 Hermes/OpenCode 前必须校验 Agent、Session、Invocation、AgentRuntimeBinding、`infra_runtime_id` 和 `endpoint_ref` 的一致性，然后以 Agent 工作负载身份调用 `POST /api/v1/infra/endpoints/{endpoint_id}/resolve`。请求固定 `purpose=AGENT_RUNTIME_ADAPTER`，并携带 owner reference 与 Invocation/trace 审计关联 ID。
- resolve 返回的 `base_url` 只允许在当前同步调用内存中使用。Agent 表、Task 结果、公共 OpenAPI、通知、SSE、事件和日志均不得新增 Endpoint 地址字段；AgentRuntimeAdapter 不得调用其他 Infra API。
- CHAT/CODING 必须使用 `agent.invocation.execute@1.0`；QUEUED 可在任务绑定提交前短暂没有 `atomic_task_id`，任何执行、取消或事件消费前必须绑定。API Server 不得启动 goroutine 或无 Task 降级执行。
- Invocation Task arguments 只允许 Agent、Session、Invocation、RuntimeBinding、`invocation_type`、短期 `agent-invocation-grant://` 授权引用、预期资源版本和可选 runtime/event 恢复游标；禁止消息 ID/正文、owner、Workspace、Runtime Endpoint、模型凭证、Git token、用户密钥和 Provider 配置。grant 必须绑定 owner、Agent、Session、Invocation、RuntimeBinding、用途、资源版本和有效期；CODING 的 `InvocationClaims` 额外固定 StudioApplication、Workspace、base Revision、base CommitSHA、Blueprint version 和 prompt kind，不再包含源码正文工具授权。Worker 只能按受信服务身份临时解析并执行协议。
- Agent 定义消费方 `WorkspaceGateway`。Platform Agent access 保持既有 AgentWorkspace 语义；Coding Agent 通过该接口获取 Runtime 生命周期的 opaque Git workspace access 和 Invocation base context。接口不得返回明文 token、GitLab remote numeric ID、credential URL 或 AppStudio 私表结构，也不得提供 Source MCP/API 写入能力。
- 未曾成功绑定 AtomicTask 的 `FAILED/ERR_AGENT_INVOCATION_TASK_UNAVAILABLE` Invocation，允许在同一业务幂等键下复用原 Message/Invocation、递增 submission generation/resource version 并重试 Task 提交；一旦绑定 Task，状态、取消和终态只能按当前 Task ID 与预期资源版本单调投影。
- Agent 内部 `ListMessages` 必须支持 owner、Agent、Session 受限查询并按 `(created_at DESC, id DESC)` 稳定分页；AppStudio 只能查询其当前 Application/generation/session。Agent Service 必须在 Invocation 创建时提供稳定 `user_message_id/assistant_message_id`，并以相同 ID 关联 delta、完成事件和持久化消息。
- AgentRuntimeAdapter 必须把 Runtime 原始输出规范化为 S1 第 12.3 节的 12 类完整事件 payload；事件按 Invocation 内 `sequence_no` 先持久化再推送。内部重放只返回游标之后的事件且无重复，唯一终态事件 flush 后关闭，已终态 Invocation 补完历史后关闭。
- Runtime 启动/恢复前必须解析用途匹配的 ACTIVE primary binding 并签发短期 AgentModelAccessGrant；校验失败前不得创建 RuntimeBinding 或 AtomicTask。Infra 只接收 grant 引用并以服务身份解析注入。
- MCP Binding 创建和 PUT 必须在同一事务写当前态与不可变 revision；PUT 全量替换可变字段并用 `resource_version` 乐观控制，凭证使用 `KEEP/SET/CLEAR`。DELETE 是不可恢复、幂等软删除；List 和新 Runtime 排除删除项，所有响应隐藏 `credential_ref`。
- `agent.runtime.ensure` 提交前按 Binding ID 稳定选择最多 50 个启用且未删除 Binding 的当前 revision，并持久化精确绑定 Runtime/请求/Agent generation/Application/refs/有效期的 AgentRuntimeGrant；入队失败撤销，重试复用同一 Grant。
- Task 参数中的 `binding_revision` 是当前整数 `resource_version` 的规范十进制字符串；resolver 必须按该精确版本解析，不得回退到最新版本。
- Infrastructure 只允许使用 `authorization_ref` 调用 Agent 内部 resolver 获取 Grant 授权的不可变 Binding revision；Grant 过期、撤销、Runtime 不匹配或 revision 越权立即拒绝。Worker、Infrastructure 和 Provider 不得读取 Agent 私表。
- Binding 解析结果只在 Runtime 创建内存中使用；endpoint、非敏感配置和 credential ref 继续交给受信 Secret/Identity resolver。明文值不得进入 Task、Agent revision、普通持久化、API、事件、日志、环境变量、命令参数或 inspect。
- RuntimeBinding 保存 `current_task_id/current_operation`；Task 结果只有同时匹配当前引用时才能单调投影。无 Runtime 删除立即写 `deleted_at`；有 Runtime 删除仅在 `agent.runtime.stop(action=DELETE)` 成功后事务写 Runtime `DELETED` 和 Agent `deleted_at`，失败保留 Infra 引用并回到可重试 `ERROR`。
- Agent Service 必须提供 owner/Application/Agent/generation-scoped 的 Runtime 详情与历史查询，并通过 `AgentRuntimeGrant` 关联全部 generation、按 Runtime Binding 去重。当前任务只取最新非终态 AgentInvocation；策略时长固定投影为空闲 1800 秒、最大生命周期 28800 秒。
- Agent Service 消费方定义 `RuntimeDiagnosticsReader`，只允许 owner-scoped 日志读取和实时健康探测；Infrastructure `Client` 实现该接口并由 bootstrap 注入。该边界不属于 `AgentRuntimeAdapter`，不得获得 Runtime 生命周期写权限或传播 Endpoint/Infra/Provider 数据。
- Hermes adapter 固定使用 `/api/ws` JSON-RPC/WebSocket；OpenCode adapter 固定使用 session REST、`/event` SSE 和 abort。两者 fixture 必须覆盖 session/message/event/cancel/idempotency。
- 固定镜像、manifest digest、headless command 和协议映射以 `runtime-protocol-fixtures.yaml` 为准；该文件验证失败时不得发布对应 Runtime Profile。

## 4. 跨域协作

| 目标 | 允许调用 | 禁止行为 |
| --- | --- | --- |
| task-center | 创建/查询/取消 Agent functionRef 任务，消费任务结果 | 写 Attempt、重试、取消终态或运行时队列 |
| infrastructure | 通过 Task Center 间接创建/操作受控 Runtime；提供受 AgentRuntimeGrant 约束的 MCP revision resolver；AgentRuntimeAdapter 直接调用只读 Endpoint resolve；RuntimeDiagnosticsReader 读取 owner-scoped 日志和实时健康 | 直接读取 Agent 私表、调用未授权 Infra API、Docker Socket 或 Provider API，持久化或传播解析地址/凭证，借诊断接口执行生命周期写操作 |
| appstudio | 调用内部 `CreateCodingAgentForStudio`、owner-scoped `ListMessages`/Invocation 事件重放、校验 Coding Agent 固定 Workspace；实现 `WorkspaceGateway` 并在 Worker 终态前幂等投影 Git commit | 允许前端调用内部创建语义、读取 Agent 私表、创建第二套 Session/Invocation/Message/Event、绕过 base Revision/CommitSHA 或 ChangeSet |
| user-model/modelgateway | 按 `agent.chat`/`agent.coding` 校验模型并签发 grant，解析为 ModelAccessSpec | 保存明文凭证、代理每次 LLM 请求 |
| notification-center/sse | 发布可靠 Agent 状态事件 | 写通知收件箱或把 SSE 当事实源 |

## 5. 一致性与安全

- Agent、Session、Memory 与 Runtime 生命周期分离；删除、挂起或重建 Agent 不改写 StudioWorkspace、Build、Release 或 StudioRuntimeInstance。
- Workspace 专属失败只允许出现在 Agent 与 AppStudio 的内部协作和诊断中；公共创建失败统一映射为 `ERR_AGENT_INITIALIZATION_FAILED`。
- Invocation 状态是 Agent 业务投影，不从 Infra 状态猜测完成；Task Center 结果通过稳定 ID 和资源版本投影。
- Session Close 只拒绝新消息，不取消已运行 Invocation；Disable 停止 Runtime 但保留数据，Enable 只回到 READY。
- Runtime 恢复必须使用已有 `infra_runtime_id`、Task 幂等键和受控运行引用，禁止重启窗口重复创建 Docker Service。
- Coding Runtime 成功必须在默认分支相对 Invocation base 产生恰好一个普通 fast-forward commit。Worker 在 Invocation 终态前读取 HEAD 并调用 AppStudio 幂等同步；无 commit、多 commit、分叉、force 语义、base 漂移或同步失败均不得把 Invocation 投影为成功，Worker 在 push 后崩溃时恢复同一同步。
- API 列表使用 `total/items` 和统一分页；关联摘要最多一跳，目标不可见时保留 ID、摘要为 null。
- 日志和事件只保留脱敏摘要，不记录 Token、Secret、Provider 原始响应、宿主路径、Host Port、`base_url`、私网地址或大型消息正文。
- 高频 Invocation 事件只属于对应 Invocation 的短期 SSE/重放事实，不进入通用 `/api/v1/events/stream` 或 Notification 收件箱；heartbeat 只使用 SSE comment，不持久化、不占用事件序号。
- 更新、删除或停用 MCP Binding 不中断当前容器，只影响下一次启动、恢复或显式重建；删除前 Grant 固定的历史 revision 在 Grant 有效期内继续可解析。
- OpenCode 以 Binding ID 为稳定 MCP server key，配置写入 tmpfs 的 `/root/.config/opencode/opencode.json` 且权限 `0600`；空 `allowed_tools` 拒绝全部。Hermes MCP 注入不在本 release 范围。

## 6. S1 追溯

主要规则：`R-AGENT-001..028`。主要来源章节：Provider/Adapter（7）、Agent/Session/Message/Invocation（8）、状态（9）、创建（10）、Runtime（11）、交互（12）、Memory（14）、MCP（16）、Workspace（18）、恢复（19-20）、Task Center（21）、权限（23）、Secret（24）、日志与可观测性（25）、事件（28）。
