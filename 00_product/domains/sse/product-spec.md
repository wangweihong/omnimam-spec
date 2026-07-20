# OmniMAM SSE 实时事件推送产品功能设计

## 1. 文档信息

| 项目     | 内容                              |
| ------ | ------------------------------- |
| 文档名称   | OmniMAM SSE 实时事件推送产品功能设计        |
| 功能域    | 实时事件推送                         |
| 文档状态   | Draft                           |
| 目标版本   | V1                              |
| 通信方案   | HTTP REST + Server-Sent Events  |
| 事件订阅范围 | 当前登录用户                          |
| 第一阶段范围 | AtomicTask、TaskAttempt、TaskGroup、DAGTaskGroup、Artifact 处理/登记与连接状态 |
| 后续阶段范围 | Canvas 实时事件、Agent 实时事件、通知中心     |
| 适用客户端  | OmniMAM Web 应用                  |
| 不适用范围  | Worker 通信、服务间 RPC、多人协同编辑、高频双向控制 |

本文档必须与已 release 的 task-center、application-platform 和 asset-library S1/S2 保持一致。SSE 仅投影业务事实，不得恢复已废弃的 TaskRun 执行路径。Artifact 处理事实归 application-platform，UserAsset 登记事实归 asset-library，SSE 只统一对客户端的事件投影。

---

## 2. 功能背景

OmniMAM 中存在大量长时间运行的异步任务，例如：

* 图像生成。
* 视频生成。
* 音频生成。
* ComfyUI 工作流运行。
* SaaS 平台异步任务。
* 文件下载。
* 制品转码。
* 缩略图和预览图生成。
* 制品登记为资产。
* 多任务并行执行。
* 任务失败重试。

用户提交任务后，服务端需要持续向前端通知：

* 任务是否已经创建。
* 任务是否进入队列。
* 任务是否开始运行。
* 当前任务运行到哪个阶段。
* 当前任务是否有可计算的进度。
* 是否生成了新的制品。
* 制品是否已经完成下载和处理。
* 制品是否已经登记为资产。
* 任务是否成功、失败、取消或重试。

如果前端完全依赖轮询获取任务状态，会产生以下问题：

1. 任务数量增加后，请求数量快速增长。
2. 状态展示存在明显延迟。
3. 制品已经生成，但前端不能及时展示。
4. 多任务同时执行时，轮询逻辑复杂。
5. 任务列表和任务详情容易出现状态不一致。
6. 页面切换后需要重复创建轮询。
7. 服务端需要处理大量没有状态变化的查询。
8. 长时间任务会造成大量无效 HTTP 请求。

因此，OmniMAM 需要提供统一的实时事件推送机制。

---

## 3. 产品目标

SSE 功能用于建立从 OmniMAM 服务端到 Web 应用端的单向实时事件通道。

第一阶段目标包括：

1. 实时通知任务状态变化。
2. 实时通知任务进度变化。
3. 实时通知制品创建和处理状态。
4. 使用一条用户级事件流承载当前用户的实时事件。
5. 支持页面刷新、断线和网络切换后的事件恢复。
6. 保证任务列表、任务详情和制品列表使用一致的事件来源。
7. 允许前端根据事件增量更新页面。
8. 保持 HTTP API 为命令提交和业务状态查询的主要方式。
9. 不将 SSE 作为业务状态事实源。
10. 支持一个用户同时运行多个异步任务。
11. 支持事件去重、重放和重新同步。
12. 为后续 Canvas、Agent 和通知中心事件提供扩展基础。

---

## 4. 非目标

SSE 第一阶段不负责解决以下问题：

* 画布节点实时运行状态。
* 画布流程运行状态。
* Agent 执行步骤。
* Agent 对话消息。
* Agent 工具调用。
* Agent 审批请求。
* 多人协同画布。
* 其他用户鼠标位置。
* 高频节点拖动同步。
* 3D 控制台实时操作。
* 视频逐帧传输。
* 音频实时流传输。
* 二进制文件传输。
* 服务端与 Worker 之间的通信。
* 服务端内部消息队列协议。
* WebSocket RPC。
* 通过 SSE 向服务端发送命令。

其中：

* Canvas 实时事件在第二阶段实现。
* Agent 实时事件在第三阶段实现。
* 多人协同和高频双向控制不使用 SSE，后续根据实际需求采用 WebSocket 或专用协同协议。

---

## 5. 核心设计结论

OmniMAM Web 应用采用以下通信组合：

```text
HTTP REST
├── 创建任务
├── 取消任务
├── 重试任务
├── 查询任务
├── 查询制品
├── 下载制品
└── 将制品登记为资产

SSE
├── 连接状态
├── 任务创建通知
├── 任务依赖阻塞或就绪通知
├── 任务开始通知
├── 任务进度通知
├── 任务重试通知
├── 任务终态通知
├── 制品创建通知
├── 制品登记成功通知
└── 制品登记失败通知
```

SSE 只负责：

> 告诉前端某个业务状态已经发生变化。

SSE 不负责：

* 创建业务对象。
* 修改业务对象。
* 取消任务。
* 重试任务。
* 提交运行参数。
* 上传文件。
* 下载文件。
* 保存最终业务状态。

---

## 6. 设计原则

### 6.1 单向事件原则

SSE 用于服务端向前端推送事件：

```text
OmniMAM Server ──────────────> OmniMAM Web
```

前端向服务端发送命令时，仍然使用 HTTP API：

```text
OmniMAM Web ───── HTTP ─────> OmniMAM Server
```

例如：

```http
POST /api/v1/atomic-tasks/{atomic_task_id}/cancel
POST /api/v1/atomic-tasks/{atomic_task_id}/retry
```

---

### 6.2 用户级单连接原则

前端不应为每一个任务建立独立 SSE 连接。

错误设计：

```text
GET /api/v1/atomic-tasks/task_001/events
GET /api/v1/atomic-tasks/task_002/events
GET /api/v1/atomic-tasks/task_003/events
```

推荐设计：

```http
GET /api/v1/events/stream
```

一条用户级事件流同时承载当前用户的：

* 任务状态事件。
* 任务进度事件。
* 制品状态事件。
* 连接控制事件。

即使用户同时运行五个、十个或更多任务，前端仍然只需要维护一条 SSE 连接。

---

### 6.3 当前登录用户决定事件范围

SSE 事件流以当前登录用户为订阅主体。

服务端根据当前登录身份确定用户能够收到哪些事件。

客户端不能通过请求参数传入其他用户 ID 来扩大订阅范围。

禁止设计：

```http
GET /api/v1/events/stream?user_id=user_002
```

推荐设计：

```http
GET /api/v1/events/stream
```

服务端从登录会话或访问令牌中解析当前用户。

---

### 6.4 事件不是事实源

SSE 事件用于通知状态变化，但不能代替业务数据查询。

业务状态事实源包括：

* `AtomicTask`
* `TaskAttempt`
* `TaskGroup`
* `DAGTaskGroup`
* `Artifact`
* `Asset`

前端在以下场景必须重新查询业务事实状态：

* 首次进入任务中心。
* 首次进入任务详情。
* 页面刷新。
* SSE 重连后无法完整恢复事件。
* 客户端发现事件版本不连续。
* 服务端要求重新同步。
* 用户重新登录。
* SSE 长时间断开后重新连接。

---

### 6.5 至少一次投递原则

SSE 不承诺每个事件只到达一次。

在以下情况下，同一个事件可能被重复发送：

* 客户端断线重连。
* 服务端重新投递。
* 消息队列重复消费。
* 服务实例切换。
* 网络代理重试。

事件消费语义为：

```text
at-least-once
```

前端必须根据 `event_id` 去重。

---

### 6.6 结构化事件原则

事件应传递结构化业务信息，而不是只传递展示文案。

错误示例：

```json
{
  "message": "任务已经完成"
}
```

推荐示例：

```json
{
  "event_type": "atomic_task.status_changed",
  "atomic_task_id": "task_001",
  "payload": {
    "previous_status": "RUNNING",
    "status": "SUCCESS"
  }
}
```

前端根据：

* `event_type`
* 状态值
* 错误码
* 消息码

生成具体界面文案。

---

### 6.7 事件最小化原则

事件不要求携带完整业务对象。

事件只需要包含：

* 用于定位对象的标识。
* 用于增量更新的必要字段。
* 用于判断顺序和版本的字段。

前端缺少完整对象时，应通过 HTTP API 查询详情。

---

## 7. 用户场景

### 7.1 单个应用任务运行

用户在应用页面提交图像生成任务。

产品流程：

1. 前端调用 HTTP API 创建应用运行。
2. 服务端创建 `AtomicTask`。
3. HTTP API 返回任务标识和初始状态。
4. SSE 推送任务创建事件。
5. 运行时将任务投影为 `READY`，如依赖未满足则为 `BLOCKED`。
6. SSE 推送任务就绪或阻塞事件。
7. Worker 获取任务并开始运行。
8. SSE 推送任务开始事件。
9. Worker 上报任务进度。
10. SSE 推送任务进度事件。
11. Worker 或制品处理服务发现生成结果。
12. SSE 推送制品创建事件。
13. application-platform 请求 asset-library 幂等登记 UserAsset。
14. SSE 推送制品登记成功或失败事件。
15. 任务进入成功终态。
16. SSE 推送任务成功事件。

---

### 7.2 多个任务同时运行

用户同时提交五个生成任务。

系统创建：

```text
AtomicTask task_001
AtomicTask task_002
AtomicTask task_003
AtomicTask task_004
AtomicTask task_005
```

所有事件通过同一条 SSE 连接推送。

每条任务事件携带对应的：

```text
atomic_task_id
task_attempt_id
```

前端根据 `atomic_task_id` 将事件更新到正确的任务卡片。

---

### 7.3 一个任务产生多个制品

一个 ComfyUI 工作流可能同时输出：

* 主图。
* 遮罩图。
* 深度图。
* 预览图。
* 中间视频。
* 最终视频。

每个制品分别创建 `Artifact`，并分别发送事件。

前端不需要等待整个任务完成，可以在制品生成后立即展示。

---

### 7.4 任务失败并重试

任务第一次调用外部平台失败，但错误允许重试。

事件流程：

```text
atomic_task.started
atomic_task.progressed
task_attempt.failed
atomic_task.retrying
task_attempt.started
atomic_task.progressed
artifact.created
atomic_task.succeeded
```

新的重试产生新的 `TaskAttempt`。

`AtomicTask` 保持同一个业务任务标识。

---

### 7.5 用户取消任务

用户点击取消任务。

流程：

1. 前端调用取消 HTTP API。
2. 服务端接受取消请求。
3. HTTP API 返回取消请求已接受。
4. SSE 推送 `atomic_task.cancel_requested`。
5. Worker 或执行器停止任务。
6. 服务端将任务更新为 `CANCELED`。
7. SSE 推送 `atomic_task.canceled`。

前端不能在 HTTP 请求成功后立即认为任务已经完全取消。

---

## 8. 第一阶段功能范围

### 8.1 Connection 事件

用于表示 SSE 连接状态和恢复要求。

包括：

* `connection.ready`
* `connection.resync_required`
* `connection.server_draining`

---

### 8.2 AtomicTask 事件

用于表示任务生命周期。

包括：

* `atomic_task.created`
* `atomic_task.blocked`
* `atomic_task.ready`
* `atomic_task.started`
* `atomic_task.progressed`
* `atomic_task.retrying`
* `atomic_task.cancel_requested`
* `atomic_task.succeeded`
* `atomic_task.failed`
* `atomic_task.canceled`
* `atomic_task.timed_out`
* `atomic_task.skipped`

---

### 8.3 TaskAttempt 事件

用于表示具体执行尝试。

包括：

* `task_attempt.created`
* `task_attempt.started`
* `task_attempt.succeeded`
* `task_attempt.failed`
* `task_attempt.canceled`
* `task_attempt.timed_out`

第一阶段前端可以主要展示 AtomicTask 状态，但任务详情和诊断页面可以展示 TaskAttempt。

---

### 8.4 TaskGroup 事件

用于表示基础串行或并行任务组。

包括：

* `task_group.created`
* `task_group.started`
* `task_group.progressed`
* `task_group.succeeded`
* `task_group.failed`
* `task_group.canceled`

`DAGTaskGroup` 包括：

* `dag_task_group.created`
* `dag_task_group.started`
* `dag_task_group.progressed`
* `dag_task_group.succeeded`
* `dag_task_group.failed`
* `dag_task_group.canceled`

复杂 DAG 流程可以复用任务事件机制，但画布侧的节点映射和展示放到后续 Canvas 阶段实现。

---

### 8.5 Artifact 事件

用于表示制品生命周期。

包括：

* `artifact.created`
* `artifact.transferring`
* `artifact.processing`
* `artifact.preview_ready`
* `artifact.ready`
* `artifact.processing_failed`
* `artifact.registration_succeeded`
* `artifact.registration_failed`
* `artifact.deleted`

---

## 9. SSE 连接设计

### 9.1 连接接口

```http
GET /api/v1/events/stream
Accept: text/event-stream
```

推荐响应头：

```http
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
X-Accel-Buffering: no
```

---

### 9.2 连接鉴权

连接必须使用当前登录会话完成身份认证。

如果 Web 应用和 API 同域，并使用安全 Cookie 会话，可以直接使用浏览器原生 `EventSource`。

如果系统使用 Bearer Token，可以选择：

1. 使用支持自定义 Header 的 Fetch SSE 客户端。
2. 使用短期有效的一次性 SSE 连接令牌。
3. 调整为同域安全 Cookie 会话。

禁止将长期有效的访问令牌放入 URL：

```http
GET /api/v1/events/stream?access_token=长期访问令牌
```

URL 可能被写入：

* 浏览器历史。
* 代理日志。
* 网关日志。
* 监控日志。
* 服务访问日志。

---

### 9.3 连接建立事件

连接建立后，服务端发送：

```text
event: connection.ready
id: 100001
data: {
  "connection_id": "conn_001",
  "server_time": "2026-07-20T12:00:00Z",
  "resume_from_event_id": 99998
}
```

前端收到后将实时连接状态更新为：

```text
connected
```

---

### 9.4 心跳

当没有业务事件时，服务端应定期发送心跳。

推荐使用 SSE 注释：

```text
: heartbeat
```

心跳不进入业务事件分发器。

心跳用于：

* 防止代理关闭空闲连接。
* 检测连接是否仍然有效。
* 保持网关和负载均衡连接。
* 帮助客户端识别假连接。

建议心跳间隔可配置，例如：

```text
15 秒至 30 秒
```

---

### 9.5 主题过滤

第一阶段默认不要求支持主题过滤。

推荐接口保持简单：

```http
GET /api/v1/events/stream
```

所有第一阶段事件都通过同一条连接发送。

后续当事件数量明显增加时，可以增加可选参数：

```http
GET /api/v1/events/stream?topics=task,artifact
```

主题过滤只用于减少无关事件，不作为权限机制。

---

## 10. 统一事件结构

### 10.1 事件信封

所有业务事件采用统一结构：

```json
{
  "event_id": 928383,
  "event_type": "artifact.created",
  "event_version": 1,
  "occurred_at": "2026-07-20T12:32:11.123Z",

  "aggregate_type": "artifact",
  "aggregate_id": "art_001",
  "aggregate_version": 1,

  "correlation_id": "corr_001",
  "causation_id": "evt_928382",

  "application_run_id": "ar_001",
  "task_group_id": "group_001",
  "dag_task_group_id": "dag_group_001",
  "atomic_task_id": "task_001",
  "task_attempt_id": "attempt_001",
  "artifact_id": "art_001",

  "payload": {}
}
```

与当前事件无关的字段可以省略。

---

### 10.2 字段说明

| 字段                 | 必填 | 说明              |
| ------------------ | -: | --------------- |
| event_id           |  是 | 当前用户事件流中的唯一事件标识 |
| event_type         |  是 | 事件类型            |
| event_version      |  是 | 事件结构版本          |
| occurred_at        |  是 | 业务事件发生时间        |
| aggregate_type     |  是 | 业务聚合类型          |
| aggregate_id       |  是 | 业务聚合标识          |
| aggregate_version  |  是 | 聚合对象状态版本        |
| correlation_id     |  否 | 同一业务执行链路标识      |
| causation_id       |  否 | 引发当前事件的前序事件     |
| application_run_id |  否 | 关联的应用运行         |
| task_group_id      |  否 | 关联的任务组          |
| dag_task_group_id  |  否 | 关联的 DAG 任务组      |
| atomic_task_id     |  否 | 关联的原子任务         |
| task_attempt_id    |  否 | 关联的执行尝试         |
| artifact_id        |  否 | 关联的制品           |
| payload            |  是 | 当前事件业务数据        |

---

### 10.3 目标用户字段

事件在服务端存储和分发时，需要记录目标用户：

```text
recipient_user_id
```

该字段用于：

* 用户事件路由。
* 权限隔离。
* 事件查询。
* 断线恢复。
* 审计和问题诊断。

发送到浏览器的事件 Payload 中可以省略该字段，因为浏览器已经通过登录身份确定当前用户。

服务端用户事件记录可以采用：

```text
UserEvent
├── id
├── recipient_user_id
├── event_type
├── event_version
├── aggregate_type
├── aggregate_id
├── aggregate_version
├── correlation_id
├── payload
├── occurred_at
└── expires_at
```

---

### 10.4 事件标识

`event_id` 必须满足：

1. 在当前用户事件流中唯一。
2. 可以用于事件去重。
3. 可以用于断线恢复。
4. 可以判断事件先后。
5. 不应使用无序随机 UUID 作为恢复游标。

可以采用：

* 数据库递增序列。
* 有序分布式 ID。
* 消息流序列号。

前端不能只依赖 `occurred_at` 判断重复事件。

---

### 10.5 聚合版本

`aggregate_version` 表示同一个业务对象的状态版本。

例如：

```text
AtomicTask task_001 version 3
AtomicTask task_001 version 4
AtomicTask task_001 version 5
```

如果前端已经处理版本 5，随后收到版本 4，应忽略版本 4。

聚合版本用于处理：

* 网络延迟。
* 事件乱序。
* 重复投递。
* 事件重放。
* 多实例事件转发差异。

---

## 11. Connection 事件

### 11.1 `connection.ready`

表示 SSE 连接已经成功建立。

```json
{
  "event_type": "connection.ready",
  "payload": {
    "connection_id": "conn_001",
    "server_time": "2026-07-20T12:00:00Z",
    "resume_from_event_id": 928000
  }
}
```

---

### 11.2 `connection.resync_required`

表示服务端无法从客户端指定的游标完整恢复事件。

```json
{
  "event_type": "connection.resync_required",
  "payload": {
    "reason": "event_retention_expired",
    "requested_after_event_id": 820001,
    "earliest_available_event_id": 900001
  }
}
```

可能原因包括：

* 事件已经超过保留时间。
* 游标不存在。
* 游标不属于当前用户。
* 服务端事件存储发生迁移。
* 服务端无法保证缺失区间完整。

前端收到后必须重新查询业务事实状态。

---

### 11.3 `connection.server_draining`

表示当前服务实例准备停止或迁移连接。

```json
{
  "event_type": "connection.server_draining",
  "payload": {
    "retry_after_seconds": 3
  }
}
```

服务端随后关闭连接，前端自动重连。

---

## 12. AtomicTask 事件

### 12.1 `atomic_task.created`

任务运行记录已经创建。

```json
{
  "event_type": "atomic_task.created",
  "atomic_task_id": "task_001",
  "aggregate_type": "atomic_task",
  "aggregate_id": "task_001",
  "aggregate_version": 1,
  "payload": {
    "function_ref": "application.execute",
    "status": "PENDING",
    "display_name": "生成角色参考图",
    "created_at": "2026-07-20T12:00:00Z"
  }
}
```

---

### 12.2 `atomic_task.blocked`

任务正在等待 TaskGroup 或 DAGTaskGroup 依赖满足。

```json
{
  "event_type": "atomic_task.blocked",
  "atomic_task_id": "task_001",
  "payload": {
    "status": "BLOCKED",
    "owner_type": "DAG_TASK_GROUP",
    "owner_id": "dag_group_001",
    "child_key": "generate_image"
  }
}
```

---

### 12.3 `atomic_task.ready`

任务依赖已满足，可以由 WorkflowRuntime 调度执行。

```json
{
  "event_type": "atomic_task.ready",
  "atomic_task_id": "task_001",
  "payload": {
    "status": "READY"
  }
}
```

---

### 12.4 `atomic_task.started`

任务已经开始运行。

```json
{
  "event_type": "atomic_task.started",
  "atomic_task_id": "task_001",
  "task_attempt_id": "attempt_001",
  "payload": {
    "status": "RUNNING",
    "attempt_number": 1,
    "started_at": "2026-07-20T12:20:00Z"
  }
}
```

---

### 12.5 `atomic_task.progressed`

任务进度发生变化。

```json
{
  "event_type": "atomic_task.progressed",
  "atomic_task_id": "task_001",
  "task_attempt_id": "attempt_001",
  "payload": {
    "status": "RUNNING",
    "progress": 0.48,
    "phase": "sampling",
    "phase_label": "图像采样",
    "current": 12,
    "total": 25,
    "message_code": "IMAGE_SAMPLING"
  }
}
```

规则：

* `progress` 范围为 `0` 到 `1`。
* 无法计算进度时可以省略或设置为 `null`。
* `phase` 是稳定的机器标识。
* `phase_label` 是默认展示文案。
* `message_code` 用于本地化。
* 同一个 TaskAttempt 内进度不应无故倒退。
* 新的 TaskAttempt 可以重新从零开始。

---

### 12.6 `atomic_task.retrying`

当前执行尝试失败，系统准备重试。

```json
{
  "event_type": "atomic_task.retrying",
  "atomic_task_id": "task_001",
  "payload": {
    "status": "RETRYING",
    "failed_attempt": 1,
    "next_attempt": 2,
    "retry_at": "2026-07-20T12:21:30Z",
    "reason_code": "PROVIDER_TEMPORARY_UNAVAILABLE"
  }
}
```

---

### 12.7 `atomic_task.cancel_requested`

取消请求已经被接受，但任务尚未完全停止。

```json
{
  "event_type": "atomic_task.cancel_requested",
  "atomic_task_id": "task_001",
  "payload": {
    "status": "CANCEL_REQUESTED",
    "requested_at": "2026-07-20T12:22:00Z"
  }
}
```

---

### 12.8 `atomic_task.succeeded`

任务成功完成。

```json
{
  "event_type": "atomic_task.succeeded",
  "atomic_task_id": "task_001",
  "payload": {
    "status": "SUCCESS",
    "finished_at": "2026-07-20T12:22:00Z",
    "artifact_count": 2
  }
}
```

---

### 12.9 `atomic_task.failed`

任务运行失败。

```json
{
  "event_type": "atomic_task.failed",
  "atomic_task_id": "task_001",
  "payload": {
    "status": "FAILED",
    "error_code": "PROVIDER_REQUEST_FAILED",
    "error_message": "视频生成平台返回请求失败",
    "retryable": true,
    "finished_at": "2026-07-20T12:22:00Z"
  }
}
```

错误事件不得包含：

* Provider 密钥。
* Authorization Header。
* 完整敏感请求体。
* 内部调用堆栈。
* 数据库连接信息。
* Worker 私有网络地址。
* 用户无权查看的外部平台原始响应。

---

### 12.10 `atomic_task.canceled`

任务已经取消并进入终态。

```json
{
  "event_type": "atomic_task.canceled",
  "atomic_task_id": "task_001",
  "payload": {
    "status": "CANCELED",
    "finished_at": "2026-07-20T12:22:00Z"
  }
}
```

---

### 12.11 `atomic_task.timed_out`

任务超过单次或整体超时策略并进入 `TIMEOUT` 终态。

---

### 12.12 `atomic_task.skipped`

任务因上游失败、组合策略或 Schedule 重叠而未执行，并进入 `SKIPPED` 终态。

---

## 13. TaskAttempt 事件

### 13.1 设计目的

`AtomicTask` 表示用户认知中的一次任务运行。

`TaskAttempt` 表示该任务的某一次具体执行尝试。

例如：

```text
AtomicTask task_001
├── TaskAttempt attempt_001：外部平台超时
└── TaskAttempt attempt_002：成功
```

自动重试时不创建新的 AtomicTask，而是创建新的 TaskAttempt。手动重试创建新 AtomicTask，并通过 `retry_of_task_id` 和 `root_task_id` 保留追溯。

---

### 13.2 `task_attempt.created`

自动执行尝试已创建并进入 `SCHEDULED`。

---

### 13.3 `task_attempt.started`

```json
{
  "event_type": "task_attempt.started",
  "atomic_task_id": "task_001",
  "task_attempt_id": "attempt_002",
  "payload": {
    "attempt_number": 2,
    "started_at": "2026-07-20T12:23:00Z"
  }
}
```

---

### 13.4 `task_attempt.succeeded`

当前自动执行尝试进入 `SUCCESS`；AtomicTask 是否同步进入成功终态仍以 Task Center 投影为准。

---

### 13.5 `task_attempt.failed`

```json
{
  "event_type": "task_attempt.failed",
  "atomic_task_id": "task_001",
  "task_attempt_id": "attempt_001",
  "payload": {
    "attempt_number": 1,
    "error_code": "PROVIDER_TIMEOUT",
    "retryable": true,
    "finished_at": "2026-07-20T12:22:00Z"
  }
}
```

---

### 13.6 `task_attempt.canceled` 与 `task_attempt.timed_out`

当前尝试分别进入 `CANCELED` 或 `TIMEOUT`。后续是否自动重试由 AtomicTask 的重试策略决定。

---

### 13.7 前端展示规则

任务列表默认展示 AtomicTask 状态。

任务详情可以展示：

* 尝试次数。
* 每次开始时间。
* 每次结束时间。
* 失败原因。
* 是否自动重试。
* 最终成功的 Attempt。

---

## 14. TaskGroup 事件

### 14.1 `task_group.created`

任务组与其 AtomicTask 子资源已创建。

---

### 14.2 `task_group.started`

任务组开始运行。

---

### 14.3 `task_group.progressed`

```json
{
  "event_type": "task_group.progressed",
  "task_group_id": "group_001",
  "payload": {
    "status": "RUNNING",
    "completed_count": 3,
    "running_count": 2,
    "pending_count": 4,
    "failed_count": 0,
    "total_count": 9,
    "progress": 0.42
  }
}
```

---

### 14.4 `task_group.succeeded`

任务组成功完成。

---

### 14.5 `task_group.failed`

任务组失败。

---

### 14.6 `task_group.canceled`

任务组取消。

---

### 14.7 DAGTaskGroup 事件

DAGTaskGroup 使用 `dag_task_group.created`、`started`、`progressed`、`succeeded`、`failed` 和 `canceled`。事件包含 `dag_task_group_id`、节点计数、整体进度和当前终态摘要；节点 AtomicTask 的具体错误仍以 Task Center 事实为准。

---

### 14.8 第一阶段限制

第一阶段只展示基础串行和并行任务组状态。

涉及画布节点映射、节点依赖展示和画布流程高亮的功能，放到后续 Canvas SSE 阶段实现。

---

## 15. Artifact 事件

### 15.1 状态与所有权

Artifact 的处理状态由 application-platform 拥有：

```text
created → transferring → processing → ready
                                      └→ failed
```

`deleted` 是 Artifact 不再可见的终态。UserAsset 登记是独立维度：

```text
pending → registered | failed
```

Artifact 处理状态与登记状态不得混用。AtomicTask 终态与 Artifact 登记终态也不得互相改写。

---

### 15.2 `artifact.created`

新的制品记录已由 application-platform 创建。此时可以只有外部结果引用，内容尚未进入 OmniMAM 可控存储。

```json
{
  "event_type": "artifact.created",
  "atomic_task_id": "task_001",
  "artifact_id": "art_001",
  "aggregate_type": "artifact",
  "aggregate_id": "art_001",
  "aggregate_version": 1,
  "payload": {
    "artifact_id": "art_001",
    "application_run_id": "ar_001",
    "output_key": "primary_output",
    "media_type": "image",
    "processing_status": "created",
    "registration_status": "pending",
    "asset_id": null
  }
}
```

---

### 15.3 `artifact.transferring`

Artifact 正在从外部平台或 Worker 结果位置转移到 OmniMAM 可控存储。

```json
{
  "event_type": "artifact.transferring",
  "artifact_id": "art_001",
  "payload": {
    "processing_status": "transferring",
    "progress": 0.35
  }
}
```

---

### 15.4 `artifact.processing`

Artifact 正在执行格式校验、媒体信息提取、缩略图/预览生成、转码或安全检测。`phase` 使用稳定机器标识，不直接作为用户展示文案。

---

### 15.5 `artifact.preview_ready`

Artifact 预览或缩略图已生成。事件只携带受保护 API 引用或短期签名引用，不携带长期公开 URL。预览就绪不代表原制品已完成全部处理。

---

### 15.6 `artifact.ready`

Artifact 已完成传输、校验、存储和必需媒体信息提取，可被查看、预览、下载、引用并登记为 UserAsset。

```json
{
  "event_type": "artifact.ready",
  "artifact_id": "art_001",
  "payload": {
    "processing_status": "ready",
    "size_bytes": 2480000,
    "media_type": "image/png",
    "ready_at": "2026-07-20T12:23:00Z"
  }
}
```

---

### 15.7 `artifact.processing_failed`

Artifact 在传输或处理阶段失败。事件携带稳定错误码、可重试性和受控摘要，不携带凭证或内部栈。必需输出处理失败时，AtomicTask 是否失败由 task-center 与 application-platform 的执行策略决定；AtomicTask 已终态后的附加处理失败不得反向改写其终态。

---

### 15.8 `artifact.registration_succeeded`

Artifact 已幂等登记为当前运行发起用户的 UserAsset。重复登记请求命中同一 UserAsset 时，仍投影为同一登记结果，不创建重复素材。

```json
{
  "event_type": "artifact.registration_succeeded",
  "artifact_id": "art_001",
  "payload": {
    "application_run_id": "ar_001",
    "registration_status": "registered",
    "asset_id": "asset_001",
    "registration_result": "created"
  }
}
```

---

### 15.9 `artifact.registration_failed`

Artifact 因内容缺失、不可读、所有者不一致或媒体信息非法而登记失败。失败不得改写 AtomicTask 终态，application-platform 保留稳定错误码和失败详情。

```json
{
  "event_type": "artifact.registration_failed",
  "artifact_id": "art_001",
  "payload": {
    "application_run_id": "ar_001",
    "registration_status": "failed",
    "registration_error_code": "ERR_ASSET_ARTIFACT_CONTENT_UNREADABLE",
    "retryable": true
  }
}
```

---

### 15.10 `artifact.deleted`

Artifact 已根据其所属领域的保留或删除规则变为不可见。该事件只从前端移除 Artifact 投影，不得级联删除已登记 UserAsset。

Artifact 正文、Provider 原始响应和内部凭证不进入 SSE 事件。前端需要完整制品或 UserAsset 时，必须查询对应业务事实。

---

## 16. SSE 原始消息格式

服务端输出示例：

```text
id: 928383
event: artifact.created
retry: 3000
data: {"event_id":928383,"event_type":"artifact.created","event_version":1,"occurred_at":"2026-07-20T12:32:11.123Z","atomic_task_id":"task_001","artifact_id":"art_001","aggregate_type":"artifact","aggregate_id":"art_001","aggregate_version":1,"payload":{"artifact_id":"art_001","application_run_id":"ar_001","output_key":"primary_output","media_type":"image","processing_status":"created","registration_status":"pending"}}

```

要求：

1. 每条 SSE 消息必须以空行结束。
2. `event` 与 JSON 中的 `event_type` 保持一致。
3. `id` 与 JSON 中的 `event_id` 保持一致。
4. JSON 必须为有效 UTF-8。
5. 单个业务事件不应包含大体积文本或二进制内容。

---

## 17. 前端功能设计

### 17.1 全局 SSE 客户端

Web 应用维护一个全局 SSE 客户端。

页面组件不得自行创建独立 SSE 连接。

推荐结构：

```text
SSEClient
├── ConnectionStore
├── EventCursorStore
├── EventDeduplicator
├── EventVersionChecker
├── EventRouter
├── TaskEventHandler
├── TaskGroupEventHandler
├── ArtifactEventHandler
└── ResyncCoordinator
```

---

### 17.2 前端职责

全局 SSE 客户端负责：

* 建立连接。
* 关闭连接。
* 自动重连。
* 保存最后事件 ID。
* 事件去重。
* 聚合版本判断。
* 事件类型分发。
* 连接状态管理。
* 触发重新同步。
* 记录客户端诊断信息。

---

### 17.3 任务事件分发

收到任务事件后，前端根据：

```text
atomic_task_id
```

更新：

* 任务中心列表。
* 任务详情。
* 当前应用运行页面。
* 顶部运行任务数量。
* 相关制品入口。

如果任务列表中不存在该 AtomicTask：

* 可以根据事件创建简要任务记录。
* 或调用任务详情 API 获取完整对象。

---

### 17.4 制品事件分发

收到制品事件后，前端根据：

```text
artifact_id
atomic_task_id
```

更新：

* 任务详情中的制品列表。
* 应用运行结果区。
* 最近生成内容。
* 制品预览状态。
* 资产登记状态。

---

### 17.5 页面初始化

前端不能只等待 SSE 事件构建页面。

进入任务中心时：

1. 调用任务列表 API。
2. 渲染当前事实状态。
3. 建立或复用 SSE 连接。
4. 使用后续事件增量更新。

进入任务详情时：

1. 查询 AtomicTask。
2. 查询 TaskAttempt。
3. 查询 TaskGroup。
4. 查询已有 Artifact。
5. 使用 SSE 更新后续变化。

---

### 17.6 乐观更新

用户点击取消任务后，前端可以立即：

* 禁用取消按钮。
* 显示“正在请求取消”。
* 将本地交互状态设置为 `cancel-requesting`。

但不能立即把任务事实状态设置为 `CANCELED`。

正确流程：

1. HTTP 请求取消。
2. HTTP 返回请求已接受。
3. 前端显示“取消中”。
4. SSE 收到 `atomic_task.cancel_requested`。
5. SSE 收到 `atomic_task.canceled`。
6. 前端进入最终取消状态。

手动重试采用相同原则：HTTP 成功后等待新 AtomicTask 的事实事件，不改写原任务终态。

---

### 17.7 制品增量展示

收到 `artifact.created`：

* 添加制品占位项。
* 显示制品类型。
* 显示当前处理和登记状态。

收到 `artifact.transferring` 或 `artifact.processing`：

* 更新处理阶段与可用进度。

收到 `artifact.preview_ready`：

* 更新预览和缩略图入口，但不把 Artifact 当作已完全就绪。

收到 `artifact.ready`：

* 启用查看、下载、引用和 UserAsset 登记操作。

收到 `artifact.processing_failed`：

* 显示处理失败原因与可重试性。

收到 `artifact.registration_succeeded`：

* 将制品更新为已登记。
* 显示 UserAsset 入口。

收到 `artifact.registration_failed`：

* 显示登记失败原因。
* 根据 `retryable` 决定是否显示重试操作。

收到 `artifact.deleted`：

* 移除 Artifact 的客户端投影，不删除或隐藏已登记 UserAsset。

---

## 18. 连接状态设计

前端连接状态包括：

| 状态           | 说明               |
| ------------ | ---------------- |
| connecting   | 正在建立 SSE 连接      |
| connected    | 实时连接正常           |
| reconnecting | 连接中断，正在自动恢复      |
| degraded     | 实时连接不可用，页面状态可能延迟 |
| resyncing    | 正在重新查询最新业务状态     |
| disconnected | 当前未建立实时连接        |

正常连接时不需要长期显示明显提示。

连接异常时，可以显示：

```text
实时连接已中断，任务仍在服务端继续运行，系统正在恢复连接。
```

禁止显示：

```text
连接中断，任务已经停止。
```

SSE 连接和任务执行是两个独立状态。

---

## 19. 多标签页行为

第一阶段要求：

1. 每个浏览器标签页最多建立一条 SSE 连接。
2. 同一标签页中的所有页面共用该连接。
3. 页面路由切换不得重新建立连接。
4. 用户退出登录后立即关闭连接。
5. 用户身份变化后必须重新建立连接。

同一浏览器打开多个标签页时，第一阶段允许每个标签页各自建立连接。

后续可以通过以下机制优化：

* `BroadcastChannel`
* `SharedWorker`
* 主标签页连接代理

该优化不属于第一阶段强制范围。

---

## 20. 断线恢复设计

### 20.1 Last-Event-ID

客户端保存最后成功处理的 `event_id`。

重连时可以使用：

```http
Last-Event-ID: 928383
```

或者：

```http
GET /api/v1/events/stream?after_event_id=928383
```

服务端从该事件之后开始发送。

---

### 20.2 游标保存

前端至少在内存中保存最后事件 ID。

为了支持页面刷新，可以保存到：

* `sessionStorage`
* IndexedDB

游标需要与当前登录会话关联。

建议键结构：

```text
sse:last-event-id:{current_user}:{session_id}
```

用户退出登录时删除当前会话游标。

禁止将一个用户的游标复用于另一个用户。

---

### 20.3 事件保留

服务端需要保留一定时间内的用户事件。

第一阶段建议默认：

```text
事件保留时间：24 小时
```

该时间应可配置。

事件保留不等于业务数据保留。

即使 SSE 事件已过期：

* AtomicTask 仍然存在。
* TaskAttempt 仍然存在。
* Artifact 仍然存在。
* Asset 仍然存在。

---

### 20.4 无法恢复时重新同步

如果客户端请求的事件已经不在保留范围内，服务端发送：

```text
connection.resync_required
```

前端收到后：

1. 暂停应用增量事件。
2. 查询当前进行中的 AtomicTask。
3. 查询最近更新的任务。
4. 查询当前打开任务的详情。
5. 查询相关 Artifact。
6. 使用服务端事实状态覆盖本地缓存。
7. 更新事件游标。
8. 恢复事件处理。

---

### 20.5 重连退避

客户端采用退避策略自动重连。

推荐：

```text
第 1 次：1 秒
第 2 次：2 秒
第 3 次：3 秒
第 4 次：5 秒
后续：最长 15 秒
```

以下场景可以立即触发重连：

* 浏览器重新联网。
* 页面从后台恢复。
* 用户重新登录。
* 服务端明确要求重连。

禁止以极高频率无限重连。

---

## 21. 事件顺序和一致性

### 21.1 同一聚合内顺序

同一个 AtomicTask 的状态事件必须具有递增的 `aggregate_version`。

典型状态顺序：

```text
PENDING
BLOCKED | READY
RUNNING
RETRYING
RUNNING
SUCCESS | FAILED | CANCELED | TIMEOUT | SKIPPED
```

终态包括：

```text
SUCCESS
FAILED
CANCELED
TIMEOUT
SKIPPED
```

AtomicTask 进入终态后，不允许重新进入运行状态。

系统自动重试使用同一 AtomicTask 下的新 TaskAttempt；用户手动重试必须创建新 AtomicTask，并记录 `retry_of_task_id` 与 `root_task_id`。

---

### 21.2 不同聚合之间不保证严格顺序

以下事件可能因为内部异步处理而出现顺序差异：

```text
artifact.registration_succeeded
atomic_task.succeeded
```

前端不能假设所有业务对象的事件都严格按全局业务顺序到达。

前端应依赖：

* `event_id`
* `aggregate_version`
* 业务对象标识
* 当前本地状态
* 必要时的事实查询

进行幂等更新。

---

### 21.3 终态保护

如果前端已经收到：

```text
atomic_task.succeeded
aggregate_version = 8
```

随后收到：

```text
atomic_task.progressed
aggregate_version = 7
```

前端必须忽略旧事件。

---

## 22. 进度语义

### 22.1 统一进度范围

统一使用：

```json
{
  "progress": 0.65
}
```

取值范围：

```text
0 <= progress <= 1
```

前端自行转换为百分比。

---

### 22.2 无法确定的进度

某些 SaaS 平台只提供：

* pending
* processing
* completed

这种情况下不应伪造精确百分比。

事件可以发送：

```json
{
  "phase": "provider_processing",
  "progress": null
}
```

前端显示不确定进度动画。

---

### 22.3 进度更新频率

服务端不应将 Worker 的每个极小进度变化都推送给前端。

可以采用以下方式限流：

* 进度变化超过指定阈值才发送。
* 固定最小发送间隔。
* 阶段变化时立即发送。
* 任务进入终态时立即发送。

例如：

```text
最小进度变化：1%
最小发送间隔：500 毫秒
```

具体值应可配置。

---

### 22.4 TaskGroup 进度

TaskGroup 整体进度可以根据子任务计算。

默认可以采用：

```text
已完成子任务权重 / 全部子任务权重
```

第一阶段每个子 AtomicTask 权重相同，与 task-center 的组合进度投影保持一致。

---

## 23. 状态模型

### 23.1 AtomicTask 状态

```text
PENDING
BLOCKED
READY
RUNNING
RETRYING
CANCEL_REQUESTED
SUCCESS
FAILED
CANCELED
TIMEOUT
SKIPPED
```

终态：

```text
SUCCESS
FAILED
CANCELED
TIMEOUT
SKIPPED
```

---

### 23.2 TaskAttempt 状态

```text
SCHEDULED
RUNNING
SUCCESS
FAILED
CANCELED
TIMEOUT
```

终态：

```text
SUCCESS
FAILED
CANCELED
TIMEOUT
```

---

### 23.3 TaskGroup 状态

```text
PENDING
RUNNING
CANCEL_REQUESTED
SUCCESS
FAILED
CANCELED
TIMEOUT
```

---

### 23.4 Artifact 处理状态

```text
created
transferring
processing
ready
failed
deleted
```

---

### 23.5 Artifact 登记状态

```text
pending
registered
failed
```

---

## 24. 服务端功能设计

### 24.1 Event Gateway

服务端提供统一的 Event Gateway。

职责包括：

* 验证用户身份。
* 建立 SSE 连接。
* 获取当前用户历史事件。
* 订阅当前用户实时事件。
* 格式化 SSE 消息。
* 发送心跳。
* 处理断线。
* 处理连接限流。
* 记录连接指标。
* 关闭慢客户端连接。
* 触发事件重放。
* 发出重新同步要求。

---

### 24.2 业务服务不能直接写 SSE

任务服务、制品服务不应直接向某个 HTTP SSE 连接写数据。

推荐链路：

```text
业务服务
├── 更新业务数据库
├── 写入领域事件
└── 提交事务
        │
        ▼
事件分发器
        │
        ├── 解析目标用户
        ├── 写入 UserEvent
        └── 发布实时事件
                │
                ▼
Event Gateway
                │
                ▼
SSE Client
```

这样可以避免：

* 业务逻辑依赖连接是否在线。
* 任务执行依赖某个 API Server 实例。
* 连接断开导致业务状态丢失。
* 多实例部署下事件只能发送给本机连接。

---

### 24.3 事务型 Outbox

业务状态更新成功但事件发布失败，会造成前端暂时无法收到变化。

建议采用事务型 Outbox：

```text
同一个数据库事务
├── 更新 AtomicTask 或 Artifact
└── 写入 OutboxEvent
```

事件分发器异步读取 Outbox，并创建用户事件。

即使即时推送失败：

* 业务状态仍然正确。
* Outbox 可以重试。
* 客户端可以通过事实查询恢复。

---

### 24.4 目标用户解析

第一阶段按业务资源已有所有权解析目标用户：

```text
AtomicTask.created_by_user_id
TaskGroup.created_by
DAGTaskGroup.created_by
```

任务事件发送给任务创建用户。

TaskGroup 和 DAGTaskGroup 事件发送给组合资源的受权用户；组合子 AtomicTask 不得扩大事件可见范围。

Artifact 事件可以通过来源任务解析：

```text
Artifact
→ ApplicationRun
→ owner_user_id
```

如果后续增加共享任务、管理员查看或协作权限，再扩展为资源访问权限判断。

当前不得为了 SSE 单独引入租户或工作区模型。

---

### 24.5 用户事件存储

推荐建立用户事件记录：

```text
UserEvent
├── id
├── recipient_user_id
├── event_type
├── event_version
├── aggregate_type
├── aggregate_id
├── aggregate_version
├── correlation_id
├── causation_id
├── payload
├── occurred_at
├── expires_at
└── created_at
```

索引建议：

```text
(recipient_user_id, id)
(recipient_user_id, occurred_at)
(aggregate_type, aggregate_id, aggregate_version)
(expires_at)
```

---

### 24.6 连接管理

服务端至少记录以下连接信息：

```text
connection_id
user_id
connected_at
last_write_at
client_instance_id
server_instance_id
remote_address
user_agent
```

连接记录用于：

* 当前连接数统计。
* 问题诊断。
* 服务实例排空。
* 用户级连接限制。
* 慢客户端检测。

连接记录不是业务事实数据。

---

### 24.7 慢客户端处理

服务端不得为消费缓慢的客户端无限缓存事件。

处理策略：

1. 设置单连接发送缓冲上限。
2. 缓冲区超过上限后关闭连接。
3. 客户端自动重连。
4. 通过 Last-Event-ID 恢复。
5. 无法恢复时执行重新同步。

---

## 25. API 设计概览

### 25.1 建立事件流

```http
GET /api/v1/events/stream
```

可选参数：

| 参数                 | 必填 | 说明          |
| ------------------ | -: | ----------- |
| after_event_id     |  否 | 从指定事件之后恢复   |
| client_instance_id |  否 | 当前前端客户端实例标识 |

第一阶段不支持：

* `user_id`
* `tenant_id`
* `workspace_id`
* 任意资源订阅范围参数

事件范围完全由当前登录身份决定。

---

### 25.2 查询历史事件

```http
GET /api/v1/events
```

参数示例：

```text
after_event_id=928383
page_num=0
page_size=200
```

该接口用于：

* 客户端主动补偿。
* SSE 恢复。
* 问题诊断。
* 短期降级。

该接口不是任务事实查询接口。

---

### 25.3 查询事件同步状态

```http
GET /api/v1/events/sync-state
```

响应：

```json
{
  "latest_event_id": 930000,
  "earliest_available_event_id": 900001,
  "retention_seconds": 86400,
  "server_time": "2026-07-20T12:00:00Z"
}
```

---

### 25.4 任务事实查询

SSE 无法恢复时，前端通过现有业务 API 重新同步。

例如：

```http
GET /api/v1/atomic-tasks
GET /api/v1/atomic-tasks/{atomic_task_id}
GET /api/v1/atomic-tasks/{atomic_task_id}/attempts
GET /api/v1/task-groups/{task_group_id}
GET /api/v1/dag-task-groups/{dag_task_group_id}
GET /api/v1/application-runs/{application_run_id}
```

---

## 26. 降级策略

### 26.1 SSE 不可用

如果浏览器、网络代理或网关暂时无法使用 SSE：

1. 任务创建不受影响。
2. 任务执行不受影响。
3. 前端显示实时连接异常。
4. 当前页面采用低频轮询同步状态。
5. SSE 恢复后停止轮询。
6. 重新查询一次事实状态。
7. 恢复增量事件处理。

推荐轮询周期：

```text
运行中任务：5 秒
后台或非活动页面：15 至 30 秒
```

轮询时间应可配置。

---

### 26.2 页面进入后台

浏览器标签页进入后台时：

* SSE 连接可以继续保持。
* 前端可以降低 UI 渲染频率。
* 事件仍然需要完成去重和状态存储。
* 页面恢复到前台时，重新查询当前关键任务状态。

---

## 27. 安全设计

### 27.1 用户隔离

服务端必须保证：

* 用户只能收到属于自己的任务事件。
* 用户只能查询自己的用户事件。
* 用户不能通过修改游标读取其他用户事件。
* 用户不能通过修改 AtomicTask ID 订阅其他用户任务。
* 退出登录后连接立即失效。

当前第一阶段可以使用：

```text
AtomicTask.created_by_user_id == current_user_id
```

作为主要判断规则。

后续如果引入共享资源和协作权限，再扩展可见性规则。

---

### 27.2 敏感信息

事件中不得包含：

* API Key。
* Access Token。
* Refresh Token。
* Provider Secret。
* Cookie。
* SSH 私钥。
* 完整内部请求。
* 完整外部平台响应。
* 内部堆栈。
* 数据库连接信息。
* Worker 私有网络凭证。
* 永久公开的受保护制品地址。

---

### 27.3 URL 安全

事件中包含的制品 URL 应当是：

* 受保护 API URL。
* 或短期签名 URL。

短期签名 URL 应具备：

* 短有效期。
* 仅访问指定文件。
* 不包含长期认证凭证。
* 到期后无法继续使用。

---

### 27.4 连接限制

服务端可以按照以下维度限制连接：

* 每个用户。
* 每个登录会话。
* 每个 IP。
* 每个客户端实例。

超过限制时，应返回明确错误。

连接限制不能影响已经在服务端运行的任务。

---

## 28. 网关和部署要求

反向代理需要支持：

* 长时间 HTTP 连接。
* 禁止 SSE 响应缓冲。
* 及时刷新响应数据。
* 足够长的读取超时。
* HTTP/1.1 或 HTTP/2。
* 客户端断开检测。

服务端需要设置：

```http
X-Accel-Buffering: no
```

在多实例部署下，Event Gateway 必须能够收到其他服务实例产生的事件。

可以使用：

* NATS。
* Redis Streams。
* Kafka。
* PostgreSQL Outbox 和通知机制。
* 其他可靠内部事件总线。

内部事件总线不属于 Web SSE 产品协议。

---

## 29. 可观测性

服务端至少记录以下指标：

```text
当前 SSE 连接数
每用户连接数
连接建立成功率
连接持续时间
异常断开次数
每秒发送事件数
事件发送延迟
事件重放数量
重新同步次数
慢客户端断开次数
连接缓冲区使用量
无权限事件拒绝数量
Outbox 待发送事件数量
Outbox 重试次数
```

关键日志包括：

* 连接建立。
* 连接关闭。
* 认证失败。
* 游标无效。
* 重放开始。
* 重放结束。
* 事件超出保留范围。
* 慢客户端关闭。
* 服务实例排空。
* 事件分发失败。

日志不得记录完整敏感事件 Payload。

---

## 30. 前端缓存更新规则

### 30.1 AtomicTask

收到 AtomicTask 事件后：

* 根据 `atomic_task_id` 查找任务。
* 根据 `aggregate_version` 判断是否更新。
* 不存在时创建任务摘要或查询完整任务。
* 终态事件更新最终状态。
* 不直接删除历史任务。
* 相同 `event_id` 不重复消费。

---

### 30.2 TaskAttempt

收到 TaskAttempt 事件后：

* 根据 `task_attempt_id` 幂等更新。
* 关联到对应 AtomicTask。
* 任务详情展示尝试记录。
* 不使用尝试序号作为唯一标识。

---

### 30.3 TaskGroup 与 DAGTaskGroup

收到 TaskGroup 事件后：

* 根据 `task_group_id` 更新整体进度。
* 子任务状态仍以 AtomicTask 为事实源。
* TaskGroup 终态不能覆盖子任务的具体错误信息。
* DAGTaskGroup 按 `dag_task_group_id` 更新，不与同 ID 的 TaskGroup 共用缓存键。

---

### 30.4 Artifact

收到 Artifact 事件后：

* 根据 `artifact_id` 幂等更新。
* 不使用文件名作为唯一标识。
* 同一任务允许多个同类型制品。
* 制品顺序使用 `created_at` 或显式 `sequence`。
* 处理状态与登记状态独立更新。
* `preview_ready` 只更新预览就绪标记，不跳过处理状态机。
* 登记失败不能删除 Artifact 或改写 AtomicTask 终态。
* 登记成功事件更新现有制品，不创建重复制品或 UserAsset。

---

## 31. 完整运行流程示例

### 31.1 创建任务

前端请求：

```http
POST /api/v1/applications/{application_id}/runs
Content-Type: application/json
```

```json
{
  "application_version_id": "app_ver_001",
  "idempotency_key": "run-demo-001",
  "inputs": {
    "prompt": "一座未来城市"
  }
}
```

服务端响应：

```json
{
  "application_run_id": "ar_001",
  "atomic_task_id": "task_001",
  "task_creation_status": "created"
}
```

后续 SSE：

```text
atomic_task.created
atomic_task.ready
task_attempt.started
atomic_task.started
atomic_task.progressed
artifact.created
artifact.transferring
artifact.processing
artifact.preview_ready
artifact.ready
task_attempt.succeeded
atomic_task.succeeded
artifact.registration_succeeded
```

---

### 31.2 外部 SaaS 异步任务

```text
1. 创建 AtomicTask
2. 创建 TaskAttempt
3. 调用 SaaS 创建任务接口
4. 获得 provider_task_id
5. AtomicTask 保持 `RUNNING`，Worker 通过延迟回调释放执行资源
6. WorkflowRuntime 延迟后重新投递同一 runtime task 和 TaskAttempt
7. SSE 推送进度或阶段变化
8. SaaS 返回生成完成
9. 创建 Artifact
10. Artifact 传输、处理并进入 `ready`
11. AtomicTask 进入 `SUCCESS`
12. application-platform 幂等请求登记 UserAsset
13. Artifact 登记进入 `registered` 或 `failed`
```

前端看到的事件可能是：

```text
atomic_task.started
atomic_task.progressed
artifact.created
artifact.transferring
artifact.processing
artifact.ready
atomic_task.succeeded
artifact.registration_succeeded
```

---

### 31.3 自动重试

```text
atomic_task.started
task_attempt.started
atomic_task.progressed
task_attempt.failed
atomic_task.retrying
task_attempt.started
atomic_task.progressed
artifact.created
artifact.processing
artifact.ready
task_attempt.succeeded
atomic_task.succeeded
artifact.registration_succeeded
```

---

## 32. 错误处理

### 32.1 连接错误

连接错误不代表任务失败。

前端提示：

```text
实时连接暂时不可用，任务仍在后台继续运行。
```

---

### 32.2 未知事件类型

前端收到未知 `event_type` 时：

* 记录诊断日志。
* 忽略当前事件。
* 不关闭 SSE 连接。
* 不导致整个事件客户端崩溃。

---

### 32.3 不支持的事件版本

如果 `event_version` 高于客户端支持版本：

1. 忽略无法正确处理的事件。
2. 标记相关资源需要重新同步。
3. 查询对应事实对象。
4. 上报兼容性问题。

---

### 32.4 事件数据不足

如果事件只包含资源标识，但前端没有完整对象：

* 调用对应业务详情 API。
* 不假设事件一定携带完整对象。
* 查询失败时保留事件摘要并显示加载状态。

---

## 33. 兼容性和事件演进

### 33.1 事件版本

每个事件包含：

```json
{
  "event_version": 1
}
```

版本规则：

| 修改       | 是否提升版本 |
| -------- | -----: |
| 新增可选字段   |      否 |
| 新增事件类型   |      否 |
| 修改字段语义   |      是 |
| 删除字段     |      是 |
| 修改字段类型   |      是 |
| 可选字段改为必填 |      是 |

---

### 33.2 前端兼容原则

前端必须：

* 忽略未知字段。
* 忽略未知事件类型。
* 为缺失可选字段提供默认行为。
* 不依赖 JSON 字段顺序。
* 不依赖固定的事件类型全集。
* 不因单个事件解析失败关闭整个连接。

---

## 34. 分阶段实施

### 第一阶段：任务中心和制品实时化

实现：

* 用户级 SSE 连接。
* Connection 事件。
* AtomicTask 事件。
* TaskAttempt 事件。
* TaskGroup 与 DAGTaskGroup 基础事件。
* Artifact 事件。
* 任务中心增量更新。
* 任务详情增量更新。
* 制品增量展示。
* Last-Event-ID。
* 自动重连。
* 事件去重。
* 聚合版本。
* 事件保留。
* 重新同步。
* SSE 不可用时降级轮询。

第一阶段不实现：

* Canvas 事件。
* NodeRun 事件。
* Agent 事件。
* 多人协同。
* WebSocket。

---

### 第二阶段：Canvas 实时事件

在画布运行功能稳定后增加：

* `canvas.run.created`
* `canvas.run.started`
* `canvas.run.progressed`
* `canvas.run.succeeded`
* `canvas.run.failed`
* `canvas.run.cancelled`
* `canvas.node.ready`
* `canvas.node.queued`
* `canvas.node.started`
* `canvas.node.progressed`
* `canvas.node.output_available`
* `canvas.node.succeeded`
* `canvas.node.failed`
* `canvas.node.skipped`
* `canvas.node.cancelled`

第二阶段需要解决：

* CanvasRun 与 TaskGroup 的关系。
* NodeRun 与 AtomicTask 的关系。
* 一个节点多次运行的识别。
* 多节点并行状态展示。
* DAG 依赖状态展示。
* 节点产生多个制品的关联。
* 只运行选中节点。
* 从指定节点向下游运行。
* 运行完整链路。

Canvas 事件仍然通过同一条用户级 SSE 连接发送，不为每个画布建立独立连接。

---

### 第三阶段：Agent 实时事件

在 Agent 运行模型确定后增加：

* `agent.run.created`
* `agent.run.started`
* `agent.run.waiting`
* `agent.step.started`
* `agent.step.progressed`
* `agent.step.succeeded`
* `agent.step.failed`
* `agent.tool.started`
* `agent.tool.succeeded`
* `agent.tool.failed`
* `agent.message.created`
* `agent.approval.requested`
* `agent.run.succeeded`
* `agent.run.failed`
* `agent.run.cancelled`

第三阶段需要解决：

* AgentRun 与 AtomicTask 的关系。
* AgentStep 的持久化。
* 工具调用记录。
* 用户可见消息和内部执行日志分离。
* 审批请求。
* 人工输入等待。
* Agent 创建或修改画布后的事件通知。
* Agent 产生制品后的关联关系。

用户提交审批和输入时仍然使用 HTTP API，而不是 SSE。

---

### 第四阶段：通知和可靠性增强

实现：

* 全局通知中心。
* 任务完成通知。
* 任务失败通知。
* Agent 审批提醒。
* 更完整的 Outbox。
* 更细粒度的事件重放。
* 慢客户端治理。
* 多标签页连接共享。
* 事件诊断页面。
* 事件发送延迟告警。
* 用户事件清理策略。

---

## 35. 业务规则与用户故事

### 35.1 业务规则

1. `BR-SSE-001`：SSE 仅提供服务端到 Web 客户端的单向事件通知；业务命令和事实查询必须使用所属领域 HTTP API。
2. `BR-SSE-002`：每个标签页最多维护一条当前登录用户的事件流，页面组件不得为单个资源自行建立连接。
3. `BR-SSE-003`：订阅范围由当前认证身份和既有资源可见性决定；客户端不得传入 `user_id`、`tenant_id` 或 `workspace_id` 扩大范围。
4. `BR-SSE-004`：SSE 事件不是业务事实源；首次加载、完整重同步和事件数据不足时必须查询 task-center、application-platform 或 asset-library。
5. `BR-SSE-005`：投递语义为 at-least-once；`event_id` 在当前用户事件流中唯一且有序，客户端按 `event_id` 去重。
6. `BR-SSE-006`：同一聚合的 `aggregate_version` 必须单调递增；客户端必须丢弃相同或更低版本，不同聚合之间不保证严格业务顺序。
7. `BR-SSE-007`：重连优先使用 `Last-Event-ID`，也允许等价的 `after_event_id`；游标无效、不属于当前用户或超出保留范围时，服务端必须发出 `connection.resync_required`。
8. `BR-SSE-008`：用户事件默认保留 24 小时且可配置；事件过期不得删除或改写业务事实。
9. `BR-SSE-009`：业务领域在事实变更事务中写入 outbox 或等价可靠投递记录；业务服务不得直接向某条 SSE 连接写数据。
10. `BR-SSE-010`：事件信封必须包含 `event_id`、`event_type`、`event_version`、`occurred_at`、`aggregate_type`、`aggregate_id`、`aggregate_version` 和 `payload`；与当前事件无关的关联 ID 可省略。
11. `BR-SSE-011`：第一阶段投影 AtomicTask、TaskAttempt、TaskGroup、DAGTaskGroup、Artifact 处理和 UserAsset 登记事实；任务语义必须对齐 task-center，不得恢复 TaskRun。
12. `BR-SSE-012`：事件不得包含 Provider 密钥、Authorization Header、凭证、内部栈、私网地址、大型正文、长期公开 URL 或用户无权查看的原始响应。
13. `BR-SSE-013`：长期访问令牌不得放入 SSE URL；使用 Bearer Token 时必须采用可写 Header 的 Fetch SSE 客户端或短期一次性连接令牌。
14. `BR-SSE-014`：服务端必须发送心跳、限制单连接缓冲并关闭慢客户端；客户端通过重连和重放恢复，不得无限占用服务端内存。
15. `BR-SSE-015`：客户端必须忽略未知字段和未知事件类型；不兼容的结构变更必须递增 `event_version` 并保留过渡期。
16. `BR-SSE-016`：SSE 不可用时业务执行不受影响；当前页面可降级为低频事实轮询，连接恢复后必须先重同步再继续增量消费。

### 35.2 用户故事与验收

#### US-SSE-001 建立用户级事件流

作为已登录 Web 用户，我希望页面共用一条实时连接，以便在路由切换时持续接收属于我的事件。

- `AC-SSE-001-01`：连接成功后收到 `connection.ready`，同一标签页路由切换不新建连接。
- `AC-SSE-001-02`：退出登录或身份变化时旧连接立即关闭，未认证请求不得获取事件。

#### US-SSE-002 实时查看任务进展

作为执行异步任务的用户，我希望列表和详情按已确认的 Task Center 事实增量更新。

- `AC-SSE-002-01`：AtomicTask、TaskAttempt、TaskGroup 和 DAGTaskGroup 的创建、进度、重试、取消和终态变化无需持续轮询即可反映。
- `AC-SSE-002-02`：重复或乱序事件不得创建重复资源、覆盖较新状态或使终态回退。

#### US-SSE-003 实时查看制品登记

作为应用运行用户，我希望 Artifact 的创建、传输、处理、预览就绪、可用性及 UserAsset 登记结果及时出现。

- `AC-SSE-003-01`：同一 ApplicationRun 的多个 Artifact 按 `artifact_id` 分别更新，重复事件不创建重复卡片。
- `AC-SSE-003-02`：Artifact 处理状态和登记状态独立推进，乱序事件不使处理状态回退。
- `AC-SSE-003-03`：处理或登记失败显示稳定错误结果，不反向改写已终态 AtomicTask；登记成功关联唯一 UserAsset。

#### US-SSE-004 断线恢复与重同步

作为网络不稳定的用户，我希望重连后继续获取缺失事件，无法完整恢复时回到正确事实状态。

- `AC-SSE-004-01`：保留期内按最后事件 ID 重放，重放事件不引起重复更新。
- `AC-SSE-004-02`：游标不可恢复时收到 `connection.resync_required`，客户端完整重查业务事实后再恢复增量消费。

#### US-SSE-005 安全降级与兼容演进

作为 Web 用户，我希望实时连接异常不会停止后台任务，新事件类型也不会破坏当前页面。

- `AC-SSE-005-01`：SSE 不可用时页面显示降级状态并低频轮询，任务继续在服务端执行。
- `AC-SSE-005-02`：未知字段、未知事件和单条解析失败只记录诊断，不关闭整条连接。

---

## 36. 产品验收标准

### 36.1 连接

* 用户登录后能够建立 SSE 连接。
* 连接成功后收到 `connection.ready`。
* 用户退出后连接立即关闭。
* 未登录用户不能建立事件流。
* 一个标签页最多建立一条 SSE 连接。
* 页面路由切换不重复创建连接。

---

### 36.2 任务推送

* 创建任务后，任务中心无需轮询即可出现新任务。
* 任务进入 `BLOCKED` 或 `READY` 后，页面能够实时更新。
* 任务开始后，页面能够实时变为运行中。
* Worker 上报进度后，页面能够更新进度。
* 外部平台任务通过延迟回调持续投影阶段，不伪造 waiting 事实状态。
* 自动重试时，页面能够显示重试次数。
* 任务成功、失败和取消后，页面能够实时进入终态。
* 重复事件不会创建重复任务。

---

### 36.3 制品推送

* 任务产生第一个制品后，前端无需等待任务结束即可展示。
* 同一任务多个制品能够分别显示。
* 制品传输、处理和预览就绪能够实时更新。
* 制品进入 `ready` 后能够启用查看、下载和引用。
* 制品登记为 UserAsset 后能够显示素材入口。
* 制品处理或登记失败后能够显示错误结果且不改写已终态任务。
* 重复 `artifact.created` 不会产生重复制品卡片。

---

### 36.4 断线恢复

* 网络断开后任务继续在服务端执行。
* 网络恢复后前端自动重连。
* 重连时能够从最后事件 ID 恢复。
* 重放事件不会造成重复状态。
* 事件超过保留时间时，前端执行完整状态同步。
* 同步完成后页面状态与服务端事实状态一致。

---

### 36.5 安全

* 用户不能收到其他用户的私有任务事件。
* 用户不能读取其他用户的历史事件。
* 用户不能通过修改恢复游标读取其他用户事件。
* SSE URL 不携带长期认证令牌。
* 事件中不包含 Provider 密钥或内部凭证。
* 制品访问地址遵循既有访问控制。

---

### 36.6 第一阶段边界

第一阶段验收不要求：

* 展示画布节点实时状态。
* 展示 CanvasRun 状态。
* 展示 Agent 步骤。
* 展示 Agent 消息。
* 处理 Agent 审批。
* 多人协同画布。
* WebSocket 通信。

---

## 37. 最终产品约束

1. OmniMAM Web 与服务端之间采用 HTTP REST + SSE。
2. SSE 仅用于服务端向前端推送事件。
3. 用户操作仍通过 HTTP API 提交。
4. SSE 事件流以当前登录用户为订阅主体。
5. 第一阶段不引入租户模型。
6. 第一阶段不引入工作区模型。
7. 客户端不能指定其他用户作为订阅对象。
8. 前端默认只维护一条用户级 SSE 连接。
9. 不为每个任务单独建立 SSE 连接。
10. SSE 事件不是业务状态事实源。
11. AtomicTask、TaskAttempt、TaskGroup、DAGTaskGroup、Artifact 和 UserAsset 由所属业务领域保存。
12. SSE 支持事件去重、重连、重放和补偿。
13. 客户端必须支持重复事件和一定程度的事件乱序。
14. Artifact 创建、传输、处理、预览就绪、可用、失败、删除及登记结果分别发送事件，处理或登记失败不反向改写已终态 AtomicTask。
15. 连接异常不得影响服务端任务继续运行。
16. 服务端与 Worker 之间不使用 SSE。
17. Canvas SSE 放在第二阶段实现。
18. Agent SSE 放在第三阶段实现。
19. 多人协同和高频双向控制不使用 SSE。
20. 不得为了实现 SSE 擅自增加当前产品中不存在的组织层级。
