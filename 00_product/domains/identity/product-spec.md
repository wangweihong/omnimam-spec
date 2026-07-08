# 统一身份认证与访问控制产品规格
> 本文档是 S1 产品事实源，用于定义统一身份认证与访问控制的产品语义、领域模型、业务规则、用户故事和端呈现策略。
>
> 本文档中的 Mermaid 图用于辅助理解复杂流程、状态变化、角色可见性和交互时序。图与文字描述应被视为同一事实集合；若存在不一致，应修正文档后再进入实现。

## 文档信息

- 版本：v1.x
- 最后更新：2026-07-08
- 作者：OmniMAM Spec Team
- domain_id：identity
- domain_code：IAM

## 0. 原型来源

当前文档不依赖独立 S0 原型，直接沉淀统一身份认证与访问控制的 S1 产品语义。

## 1. 功能说明

统一身份认证与访问控制用于为 OmniMAM 及其后续生态系统提供统一的用户身份管理、登录认证、Token 会话、动态 RBAC 权限控制、前后端权限解耦、SSO 单点登录、用户注册、LDAP 外部身份接入、系统级认证配置读取和安全审计能力。

本功能的核心事实是：身份认证与访问控制是全系统的基础能力。所有业务系统不应自行实现独立登录、角色判断、权限硬编码或跨系统会话逻辑，而应统一依赖 IAM 提供的身份、Token、权限码、菜单资源和授权判定能力。

当前阶段不支持邮箱验证、MFA、可信设备、OAuth2 / OIDC 登录或 OAuth Provider 管理；这些能力仅作为后续预留方向，不进入当前阶段实现依据。

IAM 的主要使用对象包括：

```text
普通用户
系统管理员
业务系统前端
业务系统后端 API
认证中心
外部身份源
```

IAM 需要支持：

```text
用户名 / 邮箱 / 手机号登录
用户自助注册
密码认证
LDAP 登录
JWT Access Token
Refresh Token
SSO 全局会话
动态 RBAC 权限
菜单 / 按钮 / API 资源控制
用户组
角色继承
互斥角色
权限缓存刷新
审计日志
系统初始化内置管理员和默认角色
系统级认证配置读取
```

---


## 2. 核心数据模型

本文档中的数据模型是 S1 领域模型，仅表达产品语义和逻辑字段，不等同于 OpenAPI DTO、SQL schema 或后端 ORM。

### User（用户）

| 字段             | 类型                | 必填 | 说明                                     |
| -------------- | ----------------- | -- | -------------------------------------- |
| id             | string            | 是  | 用户全局唯一标识                               |
| username       | string            | 是  | 登录用户名；LOCAL 用户范围内唯一且不可修改                 |
| displayName    | string            | 是  | 显示名称                                   |
| alias          | string            | 否  | 用户别名或个性化昵称，不作为登录凭证                     |
| email          | string            | 否  | 邮箱；需要全局唯一，可作为登录凭证                      |
| phone          | string            | 否  | 手机号；需要全局唯一，可作为登录凭证                     |
| passwordHash   | string            | 否  | 本地用户密码哈希；LDAP / OAuth 用户可以为空           |
| status         | enum              | 是  | 用户状态：ACTIVE、DISABLED、LOCKED、UNVERIFIED；UNVERIFIED 为后续邮箱验证或审批扩展预留 |
| lockoutEnd     | string(date-time) | 否  | 锁定截止时间                                 |
| failedCount    | integer           | 是  | 连续登录失败次数                               |
| passwordChangedAt | string(date-time) | 否  | 最后一次密码修改时间                             |
| lastLoginAt    | string(date-time) | 否  | 最后一次登录成功时间                              |
| isFirstLogin   | boolean           | 是  | 是否首次登录；为 true 时必须先完成密码和邮箱修改             |
| mfaEnabled     | boolean           | 是  | 是否启用多因子认证；当前阶段不支持，仅作为后续预留              |
| mfaMethods     | array of string   | 否  | 允许的 MFA 方式；当前阶段不支持，仅作为后续预留              |
| oauthProviders | array of object   | 否  | 绑定的第三方账号；当前阶段不支持 OAuth2 / OIDC，仅作为后续预留 |
| ldapDn         | string            | 否  | LDAP 用户 DN                             |
| ldapServerId   | string            | 否  | 关联 LDAP 服务器配置                          |
| source         | enum              | 是  | 用户来源：LOCAL、LDAP、OAUTH                  |
| extAttrs       | object            | 否  | 扩展属性，例如部门、职级、岗位                        |
| createdAt      | string(date-time) | 是  | 创建时间                                   |
| updatedAt      | string(date-time) | 是  | 更新时间                                   |

### Group（用户组）

| 字段          | 类型                | 必填 | 说明                 |
| ----------- | ----------------- | -- | ------------------ |
| id          | string            | 是  | 用户组唯一标识            |
| name        | string            | 是  | 组名，支持层级路径          |
| description | string            | 否  | 描述                 |
| parentId    | string            | 否  | 父组 ID              |
| type        | enum              | 是  | 组类型：STATIC、DYNAMIC |
| rule        | string            | 否  | 动态组规则表达式           |
| status      | enum              | 是  | 状态：ACTIVE、DISABLED |
| createdAt   | string(date-time) | 是  | 创建时间               |
| updatedAt   | string(date-time) | 是  | 更新时间               |

### GroupMember（用户组成员）

| 字段        | 类型                | 必填 | 说明                            |
| --------- | ----------------- | -- | ----------------------------- |
| groupId   | string            | 是  | 用户组 ID                        |
| userId    | string            | 是  | 用户 ID                         |
| source    | enum              | 是  | 成员来源：MANUAL、DYNAMIC、LDAP_SYNC |
| createdAt | string(date-time) | 是  | 创建时间                          |

### Role（角色）

| 字段          | 类型                | 必填 | 说明                 |
| ----------- | ----------------- | -- | ------------------ |
| id          | string            | 是  | 角色唯一标识             |
| code        | string            | 是  | 角色标识               |
| name        | string            | 是  | 角色显示名称             |
| description | string            | 否  | 角色描述               |
| isBuiltin   | boolean           | 是  | 是否内置角色             |
| status      | enum              | 是  | 状态：ACTIVE、DISABLED |
| createdAt   | string(date-time) | 是  | 创建时间               |
| updatedAt   | string(date-time) | 是  | 更新时间               |

### UserRoleGrant（用户角色授权）

| 字段            | 类型                | 必填 | 说明                         |
| ------------- | ----------------- | -- | -------------------------- |
| userId        | string            | 是  | 用户 ID                      |
| roleId        | string            | 是  | 角色 ID                      |
| grantType     | enum              | 是  | 授权来源：DIRECT、GROUP、LDAP_MAP |
| effectiveFrom | string(date-time) | 否  | 生效开始时间                     |
| effectiveTo   | string(date-time) | 否  | 生效结束时间                     |
| createdAt     | string(date-time) | 是  | 创建时间                       |

### GroupRoleGrant（用户组角色授权）

| 字段        | 类型                | 必填 | 说明     |
| --------- | ----------------- | -- | ------ |
| groupId   | string            | 是  | 用户组 ID |
| roleId    | string            | 是  | 角色 ID  |
| createdAt | string(date-time) | 是  | 创建时间   |

### RoleInheritance（角色继承）

| 字段           | 类型                | 必填 | 说明     |
| ------------ | ----------------- | -- | ------ |
| roleId       | string            | 是  | 子角色 ID |
| parentRoleId | string            | 是  | 父角色 ID |
| createdAt    | string(date-time) | 是  | 创建时间   |

### RoleMutex（互斥角色）

| 字段          | 类型                | 必填 | 说明         |
| ----------- | ----------------- | -- | ---------- |
| roleId      | string            | 是  | 角色 ID      |
| mutexRoleId | string            | 是  | 与其互斥的角色 ID |
| createdAt   | string(date-time) | 是  | 创建时间       |

### PermissionResource（权限资源）

| 字段        | 类型                | 必填 | 说明                                |
| --------- | ----------------- | -- | --------------------------------- |
| id        | string            | 是  | 资源唯一标识                            |
| code      | string            | 是  | 权限标识码，例如 user:create、order:export |
| name      | string            | 是  | 资源名称                              |
| type      | enum              | 是  | 资源类型：MENU、BUTTON、API              |
| parentId  | string            | 否  | 父资源 ID                            |
| path      | string            | 否  | 菜单路径或 API 路径模式                    |
| method    | string            | 否  | API 方法                            |
| icon      | string            | 否  | 菜单图标                              |
| sortOrder | integer           | 否  | 排序                                |
| status    | enum              | 是  | 状态：ACTIVE、DISABLED                |
| createdAt | string(date-time) | 是  | 创建时间                              |
| updatedAt | string(date-time) | 是  | 更新时间                              |

### RolePermissionGrant（角色权限授权）

| 字段             | 类型                | 必填 | 说明    |
| -------------- | ----------------- | -- | ----- |
| roleId         | string            | 是  | 角色 ID |
| permissionCode | string            | 是  | 权限标识码 |
| createdAt      | string(date-time) | 是  | 创建时间  |

### AuthSession（认证中心会话）

| 字段         | 类型                | 必填 | 说明                          |
| ---------- | ----------------- | -- | --------------------------- |
| id         | string            | 是  | 会话唯一标识                      |
| userId     | string            | 是  | 用户 ID                       |
| clientId   | string            | 否  | 来源客户端                       |
| deviceInfo | string            | 否  | 设备信息                        |
| ipAddress  | string            | 否  | 登录 IP                       |
| userAgent  | string            | 否  | 浏览器或客户端信息                   |
| status     | enum              | 是  | 会话状态：ACTIVE、REVOKED、EXPIRED |
| createdAt  | string(date-time) | 是  | 创建时间                        |
| expiresAt  | string(date-time) | 是  | 过期时间                        |

### TokenCredential（Token 凭据）

| 字段             | 类型                | 必填 | 说明                        |
| -------------- | ----------------- | -- | ------------------------- |
| accessTokenJti | string            | 是  | Access Token 唯一标识         |
| refreshTokenId | string            | 是  | Refresh Token 标识          |
| userId         | string            | 是  | 用户 ID                     |
| clientId       | string            | 否  | 客户端 ID                    |
| deviceInfo     | string            | 否  | 绑定设备信息                    |
| status         | enum              | 是  | 状态：ACTIVE、REVOKED、EXPIRED |
| issuedAt       | string(date-time) | 是  | 签发时间                      |
| expiresAt      | string(date-time) | 是  | 过期时间                      |

### OAuthProviderBinding（OAuth 账号绑定，当前阶段预留）

| 字段        | 类型                | 必填 | 说明               |
| --------- | ----------------- | -- | ---------------- |
| userId    | string            | 是  | 本地用户 ID          |
| provider  | string            | 是  | OAuth / OIDC 提供方 |
| subjectId | string            | 是  | 第三方用户唯一标识        |
| email     | string            | 否  | 第三方返回邮箱          |
| createdAt | string(date-time) | 是  | 绑定时间             |

### SystemAuthConfig（系统级认证配置）

| 字段                  | 类型      | 必填 | 说明                         |
| ------------------- | ------- | -- | -------------------------- |
| passwordPolicy      | object  | 是  | 密码复杂度策略，用于后端校验和前端展示       |
| accessTokenTimeout  | integer | 是  | Access Token 超时时间，单位由实现契约定义 |
| refreshTokenTimeout | integer | 是  | Refresh Token 超时时间，单位由实现契约定义 |
| lockoutPolicy       | object  | 是  | 登录失败锁定策略                   |
| updatedAt           | string(date-time) | 是  | 配置更新时间                     |

### LdapServerConfig（LDAP 服务器配置）

| 字段               | 类型                | 必填 | 说明                 |
| ---------------- | ----------------- | -- | ------------------ |
| id               | string            | 是  | LDAP 配置唯一标识        |
| name             | string            | 是  | LDAP 源名称           |
| url              | string            | 是  | LDAP 服务地址          |
| baseDn           | string            | 是  | Base DN            |
| bindUser         | string            | 否  | 绑定用户               |
| searchFilter     | string            | 是  | 用户搜索过滤条件           |
| attributeMapping | object            | 是  | LDAP 属性到用户字段的映射    |
| status           | enum              | 是  | 状态：ACTIVE、DISABLED |
| createdAt        | string(date-time) | 是  | 创建时间               |
| updatedAt        | string(date-time) | 是  | 更新时间               |

### AuditLog（审计日志）

| 字段          | 类型                | 必填 | 说明                  |
| ----------- | ----------------- | -- | ------------------- |
| id          | string            | 是  | 审计日志唯一标识            |
| actorUserId | string            | 否  | 操作人用户 ID            |
| action      | string            | 是  | 操作类型                |
| targetType  | string            | 否  | 操作对象类型              |
| targetId    | string            | 否  | 操作对象 ID             |
| result      | enum              | 是  | 操作结果：SUCCESS、FAILED |
| ipAddress   | string            | 否  | 操作来源 IP             |
| userAgent   | string            | 否  | 操作来源客户端             |
| detail      | object            | 否  | 详情                  |
| createdAt   | string(date-time) | 是  | 记录时间                |

---

## 3. 业务规则

### 3.1 用户与身份来源

* **BR-IAM-USER-01** 用户是 IAM 的身份主体，所有登录、授权、审计和资源访问都必须关联到用户。
* **BR-IAM-USER-02** 用户来源包括 LOCAL、LDAP、OAUTH；OAUTH 当前阶段仅作为后续预留来源。
* **BR-IAM-USER-03** LOCAL 用户必须拥有 LOCAL 用户范围内唯一的 username。
* **BR-IAM-USER-04** LOCAL 用户 username 创建后不可修改。
* **BR-IAM-USER-05** email 需要全局唯一。
* **BR-IAM-USER-06** phone 需要全局唯一。
* **BR-IAM-USER-07** LOCAL 用户必须具备密码哈希。
* **BR-IAM-USER-08** LDAP / OAUTH 用户可以没有本地密码。
* **BR-IAM-USER-09** 用户状态为 ACTIVE 时才允许正常登录。
* **BR-IAM-USER-10** UNVERIFIED 为后续邮箱验证或审批扩展预留状态；当前阶段注册主流程不进入邮箱未验证状态。
* **BR-IAM-USER-11** 用户状态为 DISABLED 或 LOCKED 时禁止登录。
* **BR-IAM-USER-12** alias 是用户个性化别名，不作为登录凭证。
* **BR-IAM-USER-13** 系统需要记录用户最后一次密码修改时间和最后一次登录成功时间。
* **BR-IAM-USER-14** 用户存在 isFirstLogin 标志；当 isFirstLogin 为 true 时，系统应视为首次登录并要求用户先修改密码和邮箱。
* **BR-IAM-USER-15** 首次登录引导完成后，isFirstLogin 应变为 false。
* **BR-IAM-USER-16** lastLoginAt 只在正式登录态签发成功后更新；密码校验通过但未签发正式登录态时不得更新。
* **BR-IAM-USER-17** 已登录用户可以修改自己的 displayName、alias、email、phone 等个人信息；username 不可修改。
* **BR-IAM-USER-18** 修改 email 或 phone 时必须校验唯一性；当前阶段不触发邮箱验证流程。

### 3.2 用户注册

* **BR-IAM-REGISTER-01** 系统支持用户使用唯一邮箱自助注册。
* **BR-IAM-REGISTER-02** 注册时需要校验用户名格式、密码强度和 email 唯一性。
* **BR-IAM-REGISTER-03** 注册成功后创建 LOCAL 用户。
* **BR-IAM-REGISTER-04** 当前阶段不支持邮箱验证；注册成功后不发送邮箱验证链接。
* **BR-IAM-REGISTER-05** 不启用管理员审批时，新注册 LOCAL 用户初始状态为 ACTIVE。
* **BR-IAM-REGISTER-06** 启用管理员审批时，系统可以使用后续扩展状态承载审批流程，但不得复用邮箱验证语义。
* **BR-IAM-REGISTER-07** 当前阶段没有邮箱验证链接、验证有效期或邮箱验证通过状态流转。
* **BR-IAM-REGISTER-08** 新注册用户自动获得 REGULAR_USER 角色。
* **BR-IAM-REGISTER-09** 系统可以配置是否需要管理员审批后才能激活用户。

### 3.3 登录认证

* **BR-IAM-AUTH-01** 用户可以使用用户名、邮箱或手机号作为登录标识。
* **BR-IAM-AUTH-02** 登录时优先匹配 LOCAL 用户。
* **BR-IAM-AUTH-03** LOCAL 用户未匹配且启用 LDAP 时，可以进入 LDAP 认证流程。
* **BR-IAM-AUTH-04** LOCAL 用户使用 bcrypt 或等价安全哈希方式校验密码。
* **BR-IAM-AUTH-05** 连续登录失败达到限制后，用户进入临时锁定状态。
* **BR-IAM-AUTH-06** 锁定期内禁止登录。
* **BR-IAM-AUTH-07** 当前阶段不支持 MFA；凭证验证通过且用户状态允许登录时，可以签发正式登录态。
* **BR-IAM-AUTH-08** 正式登录态签发成功后，系统更新 lastLoginAt。
* **BR-IAM-AUTH-09** 登录、登录失败、Token 刷新、登出都需要记录审计日志。
* **BR-IAM-AUTH-10** 已登录 LOCAL 用户可以修改自己的密码，必须同时输入原密码和新密码。
* **BR-IAM-AUTH-11** 修改密码时必须先校验原密码；原密码错误时不得修改密码。
* **BR-IAM-AUTH-12** 新密码必须满足系统级配置中的密码复杂度策略，并应遵守历史密码策略；修改密码页面必须读取后端系统级配置并展示具体、可执行的复杂度策略提示。
* **BR-IAM-AUTH-13** LDAP / OAUTH 用户没有本地密码时，不适用本地修改密码流程。
* **BR-IAM-AUTH-14** 用户修改密码成功后，系统必须撤销该用户有效 Refresh Token，并使该用户当前及全部 Access Token 在剩余有效期内不可用。
* **BR-IAM-AUTH-15** isFirstLogin 为 true 的用户通过认证后不得进入系统正常功能，必须先完成密码和邮箱修改。
* **BR-IAM-AUTH-16** 修改密码成功后，系统必须退出当前会话，并强制跳回登录页要求重新登录。

### 3.4 MFA 多因子认证

* **BR-IAM-MFA-01** 当前阶段不支持 MFA。
* **BR-IAM-MFA-02** 当前阶段不支持 TOTP、SMS、EMAIL 二次验证。
* **BR-IAM-MFA-03** 当前阶段不支持可信设备，仅保留后续预留接口和能力说明。
* **BR-IAM-MFA-04** 当前阶段登录流程不得要求用户完成二次验证后再签发正式登录态。

### 3.5 OAuth2 / OIDC 登录

* **BR-IAM-OAUTH-01** 当前阶段不支持 OAuth2 / OIDC 登录。
* **BR-IAM-OAUTH-02** 当前阶段不支持 OAuth Provider 管理。
* **BR-IAM-OAUTH-03** 当前阶段不创建 OAUTH 来源用户，仅保留后续预留接口和能力说明。
* **BR-IAM-OAUTH-04** 后续启用 OAuth2 / OIDC 时，必须通过 provider + subjectId 匹配已绑定用户，并校验 state 与 redirect URI。

### 3.6 LDAP 认证

* **BR-IAM-LDAP-01** 系统可以配置多个 LDAP 源。
* **BR-IAM-LDAP-02** LDAP 配置包含服务地址、Base DN、绑定用户、搜索过滤条件和属性映射。
* **BR-IAM-LDAP-03** LOCAL 用户未匹配时，可以按配置进入 LDAP 用户搜索和绑定认证。
* **BR-IAM-LDAP-04** LDAP 认证成功后，系统需要在本地查找或创建 LDAP 来源用户。
* **BR-IAM-LDAP-05** LDAP 新用户默认获得 REGULAR_USER 角色。
* **BR-IAM-LDAP-06** LDAP 组可以映射到 IAM 用户组。
* **BR-IAM-LDAP-07** LDAP 组映射后的用户可以通过用户组继承角色。

### 3.7 Token 与会话

* **BR-IAM-TOKEN-01** 业务系统 API 使用 JWT Bearer Token 访问。
* **BR-IAM-TOKEN-02** Access Token 采用短有效期。
* **BR-IAM-TOKEN-03** Access Token 不应暴露权限码集合。
* **BR-IAM-TOKEN-04** Access Token 载荷只表达身份、签发方、过期时间、Token ID、客户端等必要认证信息。
* **BR-IAM-TOKEN-05** Refresh Token 是可撤销的长期凭据。
* **BR-IAM-TOKEN-06** Refresh Token 需要绑定设备信息。
* **BR-IAM-TOKEN-07** Access Token 过期后，前端可以使用 Refresh Token 换取新的 Access Token。
* **BR-IAM-TOKEN-08** 用户登出时，需要撤销 Refresh Token。
* **BR-IAM-TOKEN-09** 用户登出时，需要使当前 Access Token 的 jti 在剩余有效期内不可再使用。
* **BR-IAM-TOKEN-10** 全局单点注销需要撤销该用户所有有效 Refresh Token。
* **BR-IAM-TOKEN-11** 认证中心可以通过自身域下的 HttpOnly、Secure、SameSite=Lax Cookie 维持全局会话。
* **BR-IAM-TOKEN-12** 业务系统不应依赖认证中心 Cookie 访问业务 API。

### 3.8 RBAC 权限

* **BR-IAM-RBAC-01** 权限控制以角色为核心。
* **BR-IAM-RBAC-02** 权限粒度覆盖菜单、按钮和 API。
* **BR-IAM-RBAC-03** 所有受控资源都必须使用唯一权限码标识。
* **BR-IAM-RBAC-04** 前端只通过权限码和菜单树控制界面展示。
* **BR-IAM-RBAC-05** 后端通过权限码保护 API。
* **BR-IAM-RBAC-06** 前端不得写死角色判断；通用授权仍基于权限码。
* **BR-IAM-RBAC-07** 后端业务代码不得写死用户角色判断；内置角色层级删除是 IAM 领域内置策略，由统一授权或用户删除策略层判断，不允许业务系统散落硬编码。
* **BR-IAM-RBAC-08** 角色可以继承其他角色权限。
* **BR-IAM-RBAC-09** 角色可以设置互斥关系。
* **BR-IAM-RBAC-10** 互斥角色不得同时分配给同一用户。
* **BR-IAM-RBAC-11** 用户可以直接获得角色。
* **BR-IAM-RBAC-12** 用户可以通过用户组获得角色。
* **BR-IAM-RBAC-13** 用户可以通过 LDAP 组映射获得角色。
* **BR-IAM-RBAC-14** 角色授权可以有生效时间和失效时间。
* **BR-IAM-RBAC-15** 用户组支持静态成员和动态规则成员。
* **BR-IAM-RBAC-16** 用户组层级禁止循环引用。
* **BR-IAM-RBAC-17** 动态组成员由系统根据规则自动计算。
* **BR-IAM-RBAC-18** 权限变更、用户角色变化、用户组关系变化后，需要刷新受影响用户的权限缓存。
* **BR-IAM-RBAC-19** SUPER_ADMIN 是内置超级管理员角色。
* **BR-IAM-RBAC-20** REGULAR_USER 是内置普通用户角色。
* **BR-IAM-RBAC-21** SUPER_ADMIN 用户拥有全量权限。
* **BR-IAM-RBAC-22** SUPER_ADMIN 不依赖普通角色权限绑定表判断权限。
* **BR-IAM-RBAC-23** 内置角色不可删除。
* **BR-IAM-RBAC-24** 内置角色 code 不可修改。
* **BR-IAM-RBAC-25** ADMIN 是内置管理员角色，权限低于 SUPER_ADMIN，高于 REGULAR_USER。
* **BR-IAM-RBAC-26** 内置角色删除权限优先级为 `SUPER_ADMIN > ADMIN > REGULAR_USER`；用户拥有多个内置角色时，按最高内置角色判断删除权限。
* **BR-IAM-RBAC-27** 初始用户名为 `admin` 的内置账号可以删除任何其他用户，包括其他 SUPER_ADMIN。
* **BR-IAM-RBAC-28** 非初始 `admin` 的 SUPER_ADMIN 可以删除 ADMIN 和 REGULAR_USER，但不能删除其他 SUPER_ADMIN。
* **BR-IAM-RBAC-29** ADMIN 必须拥有 `user:delete` 等用户删除权限码，且只能删除 REGULAR_USER。
* **BR-IAM-RBAC-30** 同一最高内置角色的用户不能互相删除。
* **BR-IAM-RBAC-31** 任意用户不得删除自己。
* **BR-IAM-RBAC-32** REGULAR_USER 不具备删除用户能力。
* **BR-IAM-RBAC-33** 删除用户前必须检查目标用户是否存在关联资源；存在关联资源时禁止删除，并提示先清理或转移资源。
* **BR-IAM-RBAC-34** 删除用户时不执行跨资源级联删除。

### 3.9 前后端权限解耦

* **BR-IAM-FE-01** 前端初始化后需要获取当前用户权限码集合。
* **BR-IAM-FE-02** 前端初始化后需要获取经过过滤的菜单和按钮树。
* **BR-IAM-FE-03** 前端根据菜单资源动态注册路由。
* **BR-IAM-FE-04** 用户无权限的页面不应出现在前端路由表中。
* **BR-IAM-FE-05** 按钮、表格列和操作入口需要通过权限码控制展示。
* **BR-IAM-FE-06** 前端隐藏无权限功能只负责体验，不代表安全边界。
* **BR-IAM-FE-07** 所有 API 仍必须由后端统一鉴权层判断权限。

### 3.10 SSO 单点登录

* **BR-IAM-SSO-01** 认证中心负责维护全局登录态。
* **BR-IAM-SSO-02** 业务系统检测到无有效 Token 时，可以跳转认证中心发起授权登录。
* **BR-IAM-SSO-03** 用户已在认证中心登录时，访问其他业务系统应可无缝完成登录跳转。
* **BR-IAM-SSO-04** 业务系统通过授权码换取本系统可使用的 Token。
* **BR-IAM-SSO-05** 局部登出只撤销当前业务系统或当前设备相关凭据。
* **BR-IAM-SSO-06** 全局登出需要清除认证中心会话，并撤销用户所有有效 Refresh Token。
* **BR-IAM-SSO-07** 全局登出可以通知业务系统清除本地前端 Token 状态。

### 3.11 安全与审计

* **BR-IAM-SEC-01** 密码必须使用安全哈希算法存储。
* **BR-IAM-SEC-02** 密码需要进行复杂度校验。
* **BR-IAM-SEC-03** 系统可以维护历史密码策略。
* **BR-IAM-SEC-04** 连续失败登录需要触发锁定。
* **BR-IAM-SEC-05** 可集成图形验证码或其他登录保护能力。
* **BR-IAM-SEC-06** OAuth2 客户端密钥需要加密存储。
* **BR-IAM-SEC-07** 所有需要保护的业务 API 必须经过统一鉴权层。
* **BR-IAM-SEC-08** 登录、登出、Token 刷新、权限变更、管理员操作需要记录审计日志。
* **BR-IAM-SEC-09** 权限授予应遵循最小权限原则。
* **BR-IAM-SEC-10** 系统应支持定期权限审查。
* **BR-IAM-SEC-11** 修改密码成功、原密码校验失败和密码策略校验失败都需要记录审计日志。
* **BR-IAM-SEC-12** 后端必须提供系统级认证配置读取能力，至少包含密码复杂度策略、Access Token 超时时间、Refresh Token 超时时间和登录失败锁定策略。
* **BR-IAM-SEC-13** 认证中心和业务系统前端必须读取后端系统级认证配置用于展示和处理，不得写死密码复杂度、令牌超时时间或锁定策略。

### 3.12 系统初始化

* **BR-IAM-INIT-01** 系统首次启动时自动创建 SUPER_ADMIN 角色。
* **BR-IAM-INIT-02** 系统首次启动时自动创建 ADMIN 和 REGULAR_USER 角色。
* **BR-IAM-INIT-03** 内置角色不可删除。
* **BR-IAM-INIT-04** 系统首次启动时自动创建初始管理员账户，用户名固定为 `admin`。
* **BR-IAM-INIT-05** 初始管理员账户直接绑定 SUPER_ADMIN 角色。
* **BR-IAM-INIT-06** 初始管理员首次登录后需要强制修改密码和邮箱。
* **BR-IAM-INIT-07** 初始管理员初始密码固定为 `admin`，仅作为首次启动引导凭据，是启动引导例外，不代表正常密码策略通过，不允许作为长期安全配置。
* **BR-IAM-INIT-08** 初始管理员创建时 isFirstLogin 为 true，首次登录必须完成密码和邮箱修改后才能进入系统。

---

## 4. 用户故事

### US-IAM-01 用户注册

用户可以使用用户名、密码、邮箱和可选别名注册账号。

当前阶段不支持邮箱验证。注册成功后，如未启用管理员审批，账号直接进入 ACTIVE 状态；如启用管理员审批，按审批扩展流程处理。新注册用户自动获得普通用户角色。

### US-IAM-02 邮箱验证（当前阶段不支持）

当前阶段不支持邮箱验证，不发送邮箱验证链接，不提供邮箱验证结果页，也不将注册主流程置为 UNVERIFIED。

该能力作为后续预留方向。

### US-IAM-03 用户密码登录

用户可以使用用户名、邮箱或手机号登录。

系统优先匹配本地用户。本地用户存在时，系统校验本地密码。用户状态异常或锁定时，不允许登录。

正式登录态签发成功后，系统更新 lastLoginAt；仅密码校验通过但未签发正式登录态时不得更新。

### US-IAM-04 登录失败保护

用户连续登录失败达到限制时，账号进入临时锁定状态。

锁定期间用户不能继续登录。系统需要记录失败原因和审计日志。

### US-IAM-05 MFA 登录验证（当前阶段不支持）

当前阶段不支持 MFA 登录验证。

TOTP、短信验证码、邮件验证码和按角色强制 MFA 均作为后续预留能力。

### US-IAM-06 可信设备（当前阶段不支持）

当前阶段不支持可信设备。

可信设备作为后续预留能力，当前阶段不提供信任当前设备、查看可信设备或撤销可信设备的可用流程。

### US-IAM-07 OAuth2 / OIDC 登录（当前阶段不支持）

当前阶段不支持 OAuth2 / OIDC 登录。

OAuth2 / OIDC 登录和账号绑定作为后续预留能力。

### US-IAM-08 LDAP 登录

用户可以使用 LDAP 账号登录。

当本地用户未匹配且 LDAP 启用时，系统通过 LDAP 搜索用户并尝试绑定认证。认证成功后，系统在本地查找或创建 LDAP 来源用户。

### US-IAM-09 Token 刷新

用户 Access Token 过期后，可以通过 Refresh Token 获取新的 Access Token。

Refresh Token 需要可撤销，并与设备信息绑定。

### US-IAM-10 局部登出

用户可以从当前设备或当前业务系统登出。

登出后，当前 Refresh Token 失效，当前 Access Token 在剩余有效期内不可继续使用。

### US-IAM-11 全局单点登录

用户在认证中心登录后，访问其他业务系统时，可以通过 SSO 授权跳转无缝登录。

业务系统不直接读取认证中心 Cookie，而是通过标准授权流程换取 Token。

### US-IAM-12 全局单点注销

用户可以触发全局注销。

全局注销清除认证中心会话，并撤销该用户所有有效 Refresh Token。业务系统前端需要清除本地 Token 状态。

### US-IAM-13 查看当前用户信息

登录用户可以查看自己的基础信息，包括用户名、显示名称、别名、邮箱、手机号、用户来源和账号状态。

### US-IAM-14 获取当前用户权限码

登录用户可以获取自己的权限码集合。

前端使用权限码控制按钮、操作入口和局部 UI 展示。

### US-IAM-15 获取当前用户菜单树

登录用户可以获取经过权限过滤的菜单和按钮树。

前端根据菜单树动态注册路由，并隐藏无权限页面。

### US-IAM-16 用户管理

系统管理员可以创建、查看、编辑、禁用、锁定或删除用户。

删除用户时必须遵守权限码和内置角色层级规则。初始 `admin` 账号可以删除任何其他无关联资源的用户；非初始 `admin` 的 SUPER_ADMIN 不能删除其他 SUPER_ADMIN；ADMIN 必须拥有 `user:delete` 等用户删除权限码且只能删除 REGULAR_USER；REGULAR_USER 不具备删除用户能力；任意用户不得删除自己。目标用户存在关联资源时，系统禁止删除，并提示先清理或转移资源。

用户管理操作需要记录审计日志。

### US-IAM-17 分配用户角色

系统管理员可以为用户分配角色，并可以设置角色授权的生效时间和失效时间。

管理员不能给同一用户分配互斥角色。

### US-IAM-18 用户组管理

系统管理员可以创建和维护用户组。

用户组支持层级结构、静态成员和动态规则成员。系统需要防止用户组层级循环引用。

### US-IAM-19 用户组角色授权

系统管理员可以为用户组分配角色。

用户属于该组后，可以继承组角色。动态组成员由系统根据规则自动计算。

### US-IAM-20 角色管理

系统管理员可以创建、编辑、禁用和删除非内置角色。

内置角色不可删除，内置角色 code 不可修改。

### US-IAM-21 角色继承

系统管理员可以配置角色继承关系。

子角色自动继承父角色拥有的权限码。

### US-IAM-22 互斥角色

系统管理员可以配置互斥角色。

互斥角色不能同时分配给同一用户。

### US-IAM-23 权限资源管理

系统管理员可以管理菜单、按钮和 API 类型的权限资源。

每个受控资源使用唯一权限码标识。

### US-IAM-24 角色权限分配

系统管理员可以为普通角色分配权限码。

超级管理员角色 SUPER_ADMIN 拥有全量权限，不依赖普通角色权限绑定。

### US-IAM-25 LDAP 配置管理

系统管理员可以配置 LDAP 服务器、搜索规则、属性映射和组映射规则。

系统管理员可以测试 LDAP 连接，并可以触发 LDAP 用户或组同步。

### US-IAM-26 OAuth Provider 管理（当前阶段不支持）

当前阶段不支持 OAuth Provider 管理。

OAuth Provider 配置作为后续预留能力。

### US-IAM-27 动态权限控制

前端使用当前用户权限码和菜单树动态控制路由、菜单、按钮、表格列和操作入口。

后端统一鉴权层根据请求资源匹配权限码，并判断当前用户是否拥有该权限。

### US-IAM-28 权限缓存刷新

当角色权限、用户角色、用户组成员、用户组角色或角色继承关系变化时，系统需要刷新受影响用户的权限缓存。

### US-IAM-29 审计日志

系统记录登录、登出、Token 刷新、权限变更、用户管理、角色管理、资源管理和管理员操作。

管理员可以查询审计日志用于安全追踪。

### US-IAM-30 系统初始化

系统首次启动时自动创建 SUPER_ADMIN、ADMIN、REGULAR_USER 三个内置角色和初始管理员账户。

初始管理员账户用户名为 `admin`，初始密码为 `admin`。初始密码 `admin` 仅作为启动引导例外，不代表正常密码策略通过。初始管理员直接绑定 SUPER_ADMIN 角色，并拥有删除任何其他用户的最高删除豁免。初始管理员 isFirstLogin 初始为 true，首次登录后必须修改密码和邮箱，完成后才能进入系统。

### US-IAM-31 修改当前用户密码

已登录 LOCAL 用户可以在个人设置或认证中心入口修改自己的密码。

用户必须输入原密码和新密码。系统需要读取后端系统级配置，向用户展示具体密码复杂度策略提示，并在原密码正确且新密码符合密码策略后才允许修改密码。

修改密码成功后，系统必须撤销 Refresh Token，使当前及该用户全部 Access Token 在剩余有效期内不可用，退出当前会话，并强制跳回登录页要求用户重新登录。LDAP / OAUTH 用户没有本地密码时，不进入本地修改密码流程。

### US-IAM-32 修改当前用户个人信息和邮箱

已登录用户可以在个人设置中修改 displayName、alias、email、phone 等个人信息。

username 不可修改。修改 email 或 phone 时，系统必须校验唯一性。当前阶段不支持邮箱验证，email 修改后不发送验证邮件，唯一性校验通过后生效。首次登录引导中的邮箱修改复用该能力。

### US-IAM-33 获取系统级认证配置

认证中心和业务系统前端可以读取后端提供的系统级认证配置。

配置至少包括密码复杂度策略、Access Token 超时时间、Refresh Token 超时时间和登录失败锁定策略。前端必须读取该配置用于展示和处理，不得写死密码复杂度、令牌超时时间或锁定策略。

---

## 5. 关键流程图

### 5.1 本地登录流程

```mermaid
sequenceDiagram
  actor U as 用户
  participant FE as 前端
  participant IAM as IAM 服务
  participant Token as Token 服务

  U->>FE: 输入用户名/邮箱/手机号和密码
  FE->>IAM: 提交登录凭证
  IAM->>IAM: 匹配 LOCAL 用户
  IAM->>IAM: 校验状态、锁定和密码
  alt isFirstLogin 为 true
    IAM-->>FE: 返回首次登录引导状态
  else 允许登录
    IAM->>Token: 签发正式登录态
    Token-->>FE: 返回 Access Token 和 Refresh Token
    IAM->>IAM: 更新 lastLoginAt
  end
```

### 5.2 LDAP 登录流程

```mermaid
sequenceDiagram
  actor U as 用户
  participant FE as 前端
  participant IAM as IAM 服务
  participant LDAP as LDAP 服务
  participant Token as Token 服务

  U->>FE: 输入登录标识和密码
  FE->>IAM: 提交登录凭证
  IAM->>IAM: 尝试匹配 LOCAL 用户
  alt LOCAL 未命中且 LDAP 启用
    IAM->>LDAP: 按配置搜索用户 DN
    LDAP-->>IAM: 返回用户 DN 与属性
    IAM->>LDAP: 使用用户密码尝试绑定
    LDAP-->>IAM: 绑定成功
    IAM->>IAM: 查找或创建 LDAP 来源用户
    IAM->>IAM: 应用默认角色和组映射
    IAM->>Token: 签发 Token
    Token-->>FE: 返回登录态
  else LOCAL 命中
    IAM->>IAM: 走本地认证流程
  end
```

### 5.3 OAuth2 / OIDC 登录流程（当前阶段不支持）

```mermaid
sequenceDiagram
  actor U as 用户
  participant FE as 前端
  participant IAM as IAM 服务

  U->>FE: 点击第三方登录
  FE->>IAM: 请求 OAuth2 / OIDC 登录
  IAM-->>FE: 返回当前阶段不支持，提示后续预留
```

### 5.4 SSO 自动登录流程

```mermaid
sequenceDiagram
  actor U as 用户
  participant SYSB as 业务系统 B
  participant AUTH as 认证中心
  participant Token as Token 服务

  U->>SYSB: 访问业务系统 B
  SYSB->>SYSB: 检测无本地 Token
  SYSB-->>AUTH: 跳转认证中心授权
  AUTH->>AUTH: 检查认证中心全局会话 Cookie
  alt 会话有效
    AUTH-->>SYSB: 返回授权码
    SYSB->>Token: 使用授权码换取 Token
    Token-->>SYSB: 返回 Access Token 和 Refresh Token
    SYSB-->>U: 用户无缝登录
  else 会话无效
    AUTH-->>U: 展示登录页
  end
```

### 5.5 权限计算流程

```mermaid
flowchart TD
  A["请求进入统一鉴权层"] --> B["校验 Access Token"]
  B --> C{"Token 是否有效"}
  C -->|否| D["拒绝访问"]
  C -->|是| E["提取 userId"]
  E --> F["查询权限缓存"]
  F --> G{"缓存命中"}
  G -->|是| H["获取用户权限码集合"]
  G -->|否| I["计算用户角色"]
  I --> J["合并直接角色、组角色、LDAP 映射角色"]
  J --> K["展开角色继承"]
  K --> L["过滤禁用和过期授权"]
  L --> M{"是否拥有 SUPER_ADMIN"}
  M -->|是| N["返回全量权限"]
  M -->|否| O["合并角色权限码"]
  O --> P["写入权限缓存"]
  H --> Q["匹配请求所需权限码"]
  N --> Q
  P --> Q
  Q --> R{"是否拥有所需权限"}
  R -->|是| S["允许访问"]
  R -->|否| T["返回无权限"]
```

### 5.6 前端动态权限流程

```mermaid
flowchart TD
  A["用户登录成功"] --> B["获取当前用户信息"]
  B --> C["获取权限码集合"]
  B --> D["获取菜单和按钮树"]
  D --> E["根据 MENU 节点动态注册路由"]
  C --> F["根据权限码控制按钮和元素"]
  E --> G["展示有权限页面"]
  F --> G
```

### 5.7 角色关系

```mermaid
classDiagram
  class User {
    id
    username
    source
    status
  }

  class Group {
    id
    name
    type
    parentId
  }

  class Role {
    id
    code
    isBuiltin
    status
  }

  class PermissionResource {
    id
    code
    type
    path
    method
  }

  class AuthSession {
    id
    userId
    status
  }

  class AuditLog {
    id
    action
    result
  }

  User "1" --> "*" Group : member
  User "1" --> "*" Role : direct roles
  Group "1" --> "*" Role : group roles
  Role --> Role : inheritance
  Role --> Role : mutex
  Role "1" --> "*" PermissionResource : permissions
  User "1" --> "*" AuthSession : sessions
  User "1" --> "*" AuditLog : actions
```

---

## 6. 功能适配矩阵

| 功能               | 认证中心 | IAM 管理后台 | 业务系统前端   | 业务系统后端   |
| ---------------- | ---- | -------- | -------- | -------- |
| 用户注册             | ✅    | ❌        | 可跳转      | ❌        |
| 邮箱验证             | 🚧 后续 | ❌        | 🚧 后续    | ❌        |
| 用户登录             | ✅    | ❌        | 可跳转      | ❌        |
| MFA 验证           | 🚧 后续 | 🚧 后续    | 🚧 后续    | ❌        |
| 可信设备             | 🚧 后续 | 🚧 后续    | 🚧 后续    | ❌        |
| OAuth2 / OIDC 登录 | 🚧 后续 | 🚧 后续    | 🚧 后续    | ❌        |
| LDAP 登录          | ✅    | 可配置      | ❌        | ❌        |
| Token 签发         | ✅    | ❌        | 消费 Token | 校验 Token |
| Token 刷新         | ✅    | ❌        | 调用刷新     | 校验结果     |
| 局部登出             | ✅    | ❌        | 触发登出     | 可吊销      |
| 全局单点注销           | ✅    | 可查看      | 清除本地状态   | 可接收吊销结果  |
| 当前用户信息           | ✅    | ✅        | ✅        | ✅        |
| 修改当前用户个人信息和邮箱    | ✅    | ✅        | 可跳转      | 执行唯一性校验  |
| 修改当前用户密码         | ✅    | ✅        | 可跳转      | 执行安全校验   |
| 系统级认证配置           | ✅    | 可查看      | 读取配置     | 提供配置     |
| 当前用户权限码          | ✅    | ✅        | ✅        | ✅        |
| 当前用户菜单树          | ✅    | ✅        | ✅        | ❌        |
| 用户管理             | ❌    | ✅        | ❌        | 执行权限校验   |
| 用户组管理            | ❌    | ✅        | ❌        | 执行权限校验   |
| 角色管理             | ❌    | ✅        | ❌        | 执行权限校验   |
| 权限资源管理           | ❌    | ✅        | ❌        | 执行权限校验   |
| 动态路由             | ❌    | ✅        | ✅        | ❌        |
| 按钮级控制            | ❌    | ✅        | ✅        | ❌        |
| API 动态鉴权         | ❌    | ❌        | ❌        | ✅        |
| 审计日志             | ✅    | ✅        | ❌        | ✅        |

---

## 7. 系统呈现策略

### 7.1 认证中心

认证中心负责登录、注册、SSO 会话、系统级认证配置读取和登出。

邮箱验证、MFA 验证、可信设备和 OAuth 登录当前阶段不支持，仅作为后续预留能力。

认证中心页面需要提供：

```text
登录表单
注册表单
登出结果页
SSO 自动授权过渡页
修改密码页
个人信息和邮箱修改页
首次登录引导页
```

登录表单支持：

```text
用户名
邮箱
手机号
密码
```

用户状态异常时需要展示明确提示，例如：

```text
账号未验证
账号已禁用
账号已锁定
密码错误
需要完成首次登录引导
```

修改密码页需要支持：

```text
原密码
新密码
确认新密码
密码策略提示
原密码错误提示
修改成功后跳回登录页提示
```

密码策略提示必须展示具体、可执行的复杂度要求，不能只展示“密码不符合要求”之类的泛化提示。

首次登录引导页需要要求用户修改初始密码和邮箱。用户完成首次登录引导前，不应进入系统正常功能。

个人信息和邮箱修改页需要支持 displayName、alias、email、phone 修改。username 不可修改；email 和 phone 修改时需要展示唯一性校验错误。当前阶段不发送邮箱验证邮件。

### 7.2 IAM 管理后台

IAM 管理后台用于管理员维护用户、用户组、角色、权限资源、LDAP 配置、系统级认证配置查看和审计日志。

OAuth Provider 配置当前阶段不支持，仅作为后续预留能力。

管理后台主要区域包括：

```text
用户管理
用户组管理
角色管理
权限资源管理
LDAP 配置
系统级认证配置
审计日志
```

管理员操作必须受权限码控制。

内置角色需要在界面中明确标识，并禁用删除和 code 修改。

用户管理中的删除入口必须根据当前操作者和目标用户的最高内置角色动态控制展示；后端仍必须由统一授权或用户删除策略层执行相同角色层级校验。初始 `admin` 账号可删除任何其他用户，普通 SUPER_ADMIN 不能删除其他 SUPER_ADMIN，ADMIN 只能删除 REGULAR_USER，REGULAR_USER 不具备删除用户能力，同角色用户不能互相删除。

### 7.3 业务系统前端

业务系统前端只消费 IAM 提供的身份和权限结果。

业务系统前端需要：

```text
保存和携带 Access Token
在 Token 过期时触发刷新
登录态失效时跳转认证中心
获取当前用户信息
跳转或打开个人信息和邮箱修改入口
跳转或打开修改密码入口
获取系统级认证配置
获取当前用户权限码集合
获取当前用户菜单和按钮树
根据菜单树动态注册路由
根据权限码控制按钮和操作入口
```

业务系统前端不得：

```text
硬编码角色判断
把隐藏按钮当作安全边界
直接读取认证中心 Cookie
自行维护独立登录态
```

### 7.4 业务系统后端

业务系统后端 API 只接受 Bearer Token。

业务系统后端需要：

```text
校验 Access Token
检查 Token 是否撤销
从 Token 提取用户身份
匹配请求所需权限码
计算或读取当前用户权限码集合
判断权限
提供系统级认证配置
记录安全审计
```

业务系统后端不得：

```text
信任前端隐藏逻辑
绕过统一鉴权层
在业务代码中硬编码角色判断
在 Token 中读取权限码作为最终授权依据
```

---

## 8. 状态与异常

| 状态/异常                       | 说明                         |
| --------------------------- | -------------------------- |
| unauthenticated             | 用户未登录或登录态无效                |
| invalid_credentials         | 登录凭证错误                     |
| account_unverified          | 后续邮箱验证或审批扩展状态，非当前注册主流程     |
| account_disabled            | 用户已禁用                      |
| account_locked              | 用户因失败次数过多被锁定               |
| mfa_required                | 后续 MFA 扩展预留，当前阶段不返回        |
| mfa_invalid                 | 后续 MFA 扩展预留，当前阶段不返回        |
| mfa_expired                 | 后续 MFA 扩展预留，当前阶段不返回        |
| token_expired               | Access Token 已过期           |
| token_revoked               | Token 已被撤销                 |
| refresh_token_invalid       | Refresh Token 无效、过期或与设备不匹配 |
| first_login_required        | 用户首次登录，需要先修改密码和邮箱         |
| password_changed_relogin_required | 密码修改成功后必须重新登录       |
| permission_denied           | 当前用户缺少所需权限                 |
| resource_permission_missing | 请求资源未配置权限码或权限资源不可用         |
| role_builtin_protected      | 内置角色禁止删除或修改 code           |
| user_delete_forbidden_by_role | 当前操作者角色层级不允许删除目标用户       |
| user_delete_missing_permission | 当前操作者缺少用户删除权限码           |
| user_delete_blocked_by_resources | 目标用户存在关联资源，禁止删除        |
| self_delete_forbidden       | 用户不能删除自己                   |
| role_mutex_conflict         | 用户被分配了互斥角色                 |
| role_inheritance_cycle      | 角色继承关系存在循环                 |
| group_cycle_detected        | 用户组层级存在循环                  |
| dynamic_group_rule_invalid  | 动态组规则无效                    |
| oauth_state_invalid         | 后续 OAuth2 / OIDC 扩展预留，当前阶段不返回 |
| oauth_provider_failed       | 后续 OAuth2 / OIDC 扩展预留，当前阶段不返回 |
| ldap_connection_failed      | LDAP 连接失败                  |
| ldap_auth_failed            | LDAP 认证失败                  |
| email_already_exists        | 邮箱已被使用                     |
| username_already_exists     | 用户名已被使用                    |
| phone_already_exists        | 手机号已被使用                    |
| old_password_invalid        | 修改密码时原密码错误                 |
| password_policy_failed      | 密码不符合安全策略                  |
| auth_config_unavailable     | 系统级认证配置不可用                 |
| audit_write_failed          | 审计日志写入失败                   |

---

## 9. 验收标准

### US-IAM-01 用户注册

* **AC-IAM-001-01** 用户提交符合规则的用户名、密码、邮箱和可选别名后，系统创建 LOCAL 用户。
* **AC-IAM-001-02** 当前阶段注册成功后不发送邮箱验证邮件；未启用管理员审批时，新用户状态为 ACTIVE。
* **AC-IAM-001-03** 注册成功后，新用户自动获得 REGULAR_USER 角色。

### US-IAM-02 邮箱验证（当前阶段不支持）

* **AC-IAM-002-01** 当前阶段注册、登录和邮箱修改流程不得要求用户完成邮箱验证。
* **AC-IAM-002-02** 当前阶段不发送邮箱验证链接，不展示邮箱验证结果页。

### US-IAM-03 用户密码登录

* **AC-IAM-003-01** 用户凭证正确、状态允许登录且不处于首次登录引导阻断时，系统签发正式登录态。
* **AC-IAM-003-02** 只有正式登录态签发成功后，系统才更新 lastLoginAt。
* **AC-IAM-003-03** 当前阶段登录流程不要求 MFA 验证。

### US-IAM-05 MFA 登录验证（当前阶段不支持）

* **AC-IAM-005-01** 当前阶段登录流程不得返回 MFA 待验证状态。
* **AC-IAM-005-02** 当前阶段不提供 TOTP、短信验证码、邮件验证码或按角色强制 MFA 配置作为可用能力。

### US-IAM-06 可信设备（当前阶段不支持）

* **AC-IAM-006-01** 当前阶段不提供信任当前设备、查看可信设备或撤销可信设备流程。

### US-IAM-07 OAuth2 / OIDC 登录（当前阶段不支持）

* **AC-IAM-007-01** 当前阶段不提供 OAuth2 / OIDC 登录入口作为可用能力。
* **AC-IAM-007-02** 当前阶段不创建 OAUTH 来源用户。

### US-IAM-16 用户管理

* **AC-IAM-016-01** 给定操作者为初始 `admin` 账号，当删除无关联资源的任意其他用户时，系统允许删除并记录审计日志。
* **AC-IAM-016-02** 给定操作者为非初始 `admin` 的 SUPER_ADMIN，当目标用户最高内置角色为 SUPER_ADMIN 时，系统拒绝删除并返回角色层级禁止原因。
* **AC-IAM-016-03** 给定操作者为 ADMIN，当其拥有 `user:delete` 等用户删除权限码且目标用户最高内置角色为 REGULAR_USER、无关联资源时，系统允许删除。
* **AC-IAM-016-04** 给定操作者为 REGULAR_USER 或操作者尝试删除自己时，系统拒绝删除。
* **AC-IAM-016-05** 用户删除能力必须由 IAM 统一授权或用户删除策略层判断，普通业务系统不得自行维护角色层级删除逻辑。
* **AC-IAM-016-06** 给定目标用户存在关联资源时，系统拒绝删除，并提示先清理或转移资源。
* **AC-IAM-016-07** 给定操作者缺少用户删除权限码时，即使角色层级满足，系统也拒绝删除。

### US-IAM-26 OAuth Provider 管理（当前阶段不支持）

* **AC-IAM-026-01** 当前阶段不提供 OAuth Provider 创建、编辑、启用或删除能力。

### US-IAM-30 系统初始化

* **AC-IAM-030-01** 系统首次启动后，存在 SUPER_ADMIN、ADMIN、REGULAR_USER 三个内置角色，且内置角色不可删除、code 不可修改。
* **AC-IAM-030-02** 系统首次启动后，存在用户名为 `admin`、初始密码为 `admin` 的初始管理员账号，并直接绑定 SUPER_ADMIN 角色。
* **AC-IAM-030-03** 初始管理员首次登录时，isFirstLogin 为 true，系统要求其先修改密码和邮箱；完成前不得进入系统正常功能。
* **AC-IAM-030-04** 初始密码 `admin` 仅作为启动引导例外，不应被视为通过正常密码复杂度策略的长期密码。
* **AC-IAM-030-05** 初始管理员首次登录修改邮箱后，当前阶段不发送邮箱验证邮件，邮箱唯一性校验通过后生效。

### US-IAM-31 修改当前用户密码

* **AC-IAM-031-01** 已登录 LOCAL 用户输入正确原密码和符合策略的新密码后，系统允许修改密码并记录最后一次密码修改时间。
* **AC-IAM-031-02** 修改密码页面从后端系统级认证配置读取并展示具体、可执行的密码复杂度策略提示。
* **AC-IAM-031-03** 原密码错误或新密码不符合策略时，系统不得修改密码，并记录审计日志。
* **AC-IAM-031-04** 密码修改成功后，系统撤销 Refresh Token，使当前及全部 Access Token 在剩余有效期内不可用，退出当前会话，并强制跳回登录页要求重新登录。
* **AC-IAM-031-05** LDAP / OAUTH 用户没有本地密码时，不进入本地修改密码流程。

### US-IAM-32 修改当前用户个人信息和邮箱

* **AC-IAM-032-01** 已登录用户可以修改 displayName、alias、email、phone 等允许自助维护的信息。
* **AC-IAM-032-02** username 不可修改。
* **AC-IAM-032-03** 修改 email 或 phone 时，系统必须校验唯一性；冲突时不得保存。
* **AC-IAM-032-04** 当前阶段 email 修改成功后不发送邮箱验证邮件，唯一性校验通过后生效。
* **AC-IAM-032-05** 首次登录引导中的邮箱修改复用当前用户个人信息修改能力。

### US-IAM-33 获取系统级认证配置

* **AC-IAM-033-01** 认证中心和业务系统前端可以读取系统级认证配置。
* **AC-IAM-033-02** 系统级认证配置至少包含密码复杂度策略、Access Token 超时时间、Refresh Token 超时时间和登录失败锁定策略。
* **AC-IAM-033-03** 前端必须使用后端返回的系统级认证配置展示密码策略和处理令牌超时，不得写死。

---

## 10. 非目标范围

本阶段不包含：

```text
邮箱验证或邮箱认证流程
MFA 登录验证、MFA 绑定或按角色强制 MFA
可信设备管理
OAuth2 / OIDC 登录
OAuth Provider 管理
忘记密码或邮箱找回流程
管理员重置他人密码
普通业务系统自行维护角色层级删除逻辑
删除用户时跨资源级联删除
```

## 11. 待确认问题

当前无待确认问题。
