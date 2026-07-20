# Workflow Canvas Module Contract

产品语义以 `00_product/domains/workflow-canvas/product-spec.md` 为准。

## 1. 模块边界

| 模块 | 拥有 | 不拥有 |
| --- | --- | --- |
| canvas | Canvas 元数据、草稿图、revision 和软删除 | 发布版本修改、任务状态 |
| version | 图校验、不可变 CanvasVersion、内容摘要和编译绑定 | Conductor 原生定义所有权 |
| run | CanvasRun、幂等启动、取消/重跑协作和结果视图 | DAGTaskGroup 状态机、AtomicTask 重试 |
| projection | CanvasNodeRun 映射、task-center 事件投影和对账 | 任务执行事实和 Attempt 历史 |
| access | owner、project、namespace、可见性和服务身份检查 | identity 主体生命周期 |

## 2. 发布契约

- 更新草稿必须携带 `expected_draft_revision`，冲突时拒绝覆盖。
- 发布在同一逻辑事务中验证节点 key、边、端口、祖先引用、无环、规模和节点授权。
- APPLICATION 节点固定 ApplicationVersion；FUNCTION/DYNAMIC_FORK 节点固定注册 functionRef 与配置。
- 编译器按拓扑层生成 DAGTaskGroup template：同层 Fork、层末 Join；动态节点生成 Dynamic Fork/Join。
- 运行时定义注册成功后才保存 CanvasVersion；内容摘要、定义名和版本不得漂移。
- 已发布 CanvasVersion 不支持 PATCH 或 DELETE。

## 3. 运行契约

- 创建 CanvasRun 先固定版本、输入和幂等键，再调用 task-center 创建 DAGTaskGroup。
- `project_id + namespace + created_by + idempotency_key` 唯一；请求摘要不一致返回幂等冲突。
- 静态节点创建 CanvasNodeRun 并绑定唯一 AtomicTask；动态子任务通过 DAG owner 与 child key 查询，不在画布表复制无限行映射约束。
- 取消调用 DAGTaskGroup cancel；重跑创建新 CanvasRun 和 DAGTaskGroup，并保存 `retry_of_canvas_run_id`。
- CanvasRun/NodeRun 只接受更高 `task_resource_version`，详情读取可触发 task-center 对账。
- 多父节点全部满足后才释放下游；必需父节点失败时下游投影为 SKIPPED，历史版本和历史运行不得被后续编辑改写。

## 4. 跨域依赖

- task-center 提供 DAGTaskGroup 创建、查询、取消、重跑、子 AtomicTask 和状态事件。
- application-platform 提供已发布 ApplicationVersion 的可见性、输入输出 schema 和 `application.execute` functionRef 解析。
- asset-library 提供 Artifact/Asset 引用可见性、处理和登记状态；application-platform 只提供 ApplicationRun 到 Artifact 的引用映射。
- identity 提供调用主体、项目和命名空间授权。

## 5. 安全与限制

- 前端保存的位置、缩放和展示信息不得进入 Worker 执行参数，除非节点 schema 明确声明。
- 用户不能提交 Conductor task type、HTTP endpoint、Worker 名、脚本、凭证或内部配置。
- 发布校验默认限制为 1000 节点、5000 边和单动态节点 1000 子任务。
- 大型内容仅保存 Artifact/Asset 引用；草稿与运行输入按 schema 限制 JSON 大小。
- 上述边界同时落实 BR-WORKFLOW-009、BR-WORKFLOW-012 和 BR-WORKFLOW-015。
