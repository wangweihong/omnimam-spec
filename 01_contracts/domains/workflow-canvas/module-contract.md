# Workflow Canvas Module Contract

产品语义以 `00_product/domains/workflow-canvas/product-spec.md` 为准。本契约覆盖 S1 首期范围；`selected_subgraph`、容错 Join、流级/分片级取消与分片手动重跑未开放。

## 1. 模块边界

| 模块 | 拥有 | 不拥有 | S1 引用 |
| --- | --- | --- | --- |
| node-definition | 受控 NodeDefinition 固定版本、端口、配置/控制状态 schema、renderer 标识和执行绑定 | 前端代码、Worker、Provider endpoint、凭证、ApplicationVersion 或 functionRef 实现 | BR-WORKFLOW-003..005、017、029..031；US-WORKFLOW-001、007、009 |
| canvas | Canvas 元数据、草稿图、draft revision、可见性和软删除 | 已发布版本修改、运行状态、Artifact 正文 | BR-WORKFLOW-001、012、015、029、031、034；US-WORKFLOW-001、004、007、009 |
| version | 原子发布校验、NodeDefinition 摘要、不可变 CanvasVersion、内容摘要与完整 DAG template | Task Center 私有定义表、可变节点定义或运行输入 | BR-WORKFLOW-002..004、011、017、018；US-WORKFLOW-001 |
| compiler | scope 裁剪、输入闭包、执行指纹、共享执行实例去重、复用决策和展平 ExecutionPlan | Group 嵌套、自研调度、任意运行时 task type | BR-WORKFLOW-006..010、018..021、028、033；US-WORKFLOW-002、003、005 |
| run | CanvasRun、CanvasFlowRun、CanvasNodeRun、幂等启动、整次取消、手动重跑和运行快照 | AtomicTask/Attempt/DAGTaskGroup 状态机、自动重试、Artifact 生命周期 | BR-WORKFLOW-006..009、013、020..023、026..027、032..034；US-WORKFLOW-002..006、008 |
| projection | NodeRun 1:N 任务绑定、输出绑定、Task/Artifact 单调投影、Canvas outbox 和对账游标 | 修改 Task Center 或 Asset Library 事实、伪造跨域终态 | BR-WORKFLOW-008、014、022..025、034；US-WORKFLOW-002..006 |
| access | owner、project、namespace、createdBy、visibility、权限码和配额边界 | identity 主体生命周期、跨域私有表 | BR-WORKFLOW-004、021、029、031；US-WORKFLOW-009 |

## 2. NodeDefinition 与草稿契约

- NodeDefinition 只能由系统或 `workflow.node_definition.manage` 主体创建新固定版本或标记下线；历史版本不得原地改写。
- `renderer_key` 只是已注册前端能力标识；无法识别时降级为通用配置视图，不能执行定义携带的代码。
- `execution_mode=passive` 不创建 AtomicTask；`atomic` 和 `expanded` 必须固定一个受控 functionRef 或已发布 ApplicationVersion，不能同时提交两者。
- Canvas 草稿保存完整节点实例、稳定端口 key、独立 Edge、FlowDefinition、ControllerState、分组和视口；运行状态和大型制品不进入草稿 JSON。
- 所有更新携带 `expected_draft_revision`。revision 冲突返回当前 revision，不静默覆盖本地未提交编辑。
- ControllerState 必须匹配固定 schema version、坐标系、引用权限和大小限制；预览 URL、任意 URL、文件路径、凭证和大型二进制不得进入状态。

## 3. 发布契约

- 发布事务重新校验 revision、节点定义、端口、类型、基数、流、外部引用权限、输入映射、数据边与控制边联合无环以及 1000 节点/5000 边上限。
- 发布编译生成规范化的完整 DAGTaskGroup template。只有 AtomicTaskTemplate 可执行；流、Data/Viewer、并发和复合节点不得形成 Group 嵌套。
- workflow definition 名称与版本由 Canvas 内容摘要确定。相同摘要重复发布或注册后保存中断时幂等恢复，不生成漂移定义。
- Task Center/WorkflowRuntime 注册成功后才能持久化 CanvasVersion；任一步失败均不形成部分可用版本。
- CanvasVersion 冻结图、显式/自动流边界、NodeDefinition/ApplicationVersion/functionRef 摘要、输入输出契约和编译摘要，发布后不支持 PATCH 或 DELETE。

## 4. 运行编译契约

- 首期 `scope.mode` 只接受 `all`、`flows`、`only_nodes`、`until_nodes` 和 `from_nodes`；`selected_subgraph` 返回 `ERR_CANVAS_PHASE_CAPABILITY_UNSUPPORTED`。
- 输入解析顺序固定为当前运行绑定上游输出、`runtime_inputs`、节点字面量、定义默认值。任务创建前必须完成每个必需端口的输入闭包校验。
- 复用策略只接受 `rerun_all`、`reuse_valid_outputs` 和 `reuse_required`。复用必须验证执行指纹、来源终态、必需输出、Artifact 可用性、当前权限、TTL 和副作用策略。
- `REUSED` NodeRun 保存来源运行、来源 NodeRun 和输出绑定，不创建伪造 AtomicTask；`passive` 与 `client_generated` 也可以没有 AtomicTask。
- 同一 CanvasRun 内共享节点只有在执行指纹、依赖来源和策略完全相同时共享同一 `execution_key`；FlowRun 通过引用表共同聚合该 NodeRun。
- 首期 fan-out 失败策略只支持 `all_success`，静态分片使用稳定 `shard_key`；动态展开不得超过声明上限与系统上限的较小值。
- ExecutionPlan 必须包含唯一 DAGTaskGroup、展平 AtomicTask 节点、依赖边、稳定 child key、FlowRun/NodeRun 绑定、复用决策、规模与摘要；不得包含 HTTP/INLINE、脚本、Worker、凭证或运行时私有配置。

## 5. 启动、取消与重跑

- 创建 CanvasRun 先持久化固定版本、输入、scope、策略、请求摘要和 ExecutionPlan，再以稳定命令创建唯一 DAGTaskGroup。
- `project_id + namespace + created_by + idempotency_key` 唯一；相同摘要返回原运行，不同摘要返回幂等冲突。
- Task Center 暂时不可用时保留 `PENDING` 或 `RETRYABLE_FAILED` 和恢复信息；同一幂等命令重试，不回退本地调度。
- CanvasNodeRun 可绑定 0..N AtomicTask。绑定只保存 Task Center ID、child key、角色、shard 和已观察 resource version，不复制任务输入输出或 Attempt 历史。
- 首期取消只开放整个 CanvasRun，幂等调用唯一 DAGTaskGroup cancel；已经终态的 AtomicTask 保留事实。
- `retry_failed`、`retry_node`、`retry_from_node`、`retry_flow` 和 `rerun_all` 都创建新 CanvasRun、DAGTaskGroup 与需要的新 AtomicTask，默认固定原版本和输入并保存 `retry_of_canvas_run_id`。
- 自动重试由 Task Center 在原 AtomicTask 下新增 TaskAttempt；Canvas 不提供重开原任务的接口。

## 6. 输出、状态与事件

- Artifact 内容、状态、预览、下载和资源版本归 Asset Library；Canvas 只保存 port、producer key、shard、来源任务和 Artifact ID/受控摘要。
- 稳定 producer key 至少包含 CanvasRun、CanvasNodeRun、port 和 shard；同一 AtomicTask 的自动 Attempt 重用 producer key。
- AtomicTask `SUCCESS` 不等于 NodeRun `SUCCESS`。所有必需结构化输出已持久化且必需 Artifact `READY` 后，NodeRun 才进入成功终态。
- 必需输出超时使用 `ERR_CANVAS_OUTPUT_NOT_READY_TIMEOUT` 终结 NodeRun，但不反向改写 AtomicTask；可选输出失败只形成 warning。
- Task 投影只接受匹配 binding 的更高 task resource version；Artifact 投影只接受匹配 output binding 的更高 aggregate/resource version。不同聚合版本不可比较。
- Canvas 事实与 outbox 同事务写入。`canvas_node_output_available` 只在输出绑定可用后发布，不竞争 Asset Library 的 Artifact 生命周期事件。
- SSE projector 将 Canvas domain event 映射为用户级 `canvas.run.*` 和 `canvas.node.*`，仍使用统一 UserEvent、至少一次投递、event_id 去重和 aggregate_version 保护；不建立 CanvasRun 私有连接。

## 7. 查询与关联摘要

- CanvasVersion 返回 Canvas 一跳摘要；CanvasRun 返回 Canvas、固定版本、重跑来源和 DAGTaskGroup 摘要；NodeRun 详情返回全部 TaskBinding 与 OutputBinding。
- Canvas、CanvasVersion 和重跑来源优先使用创建时的非敏感快照。同域缺失数据使用单次 JOIN 或有界批量查询。
- DAGTaskGroup/AtomicTask 摘要由 Task Center 受控批量读取，Artifact 摘要由 Asset Library 受控批量读取。禁止跨领域私有表和逐行 N+1 请求。
- 跨域查询预算：每个列表页对 Task Center 和 Asset Library 各最多一次有界批量读取；超出目标事实源批量上限时分固定大小批次，不按行退化。
- 关联资源不存在、删除或不可见时保留原始 ID，摘要为 null；父资源仍返回且不得泄露目标存在性或敏感字段。
- NodeRun 列表不展开完整 task/output 列表；详情一次返回该 NodeRun 的有界绑定集合。动态节点超过页面预算时必须使用后续分页扩展，不允许截断后伪装完整。

## 8. 跨域协作

- task-center：提供内容寻址 workflow definition 注册、DAGTaskGroup 幂等创建/查询/取消、AtomicTask 批量摘要、状态事件与对账能力。
- application-platform：提供已发布 ApplicationVersion 可见性、输入输出 schema 和到受控 `application.execute` 的解析。
- function registry：提供允许 Canvas 使用的 functionRef、binding version、输入输出 schema 和运行可用性。
- asset-library：提供 Artifact 受控交付、producer key 幂等、可用性/权限校验、批量摘要和生命周期事件。
- sse：消费 Canvas 可靠事件，写入当前用户短期 UserEvent 并通过唯一用户级连接投递；不拥有 Canvas 事实。
- identity：提供认证主体、project、namespace、visibility 和权限判断。

所有跨域协作通过受控 API 与可靠事件完成，不允许读取或写入其他领域私有表。

## 9. 首期禁用能力

- `selected_subgraph` 自由子图运行。
- `best_effort`、`min_success` 和容错 Join。
- 流级取消、分片级取消和分片手动重跑。
- 任意隐式循环、条件表达式、跨画布依赖和任意脚本节点。
- CanvasFlowRun 独立 SSE event_type；首期由 `canvas.run.progressed` 携带变化的 flow 摘要。

这些值不得提前出现在可执行枚举或成功响应中；调用保留值统一返回 `ERR_CANVAS_PHASE_CAPABILITY_UNSUPPORTED`。
