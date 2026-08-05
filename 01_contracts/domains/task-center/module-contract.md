# Task Center Module Contract

本文档定义当前 task-center S2 模块边界。产品语义以 `00_product/domains/task-center/product-spec.md` 为准；第一阶段 Infra-backed 函数结构以 `function-registry.schema.yaml` 为准，逐项合同以 `function-registry.yaml` 为准。

## 1. 模块边界

| 模块 | 拥有 | 不拥有 |
| --- | --- | --- |
| atomic-task | AtomicTask 创建、幂等、取消、手动重试、Attempt 查询 | Worker claim、Lease、业务函数实现 |
| orchestration | TaskGroup、DAGTaskGroup、子任务展开、状态/结果汇总、节点执行投影、规范化事件与时间线 | Group 嵌套、任意脚本、运行时 DAG 状态机 |
| schedule | TaskSchedule、ScheduleExecution、ScheduleReconcileState、暂停恢复、重叠门禁和历史保留 | cron 引擎、具体领域巡检实现 |
| reconcile-registry | 受控 reconcileRef、配置校验、轻量巡检路由和修复动作门禁 | 用户自定义代码、任意 Conductor 任务、具体领域数据归属 |
| runtime | WorkflowRuntime 接口、Conductor 适配、运行时 binding、事件投影和对账 | 对外业务 API、Conductor 数据库所有权 |
| function-registry | 可用 functionRef、输入输出 schema、能力要求、执行模式和 handler 路由 | 用户代码上传、HTTP/INLINE/脚本节点 |
| task-worker | 消费 AtomicTask、执行已注册 handler、管理 Attempt 级恢复、RuntimeOutput 字节交付和受控结果映射 | Agent/AppStudio/Infra 业务状态、Artifact ready 事实、业务数据库、Docker Provider 私有实现 |
| infra-adapter | 将 Infra-backed functionRef 转换为受控 Infra 请求与输出声明，映射取消/超时/重试、稳定运行引用和受控输出读取 | 任意用户命令、宿主机路径、Docker Socket、Provider 私有 API |
| name-catalog | 系统任务名称 key、受控参数校验和 BCP 47 多语言投影 | 翻译用户自定义名称、按请求语言改写持久化 name |
| access | project、namespace、createdBy 和服务身份访问控制 | identity 主体生命周期 |

## 2. WorkflowRuntime 消费方接口

Task Center 定义并消费 `WorkflowRuntime`，至少提供：

- 注册不可变 workflow definition，并以内容摘要避免同名版本漂移；
- 启动独立任务、Group、DAG 和持久化 WAIT launcher；
- 查询、取消执行并读取运行时任务、重试历史和按 runtime task 隔离的执行日志；
- 注册、暂停、恢复和删除 cron schedule；
- 消费状态事件，并枚举全部非终态 execution 供 reconciler 对账。
- 删除指定的终态 runtime execution，仅供 RECONCILE retention 使用。
- 通过受控日志写入器追加生命周期与业务进度日志，并按 runtime task ID 读取日志；写入失败不得改变 handler 结果。

首个生产实现是 `ConductorRuntime`，测试使用 fake。业务服务、前端和其他领域不得直接调用 Conductor API。

## 3. 执行与编排契约

- AtomicTask 是唯一 Worker handler 执行的业务资源；handler 按受控 `function_ref` 路由。
- SERIAL Group 编译为顺序 SIMPLE task；PARALLEL 编译为 Fork/Join，并应用 `max_parallelism` 门禁。
- DAGTaskGroup 发布前校验无环、key 唯一、引用完整和规模限制；普通节点编译为 SIMPLE，动态批量节点编译为 Dynamic Fork/Join。
- Workflow Canvas 可以提交按固定 count 预先展开的 serial、batch 或 cascade 静态节点；Task Center 只校验并执行展开后的无环依赖，不解析 Canvas loop 配置，也不维护 iteration 状态机。
- DAG 详情查询以声明节点为主键聚合实际 AtomicTask。`dag_node_key` 保存声明节点 key，静态节点使用唯一主任务，动态 fan-out 的全部实际任务共享该值；动态节点按活动优先和确定性终态优先级计算状态，并在摘要外保留按 node_key 分页读取实际任务的能力。
- DAG 触发来源在创建时保存 API/SCHEDULE/CANVAS/DOMAIN_EVENT/RETRY 类型、触发时间及可选来源 ID/名称快照；来源删除或不可见不回查改写历史。
- Group/DAG 创建时在一个业务事务中写根资源和全部静态 AtomicTask；运行时启动失败保留可恢复投影，不切换到本地 Dispatcher。
- 自动重试由运行时执行，但每次尝试必须投影为独立 TaskAttempt；手动重试创建新的业务资源。
- 外部异步 handler 必须持久化 `external_job_id` 并支持恢复；poll 使用延迟回调或等价非占用等待。
- Artifact 和 AssetRepresentation 内容事实归 asset-library。handler 输出只保存小型 `artifact_refs` 或 `representation_refs`，不得保存媒体正文、Provider 响应、凭证、任意 URL 或私网地址。
- Worker handler 获得始终非空的 TaskLogger，只能写 INFO、WARN、ERROR 生命周期或受控业务进度。运行时日志使用版本化 envelope；Task Center 读取时兼容纯文本历史、按时间与原始顺序稳定排序，并按生命周期 event key 去重。
- Task Worker 只能接收 Task Center 已校验的不可变 `arguments` 和 `function_ref`，不得从 Agent、AppStudio 或客户端直接接收 Infra 请求。
- Infra-backed `function_ref` 必须由 function-registry 声明 `execution_mode=JOB|SERVICE`、输入/输出 schema、required capabilities、幂等键、取消方式、超时边界和结果映射；首阶段只可路由到 DockerRuntimeProvider。
- Task Worker 对 Infra-backed handler 统一调用 `infra-adapter`。业务 handler 不得直接操作 Docker Socket、Provider 私有 API、宿主机路径、容器 ID、Host Port 或内部地址。
- `infra-adapter` 使用 Task Center 服务身份调用 Infra Service，并将结果限制为 `infra_runtime_id`、`endpoint_ref`、外部作业引用、Artifact/Workspace 受控引用和脱敏错误；原始日志、凭证、Provider 响应和大型正文不得进入 Task 输出。
- 对声明输出，Task Worker 必须调用 Infra 受控内容读取并流式传输，不得把 `infra-output://` 当作 bearer、文件路径或任意 URL。读取前后分别校验 RuntimeOutput/HTTP/实际流的 `size_bytes` 和 SHA-256；缺失、目录、符号链接逃逸、读取中断或摘要不一致均不得完成 ready Artifact。
- Task Worker 以原任务 producer context 和 `authorization_ref` 调用 Asset Library 既有 `create -> content upload -> complete`，再调用 Infra `attach-artifact`。只有 Asset Library 内容完成且 size/digest 一致时才能投影成功；Task 结果只保存 Artifact ID/digest，不保存 `content_ref`、`base_url` 或 staging 引用。
- 取消、超时、自动重试和 Worker/Infra 重启必须使用稳定幂等键与已保存的运行引用恢复或清理。`IN_PROGRESS` 通过延迟回调保持同一 Attempt，不长期占用 Worker，也不得重复创建 Docker Job/Service。以上 Infra-backed 规则对应 S1 `BR-TASK-147..152`。

### 3.1 Infra-backed Function Registry

`function-registry.yaml` 是第一阶段七个 canonical functionRef 的只读 S2 合同，不是运行时配置、数据库种子或用户可写资源：

| functionRef | 模式 | 来源领域 | 业务聚合 |
| --- | --- | --- | --- |
| `agent.runtime.ensure` | SERVICE | agent | AgentRuntime |
| `agent.runtime.stop` | SERVICE | agent | AgentRuntime |
| `appstudio.preview.ensure` | SERVICE | appstudio | StudioPreviewRuntime |
| `appstudio.preview.stop` | SERVICE | appstudio | StudioPreviewRuntime |
| `appstudio.build.execute` | JOB | appstudio | StudioBuild |
| `appstudio.production.reconcile` | SERVICE | appstudio | StudioRuntimeInstance |
| `appstudio.production.stop` | SERVICE | appstudio | StudioRuntimeInstance |

- 服务启动必须先用 `function-registry.schema.yaml` 校验 registry，确认 `function_ref + contract_version` 唯一、每个 functionRef 恰有一个 `ACTIVE` 版本、所有 I/O schema ref 可解析、引用的错误码存在且 retryable 属性一致；校验失败时 Task Center 不进入就绪状态。新任务只选择 `ACTIVE`，`RETAINED` 仅供历史任务，`DISABLED` 不允许创建或恢复执行。
- 创建 AtomicTask 时先校验调用服务身份与 `allowed_callers`，再按 input schema 校验 `arguments`。未注册或调用方不可用返回 `ERR_TASK_FUNCTION_REF_NOT_REGISTERED`，输入不合法返回 `ERR_TASK_FUNCTION_INPUT_INVALID`，两者都不得创建任务或调用 Infra。
- `required_capabilities`、执行模式、默认重试、取消、超时和 Infra Adapter 映射由固定合同派生；调用方不得提交 capability、修改 handler、扩大 RuntimeProfile、传入镜像/命令或覆盖 source policy。允许的 retry/timeout 覆盖不能超过合同上限。
- AtomicTask 保存 `function_contract_version` 和 registry 登记的规范化合同摘要，并保存派生后的 capabilities/retry/timeout/cancel 快照。摘要固定为 `sha256:<64 lowercase hex>`：对包含 `function_entry`、`input_schema`、`output_schema` 的对象执行 RFC 8785 JSON Canonicalization Scheme，其中 function entry 先将生命周期字段 `status` 规范化为 `ACTIVE`，再排除 `contract_digest` 和 `x-s1-refs`，I/O schema 使用已解析内容，最后计算 SHA-256。`status` 只控制新任务选择与历史恢复，不改变已发布合同摘要；启动加载和历史恢复都必须复算并比对登记值。服务必须保留所有非终态任务及历史保留期仍引用的 `ACTIVE/RETAINED` 合同，缺失或摘要不一致返回 `ERR_TASK_FUNCTION_CONTRACT_UNAVAILABLE`，不得回退到最新版本。
- Task Worker 只在满足固定 capability 集时接收任务；没有合格 Worker 返回可重试 `ERR_TASK_FUNCTION_CAPABILITY_UNAVAILABLE`。Worker 返回的 `TaskOutput.result` 必须按固定 output schema 校验，失败返回 `ERR_TASK_FUNCTION_OUTPUT_INVALID`，不得把不合法结果投影为业务成功。
- Task 级幂等键使用 registry 模板和内部 `retry_generation`；自动 Attempt 重试保持同一 AtomicTask。Infra `request_id` 固定为 `atomic_task_id:attempt_no`：同一 Attempt 的回调/超时恢复重放同一请求，确认失败后的新 Attempt 使用新 request ID，手动重试创建新 AtomicTask 和新 generation。
- `appstudio.build.execute@1.1` 是唯一在 Task Worker 内执行 Infra RuntimeOutput 到 Asset Library 内容交付的 ACTIVE 条目，固定声明 `bundle -> bundle.tar.gz -> application/gzip`，并要求 `infra.output.collect`、`infra.output.content.read` 能力。producer key 固定为 `studio-build:<studio_build_id>:bundle`；`1.0` 保留为 RETAINED，仅用于历史任务，原 digest 不得改写。
- 自动 TaskAttempt 重试必须先按 producer key查找并复用既有 Artifact：内容已完成且 digest 一致时直接复用并补偿 attach；内容未完成时继续同一 Artifact 上传会话；不同 digest 必须失败，不创建第二个 Artifact。新的逻辑 Build 通过新的 StudioBuild ID 获得新 producer key。
- 其他条目不得交付 Artifact。Artifact processing/ready 状态仍由 asset-library 拥有，AtomicTask 成功不代表 Artifact ready。
- 结果投影只能由 registry 的 `result_projection` 执行字段选择和状态 transform，再由来源领域消费 Task 结果更新自己的聚合；Task Worker、Task Center 和 Infra Adapter 都不得直接写 Agent/AppStudio 私表。
- Registry 没有公开 CRUD API、权限码或领域事件。修改 functionRef、I/O schema、能力、策略、映射或 transform 必须提升 `contract_version` 并重新生成规范化摘要；禁止原地改变同版本合同。

## 4. 调度与巡检契约

- MATERIALIZED TaskSchedule 只保存 AtomicTaskTemplate、TaskGroupTemplate 或 DAGTaskGroupTemplate，不得有 reconcile_spec。
- RECONCILE TaskSchedule 只保存已注册 reconcile_ref、受控 config、并发、单轮上限和两级超时，不得有 materialized target。
- cron 是六段表达式并要求 IANA 时区；单次 `run_at` 使用持久化 WAIT launcher。
- V1 `misfire_policy` 和 `overlap_policy` 固定为 `SKIP`。
- `POST /task-schedules/{id}/run` 要求计划内幂等键，可执行 ACTIVE 或 PAUSED 的 MATERIALIZED/RECONCILE 计划；SYSTEM 计划仅系统管理员可运行。COMPLETED/DELETED 使用既有状态阻止错误。
- 手动轮次先原子创建 `trigger_source=MANUAL` 的 ScheduleExecution；同一幂等键返回原记录，与任何活动轮次重叠则保存 `SKIPPED_OVERLAP`。手动 scheduled_at 使用请求接受时间且不得改变未来调度事实。
- 手动执行使用固定 `task_center_manual_schedule_controller` definition 和 ScheduleExecution ID 作为运行时稳定相关键；HTTP 请求不内联执行目标。Worker 按 execution_mode 复用 MATERIALIZED 物化或 RECONCILE 管线，运行时启动失败写 `TRIGGER_FAILED`。
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

- 系统命名资源持久化 `name_source=SYSTEM`、稳定 `system_name_key` 和小型 `system_name_params_json`；用户资源固定为 `USER` 且 key 为空。查询层通过 name-catalog 统一生成 `name_i18n`，并传递到 retry、owner、target、schedule source 和 timeline 摘要。公开请求不得设置系统名称元数据，旧数据默认 `USER` 且不作启发式回填。相关 S1：US-TASK-024、BR-TASK-142。
- Conductor 与业务表使用独立数据库或 schema，互不直接写入。
- 运行时事件按 `runtime_event_id` 幂等落入 `runtime_projection_events`；资源只接受更高 `runtime_sequence` 或确定性更强的终态。
- reconciler 周期枚举全部非终态 execution，修复漏事件、乱序和 API/运行时重启窗口。
- reconciler 同时恢复已接受但尚未绑定非终态运行时的 MANUAL execution；目标创建以 ScheduleExecution ID 派生稳定幂等键并在计划活动锁内执行，Worker/API/运行时重启不得重复物化目标。
- 状态、进度或结果变化递增 `resource_version`；消费者按资源 ID 与版本投影。
- 创建业务资源与 outbox 同事务提交；运行时启动使用可重放命令和稳定 correlation/idempotency key。
- AtomicTask、TaskAttempt、Group、DAG 和 MATERIALIZED ScheduleExecution 历史不得物理覆盖。RECONCILE 轻量历史可依契约物理清理，但 ScheduleReconcileState 累计统计不得回退。
- TaskAttempt 的 `logs_ref` 固定为 `task-attempt-log:<task_attempt_id>`，不携带运行时地址且不作为客户端可解析 URL。日志正文继续属于 WorkflowRuntime 历史，Task Center 只做受权代理；运行时历史清理后返回 `ERR_TASK_ATTEMPT_LOG_UNAVAILABLE`。
- Attempt 日志列表与下载共享同一读取管线，列表支持不透明 cursor 与前后方向，并统一应用关键字、级别、来源、排序、授权、脱敏和 retention；下载不能成为绕过日志不可用错误的旁路。
- DAG 用户事件和时间线从 `runtime_projection_events` 与任务/Attempt 投影规范化生成，不新增第二套运行历史表。事件只映射白名单字段；时间线按实际 AtomicTask 返回 DEPENDENCY_WAIT、QUEUE_WAIT、RUNNING、RETRY_WAIT，并以 `complete=false` 表达历史缺口。
- 已有 DAG 数据升级时必须以 `created_at` 回填缺失的 `triggered_at`，并依据可验证的 schedule/canvas/retry 关系回填 trigger type；无法证明来源时使用 API，不得猜测 source ID 或名称。
- AtomicTask 创建/状态、TaskAttempt 状态与 TaskGroup/DAGTaskGroup 汇总变化分别发布可重放事件；事件带 `created_by`、`project_id`、`namespace`、`resource_version` 和 correlation，供 SSE 等投影消费者按所有者路由并幂等处理。相关 S1：US-TASK-018、BR-TASK-120。

## 6. 跨域协作

- Agent 和 AppStudio 只能创建带业务授权快照的 AtomicTask；Infra 操作统一经过 `Task Center -> Task Worker -> infra-adapter -> Infra Service`。Task Center 不把 Agent/AppStudio 的任务输入直接透传为 Docker 请求。
- Agent 的 `agent.runtime.*` 与 AppStudio 的 `appstudio.preview.*`、`appstudio.build.*`、`appstudio.production.*` 只是受控 functionRef 注册项。AgentRuntime、StudioPreviewRuntime、StudioBuild 和 StudioRuntimeInstance 的业务投影仍由来源领域拥有，InfraRuntime 由 infrastructure 拥有。
- Task Worker 依据来源领域提供的授权引用生成 Infra `source_ref`：AgentWorkspace 只能由 agent 的授权绑定产生；StudioWorkspace 只能由 AppStudio 的受控授权产生；Preview 使用当前 Workspace Revision；Build 使用固定 Snapshot；Production 使用固定 Artifact。
- `appstudio.build.execute@1.1` 将 registry 固定输出声明映射为 Infra `output_declarations`。Job 成功后先消费 RuntimeOutput descriptor，再鉴权流式读取字节并完成 Asset Library Artifact 内容，最后幂等回链 RuntimeOutput；Task Center 不缓存 staging 内容或把 `infra-output://` 暴露给来源领域。

- 独立应用运行由 application-platform 创建 `application-platform.run` AtomicTask；Canvas Application 节点由 Workflow Canvas 创建 DAG 内同名 AtomicTask，Application Platform 只能通过受控绑定接口把 ApplicationRun 绑定到该现有任务，不得创建第二个任务。
- DAG Worker 输入中的 `arguments` 是 Conductor 已解析 `input_mapping` 与上游输出后的最终参数。Task Center 绑定 ApplicationRun 时持久化该快照，并校验 AtomicTask、CanvasRun、CanvasNodeRun 和 execution key 不漂移。
- SSE 领域消费 Task Center 可靠事件，建立当前用户的短期可重放投影；SSE 不得成为任务事实源，也不得直接消费 Conductor 原生事件。
- asset-library 在上传或 Artifact 登记事务写 `asset_version_representation_requested`；task-center 按 `asset-representations:<asset_version_id>:<profile_version>` 幂等创建 Representation build DAGTaskGroup。
- asset-library 在 Artifact 内容完成事务写 `artifact_content_completed`；task-center 按 `artifact-process:<artifact_id>:<processing_profile_version>` 幂等创建 `asset-library.artifact.process` AtomicTask。
- Task Center 按请求批次调用 asset-library 的 Artifact 可读摘要能力，为 `artifact_refs` 填充权限裁剪的一跳摘要；每批最多 200 项，目标不存在、已删除或不可见时保留 ID 并返回空摘要，禁止穿透 asset-library 私有表。
- build DAG 只能使用 asset-library 提供的计划和已注册 `asset-library.representation.*` functionRef；生成节点使用稳定 `representation_type + profile` childKey，只返回 Representation/Blob 引用。
- asset-library 注册 `asset-library.representation-backfill` ReconcileHandler。Task Center 以同名 system_key 原子确保唯一 SYSTEM RECONCILE 计划，默认 `03:30 UTC`，只为缺失、可重试或可重建项创建 `asset-library.representation.generate` AtomicTask。
- application-platform 注册 `application-platform.engine-health` ReconcileHandler。其 SYSTEM TaskSchedule 直接分批探测 EngineInstance，不创建 Planner DAGTaskGroup 或健康 AtomicTask；状态变化由 application-platform 在同一事务中更新投影并写 outbox。
- workflow-canvas 发布 CanvasVersion 后注册不可变 DAG 定义；CanvasRun 绑定 `dag_task_group_id`，CanvasNodeRun 绑定 `atomic_task_id`。
- workflow-canvas 的有限 loop 使用多个稳定 childKey AtomicTask 绑定同一 CanvasNodeRun；Task Center 保留每个任务的独立状态和输出，不生成额外 Group 或 aggregate task。
- 大型输出由受信 Worker/ApplicationExecutor 交付 asset-library 形成 Artifact；Task Center 只保存引用。自动 Attempt 重试复用同一 producer key，手动重试创建新 AtomicTask 并可形成新 Artifact。
- ComfyUIWorkflowTestRun 创建 `comfyui.submit -> comfyui.poll -> comfyui.collect_preview` DAG；poll handler 可返回 IN_PROGRESS 和 callbackAfterSeconds，延迟回调属于同一 Attempt。

## 7. 安全与限制

- 所有业务资源按 `project_id`、`namespace`、`created_by` 和授权关系隔离。
- Attempt 日志查询必须先复用 AtomicTask 可见性，再验证 Attempt 属于该任务；不得凭 runtime task ID 绕过业务授权。
- TaskAttempt executor 摘要只在同时通过任务可见性和 `task.operation.admin` 校验时返回，且只含稳定类型与显示名；普通响应不得暴露 Worker ID、队列、主机或地址。
- 关联摘要查询必须复用父资源已验证的 project、namespace、created_by 与授权边界；内部批量 store 方法不能成为绕过 service 权限返回完整资源的入口。
- 调度目标的访问边界继承来源 Schedule；历史数据中错误落为系统身份的目标必须按 ScheduleExecution 关系幂等修复，空 target_id 不做推断。
- 用户输入只能选择已注册 functionRef，不得传入 Worker 名、Conductor task type、任意 HTTP、INLINE、脚本、凭证或内部 endpoint。
- 默认最多 1000 个节点、5000 条边、单次 Dynamic Fork 1000 个子任务；服务可配置更低限制，不得静默提高全局上限。
- Conductor UI 和 API 只供内部运维，且不能替代 Task Center 权限、审计和租户隔离。
- 日志消息在 Worker 写入和 Task Center 读取边界双重脱敏并限制为 4096 字节；禁止自动捕获全局进程日志，禁止记录鉴权信息、凭证、Provider 原始响应、任意 URL、文件路径或大型正文。
- 普通 Task Worker 结果不得暴露 Docker container ID、Host Port、节点、宿主机路径或 Provider runtime ID；`endpoint_ref` 只能由来源领域按其授权和展示规则投影。
- 巡检指标固定包含 `reconcile_runs_total{ref,status}`、`reconcile_scanned_total{ref}`、`reconcile_findings_total{ref}`、`reconcile_actions_total{ref}`、`reconcile_duration_seconds{ref}`、`reconcile_checkpoint_age_seconds{ref}`、`reconcile_overlap_skipped_total{ref}` 和 `reconcile_retention_failures_total{backend}`。label 不得包含 schedule ID、engine ID 等无界值。

执行日志与 DAG 可观测详情相关 S1：US-TASK-022..023、BR-TASK-129..141。

## 8. 废弃路径

`TaskRun`、`TaskDefinition`、`ExecutionLease`、Worker claim/heartbeat 协议、自研 Dispatcher、watchdog 和自研 DAG 调度状态机均为历史只读概念。新实现不得创建对应资源、表、接口或事件；迁移完成后的旧终态数据仅可通过归档查询读取。
