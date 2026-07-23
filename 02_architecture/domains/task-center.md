# 任务中心领域架构参考

## 1. 架构定位

Task Center 是业务任务唯一入口和投影事实源，Conductor OSS 是内部执行与编排运行时。Watermill 与 PostgreSQL outbox 连接素材上传等领域事件；其他领域不得直接依赖 Conductor API、数据库或 UI。

```mermaid
flowchart LR
  Producers["Application / Asset / Canvas"] --> API["Task Center API"]
  Producers --> Outbox["PostgreSQL Outbox"]
  Outbox --> API
  API --> DB["Task Center Projection DB"]
  API --> Runtime["WorkflowRuntime"]
  Runtime --> Reconcile["Fixed Reconcile Controller"]
  Reconcile --> Registry["ReconcileRegistry"]
  Runtime --> Conductor["Conductor OSS"]
  Conductor --> Workers["Go AtomicTask Workers"]
  Conductor --> Events["Runtime events"]
  Events --> Projector["Projector + Reconciler"]
  Projector --> DB
```

## 2. 核心组件

| 组件 | 职责 |
| --- | --- |
| AtomicTask service | 创建、查询、取消、手动重试和 Attempt 历史 |
| Orchestration service | 展开 Group/DAG、编译定义和聚合状态结果 |
| Schedule service | 双模式计划管理、ScheduleExecution、ScheduleReconcileState、活动锁与 retention |
| ReconcileRegistry | 注册受控巡检器、校验配置、路由轻量巡检与幂等修复动作 |
| Function registry | 将受控 functionRef 映射到 Worker handler 和 schema |
| Name catalog | 将稳定系统名称 key 和参数投影为 zh-CN、en-US 及后续 BCP 47 语言映射 |
| ConductorRuntime | 注册、启动、查询、取消、Schedule 和事件适配 |
| Projection consumer | 幂等消费运行时事件并推进业务投影 |
| Reconciler | 周期对账全部非终态执行并修复遗漏 |
| Task log proxy | 通过 WorkflowRuntime 写入和读取 Attempt 隔离日志，执行 Task Center 权限、脱敏、排序与分页 |
| DAG observability query | 聚合声明节点与实际 AtomicTask，生成权限裁剪的详情、事件和规范化时间线 |

## 3. 编译模型

- AtomicTask 编译为一个 SIMPLE task。
- SERIAL TaskGroup 编译为顺序 SIMPLE tasks。
- PARALLEL TaskGroup 编译为 Fork/Join，执行门禁限制 `max_parallelism`。
- DAGTaskGroup 按拓扑层编译，同层 Fork、层末 Join；动态节点使用 Dynamic Fork/Join。
- CanvasVersion 与 DAGTaskGroup 内容摘要形成不可变 workflow definition 名称和版本。
- ComfyUI 使用 `submit -> poll -> download_artifact`；poll 使用 callback/delay 并保存外部 job ID，下载结果受控交付 asset-library 并只向任务输出返回 artifact 引用。
- AssetVersion 首次派生使用 `asset-library.representation.build` DAG，周期缺口由 `asset-library.representation-backfill` RECONCILE 发现并创建单项 generate AtomicTask；Task Center 不决定媒体策略。
- ComfyUI WorkflowTestRun 使用 `submit -> poll -> collect_preview`；Worker 返回 `IN_PROGRESS + callbackAfterSeconds` 后由 Conductor 延迟重投同一 task，期间释放 Worker。

## 4. 调度模型

cron 由 Conductor Scheduler 触发，单次 `run_at` 由持久化 WAIT launcher 触发。Task Center 在每次触发入口先写唯一 ScheduleExecution 并获取 schedule 活动锁；存在非终态轮次时写 `SKIPPED_OVERLAP`。停机期间的历史周期不补发。

MATERIALIZED 轮次创建 AtomicTask、TaskGroup 或 DAGTaskGroup。RECONCILE 轮次固定使用可复用内部 definition `task_center_reconcile_controller` 版本 1，由控制 handler 读取 ScheduleReconcileState，调用 ReconcileRegistry，再事务更新轻量 execution、checkpoint、累计统计和 outbox。巡检返回的修复动作经 functionRef 与稳定幂等键校验后才能创建 AtomicTask。

调度触发创建的目标继承 TaskSchedule 的租户和创建者边界。查询 ScheduleExecution 时按 target type 批量读取实际目标并形成轻量摘要；查询全局 AtomicTask、TaskGroup 和 DAGTaskGroup 时通过 ScheduleExecution 批量反查来源计划。触发失败、重叠跳过或目标已不可用时使用计划模板摘要降级，不伪造目标资源。

Task Center 查询层同时负责同域关联摘要：AtomicTask root/retry 使用自关联批量读取，owner 按 TASK_GROUP、DAG_TASK_GROUP、TASK_SCHEDULE 分组读取；Attempt、Group/DAG retry 和 ScheduleExecution schedule 使用同样的批量方式。摘要只包含 ID、名称、类型、状态、进度等可读字段，不递归携带参数、节点、输出或运行时内部信息；所有批量读取继续受父资源的 project、namespace 和 createdBy 权限边界约束。

系统命名资源额外持久化名称来源、稳定 key 和受控字符串参数；原 `name` 保持 en-US 兼容值。查询层由 Name catalog 一次生成当前已登记的全部 BCP 47 语言，并将同一映射复制到资源本体与一跳摘要。用户名称和无系统 key 的历史资源不进入目录，避免根据文本或 createdBy 误判。

DAG 可观测查询层以声明 node key 对齐实际 AtomicTask：静态节点返回唯一主任务，动态节点返回确定性聚合并保留实际任务分页。用户事件和时间线从已有 `runtime_projection_events`、AtomicTask 与 TaskAttempt 投影按白名单生成，不复制运行时 payload，也不建立新的事件事实表。执行器快照只向运维权限返回稳定类型和显示名。

Artifact 摘要通过 asset-library 的受控批量接口按最多 200 项解析；Task Center 不访问素材私有表。不可见、已删除或不存在目标统一降级为空摘要，原始 artifact ID 始终保留。

RECONCILE 历史由 retention worker 按状态、数量与时长幂等清理；累计统计独立保存于 ScheduleReconcileState。WorkflowRuntime adapter 只删除超过 24 小时的终态 RECONCILE execution，不删除 MATERIALIZED 历史。

## 5. 恢复与一致性

- 业务创建、幂等记录和 outbox 同事务提交。
- 运行时启动使用稳定 correlation ID，可在 API 重启后重放而不产生重复执行。
- 自动重试增加 TaskAttempt；手动重试增加 AtomicTask 或新 Group/DAG。
- AtomicTask、TaskAttempt 和 Group/DAG 变化在业务事务中写可重放事件，携带 owner/project/namespace 和 `resource_version`；SSE 等投影消费者不直接依赖 Conductor 事件或 API。
- 投影仅接受更高运行时序列，业务 `resource_version` 单调递增。
- reconciler 对账非终态 execution，因此 Worker、Conductor、API 或消息消费者重启不依赖内存状态恢复。
- 运行时不可用时保留可恢复业务状态，不启用旧 Dispatcher 或双写旧 TaskRun。
- Worker 通过运行时绑定的 TaskLogger 向 Conductor runtime task 追加版本化日志；Task Center 以 Attempt ID 授权后代理读取。日志写入和读取失败不参与业务状态事务，运行时历史被清理后稳定返回日志不可用。

## 6. 数据所有权

Task Center 拥有 AtomicTask、Attempt、Group、DAG、Schedule、ScheduleExecution、ScheduleReconcileState、runtime binding 和 projection event。Conductor 拥有其 workflow/task/schedule 内部历史，并使用独立数据库或 schema。application-platform 拥有 ApplicationRun 与 Artifact 引用投影，asset-library 拥有 Artifact、Asset、AssetVersion 和 Representation，workflow-canvas 拥有 Canvas 版本和运行视图。

执行日志正文属于 Conductor 运行历史，TaskAttempt 只保存 `task-attempt-log:<attempt_id>` 稳定引用。该引用不暴露后端地址，并为未来替换 runtime 或增加归档保留业务标识兼容性。

## 7. 安全边界

Task Center 根据服务身份和用户权限解析 functionRef，拒绝用户提供的任意 HTTP、INLINE、脚本、Worker 名、凭证和内部运行时配置。所有列表、详情、取消和重试都应用 project/namespace/owner 过滤；内部运维访问也必须审计。
