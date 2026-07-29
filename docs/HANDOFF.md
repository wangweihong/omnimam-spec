# OmniMAM Spec Handoff

## 当前项目目标

以 `spec-v1.8.0` 发布 notification-center S1/S2，并与现行领域事件、统一 SSE UserEvent 和全局架构保持一致。

## 本次完成

1. 在 notification-center S1 增加 `BR-NOTIFY-001..024`、`US-NOTIFY-001..007`、验收标准、标记未读和取消归档语义。
2. 创建 notification-center OpenAPI、设计态 schema、错误码、权限码、事件目录和模块契约六类 S2 文档。
3. 建立 ACTIVE、CONTRACT_GAP、FUTURE topic catalog，保留全部前瞻主题并阻止未就绪主题提前启用。
4. 定义独立 Notification Worker、NotificationEvent 候选、去重/聚合、解决关联、收件箱计数、偏好、双 Outbox 和未来渠道隔离。
5. 扩展 SSE S1/S2，增加四类 notification UserEvent，继续复用 `/api/v1/events/stream`、event_id、aggregate_version 和重同步机制。
6. 登记 `180200-180999` 错误码区间，并补充 notification-center 领域架构和全局依赖链路。
7. 用户已明确确认提交并 release，notification-center OpenAPI 发布为 0.1.0，SSE OpenAPI 发布为 0.2.0。
8. 正式规范提交为 `0c9bfbf4ff42a1856f54d2201b267b47739c7188`，`RELEASE.md` 已登记 `spec-v1.8.0`。

## 文件变化

- `00_product/domains/notification-center/product-spec.md`
- `00_product/domains/sse/product-spec.md`
- `01_contracts/domains/notification-center/` 六个 S2 文件
- `01_contracts/domains/sse/events.yaml`
- `01_contracts/domains/sse/module-contract.md`
- `01_contracts/domains/sse/openapi.yaml`
- `01_contracts/domains/sse/schema.sql`
- `01_contracts/error-code-index.md`
- `02_architecture/domains/notification-center.md`
- `02_architecture/global-architecture.md`
- `CHANGELOG.md`
- `RELEASE.md`
- `docs/HANDOFF.md`

用户已有的 `AGENTS.md` 工作区改动未修改。

## 关键设计决策

- 首期 ACTIVE 输入只有 `atomic_task_status_changed` 和 `canvas_run_status_changed`；Group、Asset、Application、Engine 和 ProviderModel 事件在缺口补齐前保持禁用。
- AtomicTask 通知只处理 standalone task；Group/DAG 子任务和 ApplicationRun/CanvasRun 关联任务等待上层业务域表达，避免重复或错误通知。
- source event、notification topic、Notification domain event 和 SSE UserEvent 分层命名；业务域与 Notification/SSE 各自拥有 Outbox。
- Notification、recipient counter 和 Notification Outbox 原子提交；SSE 失败不回滚收件箱。
- Email、Webhook、mobile push、摘要、静默时段和广播游标只保留 schema/边界，不作为首期可写或成功能力。

## API、Schema 与配置变化

- 新增 10 个 `/api/v1/notifications*`、`/api/v1/notification-preferences` operation，全部仅作用于当前用户。
- 批量已读最多 200 个唯一 ID，逐项返回结果；分页从 0 开始，默认 20、最大 100。
- 新增 8 张设计态表：topic catalog、candidate event、notification、event link、recipient counter、preference、delivery 预留和 outbox。
- 新增 13 个 `ERR_NOTIFICATION_*` 业务错误、6 个 notification 权限以及 4 个 notification domain event。
- SSE 增加四个 notification UserEvent 和 `notification_id` 投影字段；OpenAPI 为 `0.2.0`。

## 待办与风险

- `spec-v1.8.0` 已 release，可作为 notification-center 与 SSE 协作的正式实现依据。
- task_group、asset/version/artifact、application_run、engine health 和 model health 仍缺上游消费者或 payload 契约；对应 topic 必须保持 `CONTRACT_GAP`。
- 扫描、导入、存储、凭证、安全、系统公告和 Agent 仍是 `FUTURE`，不得由通知中心反向发明事实。
- 正式实现需要将 topic catalog 作为受控 seed/config 落地，并验证多副本 Worker 下的聚合唯一键、counter 重建和双 Outbox 恢复。
- 设计态 schema 不是 migration；任何数据库上线需要服务仓库单独设计迁移和回填。

## 已完成校验

- notification-center 与 SSE YAML 可解析，本地 OpenAPI `$ref` 和权限引用完整。
- Redocly 验证两个 OpenAPI 均有效；仅有仓库 HTTP 200 业务错误策略和缺 license 的预期 warning。
- S1 refs、错误码全局唯一、错误码区间、topic catalog 状态、SSE source event 链接和 Markdown 基础结构通过检查。

## 推荐下一任务

在服务端实现 `spec-v1.8.0` 的 ACTIVE notification topic、收件箱 API、计数、偏好、双 Outbox 和 SSE 投影；CONTRACT_GAP/FUTURE 保持禁用。

## Next Prompt

Read `docs/HANDOFF.md` and implement the released `spec-v1.8.0` in omnimam-server. Start with ACTIVE standalone AtomicTask and CanvasRun topics, NotificationEvent/Notification/counter/topic catalog persistence, inbox and preference APIs, Notification Outbox, and SSE projection. Keep every CONTRACT_GAP/FUTURE topic disabled and do not invent missing upstream facts.
