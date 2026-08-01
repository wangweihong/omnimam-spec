# MCP Context

## 1. 领域职责

`mcp` 是 OmniMAM 面向本地和远程 Agent 的标准协议访问层，负责 MCP `2026-07-28` 的 Streamable HTTP、stdio Proxy、固定 Tools、Resources、ApplicationRun 到 MCP Task 的映射、每请求授权、结果转换、审计、限流和追踪。

## 2. 核心对象

- MCP Tool Registry：固定暴露 Capability 只读发现、Application 查询/运行、ApplicationRun 查询/取消和 Asset 查询/上传。
- MCP Resource Resolver：按 `omnimam://` URI 返回 Capability、Application、ApplicationRun、Asset、Artifact 和 Representation 的权限裁剪投影。
- `McpTaskBinding`：`mcp_task_id` 到已持久化 ApplicationRun 的稳定映射，不拥有执行状态。
- MCP Audit Context：关联 Principal、客户端、协议、请求、Tool/Resource、ApplicationRun/MCP Task 和安全结果。
- stdio Proxy：只做本地 stdio 与 Streamable HTTP 转换，不实现业务或权限决策。

## 3. 核心规则

- MCP 是访问层，不是模型集成层、应用执行器、任务中心、素材库或身份系统。
- CapabilityDefinition 只读发现；v1 不支持直接 Capability 执行或泛化 Invocation。
- 唯一异步业务执行入口是已发布且 `run_enabled=true` 的 Application，ApplicationRun 固定 ApplicationVersion。
- MCP Task 只映射 ApplicationRun 绑定的 AtomicTask，不支持 `input_required` 或 `tasks/update`。
- 每个请求使用 Identity JWT，并复用领域 RBAC、可见性和资源状态；OAuth/PAT 与独立 MCP Scope 延后。
- 素材上传复用 Asset Library UploadSession 和受控内容端点，不允许直接 StorageBackend 上传。
- Tool/Resource 名称和精确结构已在 S2 固化，但 Release 前不是正式实现依据。

## 4. 领域边界

`mcp` 只拥有协议适配、MCP Task 映射和协议审计上下文。CapabilityDefinition、ProviderCapability、Engine 和 OperationExecutor 归 `modelgateway`；Application、ApplicationVersion 和 ApplicationRun 归 `application-platform`；AtomicTask 归 `task-center`；Artifact、Asset 和上传会话归 `asset-library`；身份、JWT、RBAC 和安全审计基础归 `identity`。

MCP 不读取其他领域私有表，不复制运行快照或状态，也不接受 Provider、Engine、Worker、Runtime、任意 Workflow、任意 URL 或存储路径作为路由输入。

## 5. 上游与下游

上游是支持 MCP 的本地/远程 Agent 和 Identity JWT。下游是 Model Gateway 的 CapabilityDefinition 公共投影、Application Platform 的 Application/ApplicationRun、Task Center 的 AtomicTask、Asset Library 的 Asset/Artifact/UploadSession，以及统一安全审计边界。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/mcp/product-spec.md` | S1 | MCP 产品范围、协议交互、Tool/Resource、Task 映射、安全与验收 |
| `01_contracts/domains/mcp/openapi.yaml` | S2 | `POST /mcp`、JSON-RPC、Tool、Resource 和 Tasks 合同 |
| `01_contracts/domains/mcp/schema.sql` | S2 | McpTaskBinding 设计态持久化 |
| `01_contracts/domains/mcp/errors.yaml` | S2 | MCP 协议、分发、Task 映射和访问错误 |
| `01_contracts/domains/mcp/permissions.yaml` | S2 | MCP 协议权限与目标领域权限映射 |
| `01_contracts/domains/mcp/events.yaml` | S2 | 显式无 MCP 领域事件声明 |
| `01_contracts/domains/mcp/module-contract.md` | S2 | 模块职责、跨域调用和安全边界 |
| `02_architecture/domains/mcp.md` | 参考 | 组件关系、Task 时序、部署和故障边界 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改 MCP 协议、Tool、Resource 或 Task 映射 | S1 product-spec | 需要精确结构时读 OpenAPI/module-contract |
| 修改 Capability 发现 | 当前 Context | 再读 modelgateway Context/S1 |
| 修改 Application 运行 | 当前 Context | 读 MCP OpenAPI/module-contract；涉及源事实再读 application-platform/task-center |
| 修改素材查询或上传 | 当前 Context | 读 MCP OpenAPI/module-contract；涉及源事实再读 asset-library |
| 修改 JWT/RBAC | identity Context/S1 | 仅 MCP 消费行为返回当前 S1 |

## 8. 当前状态

本领域由 2026-08-01 的 S0 Draft 原位整理为 S1，并已建立完整 S2 与领域架构参考；尚未写入 `RELEASE.md`，不得作为正式实现、合并或验收依据。Capability 直接执行、OAuth/PAT、交互式 MCP Task、动态 Tool、MCP Prompts/Apps/Sampling 和直接 StorageBackend 上传均不在 v1。

## 9. 不在本领域定义的内容

- Provider、Engine、Binding、OperationExecutor 和模型执行不在本领域定义。
- ApplicationVersion、ApplicationRun 快照和应用执行不在本领域定义。
- AtomicTask 状态、重试和取消事实不在本领域定义。
- Artifact/Asset 生命周期、Blob、Representation 和 UploadSession 不在本领域定义。
- 用户、Token、RBAC、OAuth Provider 和审计存储不在本领域定义。
- 正式实现代码、实际 migration、运行时配置和 CI/CD 不在本仓库定义。
