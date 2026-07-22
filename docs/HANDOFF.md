# OmniMAM Spec Handoff

## 当前项目目标

基于 `00_product/domains/workflow-canvas/product-spec.md` 的 v1.1 S1 草案完成可实现、可校验、可追溯的 Workflow Canvas S2，并与 Task Center、Asset Library 和用户级 SSE 边界保持一致。

## 本次完成

1. 重写 workflow-canvas OpenAPI，共 22 个 operation：
   - NodeDefinition 查询、注册新版本和下线新引用。
   - Canvas 创建、读取、revision 保存、软删除、草稿预检、发布和版本查询。
   - 固定 CanvasVersion 的运行预检，以及 CanvasRun 创建、列表、详情、FlowRun、NodeRun、整次取消和手动重跑。
   - 首期 scope 为 `all`、`flows`、`only_nodes`、`until_nodes`、`from_nodes`；复用策略为 `rerun_all`、`reuse_valid_outputs`、`reuse_required`。
2. 重构设计态 SQL schema，共 11 张表，补齐 NodeDefinition、FlowRun、共享执行实例、NodeRun 1:N TaskBinding、OutputBinding、复用来源、outbox 和对账游标。
3. 将 CanvasRun 状态补齐 `PARTIAL_SUCCESS`，NodeRun 补齐 `PARTIAL_SUCCESS` 和 `REUSED`；Task 创建失败使用可恢复 `RETRYABLE_FAILED`，不回退本地执行。
4. 扩展为 28 个 workflow-canvas 错误、11 个权限码和 9 个可靠领域事件；继续使用已登记的 `160200-160999` 区间。
5. 重写模块契约和领域架构，明确真实 DAG 直接依赖、节点最早释放、唯一 DAGTaskGroup、流业务投影和跨域批量摘要预算。
6. 解决 SSE 跨域冲突：SSE 首期现包含 15 个既有 `canvas.run.*`/`canvas.node.*` 用户事件，仍复用当前用户唯一连接，不提供 CanvasRun 私有连接或独立 FlowRun event type。

## 文件变化

- 修改 `00_product/domains/sse/product-spec.md`。
- 修改 `01_contracts/domains/workflow-canvas/openapi.yaml`。
- 修改 `01_contracts/domains/workflow-canvas/schema.sql`。
- 修改 `01_contracts/domains/workflow-canvas/errors.yaml`。
- 修改 `01_contracts/domains/workflow-canvas/permissions.yaml`。
- 修改 `01_contracts/domains/workflow-canvas/events.yaml`。
- 修改 `01_contracts/domains/workflow-canvas/module-contract.md`。
- 修改 `01_contracts/domains/sse/openapi.yaml`。
- 修改 `01_contracts/domains/sse/events.yaml`。
- 修改 `01_contracts/domains/sse/module-contract.md`。
- 修改 `01_contracts/error-code-index.md`。
- 修改 `02_architecture/domains/workflow-canvas.md`。
- 修改 `02_architecture/global-architecture.md`。
- 修改 `CHANGELOG.md` 和 `docs/HANDOFF.md`。
- 用户原有 `AGENTS.md` 修改保持不变且不应纳入本任务提交。

## 关键设计决策

- CanvasRun 固定 CanvasVersion、输入、scope、策略、复用决策和 ExecutionPlan，只创建一个 DAGTaskGroup。
- 多流、fan-out 和复合节点全部展平为 DAGTaskGroup 内 AtomicTask；FlowRun 不是 Task Center Group。
- NodeRun 到 AtomicTask 为 0..N。Data、Viewer、REUSED 和 client-generated NodeRun 可以没有新任务。
- 共享节点只在 execution fingerprint、依赖来源和策略完全一致时复用同一 execution key。
- AtomicTask 成功不等于 NodeRun 输出可用；必需 Artifact READY 后才能完成 NodeRun，Artifact 生命周期仍归 Asset Library。
- 自动重试新增 TaskAttempt；所有用户手动重跑意图创建新 CanvasRun、DAGTaskGroup 和 AtomicTask。
- 跨域关联只保存稳定 ID、非敏感快照和已观察版本；列表对 Task Center/Asset Library 使用有界批量读取，禁止 N+1 和私有表穿透。

## API、Schema 与配置变化

- OpenAPI 成功响应从旧 `code/message/data/meta` 包裹改为直接业务对象；业务错误仍为 HTTP 200 + 稳定 `code/value`。
- 列表分页统一为 `page_num=0` 起始，并补齐 keyword、search_fields、排序和时间过滤参数。
- Canvas 图改为 NodeInstance、稳定 Port key、独立 Edge 和 FlowDefinition；NodeDefinition 固定版本保存端口、schema、renderer 和受控执行绑定。
- CanvasRun 新增 scope、run_policy、reuse decision、execution plan digest、FlowRun 摘要、重跑意图和 aggregate version。
- NodeRun 新增 execution key/fingerprint、result mode、FlowRun 引用、TaskBinding、OutputBinding 和 reuse source。
- 没有运行时配置或实际 migration 变更；`schema.sql` 仅为设计态 schema。

## 验证结果

- `yq` 解析 workflow-canvas 与 SSE 的 OpenAPI、errors、permissions、events 全部通过。
- workflow-canvas OpenAPI 本地 schema 引用解析检查通过，无缺失 `$ref`。
- 所有 OpenAPI operation 均包含 `x-s1-refs` 和已定义的 `x-permission`。
- `git diff --check` 通过。
- 最终提交前仍需运行 OpenAPI lint、错误码全局唯一性、S1 引用存在性和 staged diff 检查。

## 待办与风险

- Workflow Canvas S1/S2 仍为 draft，未写入 `RELEASE.md`，不能作为正式实现、合并或验收依据。
- 本 S2 对旧 Canvas API/表结构是破坏性升级；正式实现需要设计数据迁移、客户端切换和旧 DTO 退役门禁。
- Task Center 尚未提供 `best_effort`/`min_success` 容错 Join，因此相关值、流/分片级取消、分片重跑和 `selected_subgraph` 保持禁用。
- identity 领域仍缺完整 S2；权限码已定义，但具体角色绑定和授权数据模型需要在 identity S2 中落地。
- 正式实现前应联合确认 Task Center 内容寻址 workflow definition 注册、动态 child 批量查询和 Asset Library Canvas producer context 接口。

## 推荐下一任务

人工评审本次 Workflow Canvas S2 的 API 破坏性变更、NodeDefinition 管理边界、Task Center/Asset Library 协作接口和 SSE 首期事件；确认后创建新 spec release，再到正式 Server/Web 仓库按发布版本实施。

## Next Prompt

读取 `docs/HANDOFF.md`、`skills/spec-workflow/SKILL.md`、`S1.md` 和 `S2.md`。审阅本次 workflow-canvas 与 SSE S2 diff，重点检查 OpenAPI scope/retry DTO、NodeRun 1:N TaskBinding、OutputBinding、错误码/权限/事件追溯和跨域批量接口。若用户确认发布，更新 `RELEASE.md` 并记录确切 commit；否则不要把 draft 用作正式实现依据。
