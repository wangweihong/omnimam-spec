# OmniMAM Spec Handoff

## 当前目标与状态

发布已提交的 `identity` 与 `platform-management` Spec 变更。状态：已完成；`spec-v1.11.0` 的 Release commit、annotated tag 和远端推送均成功，两领域 S1/S2 可按 Release 门禁作为正式实现、合并或验收依据。

## 本次工作完成

- Identity S1/S2 已完成认证、会话、用户、RBAC、PrincipalContext、资源授权和 ServiceAccount 契约；密码使用 Argon2id PHC 哈希，在线状态由有效会话活动时间派生，保留 presence heartbeat。
- Platform Management S1/S2 已完成只读平台概览、SystemAuthConfig、脱敏 AuditLog 和平台入口；素材、应用、模型、任务和通知统计延期，Platform 不复制其他 domain 事实。
- SystemAuthConfig、`allow_registration` 和 AuditLog 的事实归属迁移到 `platform-management`；Identity 只消费认证配置并提交脱敏审计上下文。
- 同步 Identity/Platform Context、全局上下文、Context Map、词汇、错误码索引、MCP 审计边界、架构参考、CHANGELOG 和 RELEASE 门禁说明。

## 当前进行中

- `spec-v1.11.0` 已发布：Spec commit 为 `1939166284c94e68bab731aeaddd8bba01ed9384`，Release commit 为 `9268135`，annotated tag 为 `spec-v1.11.0`；`master` 与 tag 已推送到 `origin`。
- 归档目录与设计图属于工作区已有无关改动，仍保留未提交：`archive/`、`设计图/`、`skills/archive/`。

## 文件变化

- Identity S1：`00_product/domains/identity/product-spec.md`。
- Identity S2：`01_contracts/domains/identity/{openapi.yaml,schema.sql,errors.yaml,permissions.yaml,events.yaml,module-contract.md}`。
- Platform S1：`00_product/domains/platform-management/product-spec.md`。
- Platform Context/S2：`domains/platform-management/context.md` 与 `01_contracts/domains/platform-management/{openapi.yaml,schema.sql,errors.yaml,permissions.yaml,events.yaml,module-contract.md}`。
- 联动文件：`00_product/glossary.md`、`01_contracts/domains/mcp/module-contract.md`、`01_contracts/error-code-index.md`、`02_architecture/domains/identity.md`、`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、`CHANGELOG.md`、`RELEASE.md`、`docs/HANDOFF.md`。
- 不纳入本次提交：`archive/`、`设计图/`、`skills/archive/`。

## 关键设计决策

- 所有 Identity/Platform 后端 API 使用 `/api/v1`；认证配置和审计管理路径归 Platform，Identity 不再拥有对应表、API、权限或事件。
- Identity 保留 44 个 OpenAPI operation、15 张设计态表、42 个错误码、12 个权限和 7 个可靠事件。
- Platform Management 定义 7 个 OpenAPI operation、3 张设计态表、9 个错误码、6 个权限和 2 个可靠事件；Platform Overview 不新增表或领域事件。
- 跨 domain 只通过稳定 ID、受控内部接口、权限裁剪摘要或可靠事件协作；`schema.sql` 仅为设计态 Schema，不是 migration。
- 两领域新增/迁移内容登记为 `spec-v1.11.0`，用户已确认发布，`allowed_as_formal_implementation_basis: true`。

## API、Schema、依赖与配置变化

- Identity API 前缀统一为 `/api/v1/iam`，增加 `/api/v1/iam/auth/presence/heartbeat`；移除 Identity 自有认证配置和审计接口/表。
- Platform API 定义 `/api/v1/platform/overview`、`/api/v1/platform/auth-config`、`/api/v1/platform/audit-logs` 及两个内部协作端点。
- Identity 错误码登记 `220200-221399`；Platform 错误码登记 `230200-230699`；跨 domain 引用不建外键。
- 未新增正式实现代码、实际 migration、运行时配置或依赖。

## 验证结果

- `python3` 成功解析 Identity/Platform 全部 YAML 文件。
- Identity/Platform S1 追溯引用、OpenAPI operation 引用的错误码和权限码检查通过。
- OpenAPI 实际计数已核对：Identity 44 个，Platform 7 个；Schema 表数量和可靠事件数量与文档一致。
- `git diff --check` 通过。
- Redocly CLI 未运行：当前环境没有本地 Redocly 包；未运行实现测试或构建，本任务只涉及 Spec 合同。

## 待办、问题与风险

- 用户需要评审 Identity JWT 验签/密钥轮换、服务凭据交换、撤销查询、审计写入边界及 ResourceAccessGrant 接入方式。
- 用户后续仍可评审 Platform Overview 元数据来源、SystemAuthConfig 和 AuditLog 写入边界；如需改变已发布语义，必须新增变更并重新 Release。
- 当前工作区仍有未纳入本次提交的归档删除/新增内容与设计图，提交后应继续单独处理或明确丢弃。

## 推荐下一步

读取本 handoff，核对 `spec-v1.11.0` 与远端状态；如需修改已发布语义，创建新的 Spec 变更并重新 Release。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
