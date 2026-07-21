# OmniMAM Spec Handoff

## 当前项目目标

完成 Workflow Canvas S1 的产品语义整理：保留新版设计中的多流、局部运行、结果复用、节点一对多任务、渐进制品和交互式控制节点，并对齐现有 Task Center、SSE、Asset Library 和已发布 Canvas 事实。当前只维护 S1，不修改 S2。

## 本次完成

- 将新版长文档保留在正式路径 `00_product/domains/workflow-canvas/product-spec.md`，恢复其 S1 定位和 `workflow-canvas` domain_id。
- 区分 Canvas 草稿 revision 与不可变 CanvasVersion；CanvasRun 固定版本、输入、scope、幂等键和唯一 DAGTaskGroup。
- 移除 TaskRun、DAGFlowTask、ExecutionLease、运行时 task type 和 Group 嵌套语义；多流、fan-out 和复合节点统一展平到 DAGTaskGroup 的 AtomicTask 节点。
- 补齐 all/flows/only_nodes/until_nodes/from_nodes 输入闭包、共享节点去重、执行指纹、复用资格、必需/可选输出和历史来源绑定。
- Artifact 所有权对齐 Asset Library；Canvas 只保存 ArtifactReference、输出端口、producer context 和运行投影。
- Canvas 实时能力对齐用户级单 SSE、统一 UserEvent 信封、event_id、aggregate_version、重放、重同步和轮询降级。
- 明确 BLOCKED/SKIPPED、自动 TaskAttempt/用户新 CanvasRun、整次/流级取消，以及第二阶段分片取消和容错 Join。
- 保留姿态、光照、Gaussian 和摄像机控制设计，并补充 ControllerState schema、资源权限、前端上传和受控 functionRef 边界。
- 恢复 `BR-WORKFLOW-001..016`、`US-WORKFLOW-001..004`；新增 `BR-WORKFLOW-017..034`、`US-WORKFLOW-005..009` 及验收标准。

## 文件变化

- 修改 `00_product/domains/workflow-canvas/product-spec.md`。
- 修改 `CHANGELOG.md`。
- 修改 `docs/HANDOFF.md`。
- 用户原有 `AGENTS.md` 修改保持不变。

## 关键设计决策

- AtomicTask 是唯一 Worker 执行单元；CanvasRun 只有一个 DAGTaskGroup，不使用 Group 嵌套表达多流或复合节点。
- CanvasFlowRun 是 DAG 中一组执行实例的业务投影，不是 Task Center Group。
- 普通节点通常映射一个 AtomicTask；fan-out/复合节点可映射多个；Data、Viewer、REUSED NodeRun 可以无任务。
- 首期并发失败只支持 `all_success`；`best_effort`、`min_success` 和容错 Join 保留为第二阶段。
- 自动重试新增 TaskAttempt；任何用户手动重跑都创建新 CanvasRun、DAGTaskGroup 和 AtomicTask。
- Artifact 与 AtomicTask 是不同聚合；AtomicTask 成功不代表必需 Artifact ready，也不允许反向改写任务终态。
- Canvas 页面复用用户级 SSE，不提供按 CanvasRun 私有连接；不同聚合事件不保证严格顺序。

## API、Schema 与配置变化

- 本轮无 S2 变更：未修改 OpenAPI、SQL schema、错误码、权限码、事件目录或 module contract。
- S1 中原有具体 HTTP 路径、TypeScript DTO 和数据库列建议已改写为产品操作、逻辑字段和领域所有权。
- `best_effort`、`min_success`、流/分片级操作、多任务 NodeRun、新 Canvas 事件与新增 BR/US 尚未写入 S2。

## 验证结果

- 已扫描并移除 S1 中的 TaskRun、DAGFlowTask、ExecutionLease、CanvasRevision 运行语义、CanvasRun 私有 SSE 和 Canvas 自有 Artifact 存储定义。
- 已恢复并检查 `BR-WORKFLOW-001..016` 与 `US-WORKFLOW-001..004`，新增编号不复用旧编号。
- `git diff --check` 通过。

## 待办与风险

- 当前 S1 草案尚未 release，不能作为正式实现或验收依据。
- 现有 workflow-canvas S2 仍表达“静态 NodeRun 唯一 AtomicTask”等旧范围，尚未覆盖 FlowRun、多任务绑定、局部运行、复用、渐进输出和新增事件；按用户要求本轮不修改。
- SSE S1 将 Canvas 事件列为第二阶段；Workflow Canvas S1 已补全其产品语义，后续需要联合评审事件命名和 payload 契约。
- Task Center 当前无 `best_effort`/`min_success` 容错 Join 契约，因此这些能力明确留在第二阶段。
- 应在后续 S2 生成前再次检查 ApplicationVersion/functionRef 解析、Asset Library producer key 和跨域摘要批量查询预算。

## 推荐下一任务

先对本次 Workflow Canvas S1 做人工产品评审，确认首期范围、FlowRun、共享节点去重、历史复用、流级取消和 client-generated 正式输出。确认后再单独执行 S2 差异分析和契约更新，不在未确认前 release。

## Next Prompt

读取 `docs/HANDOFF.md`、`skills/spec-workflow/SKILL.md`、`S1.md` 和 `S2.md`。先审阅 `00_product/domains/workflow-canvas/product-spec.md` 的首期范围与新增 `BR-WORKFLOW-017..034`，列出产品待确认点；用户确认后再对 `01_contracts/domains/workflow-canvas/` 做 S2 差异分析和更新。不要自动写 RELEASE。
