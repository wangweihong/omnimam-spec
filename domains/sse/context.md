# SSE Context

## 1. 领域职责

`sse` 将 task-center、asset-library、workflow-canvas 和 notification-center 等领域已持久化的可靠事件投影为当前登录用户的短期可重放 `UserEvent`，通过统一 `text/event-stream` 连接提供变化提示、断线恢复和重同步信号。

## 2. 核心对象

- `UserEvent`：权限裁剪后的用户级业务变化投影。
- `event_id`：当前用户事件流中唯一、有序的恢复与去重游标。
- `aggregate_version`：源业务聚合的单调版本，用于阻止乱序覆盖。
- `SSEEventEnvelope`：统一事件信封和资源引用。
- `EventStreamConnection`：当前用户的连接、心跳和关闭语义。
- `ReplayBuffer`、`ResyncRequired`：短期恢复窗口与超窗重同步结果。

## 3. 核心规则

- SSE 只投影已持久业务事实，不拥有 AtomicTask、Artifact、CanvasRun 或 Notification。
- 所有 Web 业务事件复用 `/api/v1/events/stream`，不得为通知建立私有 SSE。
- 客户端以 `event_id` 去重和续传，以 `aggregate_version` 防止旧事件覆盖较新状态。
- 重放窗口失效、权限变化或无法保证连续性时发送重同步信号，客户端通过 REST 重查。
- SSE 提示可以丢失后恢复，但不能成为客户端唯一完整事实来源。
- 事件必须按当前主体权限裁剪，不得泄漏不可见资源存在性或敏感配置。
- AI Chat 单次生成的 token/delta 流属于 ai-chatting 请求协议，不进入通用 UserEvent 历史。
- Worker 通信、服务间 RPC、多人协同编辑和高频双向控制不使用本领域通道。

## 4. 领域边界

本领域拥有用户事件投影、游标、短期重放与连接控制。业务状态和 resource version 归源领域；Notification 收件箱归 notification-center；AI 对话生成流归 ai-chatting。SSE 不从数据库私表拼装新业务事实。

## 5. 上游与下游

上游是各源领域可靠 Outbox 事件，当前重点为任务、Artifact/AssetVersion、画布运行和通知变化。下游是当前登录 Web 用户；客户端接收变化后调用源领域 REST API 获取完整对象。identity 提供主体与权限边界。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/sse/product-spec.md` | S1 | 连接、事件、恢复和客户端语义 |
| `01_contracts/domains/sse/openapi.yaml` | S2 | 统一事件流 HTTP 合同 |
| `01_contracts/domains/sse/schema.sql` | S2 | 设计态事件与游标结构 |
| `01_contracts/domains/sse/events.yaml` | S2 | UserEvent 投影目录 |
| `01_contracts/domains/sse/module-contract.md` | S2 | Projector、Gateway 与源领域边界 |
| `02_architecture/domains/sse.md` | 参考 | 实时投影、重放和恢复架构 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改连接、心跳或恢复 | S1 product-spec | 涉及线协议时读 OpenAPI |
| 新增 UserEvent | 源领域 S1/events | 再读本域 S1、events 和 module-contract |
| 修改通知提示 | 当前 Context | 再读 notification-center Context |
| 修改业务状态 | 对应源领域 Context | 不在 SSE 中定义状态语义 |

## 8. 当前状态

任务、素材、画布和通知事件投影已有发布记录并正在实施。S1 文档头部仍可能显示 Draft；具体正式范围、事件集合和门禁以 `RELEASE.md` 的对应版本为准。

## 9. 不在本领域定义的内容

- AtomicTask、Artifact、AssetVersion、CanvasRun 和 Notification 状态不在本领域定义。
- AI Chat token/delta 生成协议不在本领域定义。
- Worker 调度、服务间消息传输和多人双向协作不在本领域定义。
- 客户端完整缓存模型和各业务 REST DTO 不在本领域定义。
