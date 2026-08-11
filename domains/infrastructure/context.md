# Infrastructure Context

## 1. 领域职责

`infrastructure` 提供第一阶段单机 Docker 运行层，负责 Docker Job/Service、InfraRuntime、Endpoint、挂载、资源、Secret 注入、日志与 Provider 状态对账。它不拥有 Agent、AppStudio、Task Center、Artifact 或 Workspace 的业务事实。

## 2. 核心规则

- Runtime 创建、停止、删除和其他生命周期写操作必须由 Task Center 的 Task Worker 通过受控 Infra Adapter 发起；唯一例外是 AgentRuntimeAdapter 在完整业务绑定校验后，以 Agent 工作负载身份调用只读 Endpoint resolve。
- 第一阶段只支持 `DockerRuntimeProvider`，Kubernetes、Edge、Local Process 和多节点调度属于后续版本规划。
- RuntimeProfile Revision 定义命名 Endpoint；Docker Service 只向平台内部接口发布声明的容器端口，并在映射建立和健康检查通过后把 Endpoint 标记为 `READY`。
- `AgentWorkspace` 只能按 Agent 授权挂载；Coding Runtime 不挂载 StudioWorkspace，而是接收 Git clone 非敏感配置、tmpfs credential helper 和可丢弃 `/workspace`；Preview/Build 源码按 AppStudio Revision/Snapshot 固定 commit 受控注入。
- Preview 只能挂载当前 Workspace Revision；Build 只能只读挂载固定 Snapshot；Production 只能只读使用固定 Artifact digest，禁止可写 Workspace。
- Infra 只保存稳定运行引用和基础设施状态；业务状态由来源领域和 Task Center 分别拥有。
- Docker Job 从受控输出根读取声明文件的实际字节，计算大小和 SHA-256 并复制到 Infra staging；RuntimeOutput 只使用非 bearer `infra-output://` 引用。
- Task Worker 从 Infra 鉴权流式读取字节，双重校验大小和 digest，完成 Asset Library Artifact 内容后幂等回链；Infra 不生成 Artifact ready 事实。
- `requestingService + requestId` 是创建幂等作用域；同摘要重放原结果、不同摘要冲突、失败重试使用新 requestId。
- `USER_ACCESSIBLE` Endpoint 必须校验 owner 和当前授权，`PUBLIC` 第一阶段默认禁用；Host Port 和私网地址不得进入普通摘要。
- Endpoint resolve 返回的短时 `base_url` 不得进入 Agent 表、Task 结果、事件、日志或普通 Endpoint 摘要。
- Agent Invocation Worker 只能凭 Attempt-scoped authorization ref 解析 READY Runtime Endpoint；Infrastructure 不接收消息正文、用户模型凭证或源码正文 Task 参数，也不拥有 Invocation 终态。Git credential 明文只能在授权 resolver 到 tmpfs stdin 注入的内存链路中存在。

## 3. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/infrastructure/product-spec.md` | S1 Released (`spec-v1.17.2`) | Docker 运行层、Job/Service、Runtime、挂载和安全语义 |
| `02_architecture/domains/infrastructure.md` | 参考（`spec-v1.17.2`） | Task Worker、Infra Adapter、Docker Provider 和挂载边界 |
| `01_contracts/domains/infrastructure/openapi.yaml` | S2 Released (`spec-v1.17.2`) | InfraRuntime、Endpoint、Node、Profile 和输出 API |
| `01_contracts/domains/infrastructure/schema.sql` | S2 Released (`spec-v1.17.2`) | Infrastructure 设计态 Schema |
| `01_contracts/domains/infrastructure/errors.yaml`、`permissions.yaml`、`events.yaml`、`module-contract.md` | S2 Released (`spec-v1.17.2`) | 错误、权限、事件和模块边界 |

Infrastructure 当前 S1/S2、Endpoint resolve 与 RuntimeOutput 内容交付闭环已由 `spec-v1.17.2` 完成用户确认并发布，使用 `US-INFRA-001`、`BR-INFRA-001`、`R-INFRA-*` 和源章节追溯，可作为正式实现、合并和验收依据。
Agent Invocation Attempt-scoped Endpoint 授权解析边界待 `spec-v1.18.0` 发布后作为新增实现依据。

## 4. 直接依赖

- `task-center` 拥有 AtomicTask、Attempt、重试、取消、超时和 Task Worker 分发。
- `agent` 拥有 AgentRuntime 业务绑定和 AgentWorkspace 授权。
- `appstudio` 拥有 StudioWorkspace、Revision、Snapshot、Preview、Build、Release 和 Production 业务投影。
- `asset-library` 拥有 Artifact 内容、digest 和存储事实。
- `modelgateway` 提供 ModelAccessSpec；Infra 负责运行期受控注入，不代理每次模型请求。
