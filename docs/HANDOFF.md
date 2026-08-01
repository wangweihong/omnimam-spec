# OmniMAM Spec Handoff

## 当前目标与状态

将已完成的 `mcp` S1/S2、Context 和架构提交并发布为 `spec-v1.9.2`。状态：已完成，Release commit、tag、`origin/master` 和远端 tag 均已发布。

## 本次已完成

- 新增 OpenAPI 3.1 合同，固定 `POST /mcp`、MCP `2026-07-28` 每请求元数据、8 个 method、11 个 Tool、6 类 Resource URI 和 Tasks 扩展。
- 为 `tools/call` 建立 11 个 `name const + arguments schema` 分支，并定义 JSON Schema 2020-12 输入输出、Tool Complete/Task Result、Resource 和 Task DTO。
- 明确 `/mcp` 是用户确认的 `/api/v1` 路径例外；HTTP 400/403 只用于 MCP 强制传输拒绝，业务错误继续使用 HTTP 200。
- 新增 `McpTaskBinding` 设计态表，只保存短期 Task 映射，不复制 ApplicationRun/AtomicTask 状态，不建立跨域 FK。
- 登记 `190200-190999` 四段 MCP 错误区间，新增 27 个协议、分发、Task 映射和访问错误。
- 新增 5 个 MCP 权限，并固化 11 个 Tool 对 Model Gateway、Application Platform、Task Center 和 Asset Library 既有权限的叠加映射。
- 新增显式无领域事件合同；MCP v1 同步读取源领域事实，安全审计写入 Identity audit 边界。
- 新增完整模块合同与 `02_architecture/domains/mcp.md`，同步全局架构、MCP S1、Domain/Global Context、Context Map、Changelog 和错误码索引。
- 将 MCP 素材内容上传方法与 Asset Library 正式合同对齐为 `POST /api/v1/asset-uploads/{upload_id}/content`。

## 当前进行中

- 无。

## 文件变化

- 新增：`01_contracts/domains/mcp/openapi.yaml`、`schema.sql`、`errors.yaml`、`permissions.yaml`、`events.yaml`、`module-contract.md`。
- 新增：`02_architecture/domains/mcp.md`。
- 修改：`00_product/domains/mcp/product-spec.md`、`domains/mcp/context.md`。
- 修改：`01_contracts/error-code-index.md`、`02_architecture/global-architecture.md`、`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、`CHANGELOG.md`、`docs/HANDOFF.md`。
- 修改：`RELEASE.md`，新增 `spec-v1.9.2` 正式发布记录。
- 保留用户已有无关改动：`agent/`、`appstudio/`、`archive/`、`设计图/`、`skills/archive/`。

## 关键设计决策

- Capability 只读发现；不存在 `omnimam.capabilities.invoke`、CapabilityInvocation 或泛化 Invocation。
- 唯一异步执行入口是已发布且 `run_enabled=true` 的 Application；Application Platform 先持久化 ApplicationRun/AtomicTask，MCP 再创建 Binding。
- MCP Task TTL 只清理 `McpTaskBinding`，不得删除或改写 ApplicationRun、AtomicTask、Artifact、Asset 或审计事实。
- MCP 权限只控制协议能力，不能替代 `aiapp.*`、`task.*`、`asset.*` 权限和资源可见性。
- 下游业务错误保留源领域 `code/value/messages/retryable`；`ERR_MCP_*` 只表示 MCP 自身失败。
- MCP v1 不发布领域事件，不支持 OAuth/PAT、`input_required`、`tasks/update`、动态 Tool 或直接 StorageBackend 上传。

## API、Schema、依赖与配置变化

- `POST /mcp` 支持 `server/discover`、`tools/list/call`、`resources/list/templates/list/read`、`tasks/get/cancel`。
- 官方 MCP camelCase 和 Header 使用 `x-naming-exception`；OmniMAM Tool 参数和业务投影使用 lower_snake_case。
- 设计态 Schema 新增单表 `mcp_task_bindings`，包含通用资源字段、Principal、ApplicationRun、AtomicTask、扩展 ID、TTL 和幂等唯一约束。
- 新增 `mcp.protocol.access`、`mcp.discovery.read`、`mcp.resource.read`、`mcp.task.read`、`mcp.task.cancel`。
- 当前无运行时配置文件、正式 migration、生产代码或 CI/CD 变化。

## 验证结果

- 41 份当前 S2 YAML 全部可解析。
- MCP OpenAPI 157 个本地 `$ref` 全部可解析；8 个 method、11 个 Tool catalog/call 分支和 6 个 Resource Template 完整一致。
- Redocly CLI 对 OpenAPI 3.1 校验通过。
- 对照官方 MCP `2026-07-28` JSON Schema，RequestMeta 必填字段、Tool input/output Schema 和 Tool Result 字段对齐。
- 全仓 98 个错误码 code/value 唯一且区间已登记；其中 MCP 27 个。
- 全仓 64 个权限码唯一且 S1 引用可解析；其中 MCP 5 个，所有委托权限真实存在。
- 全仓 67 张设计表无重名；MCP Schema 只有 `mcp_task_bindings`，无跨域 FK。
- MCP S2 中全部 BR/US 引用可解析，无缩写编号残留。
- MCP S1、MCP 领域架构和全局架构共 8 张 Mermaid 图经 Mermaid CLI 渲染通过。
- Markdown 围栏、Context 路径和 `git diff --check` 通过；Release 记录中的文件与实施门禁已复核。
- 最终 Spec commit：`45ea82d4fd42b1697f4cd9af24c2ccb1ac965373`。
- Release commit：`32ae994`；annotated tag `spec-v1.9.2` 指向该提交。
- `spec-v1.9.2` 已登记为 released，`allowed_as_formal_implementation_basis: true`。
- `origin/master` 与远端 `spec-v1.9.2` tag 已推送成功。

## 待办、问题与风险

- Identity 当前只有 S1、缺少 S2；MCP JWT 验签、撤销检查和 AuditLog 的具体实现仍受该门禁约束。
- 后续启用 OAuth/PAT、Capability 直接执行或交互式 MCP Task 必须先修改 S1，不能由实现自行扩展。
- 本地 `spec-v1.9.0`、`spec-v1.9.1` tag 属于其他 worktree 分支且未在当前 master/远端发布，本次未移动或覆盖这些 tag。

## 推荐下一步

按 `spec-v1.9.2` 实现门禁补齐 Identity S2 的 JWT/Audit 边界，再实施 MCP Server。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
