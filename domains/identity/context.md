# Identity Context

## 1. 领域职责

`identity` 是 OmniMAM 的横向身份认证与访问控制领域，统一管理用户、登录认证、Token 会话、动态 RBAC、用户组和受控服务主体。系统认证配置与安全审计由 `platform-management` 持有，Identity 负责消费配置并提交脱敏审计上下文。其他业务领域不得自行实现独立登录、硬编码角色判断或跨系统会话。

## 2. 核心对象

- `User`、`Group`、`GroupMember`：用户身份、组织分组与成员关系。
- `Role`、`UserRoleGrant`、`GroupRoleGrant`：角色及用户或组的授权关系。
- `PrincipalContext`：当前用户或服务主体、凭据状态、可选委托用户和当前请求授权结果。
- `PermissionResource`、`RolePermissionGrant`：权限资源和角色授权。
- `ResourceAccessGrant`：由目标资源 domain 选择接入的用户/用户组共享授权。
- `AuthSession`、`TokenCredential`：认证中心会话与 Token 凭据。
- `RegistrationApplication`：ADMIN_APPROVAL 自主注册的申请、批准、拒绝和重新申请历史。
- `ServiceAccount`、`ServiceAccountRoleGrant`、`ServiceAccountCredential`：Worker、Agent Runtime、AppStudio 构建/部署等受控服务主体、直接角色和一次性凭据历史。
- `UserDeletionCheck`：Identity 聚合的短期跨域删除依赖摘要，不替代来源 domain 事实。
- `SystemAuthConfig`、`AuditLog`：由 `platform-management` 持有；Identity 只消费配置和审计写入边界。

## 3. 核心规则

- 用户身份、会话和权限计算必须由统一 IAM 提供，业务系统只消费当前主体和权限判定。
- 支持用户名或邮箱密码登录、用户注册、JWT Access Token 和 Refresh Token；手机号可作为用户资料，但当前不作为登录入口事实。
- 用户密码使用 Argon2id 不可逆哈希并以 PHC 字符串保存；成功登录或修改密码时按当前策略生成或升级哈希。
- 用户在线状态由 ACTIVE 用户的有效 AuthSession 和最近活动时间派生，默认在线窗口为 300 秒；presence heartbeat 只更新当前会话活动时间。
- Token 刷新、局部登出与全局注销必须维持会话撤销和审计语义。
- 登录、Refresh 和独立授权查询返回同一版本化主体投影，包括有效角色来源、权限码和会话限制；投影不写入 JWT，客户端版本失效后整体重取。
- 权限通过资源和权限码动态计算，前端展示控制不能替代后端校验。
- 各 domain `permissions.yaml` 的 `default_roles` 是内置角色授权基线；Identity 必须聚合并幂等物化为 `RolePermissionGrant`，同步授权版本，不能只登记权限定义。
- 用户组授权必须参与最终权限计算；角色继承和互斥关系当前不属于支持范围。
- 密码、Token、服务凭据和安全配置不得出现在普通响应或跨域摘要中。
- ADMIN_APPROVAL 注册在批准前不分配角色、会话或 Token；批准/拒绝保留不可变申请历史，拒绝后允许同一身份重新申请。
- ServiceAccount 只通过直接角色授权；owner 必须受控校验，owner 不可用时凭据交换 fail closed，Secret 只在创建或轮换时返回一次。
- 用户删除必须使用完整、未过期且提交前重验的跨域依赖检查；任何来源不可用都阻断删除，资源转移由目标 domain 完成。
- 登录失败保护、敏感操作和授权变化必须形成可追溯审计。
- 资源 owner、visibility、project、namespace 和资源状态由目标 domain 定义；只有目标 domain 声明接入时才使用 Identity 的通用共享授权。
- 邮箱验证、MFA、可信设备、LDAP、SSO、OAuth2/OIDC 登录、OAuth Provider 和 PAT 当前不支持。
- 资源共享用户目录不得返回其他用户在线状态；只有当前用户和受权管理员可查看其管理范围内的在线状态。

## 4. 领域边界

本领域拥有用户身份、注册申请、认证会话、角色权限、服务主体、删除依赖聚合快照和可选资源共享授权；不拥有 `SystemAuthConfig` 或 `AuditLog`。各业务资源的 owner、visibility、删除依赖事实、转移动作和业务权限语义仍由目标领域定义；identity 提供主体与授权基础，不拥有应用、任务、素材、画布或模型数据。

## 5. 上游与下游

上游是本地凭据和受控内部服务主体。所有其他业务领域都是下游，通过当前用户、服务主体、Token、权限码、PrincipalContext 和审计上下文依赖 identity。跨域只传递必要主体和授权结果，不共享凭证明文或 IAM 私有表。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/identity/product-spec.md` | S1 | 身份、认证流程、RBAC、PrincipalContext、资源授权和审计协作语义 |
| `01_contracts/domains/identity/openapi.yaml` | S2 | 认证、用户、RBAC、资源授权、服务主体和 PrincipalContext API |
| `01_contracts/domains/identity/schema.sql` | S2 | Identity 设计态用户、授权、会话、凭据、服务主体和 Outbox 表 |
| `01_contracts/domains/identity/errors.yaml` | S2 | Identity 业务错误码 |
| `01_contracts/domains/identity/permissions.yaml` | S2 | Identity 权限码及后端强制校验 |
| `01_contracts/domains/identity/events.yaml` | S2 | 用户、会话、授权、资源共享、服务主体和供平台审计消费的可靠事件 |
| `01_contracts/domains/identity/module-contract.md` | S2 | PrincipalContext、跨 domain 边界、平台配置消费、审计写入和安全一致性 |
| `02_architecture/domains/identity.md` | 参考 | 横向职责、核心链路和当前边界 |

Identity S2 已从当前 S1 推导为未 Release 草稿，并补充授权投影、注册审批、ServiceAccount 管理与用户删除依赖合同。任何正式实现仍必须核对 `RELEASE.md`；本 Context 不能替代 S1/S2。

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改登录、会话或 RBAC | S1 product-spec、对应 Identity S2 | 需要改变产品语义时先改 S1 |
| 修改服务主体或委托授权 | S1 product-spec、Identity S2 | 涉及业务资源再读目标 domain |
| 修改业务资源权限 | 目标领域 S1/S2、Identity Context | 仅主体与授权基础返回本 Context |
| 新增 LDAP/SSO/OAuth/MFA/PAT | S1 product-spec | 当前为不支持能力，必须先做产品决策 |

## 8. 当前状态

S1 产品语义已结合各下游 domain 收敛；Identity S2 已建立但仍为未 Release 草稿。当前不应把架构参考、其他领域权限文件或 Context 当作 Identity API 和数据结构的唯一正式依据。

## 9. 不在本领域定义的内容

- 业务资源的状态、生命周期和领域可见性规则不在本领域定义。
- 各领域操作权限码和 DTO 不在本 Context 定义。
- 当前延期的 LDAP/SSO、MFA、可信设备、OAuth2/OIDC 和 PAT 不属于已支持范围。
- 正式 migration 和实现代码不在本仓库；Identity S2 的 Release 门禁仍待用户确认。
