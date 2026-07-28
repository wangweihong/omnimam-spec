# OmniMAM Spec Handoff

## 当前项目目标

发布 TaskSchedule 立即执行契约，并作为 Server/Web 实现依据。

## 本次完成

1. 新增 `US-TASK-025`、`BR-TASK-143..146`，明确立即执行、幂等、重叠和恢复语义。
2. 新增 `POST /api/v1/task-schedules/{task_schedule_id}/run`，返回完整 ScheduleExecution。
3. ScheduleExecution 增加 trigger_source、triggered_by、idempotency_key 与 MANUAL 部分唯一索引。
4. 扩展 schedule 权限、执行记录事件、模块契约和架构；不新增错误码或权限码。

## 文件变化

- `00_product/domains/task-center/product-spec.md`
- `01_contracts/domains/task-center/openapi.yaml`
- `01_contracts/domains/task-center/schema.sql`
- `01_contracts/domains/task-center/permissions.yaml`
- `01_contracts/domains/task-center/events.yaml`
- `01_contracts/domains/task-center/module-contract.md`
- `02_architecture/domains/task-center.md`
- `CHANGELOG.md`
- `RELEASE.md`
- `docs/HANDOFF.md`

## 关键设计决策

- 手动执行使用固定控制工作流，不在 HTTP goroutine 执行，也不调用运行时原生 scheduler run-now。
- ACTIVE/PAUSED 可运行，COMPLETED/DELETED 复用既有状态错误；SYSTEM 计划只允许系统管理员。
- 手动与周期触发共用单活动轮次约束；重叠必须形成 SKIPPED_OVERLAP 历史。

## API、Schema 与配置变化

- Task Center OpenAPI 1.5.0；新增立即执行端点和请求 DTO。
- ScheduleExecution schema/event 增加触发来源、操作者和手动幂等字段。
- `task.schedule.manage` 扩展 run action；无新权限码和错误码。

## 待办与风险

- 发布 `spec-v1.7.11` 后，omnimam-server 与 omnimam-web 必须更新 SSOT pin 并实现接口、Worker 控制流、UI 和恢复测试。

## 推荐下一任务

在 omnimam-server 和 omnimam-web pin `spec-v1.7.11`，实现并验证立即执行完整链路。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
