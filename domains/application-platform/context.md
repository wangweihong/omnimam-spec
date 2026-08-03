# Application Platform Context

## 1. 领域职责

`application-platform` 将 Provider 能力与 ComfyUI 工作流封装为面向用户的稳定 Application。它拥有工作流、模板与应用版本、运行表单和 ApplicationRun 业务投影，并通过 `modelgateway` 选择真实执行实现。

## 2. 核心对象

- `CapabilityDefinition`、`ProviderCapability`、`ApplicationEngineType`、`ApplicationEngineInstance`、`EngineCapabilityBinding`、`EngineAdapter`、`OperationExecutor`：由 `modelgateway` 拥有，本领域通过受控边界消费。
- `ApplicationExecutor`：编排 ApplicationRun 并调用 Model Gateway OperationExecutor 的应用执行职责。
- `ApplicationTemplate`、`Application`、`ApplicationVersion`：应用蓝图、稳定入口和不可变发布契约。
- `RuntimeFormSchema`、`ApplicationRun`：临时运行表单和应用运行快照与状态投影。
- `ApplicationNode` 引用关系：由画布拥有节点结构，本领域提供被固定引用的 ApplicationVersion。
- `ComfyUIWorkflow`：用户导入并可转换为模板的非版本化工作流资源。

## 3. 核心规则

- Application 是上层用户和画布使用的稳定入口，Provider 参数不得泄漏为业务语义。
- ApplicationVersion 发布后不可变；Canvas 节点固定引用明确的已发布版本。
- 管理员跨 owner 代管 ComfyUIWorkflow 必须同时拥有具体操作权限与 `aiapp.comfyui_workflow.manage_all`；创建或修改 global Application 必须拥有 `aiapp.application.manage_global`，不得仅按角色名授权。
- RuntimeFormSchema 按应用版本、能力、权限与运行时可用性派生。
- ProviderCapability 从只读目录加载；管理员手工导入、编辑和热加载旧方案已废弃。
- EngineInstance 表达真实连接环境；凭证与内部配置不得进入普通摘要。
- ApplicationRun 保存不可变输入、版本、能力和执行快照，只单调投影 AtomicTask 状态。
- 无法保持应用语义兼容的工作流应创建新 Application，不能强行追加为新版本。
- Artifact 只以受控 ID 和状态摘要关联，制品事实由 asset-library 维护。

## 4. 领域边界

本领域拥有 ComfyUIWorkflow、应用、模板、版本、RuntimeFormSchema 和 ApplicationRun。能力目录、Engine、Binding、Adapter 与 OperationExecutor 归 `modelgateway`；AtomicTask 状态归 task-center；Artifact 与 Asset 归 asset-library；Canvas 图结构和编译归 workflow-canvas。

## 5. 上游与下游

上游包括 identity 的主体与权限，以及 `modelgateway` 的只读 Provider 能力、Engine 和执行入口。下游包括 task-center 的异步执行、asset-library 的制品接收、workflow-canvas 的 ApplicationNode 和 sse/notification-center 的事件投影。跨域协作使用稳定 ID、不可变快照、模块接口和可靠事件。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/application-platform/product-spec.md` | S1 | 产品语义、业务规则和应用运行流程 |
| `01_contracts/domains/application-platform/openapi.yaml` | S2 | HTTP API 与 DTO 合同 |
| `01_contracts/domains/application-platform/schema.sql` | S2 | 设计态数据结构 |
| `01_contracts/domains/application-platform/module-contract.md` | S2 | 模块和跨域协作边界 |
| `02_architecture/domains/application-platform.md` | 参考 | 运行时序、加载和失败隔离 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改应用、模板或版本语义 | S1 product-spec | 涉及接口或持久化时读 OpenAPI/Schema |
| 修改 Engine 或能力目录 | `domains/modelgateway/context.md` | 涉及应用消费行为时返回当前 Context |
| 修改 ApplicationRun | S1 product-spec | 涉及执行状态再读 task-center Context |
| 修改 Canvas 应用节点 | 当前 Context | 继续读取 workflow-canvas Context |

## 8. 当前状态

核心应用、Engine、ComfyUI、运行与跨域协作规则已有发布记录并正在实施。是否允许实现某一具体能力必须以 `RELEASE.md` 对应版本和 implementation gate 为准；S1 文件头版本可能滞后于后续发布记录。

## 9. 不在本领域定义的内容

- AtomicTask、重试和调度状态机不在本领域定义。
- Artifact 处理、登记和 Asset 生命周期不在本领域定义。
- Canvas 图、端口、编译和局部执行不在本领域定义。
- Provider 内部实现代码、正式数据库 migration 和凭证明文不在本仓库定义；Gateway 核心事实见 `modelgateway`。
