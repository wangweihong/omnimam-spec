# Identity Module Contract

## 1. 事实源与范围

- S1：00_product/domains/identity/product-spec.md
- 本合同覆盖 authn、session、user、rbac、principal、resource-access 和 service-account；认证配置与平台审计由 `platform-management` 拥有。
- Identity S2 不提供 PAT、LDAP/SSO、OAuth2/OIDC、MFA、可信设备、动态用户组或角色继承/互斥。
- schema.sql 是设计态 Schema，不是 migration；本域不定义业务 domain 的资源状态。
- 相关 S1：BR-IAM-005、BR-IAM-009、BR-IAM-010、BR-IAM-011、BR-IAM-015、BR-IAM-019、BR-IAM-021、BR-IAM-022、BR-IAM-023、BR-IAM-024、BR-IAM-025、BR-IAM-026、BR-IAM-027、BR-IAM-028、BR-IAM-029、BR-IAM-030；US-IAM-006、US-IAM-008、US-IAM-009、US-IAM-011、US-IAM-013、US-IAM-014、US-IAM-015、US-IAM-016、US-IAM-017、US-IAM-018、US-IAM-019、US-IAM-020。

## 2. 模块职责

| 模块 | 负责 | 不负责 |
| --- | --- | --- |
| authn | 本地 OPAQUE 注册/登录/改密、首次登录、Access/Refresh Token 签发和刷新、ServiceAccount 短期 Token 交换 | LDAP/OIDC/MFA、业务资源授权 |
| session | AuthSession、TokenCredential、RefreshToken 生命周期、撤销和当前会话在线心跳 | 用户角色、业务资源状态 |
| user | User 资料、状态、RegistrationApplication、注册审批、管理员创建和删除依赖检查协调 | 业务资源删除、业务资源 owner 转移 |
| rbac | Role、PermissionDefinition、用户/组角色关系和有效权限缓存 | 业务 domain 的资源可见性 |
| principal | 验证 USER/SERVICE_ACCOUNT、构建 PrincipalContext、受控委托和权限判定 | 直接读取其他 domain 私有表 |
| resource-access | 已接入资源 domain 的 ResourceAccessGrant | 资源存在性、owner、visibility、版本和业务状态 |
| service-account | ServiceAccount、直接角色、owner 受控校验、短期服务凭据、轮换、撤销和最小权限 | 普通用户登录、用户 Refresh Token、owner 私有事实 |
| config-consumer | 读取 platform-management 当前生效的 SystemAuthConfig，并在认证流程中执行策略 | SystemAuthConfig 存储、配置管理 API 和配置版本事实 |
| audit-client | 向 platform-management 提交脱敏审计上下文并处理审计边界不可用 | AuditLog 存储、查询、Outbox 和审计事件事实 |

## 3. PrincipalContext

Identity 为业务 domain 提供受验证的一跳上下文：

principal_type: USER | SERVICE_ACCOUNT
principal_id: string
actor_user_id: string|null
auth_session_id: string|null
credential_version: integer
authorization_version: integer
permission_results:
  - permission_code: string
    allowed: boolean

规则：

- principal_id 是实际认证主体；服务主体代表用户执行时才填写 actor_user_id。
- actor_user_id 必须由已验证的委托链产生，不能接受客户端任意请求字段。
- PrincipalContext 不包含密码、Token 原文、完整角色图、共享授权全集、Secret 或目标 domain 私有数据。
- 每个业务请求必须重新校验 Token/凭据状态和当前权限；不能仅依赖 JWT 签名或旧缓存。
- permission_results 只覆盖本次请求所需权限，不是完整权限列表。

前端授权投影与 PrincipalContext 不同：登录、Refresh 和 `GET /api/v1/iam/auth/permissions` 返回完整的当前主体 `authorization_version`、`effective_roles`、去重 `permission_codes`、`session_mode` 和 `allowed_actions`。角色来源只用于展示与解释，后端仍按当前 PrincipalContext 的请求级结果执行授权。投影不得写入 JWT；客户端收到更高授权版本后整体重取，不合并旧投影。

密码与在线状态规则：

- User.opaque_registration_record 必须是固定 OPAQUE 配置生成的 registration record base64url 编码；Web 使用 `@serenity-kit/opaque@1.1.0`，Go 使用 `github.com/bytemare/opaque@v0.18.0`，套件为 Ristretto255/SHA-512，KSF 为 Argon2id `t=3,m=65536,p=4`，context 为 `omnimam/identity/opaque/v1`。
- 服务端 setup 是稳定部署密钥配置；setup 变更会使全部 registration record 失效，不能在运行中静默轮换。
- 密码明文、前端哈希、可逆密文、registration exchange 原始密码字段和原始 Secret 不得出现在请求、响应、事件、审计或 PrincipalContext。
- 注册、登录、改密和管理员初始密码操作必须通过短期一次性 `identity_opaque_exchanges` 完成；未知用户登录必须使用 fake record；finish 必须原子消费 exchange，过期或重复提交失败。
- 用户 `online` 是派生字段：`User.status = ACTIVE` 且存在 `AuthSession.status = ACTIVE`、未过期并满足 `last_active_at >= now - online_presence_window_seconds` 时为 true，默认窗口为 300 秒。
- presence heartbeat 只能更新当前 AuthSession.last_active_at，不改变会话或 Token 的 expires_at，不产生可靠领域事件；撤销、过期或禁用用户的会话不参与在线判定。

相关 S1：BR-IAM-005、BR-IAM-009、BR-IAM-010、BR-IAM-019、BR-IAM-024、BR-IAM-025；US-IAM-006、US-IAM-011、US-IAM-016。

## 4. 跨域调用

### 4.1 资源 domain

- application-platform、asset-library、workflow-canvas、task-center、agent、appstudio 和其他业务 domain 通过受控模块接口提供 owner/visibility/状态裁剪结果。
- Identity 不读取目标 domain 私有表，不创建跨 domain 外键，不把 ResourceAccessGrant 当作资源存在性证明。
- 目标 domain 必须拒绝客户端指定其他 owner；owner_user_id/created_by 由已验证 PrincipalContext 或受控 producer context 注入。
- 目标 domain 决定 owner 是否天然拥有 MANAGE、哪些 access level 有效、global visibility、项目/命名空间和删除/归档行为。
- 不可见或不存在目标资源必须使用目标 domain 的稳定业务结果；Identity 不通过用户目录或 grant 列表泄露资源存在性。

相关 S1：BR-IAM-011、BR-IAM-012、BR-IAM-013、BR-IAM-019；US-IAM-006、US-IAM-007、US-IAM-012。

### 4.2 业务执行链路

- 用户发起的 Application、Canvas、Task、Agent、AppStudio 或 MCP 操作可以由服务主体执行，但必须保留原始用户授权和 actor_user_id。
- task-center 的 created_by、asset-library 的 owner_user_id、application-platform 的 owner_user_id/visibility、workflow-canvas 的 project_id/namespace/created_by 和 agent/appstudio 的 owner/collaborator 规则均由目标 domain 维护。
- mcp v1 每个请求使用 Identity JWT；不使用 PAT、OAuth 或独立 MCP scope。
- sse 和 notification-center 只消费已裁剪的可靠事件或受控摘要，不读取 Identity/业务私有表。

相关 S1：BR-IAM-010、BR-IAM-011、BR-IAM-019；US-IAM-006、US-IAM-011。

### 4.3 用户删除依赖检查

- Identity 的 user 模块维护已登记依赖来源集合，并向每个来源 domain 调用受控批量 `CheckUserDeletionDependencies` 合同；不得读取其私有表。
- 来源返回 `source_domain/category/object_type/count/blocking/source_status/handling_mode/management_entry/source_version`。`management_entry` 是已登记前端路由键，不接受任意 URL。
- Identity 自身负责角色/组关系、ServiceAccount 和 ResourceAccessGrant 摘要；目标 domain 负责资源 owner、未完成任务、转移目标资格和清理完成事实。
- 任一来源超时、不可用、版本不一致或未返回时，检查状态为 `INCOMPLETE` 并 fail closed。完整结果以短期 `dependency_check_id` 保存；删除提交必须重验来源集合、有效期和阻塞计数。
- 资源转移由目标 domain 原子持久化，目标用户必须为 ACTIVE 且满足目标 domain 规则。Identity 不提供统一 owner 写接口。

受控检查合同的逻辑结构固定为：

```yaml
request:
  user_id: string
  dependency_check_id: string
  requested_at: string(date-time)
response:
  source_domain: string
  source_version: string
  items:
    - category: string
      object_type: string
      count: integer
      blocking: boolean
      source_status: AVAILABLE | UNAVAILABLE
      handling_mode: TRANSFER | DELETE | CANCEL | REVOKE | DISABLE | NONE
      management_entry: string|null
```

来源必须一次返回该用户在本 domain 的完整摘要，不能要求 Identity 或前端逐对象查询。

相关 S1：BR-IAM-017、BR-IAM-019、BR-IAM-028；US-IAM-002、US-IAM-017。

### 4.4 ServiceAccount owner 与共享目录

- ServiceAccount 创建时，除 SYSTEM 外都必须通过 owner domain 的受控接口校验 owner 存在、状态和操作者管理权；详情/列表通过批量一跳投影返回 `owner_type/owner_id/display_name/state`。
- owner domain 删除目标前必须把关联 ServiceAccount 纳入依赖检查；异常缺失或 owner 投影不可用时，Token 交换 fail closed，Identity 不静默改绑。
- ServiceAccount 只使用 `ServiceAccountRoleGrant` 获得直接角色，不加入 Group；角色、角色权限和角色状态变化递增每个受影响服务主体的 `authorization_version`。
- 共享用户/组目录只返回 S1 允许的最小摘要。Identity 不在目录响应中返回邮箱、手机号、角色、在线状态或安全字段；资源域提供支持的 access level 和资源可见性裁剪。

owner 批量投影固定返回 `owner_type`、`owner_id`、`display_name` 和 `state=AVAILABLE|DELETED|UNAVAILABLE|NOT_VISIBLE`；不得包含 owner domain 私有配置、凭据或递归摘要。列表查询必须按 `owner_type + owner_id` 批量解析。

相关 S1：BR-IAM-012、BR-IAM-019、BR-IAM-026、BR-IAM-027、BR-IAM-029；US-IAM-018、US-IAM-019。

## 5. 一致性与安全

- User、AuthSession、TokenCredential、RefreshToken、Role/Grant、ResourceAccessGrant 和 ServiceAccount 的事实在 Identity 内部原子提交；SystemAuthConfig 与 AuditLog 的事实在 platform-management 内部原子提交。
- Identity 的权限目录同步必须聚合所有 domain 当前 `permissions.yaml` 中 ACTIVE 权限的 `default_roles`，并幂等对账内置 `USER`、`ADMIN`、`SUPER_ADMIN` 的 `identity_role_permission_grants`。权限定义登记与默认角色授权对账必须作为同一受控初始化/升级流程完成，不能只写 `identity_permission_definitions`。
- Identity/Platform 管理基线固定为：`USER` 至少拥有 `identity.auth.session`、`identity.user.read`、`identity.permission.read`、`identity.resource_grant.read`；`ADMIN` 额外拥有 `identity.user.manage`、`identity.registration.review`、`identity.group.manage`、`identity.service_account.read`、`platform.overview.read`、`platform.auth_config.read`、`platform.audit.read`；`SUPER_ADMIN` 额外拥有 `identity.role.manage`、`identity.service_account.manage`、`platform.auth_config.manage`。
- 默认角色授权对账必须校验权限码已登记且角色为 ACTIVE；新增缺失授权、删除已从 `default_roles` 移除的基线授权，并对实际受影响主体递增 `authorization_version`、失效权限缓存和发布 `identity.authorization.changed`。任一权限码、角色或写入异常都必须使本次对账失败，不得发布部分基线。
- 需要通知其他模块的变化先写 Identity Outbox，再异步投递 events.yaml 中的可靠事件。
- 授权变化递增 authorization_version；密码、用户禁用和凭据轮换递增 security_version/credential_version 并撤销受影响凭据。
- RegistrationApplication 决策与 User 状态、默认 USER 角色和 authorization_version 在 Identity 内原子提交；相同决策幂等，相反决策不能覆盖历史。
- ServiceAccount 轮换原子创建新凭据并撤销旧凭据及其 Token；禁用撤销全部凭据和 Token，重新启用不恢复旧凭据。
- 登录成功、Refresh Token 成功轮换和 presence heartbeat 更新当前 AuthSession.last_active_at；在线状态按当前时间派生，不持久化为 User.status。
- Refresh Token 重用必须在同一安全边界内撤销会话及其 Refresh Token，并写入脱敏审计。
- Identity 通过 platform-management 受控同步接口提交敏感操作审计；Identity 可靠事件不作为 AuditLog 写入通道。审计不可用时，登录、凭据、授权、跨 owner、服务账号和其他敏感操作必须回滚、撤销或补偿，不得留下可用效果并显示为成功。
- 所有响应和事件禁止密码、完整 Access/Refresh Token、client_secret、凭据哈希、内部签名材料、原始 payload 和私有存储地址。

相关 S1：BR-IAM-006、BR-IAM-007、BR-IAM-014、BR-IAM-015、BR-IAM-016、BR-IAM-023、BR-IAM-025、BR-IAM-026、BR-IAM-027、BR-IAM-028；US-IAM-004、US-IAM-008、US-IAM-009、US-IAM-015、US-IAM-016、US-IAM-017、US-IAM-018。

## 6. 认证协议与交换状态

- `register/start` 校验账号元数据并处理 registration request，返回 `exchange_id` 和 registration response；`register/finish` 只接收匹配 exchange 与 registration record。
- `login/start` 只接收登录标识和 KE1，返回 `exchange_id` 与 KE2；`login/finish` 只接收匹配 exchange 与 KE3，KE3 校验成功后才创建会话。
- `change-password/start` 使用当前用户 registration record 处理 KE1；`change-password/finish` 同时校验 KE3 和新的 registration record，成功后递增 security_version 并撤销旧会话。
- 管理员创建用户和重置初始密码使用相同 registration start/finish 语义；服务端不生成、接收或返回初始密码。
- 所有消息均为 base64url，单条消息和请求体有大小上限；旧的 `password`、`old_password`、`new_password`、`confirm_password` 单阶段请求统一返回 `ERR_IDENTITY_PASSWORD_PROTOCOL_UNSUPPORTED`。

## 7. 事件与恢复

- Identity 可靠事件必须在对应事实持久化后写入 Outbox，事件携带 event_id、聚合 ID、aggregate_version、时间、主体和最小非敏感 payload。
- 消费者按 event_id 去重、按同一聚合 aggregate_version 单调处理；不同聚合版本不可比较。
- 事件投递失败不得回滚已提交的 Identity 事实；消费者必须可重试或通过受控 API 重建投影。
- `identity.authorization.changed` 按受影响 USER 或 SERVICE_ACCOUNT 分别发布，只携带新版本和变化来源；SSE/客户端收到后重新读取投影，不从事件 payload 构造授权。
- 事件延迟期间，业务 domain 以重新调用 Identity 的当前授权结果为准，不因旧事件继续授权。

相关 S1：BR-IAM-015、BR-IAM-019；US-IAM-009、US-IAM-011。

## 7. 查询预算

- 用户、角色、组和权限列表在 Identity 内分页查询。
- PrincipalContext 一次请求只返回当前需要的权限结果和最多一跳非敏感主体摘要。
- ResourceAccessGrant 列表必须按 resource_type/resource_id 批量读取；不得因目标资源逐行调用形成 N+1。
- 跨 domain 资源摘要由目标 domain 批量提供；Identity 不递归展开 Application、Task、Asset、Canvas、Agent 或 Workspace。
- Identity 不提供审计列表；需要查询审计时调用 platform-management 的受控查询接口。Identity 同步提交的审计上下文包含来源、主体、目标、结果、occurred_at 和来源域幂等键，固定字段、脱敏并限制大小，不得包含完整请求 payload。
- 注册申请、用户删除检查、ServiceAccount 凭据历史均分页；owner 与删除依赖来源使用批量接口，禁止逐项跨 domain 调用形成 N+1。

相关 S1：BR-IAM-012、BR-IAM-019；US-IAM-006、US-IAM-009。

## 8. 实施门禁

- ServiceAccount 凭据交换已由 `POST /api/v1/iam/service-accounts/token` 定义；任何服务实现前仍必须确定 JWT 签名/密钥轮换、撤销查询，以及 platform-management 的 SystemAuthConfig 读取和 AuditLog 写入内部接口，不允许实现方自行发明未定义合同。
- 用户删除实现前，各参与 domain 必须登记 `CheckUserDeletionDependencies` 批量合同、来源版本和管理路由键；来源未登记或不可用时不得开放删除。
- 本合同完成后仍需用户确认并记录在 RELEASE.md，未 Release 前只能用于草稿讨论、实现评估和合同审查。
