# OmniMAM Spec Handoff

## 当前项目目标

以 `spec-v1.7.1` 发布 Task Center 运行中执行日志契约，使 Server 能在不暴露 Conductor 的前提下提供受权、脱敏、分页的 TaskAttempt 日志。

## 本次完成

1. 新增 `US-TASK-022`、`BR-TASK-129..132` 和四项验收标准。
2. Task Center OpenAPI 升级到 1.2.0，增加 Attempt 日志分页接口与 DTO。
3. 新增 `ERR_TASK_ATTEMPT_LOG_UNAVAILABLE`，复用 `task.atomic.operate` 权限并扩展 runtime 内部权限追溯。
4. 明确 `logs_ref=task-attempt-log:<attempt_id>`、Conductor 正文所有权、双重脱敏、4096 字节上限、生命周期去重和 best-effort 写入。
5. 保持 task-center schema 无新表、新列，events 无新事件；只补充现有 `task_attempts.logs_ref` 的 S1 追溯。
6. 更新 Task Center 模块契约、领域架构和 CHANGELOG；规格变更 commit 为 `865741c`。
7. 用户于 2026-07-22 明确要求实施并发布 `spec-v1.7.1`，允许作为正式实现依据。

## 文件变化

- 修改 Task Center S1、OpenAPI、schema、errors、permissions、module contract 和领域架构。
- 修改 `CHANGELOG.md`、`RELEASE.md` 和 `docs/HANDOFF.md`。
- 用户原有 `AGENTS.md` 修改保持不变且未纳入本任务提交。

## 关键设计决策

- 日志正文由 Conductor runtime task 保存，Task Center 只保留稳定引用并代理读取。
- 客户端只使用 Task Center API 轮询，不直接访问 Conductor，也不通过用户 SSE 传输高频日志。
- Worker 记录统一生命周期和受控业务进度，不捕获全局进程日志。
- 日志写入失败不改变任务状态；读取失败不能伪装为空列表。
- 历史可用期跟随 Conductor retention，不在 V1 增加独立归档。

## API、Schema 与配置变化

- 新增 `GET /api/v1/atomic-tasks/{atomic_task_id}/attempts/{task_attempt_id}/logs`。
- 响应包含 `sequence/source/level/message/occurred_at`，默认 page size 100、最大 200、稳定升序。
- 新增错误码 `141002 / ERR_TASK_ATTEMPT_LOG_UNAVAILABLE`。
- 无新表、无新事件、无新权限码、无运行时配置。

## 验证结果

- Task Center OpenAPI、errors 和 permissions 通过 yq 解析。
- OpenAPI 与错误/权限追溯引用存在性检查通过。
- 全局错误码 value/code 唯一性检查通过。
- `git diff --check` 通过。

## 待办与风险

- Server 尚需 pin `spec-v1.7.1` 并实现 WorkflowRuntime、Worker、Task Center API、投影、脱敏、指标和历史回填。
- Conductor runtime task 历史清理后日志不可恢复，这是 V1 明确接受的边界。
- Web 仓库尚未实现日志面板；当前 release 只定义服务端契约。

## 推荐下一任务

在 `omnimam-server` 中 pin `spec-v1.7.1`，按 release implementation gate 完成 TaskAttempt 日志端到端实现和测试。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
