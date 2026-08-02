# Infrastructure Context

## 1. 领域职责

`infrastructure` 提供第一阶段单机 Docker 运行层，负责 Docker Job/Service、InfraRuntime、Endpoint、挂载、资源、Secret 注入、日志与 Provider 状态对账。它不拥有 Agent、AppStudio、Task Center、Artifact 或 Workspace 的业务事实。

## 2. 核心规则

- 所有 Infra 操作必须由 Task Center 的 Task Worker 通过受控 Infra Adapter 发起；业务领域不得直接调用 Infra Service。
- 第一阶段只支持 `DockerRuntimeProvider`，Kubernetes、Edge、Local Process 和多节点调度属于后续版本规划。
- `AgentWorkspace` 只能按 Agent 授权挂载；`StudioWorkspace` 只能通过 AppStudio 受控授权访问。
- Preview 只能挂载当前 Workspace Revision；Build 只能只读挂载固定 Snapshot；Production 只能只读使用固定 Artifact digest，禁止可写 Workspace。
- Infra 只保存稳定运行引用和基础设施状态；业务状态由来源领域和 Task Center 分别拥有。
- Infra Job 只返回受控 output descriptor；Task Worker 使用 producer context 调用 Asset Library 登记 Artifact，Infra 不生成 Artifact ready 事实。
- `requestingService + requestId` 是创建幂等作用域；同摘要重放原结果、不同摘要冲突、失败重试使用新 requestId。
- `USER_ACCESSIBLE` Endpoint 必须校验 owner 和当前授权，`PUBLIC` 第一阶段默认禁用；Host Port 和私网地址不得进入普通摘要。

## 3. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/infrastructure/product-spec.md` | S1 Draft | Docker 运行层、Job/Service、Runtime、挂载和安全语义 |
| `02_architecture/domains/infrastructure.md` | 参考 | Task Worker、Infra Adapter、Docker Provider 和挂载边界 |
| `01_contracts/domains/infrastructure/openapi.yaml` | S2 Draft | InfraRuntime、Endpoint、Node、Profile 和输出 API |
| `01_contracts/domains/infrastructure/schema.sql` | S2 Draft | Infrastructure 设计态 Schema |
| `01_contracts/domains/infrastructure/errors.yaml`、`permissions.yaml`、`events.yaml`、`module-contract.md` | S2 Draft | 错误、权限、事件和模块边界 |

Infrastructure S1/S2 均为未 Release 草稿，使用 `US-INFRA-001`、`BR-INFRA-001`、`R-INFRA-*` 和源章节追溯。未完成用户确认和 Release 前，本文档及 S1/S2 只能用于草稿讨论、实现评估和上下文导航。

## 4. 直接依赖

- `task-center` 拥有 AtomicTask、Attempt、重试、取消、超时和 Task Worker 分发。
- `agent` 拥有 AgentRuntime 业务绑定和 AgentWorkspace 授权。
- `appstudio` 拥有 StudioWorkspace、Revision、Snapshot、Preview、Build、Release 和 Production 业务投影。
- `asset-library` 拥有 Artifact 内容、digest 和存储事实。
- `modelgateway` 提供 ModelAccessSpec；Infra 负责运行期受控注入，不代理每次模型请求。
