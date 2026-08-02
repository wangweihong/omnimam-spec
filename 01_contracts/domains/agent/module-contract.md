# Agent Module Contract

产品语义以 `00_product/domains/agent/product-spec.md` 为准。本合同只覆盖当前 S1 草稿；旧版 S2 不属于输入。

## 1. 追溯状态

当前 Agent S1 使用 `US-AGENT-001`、`BR-AGENT-001`、`AC-AGENT-001-01..08` 及 `R-AGENT-*` 规则。OpenAPI、Schema、错误、权限和事件必须同时遵守固定 Workspace、分类后的 Invocation/AtomicTask 和 Workspace Tool 授权语义。

## 2. 模块边界

| 模块 | 拥有 | 不拥有 |
| --- | --- | --- |
| agent-core | Agent、AgentProfile 可用性投影、类型、状态和固定 Workspace 引用 | Docker、StudioWorkspace 内容、Session 事实 |
| interaction | AgentSession、AgentMessage、AgentInvocation、Runtime Adapter 调用编排 | AtomicTask 状态、InfraRuntime、LLM Provider 协议 |
| memory | AgentMemory 的 scope、类型、正文和生命周期 | 向量数据库、跨用户共享记忆、Runtime 文件中的长期记忆 |
| workspace | AgentWorkspace Binding、授权摘要和挂载意图 | StudioWorkspace 私表、宿主路径、物理存储 |
| runtime | AgentRuntimeBinding、AgentRuntimeProvider 状态投影和恢复 | InfraRuntime 运行状态、Docker Provider、业务 Task 状态 |
| access | Agent 所有权、主体范围和权限组合 | Identity 用户/角色生命周期 |
| event-outbox | Agent 可靠事件、重试和重放 | Notification 收件箱、SSE 历史事实 |

## 3. 输入与输出

- 外部输入必须带可信 Principal；请求中的 `user_id` 不参与授权决策。
- Coding Agent 创建时固定 `workspace_type=studio` 和 `workspace_id`；Session/Invocation 不得切换。
- Platform Agent 只允许 `workspace_type=agent`。多个 Coding Agent 可引用同一 StudioWorkspace，但写入由 AppStudio ChangeSet 和 `base_revision` 校验。
- Agent 创建事务必须同时写入 `agents.workspace_type/workspace_id` 和唯一 `agent_workspace_bindings`，两处类型与 ID 必须一致；既有 Agent 不提供修改或重建 Binding 的写接口。
- Runtime 创建、启动、挂起、恢复、停止和删除只能通过 Task Center 的已注册 `functionRef`；Task Worker 再调用唯一 Infra Adapter。
- Agent Runtime 创建/启动/恢复只使用 `agent.runtime.ensure`，挂起/停止/删除只使用 `agent.runtime.stop`；arguments、结果、能力和策略必须符合 Task Center `function-registry.yaml` 固定版本，Agent 不提交 Infra DTO。
- Agent 只保存 `infra_runtime_id`、`endpoint_ref`、状态和脱敏错误。Infra Provider、容器、宿主机路径和明文 Secret 不得进入 Agent API、事件或业务表。
- 纯 CHAT 且不启动 Runtime、工具或后台工作的 Invocation 可以不带 `atomic_task_id`；CODING、TOOL_OPERATION、BACKGROUND_OPERATION 和 Runtime 生命周期 Invocation 必须带一跳稳定 AtomicTask 引用，重试、取消、超时和 Attempt 状态归 Task Center。

## 4. 跨域协作

| 目标 | 允许调用 | 禁止行为 |
| --- | --- | --- |
| task-center | 创建/查询/取消 Agent functionRef 任务，消费任务结果 | 写 Attempt、重试、取消终态或运行时队列 |
| infrastructure | 通过 Task Center 间接创建/操作受控 Runtime | 直接调用 Infra Service、Docker Socket 或 Provider API |
| appstudio | 校验 Coding Agent 固定 Workspace、使用 AppStudio Workspace Tool | 读取 AppStudio 私表、创建第二套 Session/Invocation、绕过 ChangeSet |
| model-management/modelgateway | 校验模型引用并生成 ModelAccessSpec | 保存明文凭证、代理每次 LLM 请求 |
| notification-center/sse | 发布可靠 Agent 状态事件 | 写通知收件箱或把 SSE 当事实源 |

## 5. 一致性与安全

- Agent、Session、Memory 与 Runtime 生命周期分离；删除、挂起或重建 Agent 不改写 StudioWorkspace、Build、Release 或 StudioRuntimeInstance。
- Invocation 状态是 Agent 业务投影，不从 Infra 状态猜测完成；Task Center 结果通过稳定 ID 和资源版本投影。
- Runtime 恢复必须使用已有 `infra_runtime_id`、Task 幂等键和受控运行引用，禁止重启窗口重复创建 Docker Service。
- API 列表使用 `total/items` 和统一分页；关联摘要最多一跳，目标不可见时保留 ID、摘要为 null。
- 日志和事件只保留脱敏摘要，不记录 Token、Secret、Provider 原始响应、宿主路径、私网地址或大型消息正文。

## 6. S1 追溯

主要规则：`R-AGENT-001..020`。主要来源章节：Agent/Session/Message/Invocation（8）、状态（9）、创建（10）、Runtime（11）、交互（12）、Memory（14）、Workspace（18）、恢复（19-20）、Task Center（21）、权限（23）、Secret（24）、事件（28）。
