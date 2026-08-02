# Identity Module Contract

## 1. 事实源与范围

- S1：00_product/domains/identity/product-spec.md
- 本合同覆盖 authn、session、user、rbac、principal、resource-access 和 service-account；认证配置与平台审计由 `platform-management` 拥有。
- Identity S2 不提供 PAT、LDAP/SSO、OAuth2/OIDC、MFA、可信设备、动态用户组或角色继承/互斥。
- schema.sql 是设计态 Schema，不是 migration；本域不定义业务 domain 的资源状态。
- 相关 S1：BR-IAM-005、BR-IAM-009、BR-IAM-010、BR-IAM-011、BR-IAM-015、BR-IAM-019、BR-IAM-021、BR-IAM-022；US-IAM-006、US-IAM-008、US-IAM-009、US-IAM-011、US-IAM-013、US-IAM-014。

## 2. 模块职责

| 模块 | 负责 | 不负责 |
| --- | --- | --- |
| authn | 本地注册、Argon2id 密码校验、首次登录、Access/Refresh Token 签发和刷新 | LDAP/OIDC/MFA、业务资源授权 |
| session | AuthSession、TokenCredential、RefreshToken 生命周期、撤销和当前会话在线心跳 | 用户角色、业务资源状态 |
| user | User 资料、状态、注册/管理员创建、删除前置检查协调 | 业务资源删除、业务资源 owner 转移 |
| rbac | Role、PermissionDefinition、用户/组角色关系和有效权限缓存 | 业务 domain 的资源可见性 |
| principal | 验证 USER/SERVICE_ACCOUNT、构建 PrincipalContext、受控委托和权限判定 | 直接读取其他 domain 私有表 |
| resource-access | 已接入资源 domain 的 ResourceAccessGrant | 资源存在性、owner、visibility、版本和业务状态 |
| service-account | ServiceAccount、短期服务凭据、轮换、撤销和最小权限 | 普通用户登录和用户 Refresh Token |
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

密码与在线状态规则：

- User.password_hash 必须是 Argon2id v=19 的完整 PHC 字符串；当前基线为 `m=65536,t=3,p=1`、32 字节输出和至少 16 字节独立随机 salt。
- `ARGON2ID_V1` 是当前固定的 password_hash_policy；管理员可调整普通密码策略和在线窗口，但不能通过认证配置 API 切换算法或降低哈希参数。
- 密码明文、可逆密文、密码哈希和原始 Secret 不得出现在响应、事件、审计或 PrincipalContext；登录成功后可按当前策略透明升级旧 Argon2id 参数。
- 用户 `online` 是派生字段：`User.status = ACTIVE` 且存在 `AuthSession.status = ACTIVE`、未过期并满足 `last_active_at >= now - online_presence_window_seconds` 时为 true，默认窗口为 300 秒。
- presence heartbeat 只能更新当前 AuthSession.last_active_at，不改变会话或 Token 的 expires_at，不产生可靠领域事件；撤销、过期或禁用用户的会话不参与在线判定。

相关 S1：BR-IAM-005、BR-IAM-009、BR-IAM-010、BR-IAM-019；US-IAM-006、US-IAM-011。

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

## 5. 一致性与安全

- User、AuthSession、TokenCredential、RefreshToken、Role/Grant、ResourceAccessGrant 和 ServiceAccount 的事实在 Identity 内部原子提交；SystemAuthConfig 与 AuditLog 的事实在 platform-management 内部原子提交。
- 需要通知其他模块的变化先写 Identity Outbox，再异步投递 events.yaml 中的可靠事件。
- 授权变化递增 authorization_version；密码、用户禁用和凭据轮换递增 security_version/credential_version 并撤销受影响凭据。
- 登录成功、Refresh Token 成功轮换和 presence heartbeat 更新当前 AuthSession.last_active_at；在线状态按当前时间派生，不持久化为 User.status。
- Refresh Token 重用必须在同一安全边界内撤销会话及其 Refresh Token，并写入脱敏审计。
- platform-management 审计写入不可用时，登录、凭据、授权、跨 owner、服务账号和其他敏感操作 fail closed；普通只读查询不得写入 Secret。
- 所有响应和事件禁止密码、完整 Access/Refresh Token、client_secret、凭据哈希、内部签名材料、原始 payload 和私有存储地址。

相关 S1：BR-IAM-006、BR-IAM-007、BR-IAM-014、BR-IAM-015、BR-IAM-016；US-IAM-004、US-IAM-008、US-IAM-009。

## 6. 事件与恢复

- Identity 可靠事件必须在对应事实持久化后写入 Outbox，事件携带 event_id、聚合 ID、aggregate_version、时间、主体和最小非敏感 payload。
- 消费者按 event_id 去重、按同一聚合 aggregate_version 单调处理；不同聚合版本不可比较。
- 事件投递失败不得回滚已提交的 Identity 事实；消费者必须可重试或通过受控 API 重建投影。
- 事件延迟期间，业务 domain 以重新调用 Identity 的当前授权结果为准，不因旧事件继续授权。

相关 S1：BR-IAM-015、BR-IAM-019；US-IAM-009、US-IAM-011。

## 7. 查询预算

- 用户、角色、组和权限列表在 Identity 内分页查询。
- PrincipalContext 一次请求只返回当前需要的权限结果和最多一跳非敏感主体摘要。
- ResourceAccessGrant 列表必须按 resource_type/resource_id 批量读取；不得因目标资源逐行调用形成 N+1。
- 跨 domain 资源摘要由目标 domain 批量提供；Identity 不递归展开 Application、Task、Asset、Canvas、Agent 或 Workspace。
- Identity 不提供审计列表；需要查询审计时调用 platform-management 的受控查询接口。Identity 提交的审计上下文固定字段、脱敏并限制大小，不得包含完整请求 payload。

相关 S1：BR-IAM-012、BR-IAM-019；US-IAM-006、US-IAM-009。

## 8. 实施门禁

- 任何服务实现前必须先确定 Identity S2 的 JWT 签名/密钥轮换、撤销查询、ServiceAccount 凭据交换，以及 platform-management 的 SystemAuthConfig 读取和 AuditLog 写入接口；本合同不允许实现方自行发明未定义的接口。
- 本合同完成后仍需用户确认并记录在 RELEASE.md，未 Release 前只能用于草稿讨论、实现评估和合同审查。
