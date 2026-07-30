# Identity Context

## 1. 领域职责

`identity` 是 OmniMAM 的横向身份认证与访问控制领域，统一管理用户、登录认证、Token 会话、动态 RBAC、用户组、SSO、LDAP、系统认证配置和安全审计。其他业务领域不得自行实现独立登录、硬编码角色判断或跨系统会话。

## 2. 核心对象

- `User`、`Group`、`GroupMember`：用户身份、组织分组与成员关系。
- `Role`、`UserRoleGrant`、`GroupRoleGrant`：角色及用户或组的授权关系。
- `RoleInheritance`、`RoleMutex`：角色继承与互斥约束。
- `PermissionResource`、`RolePermissionGrant`：权限资源和角色授权。
- `AuthSession`、`TokenCredential`：认证中心会话与 Token 凭据。
- `SystemAuthConfig`、`LdapServerConfig`、`AuditLog`：系统认证配置、外部身份源与审计。

## 3. 核心规则

- 用户身份、会话和权限计算必须由统一 IAM 提供，业务系统只消费当前主体和权限判定。
- 支持用户名、邮箱或手机号密码登录、用户注册、LDAP、JWT Access Token 和 Refresh Token。
- Token 刷新、局部登出与全局注销必须维持会话撤销和审计语义。
- 权限通过资源和权限码动态计算，前端展示控制不能替代后端校验。
- 用户组授权、角色继承和互斥关系必须参与最终权限计算。
- 密码、Token、LDAP 凭证和安全配置不得出现在普通响应或跨域摘要中。
- 登录失败保护、敏感操作和授权变化必须形成可追溯审计。
- 邮箱验证、MFA、可信设备、OAuth2/OIDC 登录和 OAuth Provider 管理当前不支持。

## 4. 领域边界

本领域拥有用户身份、认证会话、角色权限、外部身份绑定和审计。各业务资源的 owner、visibility 和业务权限语义仍由目标领域定义；identity 提供主体与授权基础，不拥有应用、任务、素材、画布或模型数据。

## 5. 上游与下游

上游是本地凭据和受控 LDAP 身份源。所有其他业务领域都是下游，通过当前用户、Token、权限码和审计上下文依赖 identity。跨域只传递必要主体和授权结果，不共享凭证明文或 IAM 私有表。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/identity/product-spec.md` | S1 | 身份、认证、RBAC、SSO、LDAP 和审计语义 |
| `02_architecture/domains/identity.md` | 参考 | 横向职责、核心链路和当前边界 |

当前尚未建立 identity S2 实现合同目录。任何 Identity API、Schema、错误码、权限码或事件任务都必须先从现有 S1 推导并建立 S2，不能由本 Context 代替。

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改登录、会话或 RBAC | S1 product-spec | 需要实现合同时先规划并创建 S2 |
| 修改 LDAP 或 SSO | S1 product-spec | 涉及运行边界时读 architecture |
| 修改业务资源权限 | 目标领域 S1/S2 | 仅主体与授权基础返回本 Context |
| 新增 OAuth/MFA | S1 product-spec | 当前为不支持能力，必须先做产品决策 |

## 8. 当前状态

S1 产品语义已确定，S2 实现合同延后且尚未建立。当前不应把架构参考、其他领域权限文件或 Context 当作 Identity API 和数据结构的正式依据。

## 9. 不在本领域定义的内容

- 业务资源的状态、生命周期和领域可见性规则不在本领域定义。
- 各领域操作权限码和 DTO 不在本 Context 定义。
- 当前延期的 MFA、可信设备和 OAuth2/OIDC 不属于已支持范围。
- 正式 IAM API、Schema、事件和 migration 尚未由本领域 S2 定义。
