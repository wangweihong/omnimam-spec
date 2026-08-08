# OmniMAM Spec Handoff

## 当前目标与状态

- 目标：为 Agent MCP Binding 生命周期、不可变 revision、Runtime Grant、Infrastructure 解析注入、`AGENT_WORKLOAD` MCP 身份和 AppStudio 默认平台 Binding 补齐 S1/S2，并发布新的 SSOT release。
- 状态：SSOT 跨域修订与聚焦验证已完成，准备创建规范内容提交并发布 `spec-v1.19.0`；Server 实现尚未开始，必须等待 release 发布并 pin。
- 工作分支：`codex/agent-mcp-runtime`。

## 本次已完成

- 已确认 `spec-v1.18.0` 只定义 MCP Binding 的 List/Create 和 `agent.runtime.ensure.mcp_binding_refs` 输入，尚未定义更新/删除、revision/grant、Infrastructure 解析端口、OpenCode 配置注入和 workload JWT。
- 已确认首版只接入 AppStudio Coding Agent 的 OpenCode Runtime；Hermes 暂不接入 MCP 注入。
- 已锁定默认平台 Binding、更新凭证模式、软删除、下一次 Runtime 生效和最小权限边界。
- 已补齐 Agent S1/S2 的 MCP Binding PUT/DELETE、活动名称唯一、不可变 revision、Runtime Grant、错误码和 OpenCode Runtime fixture。
- 已补齐 AppStudio 首次创建/代际替换的原子默认平台 Binding、已有 generation 幂等回填和删除后同代不重建语义。
- 已补齐 Infrastructure `MCP_SERVER_REF` consumer resolver 与 Docker tmpfs/0600/启动门闩注入合同。
- 已补齐 Identity `AGENT_WORKLOAD` PrincipalContext/JWT 和 MCP 每请求 Grant 复核、最小权限及 USER JWT 不回归合同。
- 目标 YAML 解析、四个受影响 OpenAPI 本地 `$ref`、Agent 错误码唯一性/区间/追溯和 `git diff --check` 已通过。

## 当前进行中

- 创建规范内容提交，用其 commit 更新 release 元数据，创建 annotated tag 并推送。

## 文件变化

- Modified: Agent 的 `product-spec.md`、`openapi.yaml`、`schema.sql`、`errors.yaml`、`module-contract.md`、`runtime-protocol-fixtures.yaml`。
- Modified: AppStudio 的 `product-spec.md`、`module-contract.md`。
- Modified: Infrastructure 的 `product-spec.md`、`openapi.yaml`、`module-contract.md`。
- Modified: Identity 的 `product-spec.md`、`openapi.yaml`、`module-contract.md`。
- Modified: MCP 的 `product-spec.md`、`openapi.yaml`、`module-contract.md`；Modified: `docs/HANDOFF.md`。

## 关键决定

- 目标 release 预计为 `spec-v1.19.0`，因为包含跨域 API、Schema、身份和 Runtime 协议新增。
- 更新/删除不打断运行中的容器，只影响后续启动、恢复或显式重建。
- Binding revision 不保存明文凭证；Infrastructure 只能通过授权引用解析，不得直接读取 Agent 数据表。
- 空 `allowed_tools` 表示拒绝全部 MCP 工具。

## API、Schema、依赖或配置变化

- 新增 MCP Binding item PUT/DELETE、Binding revision、Runtime Grant、`MCP_SERVER_REF`、OpenCode fixture 与 `AGENT_WORKLOAD` 身份契约；function registry 的既有 `mcp_binding_refs` schema 未改变。

## 验证与风险

- 已完成目标结构验证；未运行全仓验证，符合任务读取/验证范围约束。
- 风险：跨域权限、错误码、OpenAPI 和 schema 必须保持可追溯且与 function registry digest 一致。

## 未完成事项

- 完成 SSOT 修订、目标验证、release 元数据、提交和 tag/push。
- 在 Server 仓库更新 submodule pin 与 `SSOT_VERSION` 后实施后端。

## 推荐下一步

创建规范内容提交，并把准确 commit 写入 `RELEASE.md` 的 `spec-v1.19.0` 记录。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
