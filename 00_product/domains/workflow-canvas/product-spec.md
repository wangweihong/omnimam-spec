# 工作流画布 S1 产品规格

## 1. 文档定位

本文档定义 OmniMAM 无限画布在 `spec-v1.0.0` 的产品语义。画布允许用户自由组合已发布应用和任务函数，保存可编辑图，发布不可变版本，并通过 task-center 执行合法 DAG。

画布领域拥有编辑模型、版本、运行视图和节点映射；task-center 拥有 AtomicTask、DAGTaskGroup、执行状态、重试、取消与调度事实。

## 2. 核心对象

### 2.1 Canvas

Canvas 是用户可持续编辑的工作空间，包含名称、描述、可见性、当前草稿 revision 和最新发布版本。保存草稿使用乐观并发，不修改任何已发布版本。

### 2.2 CanvasVersion

CanvasVersion 是发布时冻结的节点、边、输入输出绑定和编译摘要。版本一经发布不可修改或删除；后续编辑生成更高版本。

节点类型：

- `APPLICATION`：固定引用已发布 ApplicationVersion，由受控 `application.execute` functionRef 执行。
- `FUNCTION`：引用 task-center 已注册且允许画布使用的 functionRef。
- `DYNAMIC_FORK`：根据运行输入或父节点输出动态创建同构 AtomicTask，必须配置最大展开数。

V1 不支持循环、Group 嵌套、任意 HTTP、INLINE、脚本、Worker 名或运行时原生 task type。

### 2.3 CanvasRun

CanvasRun 表示一次对已发布 CanvasVersion 的运行请求，保存不可变输入快照、`dag_task_group_id`、状态投影和结果摘要。同一 CanvasRun 幂等键不得启动多个 DAGTaskGroup。

### 2.4 CanvasNodeRun

CanvasNodeRun 是画布节点到 Task Center 的只读运行映射。普通节点关联一个 `atomic_task_id`；动态节点保存父节点映射并通过 child key 查询展开后的 AtomicTask。节点状态只接受 task-center 更高 resource version 的投影。

## 3. 发布和执行

发布流程：

1. 校验节点 key、边、端口、引用、输入映射和图规模。
2. 验证图无环，并验证所有 functionRef/ApplicationVersion 对当前用户可用。
3. 生成内容摘要和不可变 CanvasVersion。
4. 将图编译为 DAGTaskGroup template，并通过 task-center 注册不可变 workflow definition。
5. 返回版本号和编译摘要；任一步失败都不得形成部分发布版本。

运行流程：

1. 固定 CanvasVersion 与运行输入。
2. 幂等创建 CanvasRun。
3. 请求 task-center 创建 DAGTaskGroup。
4. 保存 `dag_task_group_id`，为静态节点创建 CanvasNodeRun 映射。
5. 消费 task-center 事件更新状态和结果；事件遗漏由详情查询或对账修复。

## 4. 图语义

- 没有依赖的节点可并行执行；一个节点可以有多个父节点。
- 输入绑定可引用运行输入、常量或父节点输出，不能引用非祖先节点。
- 多父节点全部满足后才释放子节点。
- 上游失败且节点没有允许的容错策略时，下游进入 SKIPPED。
- Dynamic Fork 在运行时展开，所有子任务完成后才满足其下游依赖。
- 默认每版本最多 1000 节点、5000 条边、每个动态节点最多 1000 个子任务。

## 5. 业务规则

1. `BR-WORKFLOW-001`：Canvas 草稿可编辑，CanvasVersion 发布后不可变。
2. `BR-WORKFLOW-002`：发布必须原子校验节点、边、端口、引用、无环和规模限制。
3. `BR-WORKFLOW-003`：CanvasVersion 只允许 APPLICATION、FUNCTION 和 DYNAMIC_FORK 节点。
4. `BR-WORKFLOW-004`：画布只能引用已发布 ApplicationVersion 或已注册且允许画布使用的 functionRef。
5. `BR-WORKFLOW-005`：禁止任意 HTTP、INLINE、脚本、Worker 名、凭证和运行时内部配置。
6. `BR-WORKFLOW-006`：CanvasRun 必须固定一个不可变 CanvasVersion 和输入快照。
7. `BR-WORKFLOW-007`：每个 CanvasRun 只关联一个 DAGTaskGroup，同一幂等键不得重复启动。
8. `BR-WORKFLOW-008`：每个静态 CanvasNodeRun 关联一个 AtomicTask，状态以 task-center 投影为准。
9. `BR-WORKFLOW-009`：多父节点全部满足后才可执行，失败传播使不可执行下游进入 SKIPPED。
10. `BR-WORKFLOW-010`：Dynamic Fork 必须配置不超过 1000 的最大展开数，并等待全部动态子任务汇合。
11. `BR-WORKFLOW-011`：默认单版本最多 1000 节点和 5000 条边。
12. `BR-WORKFLOW-012`：编辑已运行版本只产生新草稿和新版本，不改变历史 CanvasRun。
13. `BR-WORKFLOW-013`：取消和重跑通过 task-center 执行；重跑创建新 CanvasRun。
14. `BR-WORKFLOW-014`：CanvasRun 投影只接受更高 task resource version，遗漏事件必须可对账。
15. `BR-WORKFLOW-015`：大型媒体结果只保存 Artifact/Asset 引用，不保存正文。
16. `BR-WORKFLOW-016`：CanvasVersion、CanvasRun 和 CanvasNodeRun 响应必须保留 Canvas、版本、重跑来源、DAGTaskGroup 与 AtomicTask ID，并同时返回权限裁剪的一跳可读摘要。CanvasRun 优先使用创建时保存的 Canvas/版本快照；Task Center 摘要必须通过受控批量只读能力获取，列表查询不得逐行读取任务。

## 6. 用户故事与验收

### US-WORKFLOW-001 编辑和发布任意 DAG

作为画布用户，我希望自由连接合法节点并发布稳定版本。

- `AC-WORKFLOW-001-01`：多父节点、同层并行和端口映射可以发布。
- `AC-WORKFLOW-001-02`：环、悬空引用、非法 functionRef 和超限图在发布前拒绝。
- `AC-WORKFLOW-001-03`：发布后继续编辑不会改变已发布版本。

### US-WORKFLOW-002 运行固定版本

作为画布用户，我希望运行固定版本并查看每个节点状态和结果。

- `AC-WORKFLOW-002-01`：CanvasRun 固定版本、输入和唯一 DAGTaskGroup。
- `AC-WORKFLOW-002-02`：静态节点可以追溯到 AtomicTask 和 Attempt。
- `AC-WORKFLOW-002-03`：取消级联未终态任务，重跑创建新 CanvasRun。

### US-WORKFLOW-003 动态批量媒体流

作为媒体创作者，我希望根据文本动态并发生成多张图片，并在全部完成后生成视频。

- `AC-WORKFLOW-003-01`：动态节点按运行输入展开且不超过声明上限。
- `AC-WORKFLOW-003-02`：视频节点等待文本和全部图片任务成功后开始。
- `AC-WORKFLOW-003-03`：任一必需父节点失败时视频节点为 SKIPPED。

### US-WORKFLOW-004 故障恢复和历史一致性

作为用户，我希望服务重启后仍可查看准确画布运行历史。

- `AC-WORKFLOW-004-01`：重复运行请求不产生重复 DAGTaskGroup。
- `AC-WORKFLOW-004-02`：乱序事件不回退节点或运行状态，遗漏事件可以对账恢复。

## 7. 非目标

V1 不支持循环工作流、子画布、Group 嵌套、发布版本修改、用户脚本、任意网络请求节点、跨项目节点引用或直接展示 Conductor 工作流定义。
