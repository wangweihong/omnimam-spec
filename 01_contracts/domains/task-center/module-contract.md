# Task Center Module Contract

本文档定义 `task-center` 第一阶段 S2 模块边界。产品语义以 `00_product/domains/task-center/product-spec.md` 为准。

## 1. 模块边界

### definition

- 负责 AtomicTask、TaskGroup 和 DAGFlowTask 的定义管理。
- 负责校验 TaskGroup 只使用 `SERIAL` / `PARALLEL`，以及 DAGFlowTask 无环。
- 不负责具体业务能力执行，也不负责 ProviderAdapter 或 AppEngine 的能力封装。

### run

- 负责 TaskRun 创建、状态机推进、取消请求、重试请求、软删除和运行树查询。
- 负责保存 TaskRun 最近一次错误摘要、进度、输入和输出引用。
- 对 `application.execute` TaskRun 保存 `application_run_id`；使用 `application_run_id + idempotency_key` 保证重复创建请求返回同一 TaskRun。
- application.execute 的具体模板、能力来源、Engine 和输出映射从 ApplicationRun 快照读取，不依赖 `adapter_key`、`operation_key` 或 `operation_version` 路由。
- 不直接保存图片、视频、音频、长文本和日志等大型内容。

### worker-protocol

- 负责 Worker 注册、心跳、领取任务、创建 TaskAttempt、创建 ExecutionLease、续约 lease、进度上报、成功回写和失败回写。
- 负责校验 `worker_id`、`attempt_id`、`lease_id` 三者一致性。
- 不决定业务任务如何执行；Worker 调用 application-platform 注册的 ProviderAdapter，AppEngine 只提供实例配置。

### watchdog

- 负责扫描 Worker heartbeat 超时、TaskAttempt 单次超时、TaskRun 整体超时、ExecutionLease 过期和 RUNNING 长时间无进度。
- 负责将 Worker LOST、Lease EXPIRED、Attempt WORKER_LOST/TIMEOUT/STALLED 等异常写入任务事实。
- 不将所有异常直接标记为业务失败，必须按 RetryPolicy 和 TimeoutPolicy 判断。

### scheduler

- 负责为系统内部维护任务周期性创建计划执行的 TaskRun。
- 负责使用 `schedule_at` 表达计划开始时间，并沿用 TaskRun 生命周期、重试和失败处理规则。
- 可周期性创建 `application-platform.engine-health-plan` TaskRun，由应用平台枚举到期实例并建立 PARALLEL TaskGroup。
- 不解释业务任务执行语义；例如 `asset.sha256_backfill` 的扫描、读取、计算和写回由素材库负责。
- 不解释 ProviderAdapter 操作协议、AppEngine 认证配置、平台能力、平台连接和健康判断语义；这些由 application-platform 负责。

### access

- 负责项目、命名空间、创建人、Worker 协议调用方和运维角色的访问控制。
- 普通用户只能访问授权范围内的 TaskRun；运维角色可查看跨项目健康和异常摘要。

### task-group-runtime

- 创建 TaskGroup TaskRun 时原子展开根运行与子运行；组根由任务中心推进，不得被 Worker 领取。
- 支持静态 children 及调用领域提供的动态 `group_children`；动态引用必须属于定义白名单，最大嵌套深度 16，单树最多 10000 个运行。
- PARALLEL 按 `max_parallelism` 限制 CLAIMED/RUNNING 直接子运行；SERIAL 只释放当前子运行。
- 子运行进度和终态向父运行聚合；取消和组整体超时级联到未完成子运行。
- PARALLEL 默认 `FAILED_ONLY`，SERIAL 默认 `FROM_FAILED`；重试保留 TaskAttempt 历史。

## 2. 输入输出边界

| 模块 | 输入 | 输出 |
| --- | --- | --- |
| definition | 任务定义、组合策略、DAG 节点和边 | AtomicTask、TaskGroup、DAGFlowTask 定义 |
| run | 定义引用、运行输入、取消/重试请求 | TaskRun、运行树、状态、进度、结果引用 |
| worker-protocol | Worker 能力、领取请求、lease、进度、执行结果 | TaskAttempt、ExecutionLease、TaskRun 状态更新 |
| watchdog | Worker 心跳、lease 过期时间、任务超时策略 | 异常状态、watchdog 记录、恢复调度事件 |
| scheduler | 系统维护任务定义、固定周期、下一次计划时间 | 计划执行的 TaskRun |
| access | 当前用户、项目、命名空间、调用主体 | 可访问资源范围、权限拒绝 |

## 3. 依赖关系

- `run` 依赖 `definition` 校验任务定义存在且类型匹配。
- `worker-protocol` 依赖 `run` 获取 READY TaskRun 并推进状态。
- `worker-protocol` 调用 ProviderAdapter 执行具体业务能力；Adapter 和 AppEngine 都不属于任务中心。
- `watchdog` 依赖 `worker-protocol` 写入的 Worker、Attempt 和 Lease 状态。
- `scheduler` 依赖 `definition` 和 `run` 创建计划执行的 TaskRun。
- `application-platform` 可依赖 `scheduler` 周期性触发 `application-platform.engine-health-plan`，但 AppEngine 健康检测语义由 `application-platform` 自身解释。
- `asset-library` 可依赖 `scheduler` 周期性触发 `asset.sha256_backfill`，但业务执行语义由 `asset-library` 自身解释。
- `access` 被 `definition`、`run`、`worker-protocol`、`watchdog` 和 `scheduler` 调用。

## 4. 一致性要求

- 每次执行必须创建 TaskRun，每次 Worker 领取并执行必须创建新的 TaskAttempt。
- 同一个 TaskRun 同一时间只能有一个有效 ExecutionLease。
- 只有持有有效 lease 的 Worker 可以更新 TaskRun 进度、成功结果或失败结果。
- TaskAttempt 历史不得被覆盖；TaskRun 只保存最近一次错误摘要。
- TaskRun 的 resource_version 随状态、进度或结果变化递增，消费者必须按 run_id + resource_version 幂等投影。
- 应用运行 TaskRun 保存 adapter_key、operation_key、operation_version、requested_engine_id 和 resolved_engine_id 快照。
- TaskAttempt 已有 external_job_id 时，Worker 重试必须先调用 ProviderAdapter 恢复外部任务，不能直接重新提交。
- 取消请求发出后，最终状态允许为 `CANCELED`、`SUCCESS`、`FAILED` 或 `TIMEOUT`。
- `overallTimeout` 优先级高于重试策略；无限重试必须设置退出保护条件。
- 系统周期性调度创建的 TaskRun 必须遵循普通 TaskRun 生命周期，不绕过 Worker 领取、lease、进度和结果回写规则。
- `application-platform.engine-health-plan` 由应用平台执行器枚举到期实例，并创建 `application-platform.engine-health-group` PARALLEL TaskGroup；每个实例使用 `application-platform.engine-instance-health-check` 原子子任务。
- 软删除只允许作用于终态 TaskRun，且不得物理删除 TaskAttempt、状态历史和审计记录。

## 5. 权限边界

- `task.definition.manage` 控制任务定义管理。
- `task.run.operate` 控制 TaskRun 创建、读取、取消、重试和软删除。
- `task.worker.protocol` 仅授予 Worker 进程使用任务执行协议。
- `task.operation.admin` 控制跨项目健康查询、Worker 管理和异常排查。

## 6. 事件边界

- `run` 生产 `task_run_created` 和 `task_run_status_changed`。
- `worker-protocol` 生产 `task_run_progress_updated` 和 `task_attempt_failed`。
- application.execute 的创建、状态和进度事件必须携带 `application_run_id`；非应用 TaskRun 该字段为空。
- `watchdog` 生产 `worker_lost` 和 `lease_expired`。
- 第一阶段事件用于内部一致性、查询刷新、审计和运维监控，不定义 Webhook、消息队列、SSE 或 WebSocket 交付机制。

## 7. 非目标范围

- 不实现 ProviderAdapter 或 AppEngine 的具体业务能力封装。
- 不保存大型二进制结果内容。
- 不定义实际数据库 migration。
- 不定义 PAUSE / RESUME、复杂条件 DAG、循环 DAG、Webhook 订阅、跨项目共享 Worker 或自动拉起 GPU Worker。
