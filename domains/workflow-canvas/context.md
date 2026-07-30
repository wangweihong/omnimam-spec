# Workflow Canvas Context

## 1. 领域职责

`workflow-canvas` 管理无限画布的可编辑结构、不可变发布版本、节点与有类型的边、运行范围选择、DAG 编译和运行投影。它让用户用 Application 与 Asset 等业务节点组合工作流，但不复制这些节点所引用领域的业务定义。

## 2. 核心对象

- `Canvas`、`CanvasDraft`、`CanvasVersion`：画布身份、可编辑草稿和不可变发布图。
- `Node`、`Edge`、端口：节点配置、有类型的数据依赖和连线约束。
- `ApplicationNode`：固定引用已发布 ApplicationVersion 的业务节点。
- `AssetNode`：按规则引用 Asset 或固定 AssetVersion 的素材节点。
- `RunSelection`、`CanvasCompilation`、Partial Execution：全量、单节点、到节点或从节点运行范围及编译结果。
- `CanvasRun`、`CanvasNodeRun`：固定版本运行和节点到 AtomicTask 的只读映射。

## 3. 核心规则

- Canvas 草稿使用 revision 乐观并发保存；CanvasVersion 发布后不可变。
- 正式运行必须固定 CanvasVersion、输入和解析后的业务引用。
- 画布只拥有图、依赖、运行选择和编译，不重新定义 Application 输入输出语义。
- ApplicationNode 固定到明确的已发布 ApplicationVersion，并在发布与运行时复核可用性。
- 编译必须验证端口类型、必填输入、无环性、引用权限和安全边界。
- 多流、fan-out 和复合节点展平到唯一 DAGTaskGroup，不改变原始依赖语义。
- CanvasNodeRun 可映射零个、一个或多个 AtomicTask，只投影任务与 Artifact 引用。
- 局部执行不得绕过依赖闭包、版本固定、权限或 SSRF/RCE 防护。

## 4. 领域边界

本领域拥有 Canvas 图、版本、编译、CanvasRun 和 CanvasNodeRun。Application 与版本契约归 application-platform；AtomicTask、Group/DAG 和执行状态归 task-center；Artifact 与 Asset 生命周期归 asset-library；实时事件和通知分别归 sse 与 notification-center。

## 5. 上游与下游

上游是 identity 权限、application-platform 的可用 ApplicationVersion，以及 asset-library 的可见素材。下游是 task-center 的 DAGTaskGroup/AtomicTask、asset-library 的输出引用和 sse/notification-center 的运行事件投影。跨域解析必须走受控摘要或模块接口。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/workflow-canvas/product-spec.md` | S1 | 画布、发布、编译和运行语义 |
| `01_contracts/domains/workflow-canvas/openapi.yaml` | S2 | 画布与运行 API |
| `01_contracts/domains/workflow-canvas/schema.sql` | S2 | 设计态图、版本和运行结构 |
| `01_contracts/domains/workflow-canvas/events.yaml` | S2 | 画布运行事件合同 |
| `01_contracts/domains/workflow-canvas/module-contract.md` | S2 | 编译与跨域执行边界 |
| `02_architecture/domains/workflow-canvas.md` | 参考 | 发布、编译、投影和查询预算 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改节点、边或发布 | S1 product-spec | 涉及接口或持久化时读 OpenAPI/Schema |
| 修改编译或局部执行 | S1 product-spec | 涉及 Task DAG 时读 task-center Context |
| 修改 ApplicationNode | 当前 Context | 再读 application-platform Context |
| 修改 AssetNode 或输出 | 当前 Context | 再读 asset-library Context |

## 8. 当前状态

核心画布、发布、编译和 Application 节点执行已有发布记录并正在实施。S1 头部仍可能显示 draft，具体正式范围与 implementation gate 必须按 `RELEASE.md` 的领域记录判断。

## 9. 不在本领域定义的内容

- Application、ApplicationVersion 和运行表单语义不在本领域定义。
- AtomicTask 状态机、自动重试和 WorkflowRuntime 不在本领域定义。
- Artifact 内容处理、Asset 版本和 Representation 不在本领域定义。
- Provider 工作流协议、凭证和执行适配器不在本领域定义。
