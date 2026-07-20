# SSE Domain Architecture

SSE 领域是用户级短期事件投影与 HTTP `text/event-stream` 网关，不是 AtomicTask、Artifact 或 UserAsset 的事实源。实现契约以 `01_contracts/domains/sse/` 为准。

## 1. 模块关系

```mermaid
flowchart LR
  Task["Task Center<br/>AtomicTask / Attempt / Group / DAG"]
  App["Application Platform<br/>Artifact processing"]
  Asset["Asset Library<br/>UserAsset registration"]
  Bus["Reliable domain events"]
  Projector["SSE Event Projector"]
  Store[("UserEvent store<br/>short retention")]
  Gateway["SSE Event Gateway"]
  Web["OmniMAM Web<br/>global SSE client"]
  Facts["Domain HTTP fact queries"]

  Task --> Bus
  App --> Bus
  Asset --> App
  Bus --> Projector
  Projector --> Store
  Store --> Gateway
  Gateway -->|"text/event-stream"| Web
  Web -->|"resync / fallback"| Facts
  Facts --> Task
  Facts --> App
  Facts --> Asset
```

Task Center 发布 AtomicTask、TaskAttempt 和 Group/DAG 变化。Application Platform 发布 Artifact 处理与登记投影变化；Asset Library 仍是 UserAsset 及登记成功的事实源。

## 2. 实时与重放时序

```mermaid
sequenceDiagram
  participant Domain as "Owning domain"
  participant Outbox as "Reliable event/outbox"
  participant Projector as "SSE projector"
  participant Store as "UserEvent store"
  participant Gateway as "SSE gateway"
  participant Web as "Web SSE client"
  Domain->>Outbox: 事实与事件同事务提交
  Outbox->>Projector: 至少一次投递
  Projector->>Projector: 校验 owner / resource_version
  Projector->>Store: 幂等写入 UserEvent
  Store-->>Projector: event_id
  Projector->>Gateway: 通知新事件
  Gateway->>Web: id + event + data
  Note over Web: 按 event_id 去重<br/>按 aggregate_version 防回退
```

UserEvent 必须先持久再广播。广播失败不会丢失恢复能力；上游重复投递由 source event 幂等键去重。

## 3. 断线恢复

```mermaid
sequenceDiagram
  participant Web as "Web SSE client"
  participant Gateway as "SSE gateway"
  participant Store as "UserEvent store"
  participant Facts as "Owning domain APIs"
  Web->>Gateway: GET /api/v1/events/stream + Last-Event-ID
  Gateway->>Store: 按当前用户校验游标
  alt 保留范围内
    Store-->>Gateway: 返回游标后事件
    Gateway-->>Web: connection.ready + replay
  else 无效、跨用户或已过期
    Gateway-->>Web: connection.resync_required
    Web->>Facts: 重查任务、ApplicationRun/Artifact 与 UserAsset
    Facts-->>Web: 当前事实
    Web->>Gateway: 使用新边界重连
  end
```

游标校验始终包含当前 `recipient_user_id`。无法恢复时必须回到业务 API 重同步，不允许从事件推测完整事实。

## 4. Artifact 事件边界

Artifact 有两个独立维度：

```text
processing_status: created -> transferring -> processing -> ready | failed -> deleted
registration_status: pending -> registered | failed
```

`artifact.preview_ready` 是 processing 期间的独立事实，不跳过处理状态。`artifact.registration_succeeded` 关联 UserAsset，但 Artifact 删除不级联删除 UserAsset。已终态 AtomicTask 不被后续 Artifact 处理或登记失败反向改写。

## 5. 运行时要求

- 网关关闭代理缓冲，支持长连接、心跳和优雅排空。
- API 实例无需粘性会话；新实例通过共享 UserEvent 存储和 Last-Event-ID 恢复。
- 单连接发送缓冲有上限；慢客户端关闭后由重连恢复，不无限缓存。
- 事件默认保留 24 小时；清理只影响 UserEvent，不影响业务资源。
- 可观测指标至少包含当前连接数、投影延迟、发送延迟、重连率、重放量、resync 量、慢客户端关闭和清理失败。指标 label 不包含 user_id 或 aggregate_id 等无界值。
