# MCP Module Contract

产品语义以 `00_product/domains/mcp/product-spec.md` 为准。本合同只覆盖 MCP `2026-07-28` v1；Capability 直接执行、泛化 Invocation、OAuth/PAT、`input_required`、`tasks/update`、动态 Tool、Prompts、Apps、Sampling 和直接 StorageBackend 上传均未开放。

## 1. 路径例外

MCP Streamable HTTP 入口固定为 `POST /mcp`，不使用仓库普通 REST 的 `/api/v1` 前缀。原因是 `/mcp` 是用户已在 S1 中确认的第三方标准协议传输端点，不是 OmniMAM REST 资源 API。

OpenAPI 可以为 MCP 规范强制的传输校验声明 HTTP 400，以及为非法 Origin 声明 HTTP 403；它们只表达第三方协议/传输拒绝，不承载 OmniMAM 业务错误。所有已进入 JSON-RPC 调度的业务失败仍使用 HTTP 200，并通过 JSON-RPC error 或 `isError=true` Tool Result 表达。404 只表示路由不存在，500 只表示未预期服务异常。

## 2. 模块边界

| 模块 | 拥有 | 不拥有 | S1 引用 |
| --- | --- | --- | --- |
| transport | `POST /mcp`、Content-Type/Accept、协议 Header、Origin、HTTP JSON/SSE 响应 | JWT 事实、业务错误、Tool 逻辑、MCP Session | BR-MCP-002、BR-MCP-003、BR-MCP-018；US-MCP-007 |
| protocol | JSON-RPC 2.0、`server/discover`、method/name Header 对齐、官方字段命名例外 | legacy initialize、Prompts、Sampling、Apps、日志订阅 | BR-MCP-002、BR-MCP-019；US-MCP-001、US-MCP-004 |
| tool-registry | 11 个固定 Tool、JSON Schema 2020-12、权限过滤、结果 Schema 校验 | 动态 Capability Tool、Provider/Engine 路由、源领域私表 | BR-MCP-004、BR-MCP-005、BR-MCP-006、BR-MCP-007、BR-MCP-008、BR-MCP-016；US-MCP-001、US-MCP-002、US-MCP-005、US-MCP-006 |
| resource-resolver | 6 类 `omnimam://` URI、解析、权限、短期 Resource Link | 素材搜索、媒体正文、永久 URL、递归摘要 | BR-MCP-014、BR-MCP-016；US-MCP-003、US-MCP-005 |
| task-adapter | McpTaskBinding、Tasks 协商、状态映射、查询、协作取消、TTL 清理 | ApplicationRun/AtomicTask 状态、重试、任务队列、`tasks/update` | BR-MCP-009、BR-MCP-010、BR-MCP-011、BR-MCP-012、BR-MCP-013、BR-MCP-019；US-MCP-003、US-MCP-004 |
| access | Identity USER/AGENT_WORKLOAD Principal、Runtime Grant、MCP 权限与目标领域权限组合、存在性保护 | 用户、角色、JWT 签发、OAuth/PAT 或目标资源事实 | BR-MCP-003、BR-MCP-016、BR-MCP-021；US-MCP-007 |
| audit | 请求审计上下文、脱敏和 platform-management audit 写入 | Platform AuditLog 存储、Token、完整 payload 或二进制 | BR-MCP-018；US-MCP-007 |
| quota | MCP 速率、ApplicationRun 并发、上传大小和费用前置检查 | 源领域配额事实、已创建资源回滚 | BR-MCP-006、BR-MCP-017、BR-MCP-018；US-MCP-002、US-MCP-006、US-MCP-007 |
| stdio-proxy | stdio/HTTP 转发、凭证读取和协议版本处理 | Tool 业务、权限决策、状态存储、素材读取 | BR-MCP-002、BR-MCP-003；US-MCP-004、US-MCP-007 |

## 3. 每请求协议元数据

- `MCP-Protocol-Version` 固定支持 `2026-07-28`，并与 `_meta.io.modelcontextprotocol/protocolVersion` 一致。
- `Mcp-Method` 必须与 JSON-RPC `method` 一致。
- `Mcp-Name` 在 `tools/call` 时等于 `params.name`，在 `resources/read` 时等于 `params.uri`；Header 使用官方 Base64 sentinel 时先解码再比较。
- `_meta.io.modelcontextprotocol/clientCapabilities` 每请求必填；不得从历史请求或连接继承 Tasks 支持。
- `_meta.io.modelcontextprotocol/clientInfo` 仅用于显示、诊断和审计，不参与安全决策。
- 不创建或接受 `Mcp-Session-Id`，不维护 connection-scoped Principal、Tool List 或运行上下文。

## 4. Tool 调度与权限

Tool 调度顺序固定为：

```text
transport validation
→ Identity JWT
→ mcp.protocol.access
→ JSON-RPC / Tool Schema
→ target-domain permission
→ object visibility/state
→ idempotency
→ MCP quota/concurrency
→ controlled domain call
→ output schema validation
→ audit result
```

USER JWT 保持现有权限与资源校验。`AGENT_WORKLOAD` JWT 额外要求 `aud=mcp`，并绑定 Agent、Coding generation/Application（如适用）、Runtime 和 Grant；每个请求在 Tool 过滤和调用前重新调用 Agent Grant resolver。Grant 失效、过期、对象越界或工具不在白名单时立即拒绝。工作负载权限只取受控 Grant 固定的最小集合，不继承创建者角色或管理员权限。

目标领域权限映射以 `permissions.yaml` 末尾规范表为准。MCP 不把 `mcp.*` 权限当作绕过 `aiapp.*`、`task.*` 或 `asset.*` 的替代权限。

下游业务错误保留源领域 `code`、`value`、`messages` 和 `retryable`，并在 Tool Execution Error 增加 `source_domain`。MCP 只为协议、分发、Resource、Task 映射和 MCP access 自身失败使用 `ERR_MCP_*`。

## 5. Capability 与 Application

- Capability 查询通过 Model Gateway 受控公共目录能力获取，只返回 CapabilityDefinition 公共语义、可用性和可运行 Application 导航；不得返回 ProviderCapability 文件、EngineInstance 或 Credential。
- `supports_direct_invoke` 固定为 false；注册表不得出现 `omnimam.capabilities.invoke`。
- Application 查询通过 Application Platform 获取当前 Principal 可见、已发布且 `run_enabled=true` 的投影。
- `omnimam.applications.run` 必须把 `application_version_id`、`input` 和 `idempotency_key` 传给 Application Platform；未指定版本时由 Application Platform 在创建边界固定当前 PublishedVersion。
- MCP 不读取 Application Platform 私表，不选择 Engine/Provider，不创建 AtomicTask；Application Platform 返回已持久化 ApplicationRun 和 AtomicTask 绑定后才能创建 MCP Task。

## 6. ApplicationRun 与取消

- ApplicationRun 查询返回 Application、版本、AtomicTask 和 Artifact 的一跳权限裁剪投影；不返回 input/execution 私有快照、Provider 参数或任务内部输出。
- ApplicationRun 访问先校验 `aiapp.application.run` 和对象可见性；不存在与不可见统一处理。
- 取消通过 ApplicationRun 解析 `atomic_task_id`，再调用 Task Center 受控取消。MCP 不直接更新 ApplicationRun 或 AtomicTask。
- `CANCEL_REQUESTED` 映射为 MCP `working` 并附加取消摘要；只有 AtomicTask `CANCELED` 映射为 `cancelled`。

## 7. MCP Task Binding

- 只有当前请求协商 `io.modelcontextprotocol/tasks` 时，ApplicationRun 创建结果才能转为 MCP Task。
- ApplicationRun、AtomicTask 和 McpTaskBinding 必须在响应前全部持久化；任一步失败不得返回可查询的 `mcp_task_id`。
- 同一 `principal_id + application_run_id` 只存在一个有效 binding。重复命中 ApplicationRun 幂等结果时返回同一 binding。
- `mcp_task_id` 不是授权凭证。`tasks/get`、`tasks/cancel` 每次重新校验 Principal、ApplicationRun 可见性和相应权限。
- TTL 到期物理删除 binding；ApplicationRun、AtomicTask、Artifact、Asset 和审计事实不受影响。过期后客户端使用 `application_run_id` 查询源事实。
- 列表查询不提供 MCP Task 枚举；Agent 只能通过创建响应或已知 task ID 访问自己的 binding。

## 8. 状态映射

| AtomicTask | MCP Task | 结果 |
| --- | --- | --- |
| PENDING、BLOCKED、READY、RETRYING、RUNNING | working | 返回进度和安全阶段摘要 |
| CANCEL_REQUESTED | working | `cancel_requested=true` |
| SUCCESS | completed | 返回 ApplicationRun 与 Artifact/Asset Resource Link |
| FAILED、TIMEOUT、SKIPPED | failed | 返回归一化源领域错误 |
| CANCELED | cancelled | 返回最终取消 |

MCP 不比较 ApplicationRun、AtomicTask 和 Artifact 的不同 `resource_version`，也不从 AtomicTask SUCCESS 推断 Artifact/Asset ready。

## 9. Resource Resolver

- URI 只允许 Capability、Application、ApplicationRun、Asset、Artifact 和 Asset Representation 六类模板。
- 每次解析 URI 后调用目标领域受控只读能力，不使用跨域 JOIN 或私表。
- 返回稳定 ID 和当前页面所需一跳摘要；目标不可见、删除或不存在时统一 `ERR_MCP_RESOURCE_NOT_VISIBLE`。
- ApplicationRun 历史优先使用其不可变非敏感快照；可变关联摘要由目标领域批量/单项能力提供。
- 不以内嵌 Base64 返回大型媒体，不返回 Blob Path、StorageBackend、永久 URL 或签名 URL Query 日志。

## 10. Asset 查询与上传

- 搜索和详情分别委托 Asset Library 列表/详情能力，强制当前 Principal 范围；MCP 不定义 `library_id`。
- `prepare_upload` 创建单文件 UploadSession，并返回 OmniMAM Asset API 受控内容端点；不得返回 S3/MinIO URL 或 Token。
- Agent 对内容端点使用同一 JWT。二进制不经过 JSON-RPC，也不写入 MCP audit payload。
- `complete_upload` 委托 Asset Library 完成会话；处理未完成时返回真实 processing，不从上传完成推断 AssetVersion ready。
- 重复 prepare/complete 将幂等键传给 Asset Library，不建立 MCP 自有素材幂等表。

## 11. 审计与失败策略

- 所有请求在执行受控业务动作前建立审计上下文；Identity audit 写入不可用时，创建/取消/上传等受控写操作 fail closed，纯只读操作记录指标并按部署安全策略处理。
- 审计字段包括 Principal、clientInfo、protocol version、transport、method、name/URI、request/trace ID、ApplicationRun/MCP Task ID、结果、错误和耗时。
- 禁止记录 Token、Provider Credential、完整输入大对象、二进制、签名 URL Query、私网地址和内部栈。
- MCP v1 不发布领域事件；ApplicationRun、AtomicTask、Artifact/Asset 和 platform-management AuditLog 的可靠性由源领域负责。

## 12. 关联摘要与查询预算

- Tool 列表固定 11 项，不读取业务资源。
- Capability/Application/Asset 搜索使用目标领域分页 API；MCP 只转换当前页，不逐项追加跨域查询。
- ApplicationRun 详情复用 Application Platform 已提供的一跳 Application、Version、Engine、AtomicTask 和 Artifact 投影，不再逐 Artifact 查询。
- Resource read 是单对象调用；Representation 内容 URL 通过 Asset Library 受控能力生成。
- 所有跨域 ID 在 OpenAPI schema 中说明摘要或豁免理由，不允许递归展开。

## 13. 数据归属

| 数据 | 所有者 |
| --- | --- |
| McpTaskBinding | mcp |
| JWT、Principal、RBAC | identity |
| AuditLog | platform-management |
| CapabilityDefinition、ProviderCapability、Engine、OperationExecutor | modelgateway |
| Application、ApplicationVersion、ApplicationRun | application-platform |
| AtomicTask、TaskAttempt、取消状态 | task-center |
| UploadSession、Artifact、Asset、Representation、Blob | asset-library |

跨域只通过稳定 ID、受控 API、非敏感快照或既有可靠事件协作。
