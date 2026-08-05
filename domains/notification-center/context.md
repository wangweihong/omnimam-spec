# Notification Center Context

## 1. 领域职责

`notification-center` 消费其他业务领域已经持久化的可靠 source event，将其规范化、匹配受控 topic、解析接收者、去重或聚合后形成用户收件箱。它负责 Notification、未读计数、偏好、处理入口和通知 Outbox，但不是第二个任务中心。

## 2. 核心对象

- `NotificationTopic`：受控通知主题及 ACTIVE、CONTRACT_GAP、FUTURE 状态。
- `NotificationEvent`：从 source event 规范化的候选事件。
- `Notification`：面向一个用户的标题、摘要、状态、动作和聚合结果。
- `NotificationEventLink`：通知与一个或多个来源事件的关联。
- `NotificationRecipientCounter`：用户收件箱计数投影。
- `NotificationPreference`：当前用户的站内通知偏好。
- `NotificationOutbox`：向 SSE 等消费者可靠发布通知变化。

## 3. 核心规则

- 通知是业务事实的用户投影，不拥有 AtomicTask、CanvasRun、ApplicationRun 或 Asset 状态。
- source event 必须来自领域 Outbox；通知中心不得读取其他领域私表或猜测业务结果。
- topic catalog 决定可消费范围，只有 ACTIVE topic 可启用。
- 首期 ACTIVE 输入仅包含 standalone AtomicTask 和 CanvasRun 状态变化。
- Group、Asset、Application、Engine、ProviderModel 的 CONTRACT_GAP，以及全部 FUTURE topic 必须保持禁用。
- 重复和乱序事件通过 source identity、aggregate version、去重键与聚合键处理。
- Notification、recipient counter 与 Notification Outbox 必须原子提交；SSE 失败不回滚收件箱。
- 已读、归档、需要处理和偏好只属于通知中心，不回写源业务状态。
- 收件箱可提供全部、已读、需要处理和系统等受控视图，分类不改变源事件事实。

## 4. 领域边界

本领域拥有通知规则、候选事件、Notification、计数、偏好和投递状态。源业务状态归生产事件的领域；实时连接与短期重放归 sse。外部邮件、Webhook、移动推送和广播游标仅为未来边界，不能声明为当前成功能力。

## 5. 上游与下游

上游是 task-center、workflow-canvas 及未来通过合同门禁的 application-platform、asset-library、user-model 可靠事件。下游是用户收件箱 REST API、Notification Outbox 和 sse 的提示投影。Web 收到提示后必须重查通知事实。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/notification-center/product-spec.md` | S1 | 通知语义、topic 门禁和用户流程 |
| `01_contracts/domains/notification-center/openapi.yaml` | S2 | 收件箱、计数和偏好 API |
| `01_contracts/domains/notification-center/schema.sql` | S2 | 设计态通知、计数和 Outbox 结构 |
| `01_contracts/domains/notification-center/events.yaml` | S2 | 通知领域事件合同 |
| `01_contracts/domains/notification-center/module-contract.md` | S2 | Worker、双 Outbox 与跨域边界 |
| `02_architecture/domains/notification-center.md` | 参考 | 一致性、部署、恢复和首期门禁 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改收件箱、已读或偏好 | S1 product-spec | 涉及接口或数据时读 OpenAPI/Schema |
| 新增通知 topic | S1 product-spec | 必须再读源领域 events 与本域 module-contract |
| 修改实时通知提示 | 当前 Context | 再读 sse Context |
| 修改任务或画布结果 | 源领域 Context | 只在需要通知投影时返回本 Context |

## 8. 当前状态

`spec-v1.8.0` 已发布；首期只允许两个 ACTIVE topic。CONTRACT_GAP/FUTURE 能力处于延后状态，缺少上游 payload 或消费者合同前不得启用。

## 9. 不在本领域定义的内容

- AtomicTask、CanvasRun、ApplicationRun 和 AssetVersion 的状态机不在本领域定义。
- SSE 连接、重放游标和客户端重同步协议不在本领域定义。
- Email、Webhook、移动推送等未来渠道的正式可用性不在当前范围。
- 未经源领域确认的接收者、业务结果或人工动作不在本领域定义。
