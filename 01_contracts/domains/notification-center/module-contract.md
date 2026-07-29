# Notification Center Module Contract

产品语义以 `00_product/domains/notification-center/product-spec.md` 为准。本契约覆盖首期站内通知、基础偏好和统一 SSE 协作；Email、Webhook、mobile push、摘要、完整静默时段、广播游标和动态规则编辑未开放。

## 1. 模块边界

| 模块 | 拥有 | 不拥有 | S1 引用 |
| --- | --- | --- | --- |
| topic-catalog | notification topic、分类、启用状态、强制站内标记、默认严重程度、规则版本和受控映射 | 上游领域事件名、业务资源状态、管理员动态表达式编辑器 | BR-NOTIFY-002、003、011、014、020；US-NOTIFY-003、006、007 |
| source-consumer | 可靠 source event 消费、信封校验、NotificationEvent 规范化、重试和死信 | 跨域私表、业务状态修正、AtomicTask 执行或 SSE 连接 | BR-NOTIFY-004、007、010、017、019、021；US-NOTIFY-006、007 |
| rule-worker | 价值判断、topic 映射、接收者、偏好、模板、severity、去重、聚合和解决关联 | 上游事实推断、任意代码表达式、外部渠道发送 | BR-NOTIFY-003、005..011、014、020、021；US-NOTIFY-006、007 |
| inbox | Notification、收件箱状态、处理状态、聚合来源和保留时间 | 目标资源事实、任务历史、审计日志或业务命令 | BR-NOTIFY-001、006..009、012、018、022；US-NOTIFY-001、002、005 |
| counter | 每用户 unread、critical unread 和 unresolved action_required 计数投影 | 全局统计、跨用户榜单或业务状态 | BR-NOTIFY-008、012、016、017；US-NOTIFY-001、002、004 |
| preference | 当前用户分类/主题级站内开关、最低严重程度和重复合并覆盖 | Email/Webhook/mobile push 配置、动态规则、身份生命周期 | BR-NOTIFY-011、012、014、015、020；US-NOTIFY-003 |
| navigation | 结构化目标校验和同源 action path 派生 | 目标资源授权、任意 URL、外部跳转或业务命令 | BR-NOTIFY-001、013、019；US-NOTIFY-005 |
| notification-outbox | Notification/计数变化的事务事件和向 SSE projector 的可靠投递 | UserEvent 存储、event_id、连接、重放或 Event Gateway | BR-NOTIFY-016、017、021；US-NOTIFY-004、007 |
| retention | NotificationEvent、Notification 和 outbox 的到期清理 | 源业务、任务、运行、Artifact 或审计事实删除 | BR-NOTIFY-018；US-NOTIFY-007 |
| delivery | 预留 NotificationDelivery 与渠道隔离边界 | 首期外部渠道实现 | BR-NOTIFY-015、024；US-NOTIFY-007 |
| access | 当前接收者、管理员候选范围、权限和存在性保护 | identity 用户/角色事实或跨域资源授权 | BR-NOTIFY-010..012、019；US-NOTIFY-001..003、005、006 |

## 2. 输入 source event

首期只有以下上游事件属于 `ACTIVE` 输入：

| 上游 | source event | 要求 | 允许映射的 notification topic |
| --- | --- | --- | --- |
| task-center | `atomic_task_status_changed` | 稳定 source_event_id、atomic_task_id、owner/created_by、to_status、last_error、resource_version、occurred_at | `task.atomic_task.succeeded`、`task.atomic_task.failed`、`task.atomic_task.timed_out`、`task.atomic_task.action_required` |
| workflow-canvas | `canvas_run_status_changed` | 稳定 source_event_id、canvas_run_id、created_by、project/namespace、status、summary、warnings、aggregate_version、occurred_at | `canvas.run.succeeded`、`canvas.run.partially_succeeded`、`canvas.run.failed` |

以下现行事件登记为 `CONTRACT_GAP`，不得在缺口补齐前启用规则：

- `task_group_status_changed`：缺 notification-service 消费关系和 action_required 判定。
- `asset_version_processing_changed`：缺消费关系和单项/批次映射。
- `artifact_processing_changed`、`artifact_registration_changed`：缺消费关系。
- `application_run_projection_changed`：缺消费关系和 initiator/owner 载荷。
- `engine_instance_health_changed`：缺消费关系、from status 和管理员接收范围。
- `model_health_status_changed`：缺消费关系；现行 camelCase payload 由 model-management 契约负责，通知中心不得静默改名。

扫描、导入、StorageBackend 容量、凭证到期、系统公告、安全和 Agent 主题登记为 `FUTURE`。`CONTRACT_GAP` 与 `FUTURE` topic 的 `enabled` 必须为 false；收到相关事件时返回/记录 `ERR_NOTIFICATION_SOURCE_EVENT_UNSUPPORTED`，不得创建 Notification。

## 3. 候选规范化与规则

- source event 信封必须提供 `source_domain`、`source_event_type`、`source_event_id`、聚合类型/ID/version 和发生时间；payload 必须提供 topic 规则需要的最小字段与接收者依据。
- NotificationEvent 使用 `source_domain + source_event_id + notification_topic` 唯一；事件快照先做字段白名单、长度限制与敏感信息清理，再持久化。
- topic catalog 是后端预设事实，不提供公共 CRUD。`ACTIVE + enabled=true` 才允许生成 Notification；服务启动不得自动启用 `CONTRACT_GAP` 或 `FUTURE`。
- `atomic_task_status_changed` 只允许 standalone AtomicTask 进入任务通知规则：存在 TaskGroup/DAG owner、application_run_id 或 canvas_run_id 时必须 `IGNORED`，等待所属上层业务域表达最终语义，不能为子任务重复通知。
- standalone AtomicTask `SUCCESS` 默认 `IGNORED`；只有规则明确确认用户可见结果时才生成 `task.atomic_task.succeeded`。FAILED、TIMEOUT 或不可自动恢复且需用户处理的结果按错误摘要和 retryable 计算 topic/attention status。
- CanvasRun `SUCCESS`、`PARTIAL_SUCCESS`、`FAILED|TIMEOUT` 分别映射 succeeded、partially_succeeded、failed；CANCELED 默认不通知，除非未来独立 topic 契约启用。
- 偏好应用顺序为 mandatory topic 强制规则、topic 级用户覆盖、category 级用户覆盖、topic catalog 默认值。最低严重程度顺序固定为 `info < success < warning < error < critical`。
- 去重键固定为 `recipient_user_id + source_domain + source_event_id + notification_topic`。重复事件返回已有 Notification/处理结果，不递增 occurrence_count。
- 聚合键包含 recipient、topic、source identity、aggregation mode 和 bucket。聚合事务锁定唯一键，新增来源 link、递增 occurrence_count、更新 last_occurred_at 与 Notification resource_version。
- 同一源聚合只接受更高 source_aggregate_version；相同版本幂等，更低版本丢弃并记录指标。不同聚合的版本不可比较。
- resolved 只接受同一来源更高版本、共享 root task 且业务来源一致或显式 resolves_source_event_id。解决不修改 inbox_status。

## 4. 收件箱状态与计数

- 新 Notification 默认 `inbox_status=unread`；`attention_status` 由规则独立决定。
- read 在 unread/read 上幂等设置 `inbox_status=read` 和 `read_at`，对 archived 返回状态冲突；unread 在 read/unread 上幂等并清空 `read_at`，对 archived 返回状态冲突。
- archive 从 unread/read 进入 archived 并设置 `archived_at`、保留原 read_at，重复 archive 幂等；unarchive 从 archived 固定恢复 read、设置缺失的 read_at 并清空 archived_at，已 read 时幂等，unread 时返回状态冲突。
- 所有收件箱操作保持 attention_status、resolved_at、source 和内容不变。
- 单条/批量/全部已读、通知创建、归档变化、删除和聚合 severity/attention 变化时，同事务更新 notification_recipient_counters 与 Notification Outbox。
- `critical_count` 只统计未读 critical；`action_required_count` 只统计未归档且 attention_status=action_required 的通知。计数不得为负，异常时从当前用户 Notification 重建。
- 批量已读请求 1..200 个唯一 ID并保持顺序。请求结构错误整体返回 `ERR_NOTIFICATION_BATCH_INVALID`；每项不存在/不可见或状态错误逐项返回，成功项独立提交。
- 全部已读只更新当前用户 unread 通知；可选 category 进一步收窄范围。并发新通知不因旧批次读取快照而被误标已读。

## 5. 查询与关联引用

- 列表固定 `page_num=0` 起始、默认 page_size=20、最大 100，返回 `total + items`。默认 `created_at desc`。
- keyword 只搜索 title/name 和 content/description；search_fields 只允许 `title,content`，不得扫描 payload_snapshot、extend_shadow 或错误正文。
- inbox/category/severity/attention/topic 多值过滤使用逗号分隔字符串；未知值整体返回 `ERR_NOTIFICATION_QUERY_INVALID`。
- 所有查询强制 `recipient_user_id=当前认证用户` 且 `deleted_at IS NULL`；不提供 user_id 参数、管理员跨用户列表或通知详情穿透接口。
- `source_id` 和 navigation `target_id` 保留稳定引用，但不展开多态关联摘要：Notification 的 title/content 是创建时非敏感可读快照，navigation target 和 action path 已满足当前卡片识别与导航需求。该豁免不得用于返回目标资源当前状态。
- action_path 由 target_type、target_id、view 和受控字符串 params 通过白名单路由生成；目标不可见、删除或类型未知时为 null。目标领域 API 仍执行自身权限校验。
- NotificationEvent、recipient_basis、payload_snapshot、dedup/aggregate key、其他接收者和内部错误不进入公共响应。

## 6. 偏好契约

- GET 返回显式偏好、默认值、mandatory topic 和渠道 capabilities。首期 capabilities 固定 `in_app=true`，其他渠道、digest 和 quiet_hours 为 false。
- PUT 是当前用户显式偏好的整体替换；空 items 删除全部覆盖并恢复默认值。`category + nullable notification_topic` 在请求中必须唯一。
- notification_topic 不为空时必须为 catalog 中 `ACTIVE + enabled=true` 的主题且 category 一致；FUTURE/CONTRACT_GAP topic 不进入首期公共偏好目录，也不能写入用户覆盖。
- mandatory topic 的 `in_app_enabled` 必须为 true；关闭返回 `ERR_NOTIFICATION_MANDATORY_TOPIC_DISABLED`。
- 请求不得包含 Email、Webhook、mobile push、digest 或 mute 字段；未来客户端提前提交未知字段由 additionalProperties=false 拒绝，不静默保存。
- 偏好只影响新 source event 的规则判断，不追溯删除或修改既有 Notification。

## 7. Outbox 与 SSE 协作

- Notification 创建、更新、删除以及 recipient counter 更新必须与 notification_outbox 同事务提交。
- 出站事件仅为 `notification_created`、`notification_updated`、`notification_deleted`、`notification_unread_count_changed`；使用 snake_case 领域事件名。
- SSE projector 将其映射为 `notification.created`、`notification.updated`、`notification.deleted`、`notification.unread_count_changed` UserEvent，沿用统一 `/api/v1/events/stream`、event_id、aggregate_version 和 Last-Event-ID。
- notification payload 仅携带 ID、topic、分类、严重程度、状态、计数和 navigation availability；完整 title/content/navigation 通过 Notification API 重查。
- SSE 投影失败不回滚 Notification；客户端收到 `connection.resync_required` 后重查列表和未读数。通知中心不建立连接表、Broker 或私有 stream endpoint。

## 8. 保留与安全

- NotificationEvent 默认保留 30..90 天，具体值由受控部署策略选择；Notification 按 S1 类型保留策略计算 expires_at。保留值变化只影响未来清理，不修改源事实。
- 删除/清理 Notification 时同步更新 counter 并写 notification_deleted；清理 event link 后才能删除已到期 NotificationEvent。
- payload_snapshot、title/content、navigation、日志与死信摘要禁止凭证、Authorization Header、Token、签名、私网地址、完整 URL、内部栈、大型正文、媒体内容和未经处理的上游 payload。
- 错误日志只记录 source domain/event ID、topic、聚合标识、规则版本和稳定错误码；不得记录 recipient_basis 或完整 payload。
- 通知不存在与不属于当前用户统一返回 `ERR_NOTIFICATION_NOT_VISIBLE`，不泄露真实接收者或存在性。

## 9. 跨域协作

- task-center：只提供 AtomicTask/Group 可靠事件和受控任务导航；通知中心不读 Conductor 或 Task Center 私表。
- workflow-canvas：只提供 CanvasRun 可靠事件和受控运行导航；通知中心不从 AtomicTask 自行推断 CanvasRun 结果。
- asset-library：未来补齐 Artifact/AssetVersion 消费关系后提供 owner 和业务结果；AtomicTask SUCCESS 不代表 AssetVersion ready。
- application-platform：未来补齐 ApplicationRun/EngineInstance 事件接收者和前态；ApplicationEngineInstance 与 ProviderModel 不合并。
- model-management：未来按 ownerUserId 消费 ProviderModel 健康变化；camelCase 例外由其源 S2 负责。
- identity：提供当前认证用户、ADMIN/SUPER_ADMIN 角色和通知权限判断；Notification Center 不维护用户或角色事实。
- sse：消费 Notification Outbox 事件并拥有 UserEvent、event_id、历史、重放和连接；不拥有 Notification。

所有跨域协作通过可靠事件或受控 API 完成，不访问其他领域私有表。

## 10. 首期禁用能力

- 通知 topic、模板或任意表达式的管理员 CRUD。
- Email、Webhook、mobile push、daily/weekly digest、完整静默时段和广播阅读游标。
- 用户代表其他用户订阅、管理员跨用户通知查询或手工创建系统广播。
- 通知中心直接执行 retry、修复、配置变更或其他业务命令。
- `/api/v1/notifications/stream`、通知私有 SSE Broker 或直接写 Web 连接。
- 启用 `CONTRACT_GAP`、`FUTURE` topic，或从未知 source event 猜测业务事实。

这些能力不得提前出现在成功响应或可写枚举中；外部渠道请求使用 `ERR_NOTIFICATION_CHANNEL_UNSUPPORTED`，未启用 source/topic 使用 `ERR_NOTIFICATION_SOURCE_EVENT_UNSUPPORTED`。
