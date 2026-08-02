# Agent Context

## 1. 领域职责

`agent` 管理持久化 Agent、交互 Session、Invocation、消息、记忆、Platform Agent 使用的 AgentWorkspace，以及运行 Hermes/OpenCode 的 AgentRuntime。Coding Agent 可以固定引用 AppStudio 的 StudioWorkspace，但不拥有生成应用的源码、构建、发布或运行事实。

## 2. 核心对象

- `Agent`：持久化智能代理，类型为 platform 或 coding，并固定引用一个 Workspace。
- `AgentSession`、`AgentInvocation`、`AgentMessage`、`AgentMemory`：持续交互、单轮执行、原始消息和可恢复记忆事实。
- `AgentWorkspace`：Platform Agent 的独立持久化工作区。
- `AgentRuntime`：按需运行 Hermes/OpenCode 的 Agent 执行实例。
- `AgentRuntimeProvider`：创建、恢复和检查 AgentRuntime 的系统注册组件。

## 3. 核心规则

- `workspace_type=agent` 只用于 Platform Agent；`workspace_type=studio` 只用于 Coding Agent。
- Coding Agent 创建时必须固定绑定一个已存在且受权的 StudioWorkspace，Session 和 Invocation 不得切换。
- 多个 Coding Agent 可以引用同一 StudioWorkspace，但写入必须经过 AppStudio ChangeSet 和 `base_revision` 校验。
- Coding Agent 不直接挂载 AppStudio 存储，只使用当前 AgentInvocation 的受控 Workspace Tool 授权；Runtime 挂载请求必须经 Task Center、Task Worker 和 Infra Adapter。
- Agent 删除、挂起或 Runtime 重建不得改写 StudioWorkspace、StudioBuild、StudioRelease 或 StudioRuntimeInstance。
- AgentInvocation 关联 AtomicTask；任务尝试、重试、取消和调度并发均以 task-center 当前事实源为准。

## 4. 领域边界

本领域拥有 Agent、Session、Invocation、Message、Memory、AgentWorkspace、AgentRuntime 和 AgentRuntimeProvider 状态。StudioWorkspace、ChangeSet、Source Snapshot、Build、Release 和生成应用 Runtime 归 appstudio；AtomicTask 和调度归 task-center；通知收件箱归 notification-center。

## 5. 上游与下游

上游是用户、AppStudio 和受权平台入口创建 Agent 或发起 Invocation。下游包括 AgentRuntimeProvider、Task Center/Task Worker、AppStudio Workspace Tool、infrastructure，以及消费可靠 Agent 事件的 notification-center 和 sse。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/agent/product-spec.md` | S1 | Agent、Session、Memory、Workspace 引用和 AgentRuntime 产品语义 |
| `01_contracts/domains/agent/openapi.yaml` | S2 Draft | Agent、Session、Invocation、Memory 和 Runtime API |
| `01_contracts/domains/agent/schema.sql` | S2 Draft | Agent 领域设计态 Schema |
| `01_contracts/domains/agent/errors.yaml`、`permissions.yaml`、`events.yaml`、`module-contract.md` | S2 Draft | 错误、权限、事件和模块边界 |
Context 只负责导航，Task Center 的任务执行契约和 infrastructure 的运行层合同必须按跨域任务继续读取。

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| Agent/Session/Invocation/Memory | Agent S1 | 涉及任务执行再读 task-center Context |
| Platform Agent Workspace | Agent S1 | 涉及 Artifact 再读 asset-library Context |
| Coding Agent 修改源码 | Agent S1 | 必须继续读 appstudio Context |
| AgentRuntime/Provider | Agent S1 | 涉及周期调度再读 task-center Context |

## 8. 当前状态

Agent S1/S2 均为未 Release 草稿，不能作为正式实现、合并或验收依据。当前 S2 使用 `R-AGENT-*` 和源章节追溯；标准 `US/BR` 编号仍是 Release 前置任务。

## 9. 不在本领域定义的内容

- StudioApplication 的源码、版本、Build、Artifact、Release 和运行实例。
- AtomicTask、TaskAttempt、TaskGroup 和 TaskSchedule 状态机。
- Notification、UserEvent 和 Asset 生命周期。
