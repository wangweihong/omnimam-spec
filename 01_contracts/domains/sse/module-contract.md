# SSE Module Contract

本契约定义 SSE 用户级实时事件投影的模块边界。产品语义以 `00_product/domains/sse/product-spec.md` 为准。

## 1. 模块边界

| 模块 | 职责 | 不负责 | S1 引用 |
| --- | --- | --- | --- |
| source-consumer | 消费 task-center、asset-library、workflow-canvas 与 application-platform 可靠事件，校验所有者、版本和必需字段 | 不直接读 Conductor、Provider 或跨域私有表 | BR-SSE-009..012、017、018；BR-WORKFLOW-024、025；US-SSE-002、003 |
| event-projector | 将上游事件映射为稳定客户端 event_type 和统一信封 | 不创造业务状态或改写上游资源 | BR-SSE-004、006、010、011、015 |
| user-event-store | 按用户持久短期可重放 UserEvent，分配有序 event_id，执行保留清理 | 不保存长期业务历史或正文 | BR-SSE-005..008、012 |
| event-gateway | 鉴权、建立 SSE、心跳、格式化、连接限制、慢客户端和实例排空 | 不执行业务命令，不为单个资源创建专属连接 | BR-SSE-001..003、013、014 |
| replay | 校验 Last-Event-ID/after_event_id，返回历史和同步边界，发出 resync_required | 不用事件重放替代完整事实重同步 | BR-SSE-004、007、008；US-SSE-004 |
| access | 将认证主体固定为 recipient_user_id，校验 stream/history 权限 | 不允许请求传入其他用户、租户或工作区 | BR-SSE-003、013 |

## 2. 输入事件

SSE 只消费以下已持久业务事实的可靠事件：

| 上游 | 事件 | 用途 |
| --- | --- | --- |
| task-center | `atomic_task_created` | 生成 `atomic_task.created` |
| task-center | `atomic_task_status_changed` | 生成 AtomicTask 状态、进度和终态事件 |
| task-center | `task_attempt_status_changed` | 生成 TaskAttempt 创建、开始和终态事件 |
| task-center | `task_group_status_changed` | 按 `group_type` 生成 TaskGroup 或 DAGTaskGroup 事件 |
| asset-library | `artifact_created`、`artifact_processing_changed` | 生成 Artifact 创建、传输、处理、预览、ready、失败和删除事件 |
| asset-library | `artifact_registration_changed` | 生成 Artifact 登记成功或失败事件 |
| asset-library | `asset_version_processing_changed` | 生成 AssetVersion processing、ready、ready_with_warnings 和 failed 事件 |
| workflow-canvas | `canvas_run_created`、`canvas_run_task_group_bound`、`canvas_run_status_changed` | 生成 `canvas.run.*`，并在 progressed 中携带变化的 FlowRun 摘要 |
| workflow-canvas | `canvas_node_run_status_changed`、`canvas_node_output_available` | 生成 `canvas.node.*`，包括渐进输出可用事件 |

上游事件必须提供稳定 source_event_id、所有者、聚合 ID、`resource_version`、发生时间和受控 payload。缺少必需字段的事件进入可观测错误与重试/死信边界，不允许猜测所有者。

## 3. 投影与幂等

- 业务事件投影键为 `recipient_user_id + source_domain + source_event_id + event_type`。
- 同一聚合的 `aggregate_version` 来自上游 `resource_version`；不得使用 UserEvent 写入次数伪造业务版本。
- `event_sequence` 只是当前用户事件流的恢复顺序，不表示跨聚合业务因果顺序。
- 投影与 UserEvent 写入必须原子完成；实时广播失败后仍可从 UserEvent 重放。
- Artifact 处理与登记使用同一 Artifact `resource_version` 序列，但客户端独立更新 processing/registration 字段；`preview_ready` 不提前设置 processing_status=ready。
- AssetVersion 使用独立 `resource_version`；Artifact、AssetVersion 与 AtomicTask 不同聚合间不保证严格顺序，前端不得从任务终态推断素材 ready。
- CanvasRun 与 CanvasNodeRun 使用各自 `aggregate_version`；CanvasNodeRun、AtomicTask 和 Artifact 版本不可互相比较，`canvas.node.output_available` 不能替代 Artifact 生命周期事件。

## 4. SSE 输出

- 路径固定为 `GET /api/v1/events/stream`，响应 `Content-Type: text/event-stream`、`Cache-Control: no-cache`、`X-Accel-Buffering: no`。
- 业务消息按 `id`、`event`、`retry`、`data` 输出并以空行结束；`id` 等于 `event_sequence`。
- 心跳使用 SSE 注释，不写入 UserEvent，不推进恢复游标。
- `connection.ready`、`connection.resync_required`、`connection.server_draining` 是连接控制事件，不进入历史列表。
- 慢客户端缓冲超限时关闭连接；不丢弃或改写已持久 UserEvent。

## 5. 恢复与保留

- `Last-Event-ID` 与 `after_event_id` 是等价游标；同时出现时必须相同。
- 游标查询始终同时限制 `recipient_user_id=当前用户`，不向调用方暴露不可见游标的真实所有者。
- 默认保留 24 小时，配置只能改变 UserEvent 保留，不得影响上游业务数据。
- 游标无效或过期时发出 `connection.resync_required`；客户端查询 task-center、application-platform、asset-library 和 workflow-canvas 事实后再恢复增量消费。

## 6. 权限与安全

- 只支持当前认证用户的事件流和历史；不定义代表他人订阅的公开 API。
- 长期访问令牌不得进入 URL。Bearer Token 客户端使用 Header；一次性连接令牌若实现，必须短期、单次使用并绑定当前用户。
- payload 禁止 Provider 密钥、Authorization Header、内部栈、私网地址、大型正文、长期公开 URL 和用户无权查看的原始响应。
- 服务端日志只记录 event_id、event_type、aggregate 标识、耗时和稳定错误码，不记录完整 payload。

## 7. 跨域边界

- task-center 拥有 AtomicTask、TaskAttempt、TaskGroup 和 DAGTaskGroup；SSE 只消费 S2 事件，不读运行时数据库或 API。
- asset-library 拥有 Artifact、Asset、AssetVersion、AssetRepresentation 和对应生命周期事件；application-platform 只拥有 ApplicationRun 的 Artifact 引用投影。
- workflow-canvas 拥有 CanvasRun、CanvasFlowRun、CanvasNodeRun、任务/输出绑定和对应 Canvas 语义事件；SSE 不从 Task 事件自行猜测 Canvas 状态。
- identity 提供认证主体和权限校验；SSE 不维护用户、租户或工作区生命周期。
- 业务命令和完整资源查询回到所属领域 HTTP API；SSE 不定义取消、重试、登记、下载或删除命令。

## 8. 非目标

- Worker 通信、服务间 RPC 或内部消息总线协议。
- CanvasFlowRun 独立事件、流/分片级操作事件、Agent 事件、多人协同、高频双向控制或二进制流。
- 以 UserEvent 代替审计日志、任务历史、Artifact 生命周期或 UserAsset 事实。
