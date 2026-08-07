# Agent Context

## 1. 领域职责

`agent` 管理持久化 Agent、交互 Session、Invocation、消息、记忆、Platform Agent 使用的内部 AgentWorkspace，以及运行 Hermes/OpenCode 的 AgentRuntime。用户侧只创建和管理 Platform Agent；Coding Agent 由 AppStudio 通过内部模块语义创建，可以固定引用 StudioWorkspace，但不拥有生成应用的源码、构建、发布或运行事实。

## 2. 核心对象

- `Agent`：持久化智能代理；公共 Agent 管理只投影 platform，内部还支持 AppStudio 创建的 coding，并固定引用一个后端 Workspace。
- `AgentSession`、`AgentInvocation`、`AgentMessage`、`AgentMemory`：持续交互、Task-backed 单轮执行、原始消息和可恢复记忆事实；Invocation 保存当前 Task、Runtime 恢复引用与单调事件游标。
- `AgentWorkspace`：Platform Agent 的独立持久化工作区，由后端自动创建和绑定，不是用户侧资源。
- `AgentRuntime`：按需运行 Hermes/OpenCode 的 Agent 执行实例。
- `AgentRuntimeProvider`：创建、恢复和检查 AgentRuntime 的系统注册组件。
- `AgentRuntimeAdapter`：校验 Agent、Session、Invocation、Runtime Binding 和短期授权后，短时解析 READY Endpoint并按固定 Hermes/OpenCode 协议执行的内部适配边界。

## 3. 核心规则

- `workspace_type=agent` 只用于 Platform Agent；`workspace_type=studio` 只用于 Coding Agent；两者均是后端内部事实。
- 用户创建请求固定产生 Platform Agent，不接收 `kind/workspace_type/workspace_id`；后端原子创建 AgentWorkspace、Agent、默认 Session 和固定 Binding。
- Coding Agent 只能由 AppStudio 通过内部 `CreateCodingAgentForStudio` 创建；用户侧 Agent 页面、公共 API、通知和 SSE 不展示 Coding Agent 的 Workspace 或 Binding。
- Agent 创建后内部 Workspace 固定；Session 和 Invocation 不得切换。
- 多个 Coding Agent 可以引用同一 StudioWorkspace，但写入必须经过 AppStudio ChangeSet 和 `base_revision` 校验。
- Coding Agent 不直接挂载 AppStudio 存储，只使用当前 AgentInvocation 的受控 Workspace Tool 授权；Runtime 挂载请求必须经 Task Center、Task Worker 和 Infra Adapter。
- Agent 删除、挂起或 Runtime 重建不得改写 StudioWorkspace、StudioBuild、StudioRelease 或 StudioRuntimeInstance。
- 所有 `CHAT` 和 `CODING` AgentInvocation 统一使用 `agent.invocation.execute@1.0` AtomicTask；任务尝试、重试、取消、超时和调度并发均以 task-center 当前事实源为准，API Server 不得进程内执行或降级绕过 Task。
- Invocation 执行前必须存在 ACTIVE primary ModelBinding，并通过 Attempt-scoped Model Access Grant 解析模型访问；Coding 还必须使用短期 AppStudio Workspace Tool Grant，Worker 不得代表 Coding Agent 直接调用 `ApplyChangeSet`。
- AgentRuntime 的创建、停止、删除和恢复写操作仍经 Task Center；AgentRuntimeAdapter 仅可用 Agent 工作负载身份调用 Infrastructure 的只读 Endpoint resolve，解析地址只用于当次 Hermes/OpenCode 调用且不得持久化或传播。
- AgentRuntimeProvider 当前只承载 Hermes/OpenCode 的业务生命周期和 Task 编排；Infrastructure RuntimeProvider 第一阶段只承载 Docker，两者不得混用。

## 4. 领域边界

本领域拥有 Agent、Session、Invocation、Message、Memory、AgentWorkspace、AgentRuntime 和 AgentRuntimeProvider 状态。StudioWorkspace、ChangeSet、Source Snapshot、Build、Release 和生成应用 Runtime 归 appstudio；AtomicTask 和调度归 task-center；通知收件箱归 notification-center。

## 5. 上游与下游

上游是用户创建 Platform Agent、AppStudio 内部创建 Coding Agent，以及受权平台入口发起 Invocation。下游包括 AgentRuntimeProvider、Task Center/Task Worker、AppStudio Workspace Tool、infrastructure，以及消费不含 Workspace 字段的可靠 Agent 事件的 notification-center 和 sse。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/agent/product-spec.md` | S1 | Agent、Session、Memory、内部 Workspace 绑定和 AgentRuntime 产品语义 |
| `01_contracts/domains/agent/openapi.yaml` | S2 | Agent、Session、Invocation、Memory 和 Runtime API |
| `01_contracts/domains/agent/schema.sql` | S2 | Agent 领域设计态 Schema |
| `01_contracts/domains/agent/runtime-protocol-fixtures.yaml` | S2 | Hermes/OpenCode 固定镜像的会话、消息、事件、取消与幂等发布门禁 |
| `01_contracts/domains/agent/errors.yaml`、`permissions.yaml`、`events.yaml`、`module-contract.md` | S2 | 错误、权限、事件和模块边界 |
Context 只负责导航，Task Center 的任务执行契约和 infrastructure 的运行层合同必须按跨域任务继续读取。

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| Agent/Session/Invocation/Memory | Agent S1 | 涉及任务执行再读 task-center Context |
| Platform Agent 初始化 | Agent S1 | 涉及内部 Workspace 持久化再读 Agent S2 |
| Coding Agent 修改源码 | Agent S1 | 必须继续读 appstudio Context |
| AgentRuntime/Provider | Agent S1 | 涉及周期调度再读 task-center Context |

## 8. 当前状态

Agent 截至 Endpoint resolve 的基线已由 `spec-v1.17.2` 发布；统一 CHAT/CODING Task、短期授权、当前 Task 单调投影和固定 Runtime 协议契约待 `spec-v1.18.0` 发布后才可作为正式实现依据。当前 S2 使用 `US-AGENT-001`、`BR-AGENT-001`、`R-AGENT-*` 和源章节追溯。

## 9. 不在本领域定义的内容

- StudioApplication 的源码、版本、Build、Artifact、Release 和运行实例。
- AtomicTask、TaskAttempt、TaskGroup 和 TaskSchedule 状态机。
- Notification、UserEvent 和 Asset 生命周期。
