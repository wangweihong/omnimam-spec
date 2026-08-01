# Task Center Context

## 1. 领域职责

`task-center` 为应用、素材、画布和系统维护任务提供统一异步执行、组合编排、周期或单次调度、运行汇总与故障恢复。它对外提供稳定业务资源和状态投影，对内通过已注册 `WorkflowRuntime` 使用 Conductor OSS 的调度、自动重试和 Worker 分发能力。

## 2. 核心对象

- `AtomicTask`：唯一真实异步执行单元，也是状态、进度、取消与重试事实源。
- `TaskAttempt`：AtomicTask 的一次自动执行尝试和外部任务恢复记录。
- `TaskGroup`：多个 AtomicTask 的 SERIAL 或 PARALLEL 组合及汇总。
- `DAGTaskGroup`：AtomicTask 节点和有向无环依赖组成的编排资源。
- `TaskSchedule`、`ScheduleExecution`：触发目标的计划与每次调度历史。
- `WorkflowRuntime`、`Worker`：内部运行时边界和已注册 handler 的执行者。

## 3. 核心规则

- AtomicTask 是唯一执行单元，不再区分任务定义与 TaskRun。
- TaskGroup、DAGTaskGroup 和 TaskSchedule 只组合或触发 AtomicTask，不能作为 Worker 任务。
- TaskAttempt 记录一次自动尝试；手动重试创建新的 AtomicTask，并保留来源关系。
- 幂等、权限、租户、业务摘要和状态投影由 Task Center 保证，Conductor 不是产品 API。
- `TaskRun`、`ExecutionLease`、Worker claim、自研 Dispatcher 和旧 DAG 状态机已废弃。
- ApplicationRun、CanvasRun 和素材处理状态是上层业务投影，不由任务终态替代。
- 任务结果只保存 Artifact 等小型引用，不保存媒体正文或其他领域私有数据。
- 可靠状态事件必须支持下游幂等消费，乱序事件不得回退较新投影。

## 4. 领域边界

本领域拥有 AtomicTask、Attempt、Group/DAG、Schedule 及其执行状态。应用业务定义归 application-platform；画布图和编译语义归 workflow-canvas；Artifact、Asset 和 Representation 归 asset-library；通知已读和用户收件箱归 notification-center。

## 5. 上游与下游

上游是 application-platform、modelgateway、workflow-canvas、asset-library 和系统维护模块提交的受控任务定义。Model Gateway 使用既有 system_key 注册 Engine 健康与 object-info ReconcileHandler；下游是 WorkflowRuntime/Worker 执行边界，以及消费任务事件的业务投影、notification-center 和 sse。Worker 执行业务 handler，但不拥有调用方的业务定义。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/task-center/product-spec.md` | S1 | 当前任务模型、编排、调度和恢复语义 |
| `01_contracts/domains/task-center/openapi.yaml` | S2 | 任务查询、动作和调度 API |
| `01_contracts/domains/task-center/schema.sql` | S2 | 设计态任务资源结构 |
| `01_contracts/domains/task-center/events.yaml` | S2 | 可靠任务事件合同 |
| `01_contracts/domains/task-center/module-contract.md` | S2 | Runtime 与跨域模块边界 |
| `02_architecture/domains/task-center.md` | 参考 | 编译、调度、恢复和数据所有权 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改任务状态、重试或取消 | S1 product-spec | 涉及接口时读 OpenAPI，涉及事件时读 events |
| 修改 DAG 或 Schedule | S1 product-spec | 涉及运行时边界时读 module-contract/architecture |
| 修改 Application 执行 | 当前 Context | 再读 application-platform Context |
| 修改 Engine 健康或 object-info Schedule | 当前 Context | 再读 modelgateway Context |
| 修改任务输出素材 | 当前 Context | 再读 asset-library Context |

## 8. 当前状态

`spec-v1.0.0` 起的新任务模型已确定，后续 Schedule、关联摘要、画布与通知协作有增量发布并正在实施。具体实现门禁以 `RELEASE.md` 为准；旧编号只保留审计追溯意义。

## 9. 不在本领域定义的内容

- Application、ApplicationRun 的业务语义不在本领域定义。
- CanvasVersion 的图结构和编译结果语义不在本领域定义。
- Artifact 内容处理、Asset 登记和 Representation 生命周期不在本领域定义。
- 通知规则、已读状态和 SSE 用户事件历史不在本领域定义。
