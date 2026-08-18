# Task Center Context

## 1. 领域职责

`task-center` 为应用、素材、画布和系统维护任务提供统一异步执行、组合编排、周期或单次调度、运行汇总与故障恢复。它对外提供稳定业务资源和状态投影，对内通过已注册 `WorkflowRuntime` 使用 Conductor OSS 的调度、自动重试和 Task Worker 分发能力；Infra-backed 操作由版本化 Function Registry 校验，再由 Task Worker 的 Infra Adapter 调用 infrastructure。

## 2. 核心对象

- `AtomicTask`：唯一真实异步执行单元，也是状态、进度、取消与重试事实源。
- `TaskAttempt`：AtomicTask 的一次自动执行尝试和外部任务恢复记录。
- `TaskGroup`：多个 AtomicTask 的 SERIAL 或 PARALLEL 组合及汇总。
- `DAGTaskGroup`：AtomicTask 节点和有向无环依赖组成的编排资源。
- `TaskSchedule`、`ScheduleExecution`：触发目标的计划与每次调度历史。
- `Function Registry`：14 个 Agent/AppStudio/Model Deployment canonical functionRef 的版本化 I/O、能力、策略、执行/Infra 映射、输出交付与结果投影合同。
- `gitlab.pipeline.run`：GitLab 领域拥有的非 Infra-backed 外部 handler，通过 external_job_id 和延迟回调恢复，不进入 Agent/AppStudio Infra Function Registry。
- AppStudio 可通过受信任的领域内部入口提交包含 `gitlab.pipeline.run` 的固定 DAG；公共 DAG API 继续禁止用户选择该内部 functionRef。
- `WorkflowRuntime`、`Task Worker`、`Infra Adapter`、`Agent Runtime Adapter`：内部运行时边界、已注册 handler 的执行者、Infra-backed 请求和 Agent Invocation 协议适配边界。

## 3. 核心规则

- AtomicTask 是唯一执行单元，不再区分任务定义与 TaskRun。
- TaskGroup、DAGTaskGroup 和 TaskSchedule 只组合或触发 AtomicTask，不能作为 Worker 任务。
- 上游可以把固定 count 的有限重复预先展开为静态无环 DAG；Task Center 不拥有运行时循环或 iteration 状态机。
- TaskAttempt 记录一次自动尝试；手动重试创建新的 AtomicTask，并保留来源关系。
- 幂等、权限、租户、业务摘要和状态投影由 Task Center 保证，Conductor 不是产品 API。
- `TaskRun`、`ExecutionLease`、Worker claim、自研 Dispatcher 和旧 DAG 状态机已废弃；Task Worker 不等于旧 Worker claim/lease 模型。
- ApplicationRun、CanvasRun 和素材处理状态是上层业务投影，不由任务终态替代。
- 任务结果只保存 Artifact 等小型引用，不保存媒体正文或其他领域私有数据。
- Infra-backed AtomicTask 创建前按精确 registry schema 校验，并固定 function contract version/digest；重试和恢复不得漂移到新版本。
- `agent.invocation.execute@1.0` 同时执行 CHAT/CODING，只接收稳定引用、Invocation 类型、短期授权引用、资源版本和恢复游标；Worker 按 Runtime Profile 使用 Hermes WebSocket JSON-RPC 或 OpenCode REST/SSE。CODING 成功前还必须校验 base Revision/CommitSHA 到 GitLab HEAD 恰好一个普通 fast-forward commit，并通过 AppStudio 幂等投影既有 ChangeSet/Revision；Worker 不拥有 Agent/AppStudio 业务状态。
- `appstudio.build.execute@1.1` 固定声明 Build 输出；Task Worker 从 Infra 鉴权流式读取实际字节，校验大小和 SHA-256，再按 `create -> upload -> complete -> attach` 完成 Artifact 交付。`infra-output://` 不是外部 URL，也不得进入 Task 结果。
- 自动 TaskAttempt 重试按 StudioBuild producer key 复用既有 Artifact；内容 digest 不一致时失败，不重复创建 Artifact。
- 可靠状态事件必须支持下游幂等消费，乱序事件不得回退较新投影。
- AppStudio 初始化读取固定四节点的状态、进度、Attempt、时间和安全错误；Task Center 保留完整历史，AppStudio 必须按 AtomicTask owner 与当前 DAG ID fence 迟到事件。

## 4. 领域边界

本领域拥有 AtomicTask、Attempt、Group/DAG、Schedule 及其执行状态。应用业务定义归 application-platform；画布图和编译语义归 workflow-canvas；Artifact、Asset 和 Representation 归 asset-library；通知已读和用户收件箱归 notification-center。

## 5. 上游与下游

上游是 application-platform、modelgateway、workflow-canvas、asset-library、agent、appstudio、gitlab 和系统维护模块提交的受控任务定义。Model Gateway 使用既有 system_key 注册 Engine 健康与 object-info ReconcileHandler；下游是 WorkflowRuntime/Task Worker/Infra Adapter 执行边界，以及消费任务事件的业务投影、notification-center、sse 和 infrastructure。Task Worker 执行业务 handler，但不拥有调用方的业务定义。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/task-center/product-spec.md` | S1 | 当前任务模型、编排、调度和恢复语义 |
| `01_contracts/domains/task-center/openapi.yaml` | S2 | 任务查询、动作和调度 API |
| `01_contracts/domains/task-center/schema.sql` | S2 | 设计态任务资源结构 |
| `01_contracts/domains/task-center/function-registry.schema.yaml` | S2 | Infra-backed Function Registry 文件结构 |
| `01_contracts/domains/task-center/function-registry.yaml` | S2 | 14 个 canonical functionRef、16 个版本合同条目的精确合同 |
| `01_contracts/domains/task-center/events.yaml` | S2 | 可靠任务事件合同 |
| `01_contracts/domains/task-center/module-contract.md` | S2 | Runtime 与跨域模块边界 |
| `02_architecture/domains/task-center.md` | 参考 | 编译、调度、恢复和数据所有权 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改任务状态、重试或取消 | S1 product-spec | 涉及接口时读 OpenAPI，涉及事件时读 events |
| 修改 functionRef、Task Worker 或 Infra Adapter | S1 product-spec | 必须读 function-registry、module-contract；涉及 Coding commit 同步时读 agent/appstudio/gitlab Context，涉及运行层再读 infrastructure Context |
| 修改 GitLab Pipeline handler | S1 product-spec | 继续读 gitlab Context 与 GitLab module-contract；不得加载 AppStudio |
| 修改 DAG 或 Schedule | S1 product-spec | 涉及运行时边界时读 module-contract/architecture |
| 修改 Application 执行 | 当前 Context | 再读 application-platform Context |
| 修改 Engine 健康或 object-info Schedule | 当前 Context | 再读 modelgateway Context |
| 修改任务输出素材 | 当前 Context | 再读 asset-library Context |

## 8. 当前状态

`spec-v1.0.0` 起的新任务模型已确定，Infra-backed `appstudio.build.execute@1.1` 已由 `spec-v1.17.2` 发布，`agent.invocation.execute@1.0` 及 Agent Runtime Adapter 已由后续 release 发布；Coding commit 终态同步与 Runtime Git access 由 `spec-v1.23.0` 发布；六个 Model Deployment Provider 专属合同与固定 DAG 由 `spec-v1.24.0` 发布。具体实现门禁以 `RELEASE.md` 为准，旧编号只保留审计追溯意义。

## 9. 不在本领域定义的内容

- Application、ApplicationRun 的业务语义不在本领域定义。
- CanvasVersion 的图结构和编译结果语义不在本领域定义。
- Artifact 内容处理、Asset 登记和 Representation 生命周期不在本领域定义。
- 通知规则、已读状态和 SSE 用户事件历史不在本领域定义。
