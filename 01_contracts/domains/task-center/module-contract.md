# Task Center Module Contract

本文档定义 `spec-v1.0.0` 的 task-center S2 模块边界。产品语义以 `00_product/domains/task-center/product-spec.md` 为准。

## 1. 模块边界

| 模块 | 拥有 | 不拥有 |
| --- | --- | --- |
| atomic-task | AtomicTask 创建、幂等、取消、手动重试、Attempt 查询 | Worker claim、Lease、业务函数实现 |
| orchestration | TaskGroup、DAGTaskGroup、子任务展开、状态和结果汇总 | Group 嵌套、任意脚本、运行时 DAG 状态机 |
| schedule | TaskSchedule、ScheduleExecution、ScheduleReconcileState、暂停恢复、重叠门禁和历史保留 | cron 引擎、具体领域巡检实现 |
| reconcile-registry | 受控 reconcileRef、配置校验、轻量巡检路由和修复动作门禁 | 用户自定义代码、任意 Conductor 任务、具体领域数据归属 |
| runtime | WorkflowRuntime 接口、Conductor 适配、运行时 binding、事件投影和对账 | 对外业务 API、Conductor 数据库所有权 |
| function-registry | 可用 functionRef、输入输出 schema、能力要求和 handler 路由 | 用户代码上传、HTTP/INLINE/脚本节点 |
| access | project、namespace、createdBy 和服务身份访问控制 | identity 主体生命周期 |

## 2. WorkflowRuntime 消费方接口

Task Center 定义并消费 `WorkflowRuntime`，至少提供：

- 注册不可变 workflow definition，并以内容摘要避免同名版本漂移；
- 启动独立任务、Group、DAG 和持久化 WAIT launcher；
- 查询、取消执行并读取运行时任务和重试历史；
- 注册、暂停、恢复和删除 cron schedule；
- 消费状态事件，并枚举全部非终态 execution 供 reconciler 对账。
- 删除指定的终态 runtime execution，仅供 RECONCILE retention 使用。

首个生产实现是 `ConductorRuntime`，测试使用 fake。业务服务、前端和其他领域不得直接调用 Conductor API。

## 3. 执行与编排契约

- AtomicTask 是唯一 Worker handler 执行的业务资源；handler 按受控 `function_ref` 路由。
- SERIAL Group 编译为顺序 SIMPLE task；PARALLEL 编译为 Fork/Join，并应用 `max_parallelism` 门禁。
- DAGTaskGroup 发布前校验无环、key 唯一、引用完整和规模限制；普通节点编译为 SIMPLE，动态批量节点编译为 Dynamic Fork/Join。
- Group/DAG 创建时在一个业务事务中写根资源和全部静态 AtomicTask；运行时启动失败保留可恢复投影，不切换到本地 Dispatcher。
- 自动重试由运行时执行，但每次尝试必须投影为独立 TaskAttempt；手动重试创建新的业务资源。
- 外部异步 handler 必须持久化 `external_job_id` 并支持恢复；poll 使用延迟回调或等价非占用等待。
- Artifact 和 AssetRepresentation 内容事实归 asset-library。handler 输出只保存小型 `artifact_refs` 或 `representation_refs`，不得保存媒体正文、Provider 响应、凭证、任意 URL 或私网地址。

## 4. 调度与巡检契约

- MATERIALIZED TaskSchedule 只保存 AtomicTaskTemplate、TaskGroupTemplate 或 DAGTaskGroupTemplate，不得有 reconcile_spec。
- RECONCILE TaskSchedule 只保存已注册 reconcile_ref、受控 config、并发、单轮上限和两级超时，不得有 materialized target。
- cron 是六段表达式并要求 IANA 时区；单次 `run_at` 使用持久化 WAIT launcher。
- V1 `misfire_policy` 和 `overlap_policy` 固定为 `SKIP`。
- 每个 `schedule_id + scheduled_at` 先创建唯一 ScheduleExecution，再由活动锁判断是否启动目标。
- Schedule 触发创建的目标继承 Schedule 的 project、namespace 和 createdBy；直接 AtomicTask 目标使用 TASK_SCHEDULE owner 关系，Group/DAG 通过 ScheduleExecution 关联。
- Group/DAG 内部 childKey 在所属组合中唯一；周期 Schedule 每轮可复用模板 key，轮次唯一性由 ScheduleExecution 保证，不对 TASK_SCHEDULE owner 应用 owner/childKey 唯一索引。
- 前一执行非终态时，本轮写 `SKIPPED_OVERLAP`，不得创建目标资源。
- 暂停、恢复和软删除只影响未来触发，不取消已启动目标。
- Schedule 与执行历史查询批量补充轻量目标摘要；全局任务与组合列表批量补充来源计划摘要，禁止逐行访问目标形成 N+1 查询。
- AtomicTask 列表和详情按 ID 批量补充 root/retry AtomicTask 摘要，并按 owner_type 分组补充 TaskGroup、DAGTaskGroup 或 TaskSchedule 摘要；TaskAttempt、Group/DAG retry 来源和 ScheduleExecution 所属计划使用相同的一跳摘要规则。目标缺失或不可见时摘要为空，原始 ID 保留。
- ReconcileRegistry 消费方契约为 `Ref()`、`ValidateConfig(config)` 和 `Reconcile(ctx, request) -> result`。request 包含 schedule ID、scheduledAt、checkpoint、config、并发、单轮上限和两级超时；result 包含 nextCheckpoint、cycleCompleted、scanned、findings、deferred、actions 和 summary。
- `actions[]` 只能包含已注册 functionRef 的 AtomicTaskCreateRequest，每项必须带稳定幂等键；Task Center 统一校验和创建，巡检器不得构造任意 Conductor 任务。
- checkpoint 以稳定 ID 为游标，按 max_parallelism 分块且只在整块完成后推进。ScheduleReconcileState 与当轮 execution 在同一业务事务中更新。
- 内部控制 handler 固定使用可复用 workflow definition `task_center_reconcile_controller` 版本 1；禁止按 schedule execution ID 注册新 definition。
- SYSTEM 计划通过非空唯一 system_key 原子确保，启动时只补缺失计划，不覆盖管理员已保存的 cron、时区和运行参数。
- retention worker 幂等保留所有非终态、最近 4 次成功、最近 4 次 SKIPPED_OVERLAP、最近 20 次且 7 天内的失败和 TRIGGER_FAILED；Conductor 终态 RECONCILE execution 默认保留 24 小时，不触碰 MATERIALIZED execution。

## 5. 投影与一致性

- Conductor 与业务表使用独立数据库或 schema，互不直接写入。
- 运行时事件按 `runtime_event_id` 幂等落入 `runtime_projection_events`；资源只接受更高 `runtime_sequence` 或确定性更强的终态。
- reconciler 周期枚举全部非终态 execution，修复漏事件、乱序和 API/运行时重启窗口。
- 状态、进度或结果变化递增 `resource_version`；消费者按资源 ID 与版本投影。
- 创建业务资源与 outbox 同事务提交；运行时启动使用可重放命令和稳定 correlation/idempotency key。
- AtomicTask、TaskAttempt、Group、DAG 和 MATERIALIZED ScheduleExecution 历史不得物理覆盖。RECONCILE 轻量历史可依契约物理清理，但 ScheduleReconcileState 累计统计不得回退。
- AtomicTask 创建/状态、TaskAttempt 状态与 TaskGroup/DAGTaskGroup 汇总变化分别发布可重放事件；事件带 `created_by`、`project_id`、`namespace`、`resource_version` 和 correlation，供 SSE 等投影消费者按所有者路由并幂等处理。相关 S1：US-TASK-018、BR-TASK-120。

## 6. 跨域协作

- application-platform 创建 `application.execute` AtomicTask，并在 ApplicationRun 保存 `atomic_task_id` 与只读状态投影。
- SSE 领域消费 Task Center 可靠事件，建立当前用户的短期可重放投影；SSE 不得成为任务事实源，也不得直接消费 Conductor 原生事件。
- asset-library 在上传或 Artifact 登记事务写 `asset_version_representation_requested`；task-center 按 `asset-representations:<asset_version_id>:<profile_version>` 幂等创建 Representation build DAGTaskGroup。
- asset-library 在 Artifact 内容完成事务写 `artifact_content_completed`；task-center 按 `artifact-process:<artifact_id>:<processing_profile_version>` 幂等创建 `asset-library.artifact.process` AtomicTask。
- build DAG 只能使用 asset-library 提供的计划和已注册 `asset-library.representation.*` functionRef；生成节点使用稳定 `representation_type + profile` childKey，只返回 Representation/Blob 引用。
- asset-library 注册 `asset-library.representation-backfill` ReconcileHandler。Task Center 以同名 system_key 原子确保唯一 SYSTEM RECONCILE 计划，默认 `03:30 UTC`，只为缺失、可重试或可重建项创建 `asset-library.representation.generate` AtomicTask。
- application-platform 注册 `application-platform.engine-health` ReconcileHandler。其 SYSTEM TaskSchedule 直接分批探测 EngineInstance，不创建 Planner DAGTaskGroup 或健康 AtomicTask；状态变化由 application-platform 在同一事务中更新投影并写 outbox。
- workflow-canvas 发布 CanvasVersion 后注册不可变 DAG 定义；CanvasRun 绑定 `dag_task_group_id`，CanvasNodeRun 绑定 `atomic_task_id`。
- 大型输出由受信 Worker/ApplicationExecutor 交付 asset-library 形成 Artifact；Task Center 只保存引用。自动 Attempt 重试复用同一 producer key，手动重试创建新 AtomicTask 并可形成新 Artifact。
- ComfyUIWorkflowTestRun 创建 `comfyui.submit -> comfyui.poll -> comfyui.collect_preview` DAG；poll handler 可返回 IN_PROGRESS 和 callbackAfterSeconds，延迟回调属于同一 Attempt。

## 7. 安全与限制

- 所有业务资源按 `project_id`、`namespace`、`created_by` 和授权关系隔离。
- 关联摘要查询必须复用父资源已验证的 project、namespace、created_by 与授权边界；内部批量 store 方法不能成为绕过 service 权限返回完整资源的入口。
- 调度目标的访问边界继承来源 Schedule；历史数据中错误落为系统身份的目标必须按 ScheduleExecution 关系幂等修复，空 target_id 不做推断。
- 用户输入只能选择已注册 functionRef，不得传入 Worker 名、Conductor task type、任意 HTTP、INLINE、脚本、凭证或内部 endpoint。
- 默认最多 1000 个节点、5000 条边、单次 Dynamic Fork 1000 个子任务；服务可配置更低限制，不得静默提高全局上限。
- Conductor UI 和 API 只供内部运维，且不能替代 Task Center 权限、审计和租户隔离。
- 巡检指标固定包含 `reconcile_runs_total{ref,status}`、`reconcile_scanned_total{ref}`、`reconcile_findings_total{ref}`、`reconcile_actions_total{ref}`、`reconcile_duration_seconds{ref}`、`reconcile_checkpoint_age_seconds{ref}`、`reconcile_overlap_skipped_total{ref}` 和 `reconcile_retention_failures_total{backend}`。label 不得包含 schedule ID、engine ID 等无界值。

## 8. 废弃路径

`TaskRun`、`TaskDefinition`、`ExecutionLease`、Worker claim/heartbeat 协议、自研 Dispatcher、watchdog 和自研 DAG 调度状态机均为历史只读概念。新实现不得创建对应资源、表、接口或事件；迁移完成后的旧终态数据仅可通过归档查询读取。
