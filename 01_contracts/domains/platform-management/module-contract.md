# Platform Management Module Contract

## 1. 事实源与范围

- S1：`00_product/domains/platform-management/product-spec.md`
- 本合同覆盖只读 `PlatformOverview`、`SystemAuthConfig`、`AuditLog`、平台认证配置消费和跨 domain 平台审计。
- `schema.sql` 是设计态 Schema，不是 migration；平台管理不拥有 Identity、Engine、用户模型、素材、任务或通知私有表。
- 相关 S1：`BR-PLATFORM-001..009`、`US-PLATFORM-001..005`。

## 2. 模块职责

| 模块 | 负责 | 不负责 |
| --- | --- | --- |
| overview | 返回固定平台运行/部署元数据和最近 10 条脱敏审计摘要 | 其他 domain 业务统计、基础设施监控、配置写入和私有表读取 |
| auth-config | SystemAuthConfig 读取、完整替换、版本校验、派生 allow_registration 和变更事件 | 用户密码校验、Token 签发、会话生命周期 |
| audit | 脱敏 AuditLog 追加、查询、Outbox 和审计可用性保护 | 用户、角色、业务资源状态和通知收件箱 |

## 3. SystemAuthConfig 消费合同

- 第一阶段只存在 `id=default` 的单例配置；管理端使用 PUT 完整替换，并以 `resource_version` 乐观并发，冲突时不得覆盖当前版本。
- `registration_mode` 是唯一可写注册策略；`allow_registration` 只读派生，`OPEN` 为 true，`ADMIN_APPROVAL` 为 false。
- `password_policy` 和 `login_failure_policy` 必须使用 OpenAPI 定义的结构化字段；未知字段、跨字段约束和生命周期范围非法时返回 `ERR_PLATFORM_AUTH_CONFIG_INVALID`。
- password hash policy 固定为 Identity S1 定义的 Argon2id 基线；Platform 不允许通过配置 API 切换算法或降低参数。
- Identity 通过 `platform.auth_config.read_internal` 读取当前配置，并校验返回的 resource version。
- Identity 不得缓存无法与平台版本关联的认证策略；配置更新事件只携带失效所需版本和操作者摘要，不能作为部分配置应用或扩大授权。
- 配置缺失、版本冲突或策略非法时，认证相关受保护操作返回稳定平台错误；实现不得静默使用不明默认值。
- 配置新版本、`platform.auth_config.update` AuditLog 和 `platform.system_auth_config.changed` Outbox 必须在平台管理边界内原子提交；任一步失败都不改变当前版本。

## 4. PlatformOverview 查询合同

- `platform.overview.read` 只允许已授权管理员读取；响应固定包含平台运行/部署元数据和最近最多 10 条 `PlatformAuditLogSummary`。
- `platform_name` 固定为 `OmniMAM`；版本、环境、部署模式、时区、启动时间和运行时长来自运行时或部署元数据，不形成可在线修改的 Platform 配置。
- 审计摘要当前只筛选 `action=platform.auth_config.update`，按 `occurred_at DESC, id DESC` 读取；Identity 高频认证审计只在审计列表中查询。
- 审计摘要只包含 ID、来源、操作、目标引用、结果、发生时间和创建时间，不展开 detail、凭据、Token、原始请求或业务正文。
- 没有审计记录时返回空列表；运行元数据或审计读取边界不可用时返回 `ERR_PLATFORM_OVERVIEW_UNAVAILABLE`，不得返回模拟数据或部分伪造的成功响应。
- PlatformOverview 不读取或复制素材、应用、模型、任务和通知统计；这些能力延期到下一阶段，届时必须通过目标 domain 的受控摘要合同接入。

## 5. AuditLog 写入合同

- 受控 domain 使用 `platform.audit.record` 提交 `source_domain`、`source_module`、PrincipalContext 摘要、目标、结果、原因、request/trace ID、`occurred_at`、幂等键和最小 detail。
- 内部接口只接受登记的服务主体 Token。Platform 服务端从服务主体登记校验 `source_domain/source_module`、委托用户、字段长度、发生时间、禁止字段和幂等作用域；调用方不能伪造其他来源或主体。
- `platform_audit_logs` 只能追加，业务 API 不提供更新或删除；幂等作用域为 `source_domain + source_module + idempotency_key`，以服务端接受后的规范化内容 SHA-256 比较。相同内容重试返回原记录，不同内容复用键返回 `ERR_PLATFORM_AUDIT_IDEMPOTENCY_CONFLICT`。
- `detail` 必须脱敏且有界，UTF-8 JSON 最多 16 KiB、最多 4 层；不得包含密码、完整 Access/Refresh Token、Secret、凭据哈希、Authorization、原始请求 payload、Provider 响应、文件路径或大型正文。命中禁止字段时拒绝整条记录。
- 登录、密码、Token、授权、服务账号、跨 owner 和认证配置等敏感操作在审计写入失败时必须 fail closed。跨 domain 来源在返回成功前必须确认 AuditLog 已追加；失败时回滚、撤销或补偿，确保不留下可用会话、凭据或授权效果。普通只读查询不产生审计写入要求。
- 来源可靠事件只能补偿非敏感诊断记录；不能代替敏感操作的同步审计确认，也不能把未确认记录伪装为已持久化 AuditLog。
- AuditLog 持久化与 `platform.audit.recorded` Outbox 在平台管理边界内原子提交；事件延迟不影响已提交审计事实。

## 6. Identity 协作

- Identity 拥有 User、AuthSession、TokenCredential、RefreshToken、Role/Grant、ResourceAccessGrant 和 ServiceAccount；Platform 不创建这些表或镜像这些事实。
- Identity 认证流程通过受控内部接口读取 SystemAuthConfig；Identity 的敏感操作通过受控内部接口追加 AuditLog。
- Identity 可靠事件不由 Platform 作为 AuditLog 写入通道消费；平台审计只接受受控同步接口记录，避免重复写入和将异步投递误作 fail-closed 确认。
- Identity 的旧 `identity.auth_config.*`、`identity.audit.read` API/权限和 `identity_system_auth_configs`、`identity_audit_logs` 表均废弃；新实现不得创建。

## 7. 查询与安全

- AuditLog 列表从 `page_num=0` 开始分页，支持 keyword/search_fields、source_domain、source_module、principal、action、target、request、result、发生时间和创建时间过滤，以及受控排序字段。
- `occurred_at` 是来源操作时间，`created_at` 是平台接收时间；默认按 `occurred_at DESC, id DESC` 排序，时间范围非法时返回 `ERR_PLATFORM_AUDIT_QUERY_INVALID`。
- 查询结果只返回权限裁剪的固定字段和有限 detail；不可见记录按稳定业务错误返回，不泄露存在性。
- 跨 domain 审计列表不递归展开 principal、actor、owner 或目标资源。审计响应保留操作发生时的稳定 ID 作为历史事实；管理员需要当前名称或状态时进入目标 domain 的受控页面，Platform 不为列表逐项补查。

## 8. 实施门禁

- 本合同完成后仍需用户确认并登记 `RELEASE.md`；未 Release 前只能用于草稿讨论、实现评估和合同审查。
- 正式实现前必须验证 Identity 服务主体到来源 domain/module 的登记、Token 撤销、委托链校验，以及每类敏感操作在审计失败后的回滚/撤销/补偿测试；实现不得直接访问平台数据库，也不得仅以异步事件声称满足 fail-closed。
