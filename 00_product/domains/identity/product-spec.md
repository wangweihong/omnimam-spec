# OmniMAM 身份认证与访问控制功能设计

> 文档状态：v2.1-draft
> 适用阶段：非企业版
> 用户模型：平台统一用户
> 资源模型：资源域定义所有权、可见性与可选共享
> 当前不包含：企业、租户、LDAP、SSO、OIDC、MFA、PAT

---

## 1. 文档目的

本文档定义 OmniMAM 非企业版本的身份认证与访问控制能力，包括：

* 用户注册与登录；
* 用户账号管理；
* Access Token 与 Refresh Token；
* 登录会话管理；
* 平台角色与权限码；
* 用户组；
* 跨领域主体与资源授权基础；
* Service Account；
* 前后端统一鉴权；
* 向平台管理提交认证与授权审计上下文；
* 系统初始化。

本版本不引入企业、租户或组织隔离。

所有用户直接属于 OmniMAM 平台。

---

## 2. 核心设计结论

## 2.1 单一用户体系

系统只有一个用户主体：

```text
User
```

不存在：

```text
企业用户
普通用户
租户用户
TenantMember
TenantRole
TenantInvitation
```

所有注册用户均可登录 OmniMAM。

用户之间的区别由角色、权限和资源授权决定，不通过用户类型区分。

---

## 2.2 资源授权由资源域与 Identity 协作

多数用户创建的业务资源以用户作为 owner，例如：

```text
Asset
Canvas
Application
Agent
Workspace
Task
```

但资源是否具有 owner、`createdBy`、`visibility`、项目/命名空间或协作成员，以及这些字段如何影响生命周期，必须由资源所属 domain 的 S1 定义。Identity 不要求所有资源使用同一套字段，也不拥有 Asset、Application、Task、Canvas、Agent 或 Workspace 的状态。

跨域协作统一遵循以下原则：

```text
资源域从已验证的 PrincipalContext 注入 owner_user_id / created_by，而不是信任请求体；
owner_user_id 表示业务资源所有权，created_by 表示本次创建主体，二者可以不同；
资源域拥有 visibility、project、namespace 和协作规则；
只有资源域声明支持共享时，才使用 Identity 的 ResourceAccessGrant；
资源域不得读取 Identity 私有表来推导资源状态。
```

例如，asset-library 首期按当前用户 owner 范围隔离；application-platform、workflow-canvas、agent 和 appstudio 由各自 S1 定义 owner、visibility 或 collaborator 规则。Identity 提供授权结果和审计上下文，但不把这些 domain 统一改写成共享资源模型。

---

## 2.3 权限采用两层判断

一次业务访问必须同时满足：

```text
操作权限
+
资源访问权限
```

例如用户执行某个资源域的编辑动作：

```text
拥有目标 domain 登记的编辑权限码
并且
满足该 domain 定义的 owner、visibility 或协作授权规则
```

RBAC 只判断“能否执行这一类操作”。

资源授权判断“能否访问这一个具体对象”，但具体对象是否存在、是否可见、是否已发布或已删除，仍由资源域确认。

---

## 2.4 权限定义由系统注册

权限码属于产品和后端接口契约。

权限定义由 OmniMAM 各模块注册，管理员只能将已有权限分配给角色，不能随意创建权限码。

示例：

```text
user.read
user.manage

asset.create
asset.read
asset.update
asset.delete
asset.share
asset.manage_all

canvas.create
canvas.read
canvas.edit
canvas.execute
canvas.delete
canvas.share
canvas.manage_all

application.read
application.run
application.manage

agent.read
agent.use
agent.manage

task.read
task.cancel
task.manage_all
```

---

各 domain 的 `ordinary_user`、`business_developer`、`system_admin` 等 subject 只是权限合同中的策略分类，不是业务代码可以直接判断的 Identity 角色名。业务 API 必须请求具体权限码，并由 Identity 根据主体的有效角色/用户组授权返回结果。

## 2.5 Token 不保存完整权限

Access Token 只表达身份和凭据状态。

不在 Token 中保存：

```text
完整角色列表
完整权限列表
菜单树
资源共享关系
```

角色或权限变更后，不需要等待旧 Token 过期。

---

## 3. 当前功能范围

## 3.1 当前阶段支持

```text
普通用户自主注册
管理员创建用户
用户名或邮箱登录
本地密码认证
登录失败锁定
首次登录引导
修改密码
个人资料维护
Access Token
Refresh Token
Refresh Token 轮换
登录会话管理
角色
权限码
静态用户组
用户直接角色
用户组角色
资源授权基础（由资源域选择接入）
权限缓存
服务账号
统一 API 鉴权
脱敏审计上下文提交
系统初始化
```

## 3.2 当前阶段不支持

```text
企业
租户
TenantMember
LDAP
OAuth2 / OIDC 登录
MFA
可信设备
邮箱验证
忘记密码邮件
动态用户组
角色继承
互斥角色
复杂 ABAC
跨实例身份同步
Personal Access Token（PAT）
```

---

## 4. 系统组成

```mermaid
flowchart TB
    U["用户"] --> FE["OmniMAM Web"]

    FE --> IAM["IAM Service"]
    FE --> API["OmniMAM API"]

    IAM --> USER["用户管理"]
    IAM --> AUTH["认证与会话"]
    IAM --> ROLE["角色与权限"]
    IAM --> GROUP["用户组"]
    IAM --> GRANT["资源授权"]
    IAM --> AUDIT["审计客户端"]

    API --> AUTHZ["统一鉴权中间件"]
    AUTHZ --> IAM

    AUDIT -.提交脱敏上下文.-> PLATFORM["platform-management"]

    WORKER["Worker / Agent / App"] --> IAM
    WORKER --> API
```

IAM Service 是以下数据的事实源：

```text
用户
密码凭据
会话
Token
角色
权限
用户组
资源授权
服务账号
服务账号及其凭据
```

`SystemAuthConfig` 与 `AuditLog` 的配置、存储和查询事实属于 `platform-management`。Identity 只消费当前生效认证配置，并通过受控接口提交脱敏审计上下文。

业务资源本身仍由各业务模块管理。

---

## 5. 核心数据模型

## 5.1 User

| 字段                   | 类型       | 说明                                     |
| -------------------- | -------- | -------------------------------------- |
| id                   | string   | 用户全局唯一标识                               |
| username             | string   | 用户名，全局唯一                               |
| normalizedUsername   | string   | 标准化用户名                                 |
| displayName          | string   | 显示名称                                   |
| alias                | string   | 用户别名                                   |
| email                | string   | 邮箱，全局唯一                                |
| normalizedEmail      | string   | 标准化邮箱                                  |
| phone                | string   | 手机号，可选                                 |
| opaqueRegistrationRecord | string | OPAQUE registration record 的 base64url 编码；只作为服务端验证材料保存 |
| status               | enum     | ACTIVE、PENDING、REJECTED、DISABLED、LOCKED、DELETED |
| firstLoginRequired   | boolean  | 是否需要首次登录引导                             |
| failedLoginCount     | integer  | 连续登录失败次数                               |
| lockedUntil          | datetime | 临时锁定截止时间                               |
| securityVersion      | integer  | 凭据安全版本                                 |
| authorizationVersion | integer  | 权限缓存版本                                 |
| passwordChangedAt    | datetime | 密码修改时间                                 |
| lastLoginAt          | datetime | 最后登录成功时间                               |
| online               | boolean  | 根据有效会话和最近活动时间派生的在线状态；仅当前用户和受权管理员可见       |
| createdBy            | string   | 创建人                                    |
| createdAt            | datetime | 创建时间                                   |
| updatedAt            | datetime | 更新时间                                   |

状态说明：

```text
ACTIVE
允许正常登录和使用系统

PENDING
等待管理员审批

REJECTED
最近一次自主注册申请已被拒绝；不能登录，但可以按第 6 章重新申请

DISABLED
管理员禁用

LOCKED
登录失败触发临时锁定

DELETED
逻辑删除
```

当前阶段所有用户均使用本地密码，不单独拆分外部登录身份模型。

### 5.1.1 OPAQUE 密码凭据安全

本地密码认证采用 OPAQUE（RFC 9807），不采用“前端哈希后提交”或“前端加密、后端解密”。固定配置为：

```text
Web: @serenity-kit/opaque@1.1.0
Go: github.com/bytemare/opaque@v0.18.0
OPRF/AKE: Ristretto255/SHA-512
KSF: Argon2id, t=3, m=65536 KiB, p=4
context: omnimam/identity/opaque/v1
```

服务端只保存 OPAQUE `registration_record`，以及稳定部署密钥生成的 setup。服务端 setup 是部署密钥，变更会使已有 registration record 无法验证；部署必须先完成数据清理和新 schema 初始化。原始密码只在浏览器输入和 OPAQUE 计算期间短暂存在，禁止进入 HTTP 请求、日志、审计、事件、响应、数据库或跨 domain 摘要。HTTPS 仍必须强制启用；OPAQUE 不替代 TLS。

注册、登录和改密均使用显式二阶段 exchange。协议消息使用 base64url 编码，exchange 只允许一次提交且短期过期。密码复杂度由 Web 在输入层校验；服务端只校验 OPAQUE 消息合法性、大小、exchange 状态和账号元数据，不接收 `password`、`old_password`、`new_password` 或确认密码字段。

登录开始阶段对未知用户使用 fake registration record，并按与真实用户一致的流程完成协议计算，避免通过响应时间或协议错误枚举用户。只有 OPAQUE KE3 校验成功后，Identity 才执行账号状态、锁定、审计、会话和 Token 逻辑。

## 5.1.2 SystemAuthConfig（事实源迁移至 platform-management）

系统认证配置由 `platform-management` 管理，Identity 只读取其当前生效版本，用于约束本地注册、密码和登录保护。当前产品语义至少包括：

```text
registrationMode: OPEN | ADMIN_APPROVAL
passwordPolicy
passwordHashPolicy: ARGON2ID_V1
loginFailurePolicy
onlinePresenceWindowSeconds: 300
accessTokenLifetime
refreshTokenLifetime
updatedAt
```

配置只能通过 `platform-management` 的受保护管理能力修改；认证流程和后端授权使用同一份生效配置。Identity 不创建或修改 `SystemAuthConfig` 私有表，不提供认证配置管理 API。

---

## 5.2 Role

| 字段          | 类型       | 说明              |
| ----------- | -------- | --------------- |
| id          | string   | 角色 ID           |
| code        | string   | 稳定角色编码          |
| name        | string   | 显示名称            |
| description | string   | 描述              |
| builtin     | boolean  | 是否为内置角色         |
| status      | enum     | ACTIVE、DISABLED |
| createdAt   | datetime | 创建时间            |
| updatedAt   | datetime | 更新时间            |

当前内置角色：

```text
SUPER_ADMIN
ADMIN
USER
```

角色只是权限集合，不表达组织等级。

业务代码不得通过角色名称直接判断权限。

---

## 5.3 PermissionDefinition

| 字段          | 类型     | 说明                         |
| ----------- | ------ | -------------------------- |
| code        | string | 全局唯一权限码                    |
| domain      | string | 所属业务领域                     |
| resource    | string | 资源类型                       |
| action      | string | 操作类型                       |
| name        | string | 显示名称                       |
| description | string | 描述                         |
| riskLevel   | enum   | NORMAL、SENSITIVE、DANGEROUS |
| status      | enum   | ACTIVE、DEPRECATED          |

权限码推荐格式：

```text
<domain>.<resource>.<action>
```

例如：

```text
iam.user.read
iam.user.manage
iam.role.manage

asset.asset.create
asset.asset.read
asset.asset.update
asset.asset.delete
asset.asset.share
asset.asset.manage_all
```

权限定义只读，不允许管理员新增任意权限码。

---

## 5.4 RolePermissionGrant

```text
roleId
permissionCode
createdBy
createdAt
```

表示某个角色拥有某个权限。

---

## 5.5 UserRoleGrant

| 字段            | 说明    |
| ------------- | ----- |
| userId        | 用户 ID |
| roleId        | 角色 ID |
| effectiveFrom | 生效时间  |
| effectiveTo   | 失效时间  |
| createdBy     | 授权人   |
| createdAt     | 创建时间  |

---

## 5.6 Group

用户组用于批量分配角色和资源访问权限。

| 字段          | 说明              |
| ----------- | --------------- |
| id          | 用户组 ID          |
| code        | 稳定编码            |
| name        | 名称              |
| description | 描述              |
| status      | ACTIVE、DISABLED |
| createdBy   | 创建人             |
| createdAt   | 创建时间            |
| updatedAt   | 更新时间            |

当前只支持静态用户组。

---

## 5.7 GroupMember

```text
groupId
userId
createdBy
createdAt
```

唯一约束：

```sql
UNIQUE (group_id, user_id)
```

---

## 5.8 GroupRoleGrant

```text
groupId
roleId
createdBy
createdAt
```

用户有效角色来源包括：

```text
用户直接角色
+
用户所在组的角色
```

---

## 5.9 ResourceAccessGrant

表示资源域选择接入共享能力后，由 Identity 保存的用户或用户组授权关系。它不是跨领域资源目录，也不能单独证明 `resourceType/resourceId` 存在或可见。

| 字段           | 说明                   |
| ------------ | -------------------- |
| resourceType | 资源类型                 |
| resourceId   | 资源 ID                |
| subjectType  | USER、GROUP           |
| subjectId    | 用户或用户组 ID            |
| accessLevel  | VIEW、USE、EDIT、MANAGE |
| grantedBy    | 授权人                  |
| expiresAt    | 可选失效时间               |
| createdAt    | 创建时间                 |

访问等级：

```text
VIEW
查看资源

USE
运行或使用资源

EDIT
修改资源

MANAGE
修改资源、共享和删除资源
```

等级关系：

```text
MANAGE > EDIT > USE > VIEW
```

不同资源可以只支持其中部分等级。

资源域必须声明可用等级、默认可见性、owner 转移规则和删除/归档后的授权行为。未声明接入 ResourceAccessGrant 的资源域不得依赖本对象获得访问权。

---

## 5.10 AuthSession

| 字段           | 说明                     |
| ------------ | ---------------------- |
| id           | 会话 ID                  |
| userId       | 用户 ID                  |
| clientId     | 客户端 ID                 |
| deviceInfo   | 设备信息                   |
| ipAddress    | 来源 IP                  |
| userAgent    | User-Agent             |
| status       | ACTIVE、REVOKED、EXPIRED |
| createdAt    | 创建时间                   |
| lastActiveAt | 最后活动时间                 |
| expiresAt    | 到期时间                   |

---

## 5.11 RefreshToken

| 字段        | 说明                          |
| --------- | --------------------------- |
| id        | Refresh Token ID            |
| sessionId | 所属会话                        |
| tokenHash | Token 哈希                    |
| parentId  | 上一个 Refresh Token           |
| status    | ACTIVE、USED、REVOKED、EXPIRED |
| issuedAt  | 签发时间                        |
| expiresAt | 到期时间                        |

Refresh Token 明文不保存到数据库。

---

## 5.12 PersonalAccessToken（延期）

PAT 不是当前版本可用的认证方式。本节只保留未来设计边界，不能作为 CLI、本地 Agent、MCP Client 或自动化脚本的当前接入依据。MCP v1 必须使用当前用户的 Identity JWT，并在每次请求重新执行授权。

| 字段                 | 说明                     |
| ------------------ | ---------------------- |
| id                 | PAT ID                 |
| userId             | 所属用户                   |
| name               | 用户定义名称                 |
| tokenHash          | Token 哈希               |
| prefix             | 展示前缀                   |
| allowedPermissions | 允许的权限上限                |
| status             | ACTIVE、REVOKED、EXPIRED |
| expiresAt          | 到期时间                   |
| lastUsedAt         | 最后使用时间                 |
| createdAt          | 创建时间                   |

PAT 的最终权限：

```text
用户当前有效权限
∩
PAT 允许权限
```

用户失去权限后，PAT 不能继续保留该权限。

PAT 的创建、交换、轮换和撤销 API 不属于当前版本，也不得在其他 domain 的 S1/S2 中声明为已支持能力。

---

## 5.13 ServiceAccount

供受控 Worker、Agent Runtime、AppStudio 构建/部署组件或其他内部自动化组件访问平台。ServiceAccount 是服务主体，不是普通用户，也不自动继承某个用户的资源所有权。

| 字段                   | 说明                                       |
| -------------------- | ---------------------------------------- |
| id                   | 服务账号 ID                                  |
| code                 | 稳定编码                                     |
| name                 | 名称                                       |
| ownerType            | SYSTEM、WORKER、AGENT、APPLICATION、EXTERNAL |
| ownerId              | 关联对象 ID                                  |
| status               | ACTIVE、DISABLED                          |
| securityVersion      | 凭据版本                                     |
| authorizationVersion | 权限版本                                     |
| createdBy            | 创建人                                      |
| createdAt            | 创建时间                                     |

服务账号通过独立凭据换取短期 Access Token。

服务账号不能使用普通用户登录接口。

服务账号的权限由 Identity 计算；当服务主体代表用户执行用户发起的操作时，调用链必须同时传递不可伪造的委托用户上下文，由目标 domain 记录 `principal_id` 与 `actor_user_id`。没有委托用户时，服务账号只能执行其被授予的系统或服务权限。

服务账号只通过直接角色获得权限，不加入用户组，也不接受游离于角色之外的权限码列表。`ServiceAccountRoleGrant` 至少包含 `serviceAccountId`、`roleId`、`effectiveFrom`、`effectiveTo`、`createdBy` 和 `createdAt`；有效角色同样过滤禁用角色、未生效和已过期授权。角色授权变化递增 `authorizationVersion`。

`ownerType + ownerId` 是受控归属引用。创建时必须由对应 owner domain 校验目标存在且操作者有管理权；`SYSTEM` 可无 `ownerId`。owner 摘要只包含类型、ID、显示名和 `AVAILABLE | DELETED | UNAVAILABLE | NOT_VISIBLE` 状态。owner 被删除前必须处理关联服务账号；如果异常情况下 owner 不可用，凭据交换必须 fail closed，管理员只能禁用该账号并创建新的正确归属账号，不允许静默改绑。

## 5.14 RegistrationApplication

自主注册审批的独立事实，用于保存每次申请和不可变决策历史：

| 字段 | 说明 |
| --- | --- |
| id | 注册申请 ID |
| userId | 对应 User ID |
| attemptNo | 同一 User 的申请序号，单调递增 |
| status | PENDING、APPROVED、REJECTED |
| submittedAt | 提交时间 |
| decidedAt | 决策时间，可空 |
| decidedBy | 审批主体 ID，可空 |
| decisionReason | 拒绝时必填的原因；批准时可空 |

同一 User 同时最多存在一条 `PENDING` 申请。审批历史不可覆盖或删除，普通登录响应不暴露内部审批人信息。

---

## 6. 用户注册

## 6.1 自主注册流程

```mermaid
sequenceDiagram
    actor U as 用户
    participant FE as OmniMAM Web
    participant IAM as IAM Service

    U->>FE: 输入用户名、邮箱和密码
    FE->>FE: 校验密码策略并生成 registration_request
    FE->>IAM: register/start(registration_request, 账号元数据)
    IAM-->>FE: exchange_id + registration_response
    FE->>FE: 生成 registration_record 并清理协议状态
    FE->>IAM: register/finish(exchange_id, registration_record)

    IAM->>IAM: 校验账号元数据和 OPAQUE 消息

    alt 校验失败
        IAM-->>FE: 返回注册错误
    else 校验成功且 registrationMode=OPEN
        IAM->>IAM: 创建 ACTIVE User 并分配 USER 角色
        IAM->>IAM: 创建登录会话
        IAM-->>FE: 返回凭据与授权投影
    else 校验成功且 registrationMode=ADMIN_APPROVAL
        IAM->>IAM: 创建 PENDING User 和 RegistrationApplication
        IAM-->>FE: 返回待审批结果，不创建角色、会话或 Token
    end
```

注册成功后：

```text
User.status = ACTIVE
firstLoginRequired = false
```

如果系统启用注册审批：

```text
User.status = PENDING
```

此时不得分配有效角色、创建会话或签发 Token。注册结果页展示“等待审批”和申请提交时间，不展示审批人或内部审计信息。

### 6.1.1 注册审批

具有注册审批权限的管理员可以按 `PENDING` 状态分页查看申请和对应用户最小管理摘要，并执行：

```text
批准
拒绝（必须填写原因）
```

批准时，Identity 原子地将申请标记为 `APPROVED`、将 User 置为 `ACTIVE`、分配默认 `USER` 角色并递增 `authorizationVersion`。批准不代替登录，不创建会话；申请人随后使用注册密码正常登录，`firstLoginRequired=false`。

拒绝时，Identity 将申请标记为 `REJECTED`、保存拒绝原因并将 User 置为 `REJECTED`。拒绝不删除用户、凭据历史或审计事实，不分配角色，也不允许登录。相同决策的重复请求返回当前决策结果；对已决申请提交相反决策返回稳定冲突错误。

被拒绝的申请人可以使用相同的标准化用户名和邮箱重新提交注册。重新申请会替换 registration record，创建更高 `attemptNo` 的新申请并将 User 恢复为 `PENDING`；旧申请保持不可变。用户名或邮箱只匹配其中一项、账号不是 `REJECTED`，或仍有待审批申请时，继续按用户名/邮箱冲突处理。

审批、拒绝和重新申请都属于敏感操作；平台审计写入不可用时必须 fail closed。审批完成后的页面状态可以通过可靠事件或重新查询刷新，不依赖前端推断。

---

## 6.2 管理员创建用户

管理员创建用户时，管理员在受信任的 Web 客户端输入或生成初始密码，Web 使用与自主注册相同的 registration start/finish 流程提交 registration record。服务端不生成、不接收、不返回初始密码；创建成功后只返回用户元数据和 `firstLoginRequired=true`。遗失初始密码只能重新提交新的 registration 流程。

1. 输入用户名、邮箱、显示名称；
2. 系统生成一次性初始密码；
3. 创建用户；
4. 设置 `firstLoginRequired=true`；
5. 分配默认 `USER` 角色；
6. 创建响应只返回一次初始密码，关闭后不能再次读取；遗失时只能重新生成新的一次性密码并使旧值失效；
7. 用户首次登录后必须修改密码。

重新生成初始密码只允许用于仍处于 `firstLoginRequired=true` 的管理员创建用户。操作会递增 `securityVersion`、撤销已有受限会话，并只返回一次新密码；已完成首次登录的用户必须使用普通改密或后续受控找回流程，不能通过该动作重置。

管理员不能查看用户后续密码。

---

## 7. 用户登录

```mermaid
flowchart TD
    A["提交用户名或邮箱和密码"] --> B["查找 User"]
    B --> C{"用户是否存在"}

    C -->|否| D["返回 invalid_credentials"]
    C -->|是| E["检查用户状态"]

    E --> F{"是否允许登录"}
    F -->|否| G["返回账号状态错误"]
    F -->|是| H["校验密码"]

    H --> I{"密码是否正确"}
    I -->|否| J["增加失败次数"]
    J --> K{"达到锁定阈值"}
    K -->|是| L["临时锁定用户"]
    K -->|否| D

    I -->|是| M["清零失败次数"]

    M --> N{"firstLoginRequired"}
    N -->|是| O["创建首次登录受限会话"]
    N -->|否| P["创建正常会话"]

    P --> Q["签发 Access Token 和 Refresh Token"]
    O --> Q
    Q --> R["更新 lastLoginAt 和当前会话 lastActiveAt"]
```

登录失败统一返回：

```text
用户名或密码错误
```

不得向未认证用户暴露用户名是否存在。

`PENDING`、`REJECTED`、`DISABLED` 和 `LOCKED` 使用稳定账号状态结果；只有在调用方已经通过正确密码证明其持有该账号凭据后，才可以返回对应状态。临时锁定可返回 `lockedUntil` 供本人展示解锁时间，但错误文案仍不得用于探测账号是否存在。平台审计写入失败时，登录不得创建可用会话，并返回可重试的稳定失败结果。

登录成功响应必须包含第 10.3 节的版本化当前主体授权投影。该投影用于身份展示和客户端能力呈现，不写入 JWT，也不替代后端实时鉴权。

---

## 8. 首次登录

首次登录受限会话只允许：

```text
读取密码策略
修改密码
修改邮箱和个人信息
退出登录
```

完成流程：

```mermaid
flowchart TD
    A["首次登录认证成功"] --> B["创建受限会话"]
    B --> C["用户修改初始密码"]
    C --> D["启动 change-password OPAQUE exchange"]
    D --> E["验证旧密码并保存新 registration record"]
    E --> F["firstLoginRequired = false"]
    F --> G["增加 securityVersion"]
    G --> H["撤销受限会话"]
    H --> I["要求重新登录"]
```

---

## 9. Token 与会话

## 9.1 Access Token

Access Token 使用 JWT。

推荐载荷：

```json
{
  "iss": "omnimam-iam",
  "sub": "principal-id",
  "subject_type": "USER",
  "aud": "omnimam-api",
  "sid": "session-id",
  "client_id": "omnimam-web",
  "jti": "token-id",
  "security_version": 3,
  "iat": 0,
  "exp": 0
}
```

用户 Access Token 的 `subject_type` 为 `USER`；服务主体换取的 Access Token 使用 `SERVICE_ACCOUNT`，不创建用户 AuthSession。Access Token 不包含权限码。

---

## 9.2 Token 保存

浏览器端建议：

```text
Access Token
保存在前端内存

Refresh Token
保存在 HttpOnly、Secure Cookie
```

Refresh Token 不允许被 JavaScript 直接读取。

---

## 9.3 Refresh Token 轮换

```mermaid
sequenceDiagram
    participant FE as Web
    participant IAM as IAM Service

    FE->>IAM: 使用 Refresh Token 刷新
    IAM->>IAM: 校验 Token 和 Session
    IAM->>IAM: 将旧 Refresh Token 标记 USED
    IAM->>IAM: 签发新 Access Token
    IAM->>IAM: 签发新 Refresh Token
    IAM-->>FE: 返回新登录凭据
```

旧 Refresh Token 被再次使用时：

```text
撤销整个 AuthSession
撤销该会话所有 Refresh Token
记录 refresh_token_reused 审计
要求用户重新登录
```

刷新成功响应返回新的凭据和最新授权投影。Refresh Token 无效、过期、重用或对应会话已撤销时，客户端清除本地登录态、返回登录页并保留不含敏感内容的重新登录原因；不得无限自动重试。

---

## 9.4 登出

当前设备登出：

```text
撤销当前 AuthSession
撤销当前会话 Refresh Token
使当前 Access Token jti 在剩余有效期内失效
```

全部设备登出：

```text
撤销用户全部 AuthSession
撤销全部 Refresh Token
增加 User.securityVersion
```

会话列表必须区分当前会话与其他会话，展示设备/客户端、IP、最近活动、创建时间、过期时间和状态。当前列表默认保留最近 30 天内撤销或过期的会话用于用户识别，超过保留窗口不再展示；该展示保留不改变审计保留策略。

撤销其他会话后当前会话继续有效；撤销当前会话或执行当前设备登出后立即清除本地凭据并返回登录页；全部设备登出使所有客户端重新认证。对已经撤销或过期的会话重复撤销返回幂等成功结果。

---

## 9.5 修改密码

用户修改密码必须输入：

```text
旧密码和新密码只在浏览器内存中用于 OPAQUE 计算；请求只包含 `ke1`、`ke3` 和新的 `registration_record`
```

修改成功后：

```text
增加 User.securityVersion
撤销全部 Session
撤销全部 Refresh Token
强制重新登录
```

---

## 9.6 用户在线状态

用户在线状态不是 `User.status` 的新状态，而是基于认证会话实时派生的布尔值。默认在线窗口为 `300` 秒，由 `SystemAuthConfig.onlinePresenceWindowSeconds` 配置。

在判断时，用户满足以下条件才算在线：

```text
User.status = ACTIVE
且存在 AuthSession：
  AuthSession.status = ACTIVE
  AuthSession.expiresAt > 当前时间
  AuthSession.lastActiveAt >= 当前时间 - onlinePresenceWindowSeconds
```

被撤销、过期或所属用户已禁用的会话不参与判断。一个用户拥有多个设备时，只要任一有效会话满足条件即为在线；所有有效会话都超出在线窗口后即为离线。在线状态不改变 `User.status`，也不代表用户正在执行具体业务操作。

登录成功创建会话、Refresh Token 成功轮换以及当前会话的 presence heartbeat 都会更新该会话的 `lastActiveAt`。客户端应在会话有效期间调用 `POST /api/v1/iam/auth/presence/heartbeat` 维持在线状态；心跳只更新当前会话，不会延长 Token 或会话的 `expiresAt`。

当前用户可以查看自己的在线状态；具有用户管理权限的管理员可以查看其管理范围内用户的在线状态。资源共享用户目录和普通用户搜索结果不得返回其他用户的在线状态。在线状态是短暂派生信息，不写入跨 domain 事件，也不作为资源授权、任务执行或用户状态变更的依据。

---

## 10. 角色与权限计算

## 10.1 有效角色

```text
用户直接角色
+
用户组角色
```

计算时过滤：

```text
禁用角色
未生效授权
已过期授权
禁用用户组
```

## 10.2 有效权限

```mermaid
flowchart TD
    A["计算用户权限"] --> B["获取用户直接角色"]
    A --> C["获取用户组角色"]

    B --> D["合并角色"]
    C --> D

    D --> E["过滤无效角色"]
    D --> E["合并 RolePermissionGrant"]
    E --> F["写入权限缓存"]
```

`SUPER_ADMIN` 的全量管理能力必须通过已登记的权限定义表达，不能成为绕过授权的隐式分支。任何主体仍然不能绕过：

```text
用户状态检查
Token 和 Session 检查
敏感操作审计写入
最后一个超级管理员保护
```

## 10.3 当前主体授权投影

前端登录后使用统一的版本化授权投影：

```text
principalType: USER | SERVICE_ACCOUNT
principalId
actorUserId: 可选
authorizationVersion
effectiveRoles:
  - id
    code
    name
    source: DIRECT | GROUP
    sourceId: GROUP 来源时为用户组 ID，DIRECT 时为空
permissionCodes
sessionMode: NORMAL | FIRST_LOGIN_RESTRICTED
allowedActions
```

USER 的 `effectiveRoles` 区分直接授权与用户组来源；同一角色通过多个来源获得时可以返回多条来源摘要，但 `permissionCodes` 必须去重。SERVICE_ACCOUNT 只返回 `DIRECT` 角色。角色摘要仅用于身份标签和授权来源解释；菜单、按钮和动作可用性只使用 `permissionCodes` 与 `allowedActions`，业务代码不得按角色名授权。

登录和 Refresh 响应返回当时最新投影；`GET /api/v1/iam/auth/permissions` 返回同一结构，供客户端独立刷新。客户端在应用启动、Token 刷新、页面重新聚焦/网络重连、收到当前主体的授权失效通知或遇到权限拒绝后重新获取投影。`identity.authorization.changed` 只通知新的 `authorizationVersion`，客户端必须重新读取投影，不从事件拼装角色或权限。

`FIRST_LOGIN_RESTRICTED` 明确只允许读取密码策略、修改密码、修改本人资料和退出；其他 `permissionCodes` 即使存在也不得在该会话中启用。授权变化必须递增受影响主体的 `authorizationVersion`；客户端看到更高版本后替换整个旧投影，不能合并。后端每次请求仍检查当前主体状态、凭据和权限，旧客户端投影不能扩大权限。

## 10.4 内置角色权限基线

各 domain 在 `permissions.yaml` 中声明的 `default_roles` 是内置角色权限基线，不是仅供文档展示的标签。Identity 完成权限目录登记后，必须将所有 ACTIVE 权限声明聚合并幂等物化为 `RolePermissionGrant`；新增权限、调整 `default_roles` 或权限废弃时必须重新对账。只登记 `PermissionDefinition`、但不创建对应角色授权，属于不完整初始化。

当前与 Identity 和 Platform 管理入口直接相关的最小基线为：

| 内置角色 | 必须包含的权限 |
| --- | --- |
| `USER` | `identity.auth.session`、`identity.user.read`、`identity.permission.read`、`identity.resource_grant.read` |
| `ADMIN` | `USER` 基线，加 `identity.user.manage`、`identity.registration.review`、`identity.group.manage`、`identity.service_account.read`、`platform.overview.read`、`platform.auth_config.read`、`platform.audit.read` |
| `SUPER_ADMIN` | `ADMIN` 基线，加 `identity.role.manage`、`identity.service_account.manage`、`platform.auth_config.manage` |

上表只列出 Identity 与 Platform 的直接管理权限；其他业务 domain 的 `default_roles` 声明仍必须进入同一聚合与对账流程。`SUPER_ADMIN` 不得通过角色名获得隐式全权限，其最终 `permissionCodes` 仍来自已登记的 `RolePermissionGrant`。

对账发现权限码未登记、内置角色缺失或授权写入失败时必须失败并报告，不得返回一个看似有效但缺少基线权限的授权投影。对账成功后，所有受影响角色的用户和服务主体必须递增 `authorizationVersion`，使登录、Refresh 和 `GET /api/v1/iam/auth/permissions` 返回更新后的去重权限码和 `allowedActions`。

---

## 11. 权限缓存

权限缓存键：

```text
authz:user:{userId}:{authorizationVersion}
```

以下变化增加 `User.authorizationVersion`：

```text
用户角色变化
用户组成员变化
用户组角色变化
角色权限变化
角色被禁用
```

旧缓存自然失效。

不要求扫描删除全部旧缓存键。

---

## 12. 资源所有权与共享

## 12.1 资源所有权

资源域向 Identity 授权检查提供其自己的 owner、visibility 和资源状态摘要。平台通用约定是：

```text
owner_user_id（资源域支持用户所有权时）
created_by（资源域需要记录创建主体时）
```

Identity 不替资源域决定 owner 是否天然拥有 `MANAGE`；资源域必须在自身 S1 中定义默认 owner 能力。资源域也必须拒绝客户端直接指定其他用户为 owner。

---

## 12.2 资源访问判断

```mermaid
flowchart TD
    A["访问具体资源"] --> B["校验身份和 Token"]
    B --> C["检查操作权限码"]

    C --> D{"是否拥有操作权限"}
    D -->|否| E["permission_denied"]

    D -->|是| F["由资源域确认对象存在、状态、owner 与 visibility"]
    F --> G{"资源域是否允许当前主体"}
    G -->|是| H["允许访问"]
    G -->|否| I{"资源域是否接入 ResourceAccessGrant"}
    I -->|是| J["检查用户/用户组授权等级"]
    J -->|满足| H
    J -->|不满足| K["resource_access_denied"]
    I -->|否| K
    F --> L{"是否拥有该资源域登记的 manage_all"}
    L -->|是| H
    L -->|否| K
```

---

## 12.3 资源共享

对于已声明接入共享的资源域，资源所有者或具有资源域 `MANAGE` 能力的用户可以：

```text
共享给指定用户
共享给用户组
修改共享等级
设置共享过期时间
撤销共享
```

共享时只能选择平台内已经存在的用户或用户组。

普通用户搜索能力只用于明确的资源共享场景，并应限制返回字段：

```text
userId
displayName
username
avatar
```

不得返回：

```text
邮箱
手机号
角色
登录状态
安全信息
私有资源
```

平台也可以通过精确用户名输入代替全量用户目录。

共享授权只解决主体到资源的授权关系；资源域仍负责检查资源状态、visibility、版本和业务动作是否允许。管理员代管或跨 owner 操作必须同时记录操作主体与资源 owner。

---

## 12.4 全量管理权限

管理员跨 owner 访问全部同类资源时，必须拥有资源域登记的显式权限：

```text
asset.asset.manage_all
canvas.canvas.manage_all
application.application.manage_all
agent.agent.manage_all
```

不能仅因为角色名是 `ADMIN` 就自动访问全部用户资源。

---

## 13. API 鉴权

受保护 API 必须显式声明权限码。

例如：

```text
POST /api/v1/assets
permission: asset.asset.create

GET /api/v1/assets/{id}
permission: asset.asset.read
resource-check: VIEW

PUT /api/v1/assets/{id}
permission: asset.asset.update
resource-check: EDIT

DELETE /api/v1/assets/{id}
permission: asset.asset.delete
resource-check: MANAGE
```

完整流程：

```mermaid
flowchart TD
    A["请求进入 API"] --> B["验证 Access Token"]
    B --> C{"Token 是否有效"}

    C -->|否| D["HTTP 200 + unauthenticated"]
    C -->|是| E["构建 PrincipalContext"]

    E --> F["读取接口权限码"]
    F --> G["检查用户操作权限"]

    G --> H{"是否允许"}
    H -->|否| I["HTTP 200 + permission_denied"]

    H -->|是| J{"是否涉及具体资源"}
    J -->|否| K["进入业务处理"]

    J -->|是| L["检查资源所有权或共享关系"]
    L --> M{"是否允许访问"}
    M -->|否| N["HTTP 200 + resource_access_denied"]
    M -->|是| K
```

后端禁止：

```text
if role == "ADMIN"
if username == "admin"
信任前端 ownerUserId
只验证 JWT 签名
使用前端隐藏作为安全边界
```

### 13.1 跨 domain PrincipalContext

所有业务 domain 只消费受 Identity 验证后的主体与授权结果，不直接查询 IAM 私有表。逻辑上的 `PrincipalContext` 至少表达：

```text
principal_type: USER | SERVICE_ACCOUNT
principal_id: 当前认证主体 ID
actor_user_id: 可选；服务主体代表用户执行操作时的委托用户 ID
auth_session_id: 用户会话 ID；服务主体可为空
credential_version: 用于撤销和安全版本校验
permission_snapshot: 当前请求的权限判定结果，不是 Token 内的完整权限列表
```

跨域规则：

1. 业务资源的 `owner_user_id`、`created_by`、`visibility`、`project` 和 `namespace` 由资源 domain 维护；调用者不能通过请求体覆盖。
2. `principal_id` 用于识别实际认证主体；`actor_user_id` 只在存在受控委托时出现，不能由客户端任意提交。
3. 业务 domain 可以把 `principal_id` 解析为一跳 owner/collaborator 摘要，但不能递归展开用户、角色或完整权限。
4. service-to-service 调用使用 ServiceAccount；用户发起的异步任务、Agent、AppStudio 或 MCP 操作必须保留原始用户授权语义，不得用一个全局服务账号替代用户授权。
5. sse、notification-center 等投影只接收已裁剪的主体/资源事件，不从 Identity 或业务私表拼装新的业务事实。

---

## 14. 用户管理

管理员可以：

```text
查看用户列表
创建用户
修改用户基础资料
禁用用户
恢复用户
解除临时锁定
分配角色
加入或移出用户组
逻辑删除用户
```

管理员不能：

```text
查看用户密码
获取用户完整 Token
直接修改用户密码为已知值
删除审计记录
```

---

## 14.1 禁用用户

禁用用户后：

```text
User.status = DISABLED
增加 securityVersion
撤销全部 Session
撤销全部 Refresh Token
禁用相关服务账号由业务策略决定
```

用户拥有的资源继续保留。

---

## 14.2 删除用户

默认优先禁用用户，不直接删除。

Identity 的用户生命周期协调器负责聚合删除依赖摘要，但不读取其他 domain 私有表。每个已登记资源 domain 通过受控批量检查合同返回：

```text
sourceDomain
category
objectType
count
blocking
sourceStatus: AVAILABLE | UNAVAILABLE
handlingMode: TRANSFER | DELETE | CANCEL | REVOKE | DISABLE | NONE
managementEntry: 可选的稳定前端路由键，不是任意 URL
```

Identity 自身返回直接角色/组关系、服务账号和有效共享授权摘要；asset-library、workflow-canvas、application-platform、agent、appstudio、task-center 等目标 domain 分别返回其拥有资源和未完成工作的摘要。任一已登记来源超时、不可用或返回不完整结果时，聚合状态为 `INCOMPLETE` 并阻断删除，不能把未知当作零依赖。

每次完整检查产生短期有效的 `dependencyCheckId`、`checkedAt`、`expiresAt` 和逐项摘要。管理员必须先处理所有阻塞项，再重新检查；删除请求携带最新检查 ID，Identity 在提交前再次验证检查未过期、来源集合未变化且没有新增阻塞。旧检查不得复用。

存在资源时应由事实拥有 domain 完成：

```text
资源转移
或
资源清理
```

资源转移由目标 domain 发起和持久化；目标用户必须为 `ACTIVE`、不是待审批/拒绝/禁用/删除用户，并通过目标 domain 的 owner/协作者规则校验。Identity 只提供受控用户摘要和删除检查协调，不提供伪造的统一转移写接口。未完成任务由 task-center 决定取消或等待策略；服务账号必须先禁用并撤销凭据；共享关系按目标 domain 与 Identity 的协作合同撤销或重建。

删除规则：

```text
用户不能删除自己
不能删除最后一个有效 SUPER_ADMIN
不能级联删除业务资源
不能删除审计记录
任何依赖来源不可用时 fail closed
```

删除成功后撤销用户全部会话和凭据，清理 Identity 内不再有效的角色/组关系和授权投影，将 User 置为 `DELETED`，但保留稳定 ID 和必要审计关联。失败响应返回可处理的依赖摘要或不可用来源；管理员从对应管理入口处理后重新检查并重试。

---

## 15. Service Account

## 15.1 使用场景

```text
Task Worker
Notification Worker
Agent Runtime
AppStudio Build / Deployment
外部自动化程序
```

## 15.2 服务账号认证

```mermaid
sequenceDiagram
    participant C as Worker / Agent / App
    participant IAM as IAM Service
    participant API as OmniMAM API

    C->>IAM: client_id + client_secret
    IAM->>IAM: 校验 ServiceAccount
    IAM-->>C: 短期 Access Token

    C->>API: Bearer Access Token
    API->>IAM: 检查身份与权限
    IAM-->>API: 授权结果
```

服务账号不使用 Refresh Token。

Access Token 过期后重新交换。

凭据交换前必须检查服务账号状态、owner 可用性、凭据状态和到期时间、`securityVersion`、有效直接角色与当前权限；成功后更新凭据 `lastUsedAt` 并返回短期 Access Token 和当前授权投影。失败不得暴露账号或凭据是否单独存在。

## 15.3 管理与授权投影

管理员可以创建、分页查询、查看详情、更新非敏感资料、禁用、启用、替换直接角色、轮换凭据和撤销指定凭据。列表和详情至少展示：

```text
code、name、status
ownerType、ownerId、ownerSummary、ownerState
authorizationVersion、effectiveRoles
凭据 prefix、status、issuedAt、expiresAt、lastUsedAt、revokedAt
轮换来源和轮换时间
```

创建和轮换响应只返回一次新的 `clientSecret`。用户界面必须明确要求操作者确认已经安全保存后再关闭；关闭后服务端不提供再次读取接口，遗失时只能轮换。轮换原子创建新凭据并立即撤销旧凭据及其已签发 Token；撤销最后一个有效凭据允许服务账号保持 `ACTIVE`，但其无法换取新 Token。

禁用服务账号会递增 `securityVersion`、撤销全部凭据和已签发 Token；重新启用不会恢复旧凭据，必须创建新凭据。直接角色、角色状态或角色权限变化递增 `authorizationVersion`，不必等待已有 Token 过期即可收紧权限。

## 15.4 安全要求

```text
不同运行实体使用不同服务账号
密钥只显示一次
数据库只保存密钥哈希
支持凭据轮换
支持立即撤销
服务账号默认最小权限
```

不得让所有 Worker 或 Agent 共用一个全权限账号。

---

## 16. PAT

当前版本不提供 PAT。未来如需支持，用户才可以创建 PAT 用于：

```text
CLI
本地 Agent
自动化脚本
```

创建时必须设置：

```text
名称
权限上限
到期时间
```

PAT 明文只显示一次。

用户可以查看：

```text
名称
前缀
创建时间
到期时间
最后使用时间
状态
```

用户不能再次查看完整 PAT。

当前版本不得提供 PAT 管理页面或 `/api/pats` 接口；MCP Client 使用当前用户的 Identity JWT。

---

## 17. 系统初始化

系统首次启动时创建：

```text
SUPER_ADMIN
ADMIN
USER
```

以及一个初始化管理员。

初始化管理员规则：

1. 用户名可以默认为 `admin`；
2. 用户名本身不产生特殊权限；
3. 初始密码不得固定写死为 `admin`；
4. 通过部署环境变量、安装向导或随机值提供一次性密码；
5. 初始密码只展示一次；
6. `firstLoginRequired=true`；
7. 首次登录必须修改密码；
8. 系统始终至少保留一个有效 SUPER_ADMIN；
9. 所有操作必须记录审计。

---

## 18. 前端页面

页面只投影 S1/S2 事实，不以隐藏控件代替后端授权。每个失败结果都使用稳定业务码，并保留不含密码、Token、Secret 或内部堆栈的恢复说明。

## 18.1 登录、注册与首次登录

- 注册入口根据当前 `registrationMode` 显示自主注册或审批注册；若平台配置不可用，不猜测默认模式，展示暂不可注册并允许重试。
- `OPEN` 注册成功进入已登录状态；`ADMIN_APPROVAL` 进入待审批结果页，展示申请状态和提交时间，不持有 Token。
- `PENDING`、`REJECTED`、`DISABLED`、`LOCKED` 以及首次登录受限状态使用明确结果；锁定截止时间只在正确密码校验后向账号持有者显示。
- 首次登录页只开放密码、本人资料和退出动作；完成后清除受限会话并返回登录页。
- Refresh Token 失效、重用或强制撤销时停止自动刷新、清除本地登录态并要求重新认证。
- 敏感操作因平台审计不可用而 fail closed 时，展示稳定的暂不可用结果和人工重试入口，不将未提交的动作显示为成功。

## 18.2 个人资料与会话

- 个人资料页将用户名显示为只读；可编辑显示名称、别名、邮箱和手机号，并显示邮箱冲突等字段结果。
- 当前用户可以查看自己的短暂在线状态；页面说明该状态可能受心跳和 300 秒窗口影响，不能作为账号状态或授权依据。
- 修改密码成功后明确提示所有设备会话已失效，并立即进入重新登录流程。
- 会话页区分当前会话和其他会话，展示设备、客户端、IP、最近活动、创建、过期和状态；允许撤销单个其他会话、当前设备登出和全部设备登出。
- 撤销/过期会话按第 9.4 节保留窗口展示；重复撤销为幂等结果，撤销当前会话后不得停留在受保护页面。

## 18.3 用户与注册审批管理

- 用户列表和详情展示账号状态、派生在线状态、锁定截止时间、首次登录标记、`authorizationVersion`、直接角色和用户组角色来源。
- 管理员可按 `PENDING` 查看注册申请，批准或带原因拒绝；已决申请只读，重复同一决策显示当前结果，冲突决策提示不可覆盖。
- 用户动作根据状态只提供可执行的批准、拒绝、禁用、恢复、解锁和逻辑删除；自删除、最后一个有效 SUPER_ADMIN 和非法状态显示保护原因。
- 管理员创建用户和系统初始化的一次性初始密码只在成功结果中出现一次；关闭后不提供查看入口。
- 删除前展示带检查时间和完整性状态的依赖摘要。阻塞项提供来源 domain 与稳定管理入口；来源不可用时明确阻断。处理完成后管理员重新检查并使用最新检查结果删除。

## 18.4 角色、权限与用户组管理

- 内置角色显示保护标记；自定义角色可修改名称、描述、状态和已登记权限，内置角色不可执行受保护修改。
- 角色禁用前展示受影响主体数量；禁用后相关有效角色和权限立即失效，客户端按更高 `authorizationVersion` 刷新。
- 权限目录按 domain、resource、action、riskLevel 和状态展示；`DEPRECATED` 权限不可新增分配，并提示管理员从角色中移除。
- 用户直接角色展示生效/失效时间；用户组角色展示组来源。用户组禁用后，其成员不再从该组获得有效角色。
- 角色权限、组成员或组角色整体替换前展示影响摘要，成功后显示已产生的新授权版本或重新加载提示。

## 18.5 Service Account 管理

- 列表和详情展示非敏感账号、owner 摘要、状态、有效直接角色、授权版本及凭据状态/到期/最后使用/轮换历史。
- 创建和轮换只展示一次 `clientSecret`，关闭前要求确认已安全保存；关闭后只能轮换，不能再次查看。
- 管理员可禁用、启用、替换角色、轮换和撤销凭据；禁用或 owner 不可用时明确说明凭据交换已被阻断。
- owner 摘要不可用不伪造名称；保留 `ownerType + ownerId` 和不可用状态，禁止从页面静默改绑。

## 18.6 资源共享投影

- 资源详情只展示目标 domain 声明支持的访问等级，不固定展示全部 `VIEW/USE/EDIT/MANAGE`。
- 用户/用户组选择器只返回受限摘要。用户摘要不包含邮箱、手机号、角色或在线状态。
- 授权项展示直接用户或用户组来源、当前有效访问等级，以及 `ACTIVE | EXPIRING | EXPIRED | REVOKED | SUBJECT_UNAVAILABLE` 状态。
- 用户或组被禁用、删除后不再产生有效访问；历史授权可以保留不可变摘要，但不能继续授权。owner 转移入口和规则仍由目标资源 domain 拥有。

## 18.7 在线状态投影

- 只有当前用户和具有用户管理权限的管理员可在个人资料或用户管理范围内查看在线状态。
- 普通共享目录、跨域用户摘要和普通用户搜索不返回其他用户在线状态。
- 心跳失败只影响在线投影的新鲜度，不延长 Token 或会话，不自动把用户登出；Token/会话错误按认证规则单独处理。

## 18.8 跨域管理入口

“系统认证配置”和“安全审计”页面属于 `platform-management`，不属于 Identity 管理页面。Identity 可提供带权限校验的导航入口，但只负责应用当前认证配置和提交脱敏审计上下文；配置读取、修改、审计查询和详情投影均由 `platform-management` 定义。

---

## 19. 主要接口

## 19.1 认证

```text
POST /api/v1/iam/auth/register/start
POST /api/v1/iam/auth/register/finish
POST /api/v1/iam/auth/login/start
POST /api/v1/iam/auth/login/finish
POST /api/v1/iam/auth/refresh
POST /api/v1/iam/auth/logout
POST /api/v1/iam/auth/logout-all
POST /api/v1/iam/auth/change-password/start
POST /api/v1/iam/auth/change-password/finish
POST /api/v1/iam/auth/presence/heartbeat
GET  /api/v1/iam/auth/me
PUT  /api/v1/iam/auth/me
GET  /api/v1/iam/auth/permissions
GET  /api/v1/iam/auth/sessions
DELETE /api/v1/iam/auth/sessions/{id}
POST /api/v1/iam/service-accounts/token
```

## 19.2 用户管理

```text
GET    /api/v1/iam/admin/users
POST   /api/v1/iam/admin/users
GET    /api/v1/iam/admin/users/{id}
PUT    /api/v1/iam/admin/users/{id}
POST   /api/v1/iam/admin/users/{id}/disable
POST   /api/v1/iam/admin/users/{id}/enable
POST   /api/v1/iam/admin/users/{id}/unlock
POST   /api/v1/iam/admin/users/{id}/reset-initial-password/start
POST   /api/v1/iam/admin/users/{id}/reset-initial-password/finish
PUT    /api/v1/iam/admin/users/{id}/roles
GET    /api/v1/iam/admin/users/{id}/deletion-dependencies
DELETE /api/v1/iam/admin/users/{id}?dependency_check_id={check_id}

GET  /api/v1/iam/admin/registration-applications
GET  /api/v1/iam/admin/registration-applications/{id}
POST /api/v1/iam/admin/registration-applications/{id}/approve
POST /api/v1/iam/admin/registration-applications/{id}/reject
```

## 19.3 角色和用户组

```text
GET  /api/v1/iam/admin/roles
POST /api/v1/iam/admin/roles
GET  /api/v1/iam/admin/roles/{id}
PUT  /api/v1/iam/admin/roles/{id}
PUT  /api/v1/iam/admin/roles/{id}/permissions

GET  /api/v1/iam/admin/permissions

GET  /api/v1/iam/admin/groups
POST /api/v1/iam/admin/groups
GET  /api/v1/iam/admin/groups/{id}
PUT  /api/v1/iam/admin/groups/{id}
PUT  /api/v1/iam/admin/groups/{id}/members
PUT  /api/v1/iam/admin/groups/{id}/roles
```

## 19.4 资源授权（仅供接入的资源域使用）

```text
GET    /api/v1/iam/resources/{type}/{id}/grants
POST   /api/v1/iam/resources/{type}/{id}/grants
PATCH  /api/v1/iam/resources/{type}/{id}/grants/{grant_id}
DELETE /api/v1/iam/resources/{type}/{id}/grants/{grant_id}

GET /api/v1/iam/directory/users
GET /api/v1/iam/directory/groups
```

## 19.5 Service Account

```text
GET  /api/v1/iam/admin/service-accounts
POST /api/v1/iam/admin/service-accounts
GET  /api/v1/iam/admin/service-accounts/{id}
PUT  /api/v1/iam/admin/service-accounts/{id}
POST /api/v1/iam/admin/service-accounts/{id}/disable
POST /api/v1/iam/admin/service-accounts/{id}/enable
PUT  /api/v1/iam/admin/service-accounts/{id}/roles
GET  /api/v1/iam/admin/service-accounts/{id}/credentials
POST /api/v1/iam/admin/service-accounts/{id}/rotate-credential
POST /api/v1/iam/admin/service-accounts/{id}/credentials/{credential_id}/revoke
```

## 19.6 受控内部主体检查

```text
POST /api/v1/iam/internal/principal/check
```

该接口只返回本次请求的权限判定和最小 PrincipalContext，不返回完整授权投影、角色图或凭据。

---

## 20. 错误码

| 错误码                              | 说明                   |
| -------------------------------- | -------------------- |
| unauthenticated                  | 未登录或登录态无效            |
| invalid_credentials              | 用户名或密码错误             |
| account_pending                  | 账号等待审批               |
| account_rejected                 | 注册申请已被拒绝             |
| account_disabled                 | 账号已禁用                |
| account_locked                   | 账号已锁定                |
| first_login_required             | 必须完成首次登录             |
| token_expired                    | Access Token 已过期     |
| token_revoked                    | Token 或会话已撤销         |
| refresh_token_invalid            | Refresh Token 无效     |
| refresh_token_reused             | 检测到 Refresh Token 重用 |
| password_policy_failed           | 密码不符合安全策略            |
| old_password_invalid             | 原密码错误                |
| password_protocol_unsupported    | 请求使用了不支持的旧密码协议 |
| password_protocol_invalid        | OPAQUE 消息或 exchange 无效 |
| password_exchange_expired        | OPAQUE exchange 已过期 |
| password_exchange_replayed       | OPAQUE exchange 已被使用 |
| username_already_exists          | 用户名已存在               |
| email_already_exists             | 邮箱已存在                |
| permission_denied                | 缺少操作权限               |
| resource_access_denied           | 无权访问资源               |
| resource_permission_missing      | API 未配置权限            |
| role_builtin_protected           | 内置角色禁止修改             |
| last_super_admin_protected       | 禁止删除最后一个超级管理员        |
| self_delete_forbidden            | 用户不能删除自己             |
| user_delete_blocked_by_resources | 用户仍拥有业务资源            |
| registration_decision_conflict   | 注册申请已存在相反审批结果        |
| user_delete_dependency_unavailable | 删除依赖来源不可用或结果不完整      |
| user_delete_check_stale          | 删除依赖检查已过期或不再匹配        |
| service_account_disabled         | 服务账号已禁用              |
| service_account_owner_unavailable | 服务账号 owner 不可用        |
| credential_expired               | 凭据已过期                |
| credential_revoked               | 凭据已撤销                |

---

## 21. 平台审计协作

以下 Identity 行为必须向 `platform-management` 提交脱敏审计记录：

```text
用户注册
登录成功
登录失败
账号锁定
Token 刷新
Refresh Token 重用
登出
全部设备登出
修改密码
用户创建
初始密码重新生成
用户禁用和恢复
用户删除
角色分配
角色权限修改
用户组成员变化
资源共享
资源共享撤销
Identity 管理的跨 owner 授权操作
注册审批和拒绝
服务账号创建和禁用
服务账号凭据轮换
服务账号凭据撤销
权限拒绝
```

Identity 提交的审计上下文至少包含：

```text
sourceDomain
sourceModule
principalType
principalId
actorUserId
action
targetType
targetId
ownerUserId
result
reason
requestId
traceId
ipAddress
userAgent
detail
occurredAt
idempotencyKey
```

平台管理负责 AuditLog 的持久化、查询、脱敏和可靠事件。Identity 不拥有审计表或审计查询 API；Identity 通过受控同步接口提交上述敏感操作，不能用 Identity 领域事件替代审计确认。平台审计写入失败时，登录、密码、Token、授权、服务账号和跨 owner 等敏感操作必须回滚、撤销或补偿，不得留下可用效果并显示为成功。

审计上下文不得包含：

```text
密码
完整 Access Token
完整 Refresh Token
完整 client_secret
```

---

## 22. 验收标准

## 22.1 注册与登录

* 用户可使用用户名、邮箱和密码注册；
* 用户名和邮箱全局唯一；
* `OPEN` 注册用户自动获得 USER 角色和正常会话；`ADMIN_APPROVAL` 注册只创建 PENDING User 和申请，不创建角色、会话或 Token；
* 管理员可以批准或带原因拒绝注册申请；批准后用户获得 USER 角色并自行登录，拒绝后可以保留历史并重新申请；
* 已决申请的相同决策幂等，相反决策被稳定拒绝；
* 登录失败达到阈值后触发临时锁定；
* 只有正式会话创建成功后才更新最后登录时间；登录成功同时更新当前会话最后活动时间。
* 用户只通过 OPAQUE 完成注册、登录和改密；数据库只保存 registration record，密码明文、前端哈希、可逆密文和原始密码字段不得持久化或出现在服务端边界。

## 22.2 Token

* Access Token 不包含完整权限；
* Refresh Token 每次使用后轮换；
* 旧 Refresh Token 重复使用时撤销整个会话；
* 用户被禁用后旧 Token 不可继续访问；
* 修改密码后所有旧会话失效；当前版本不存在可继续使用的 PAT。
* 用户在线状态由有效会话和最近活动时间派生，不把 `online` 写入 `User.status`；默认在线窗口为 300 秒。
* presence heartbeat 只更新当前会话的 `lastActiveAt`，不延长 Token 或会话过期时间。
* 会话列表能够识别当前会话，并区分撤销其他会话、当前设备登出和全部设备登出的结果。

## 22.3 权限

* 后端 API 使用权限码鉴权；
* 业务代码不通过角色名称判断权限；
* 权限变更后无需等待 Token 过期即可生效；
* 登录、Refresh 和独立授权投影接口返回 `authorizationVersion`、有效角色来源、权限码和会话限制；
* 直接角色和用户组角色来源可区分；客户端看到更高授权版本后整体刷新投影；
* 首次登录受限会话即使拥有其他权限码也只能执行明确允许动作；
* 内置角色不可删除；
* 系统始终保留至少一个有效 SUPER_ADMIN。

## 22.4 资源隔离

* 资源域明确支持用户所有权时，资源 owner 只能来自认证上下文；
* 具有资源操作权限但不满足资源域可见性或授权关系时，请求被拒绝；
* 只有资源域声明接入共享时，资源所有者才可以创建共享授权；
* 撤销共享后，用户立即失去新的访问能力；
* 管理员访问全部资源必须具备显式 `manage_all` 权限。
* 普通共享目录不返回邮箱、手机号、角色或在线状态，并只展示目标 domain 支持的访问等级。
* 用户删除依赖检查返回可处理的跨域摘要；任何来源不可用、检查过期或仍有阻塞项时删除失败且不级联删除业务事实。

## 22.5 服务账号

* Worker、Agent 和应用运行环境不使用用户密码；
* 不同运行主体使用独立服务账号；
* 服务凭据只显示一次；
* 服务账号通过有效直接角色获得权限，并展示 owner 摘要、凭据状态、到期时间、最后使用时间和轮换历史；
* 关闭一次性 Secret 后不能再次读取，遗失时只能轮换；
* 服务账号禁用后已有 Token 失效；
* owner 不可用、凭据撤销或过期时凭据交换 fail closed；
* 服务账号权限遵守最小权限原则。

## 22.6 页面与跨域边界

* 用户列表、详情和管理动作能够表达 PENDING、REJECTED、DISABLED、LOCKED、首次登录和授权摘要；
* 一次性初始密码和 Service Account Secret 关闭后均不能再次查看；
* 认证策略和安全审计页面、API 和事实源由 `platform-management` 拥有，Identity 不维护重复页面或查询事实；
* platform-management 审计写入失败时，敏感操作返回稳定错误且不会被显示为成功。

---

## 23. 当前版本最终模型

```mermaid
flowchart TB
    USER["User"]

    USER --> ROLE["直接角色"]
    USER --> GROUP["用户组"]
    GROUP --> GROUP_ROLE["用户组角色"]

    ROLE --> PERMISSION["权限码"]
    GROUP_ROLE --> PERMISSION

    USER --> OWNED["用户拥有的资源"]
    USER --> SHARED["被共享的资源"]

    USER --> SESSION["登录会话"]
    USER --> REGISTRATION["RegistrationApplication"]
    USER --> DELETE_CHECK["UserDeletionCheck"]
    SERVICE["ServiceAccount"] --> SERVICE_ROLE["直接角色授权"]
    SERVICE --> CREDENTIAL["服务凭据历史"]
    SERVICE_ROLE --> PERMISSION
```

核心规则：

```text
所有用户属于同一个 OmniMAM 平台。

用户通过角色获得操作权限。

资源域定义 owner、created_by、visibility 和资源状态；需要共享时通过 ResourceAccessGrant 接入 Identity。

平台管理员访问全部资源也必须拥有显式 manage_all 权限。

业务 domain 通过 PrincipalContext 消费用户、服务主体或受控 Agent 工作负载主体；系统当前不包含企业、租户、LDAP、OIDC、MFA 和 PAT。
```

---

## 23.1 Agent Workload JWT

`AGENT_WORKLOAD` 是仅供受控 Agent Runtime 使用的短期主体类型，不是用户登录、ServiceAccount 或 Refresh Token。用于 OmniMAM MCP 的 Token 必须固定 `aud=mcp`，并包含不可伪造的 `agent_id`、可选 `agent_generation`、可选 `studio_application_id`、`runtime_binding_id`、`runtime_grant_id`、owner/tenant scope 和过期时间；有效期不得超过 Runtime 或 Grant 生命周期。

Identity 验证签名、audience 和标准时效后构造最小 PrincipalContext；MCP 每次请求还必须向 Agent Grant resolver 重新校验 Grant ACTIVE、Runtime/Agent/generation/Application/object scope 和允许工具。工作负载权限由受控 Profile/Grant 固定，不继承创建者角色、管理员权限或可变用户权限全集，不提供 Refresh Token。

---

## 24. S2 追溯锚点

以下编号是本 S1 对 Identity S2 的稳定追溯入口。编号只表达当前产品语义，不代表 API、Schema 或实现细节已经发布。

### 24.1 业务规则

| 编号 | 业务规则 | 相关章节 |
| --- | --- | --- |
| `BR-IAM-001` | 平台使用统一 User 主体；用户名全局唯一且不可修改，邮箱可作为登录标识且必须唯一。 | 2.1、5.1、6、22.1 |
| `BR-IAM-002` | 用户可自主注册或由管理员创建；OPEN 注册获得 USER 角色和会话，审批注册只有批准后获得 USER 角色，管理员创建用户必须触发首次登录引导。 | 3.1、6、17、22.1 |
| `BR-IAM-003` | 登录必须检查账号状态和密码；失败达到策略阈值后临时锁定，未认证请求不得暴露用户是否存在。 | 5.1、7、20、22.1 |
| `BR-IAM-004` | 首次登录受限会话只能完成密码/个人信息引导和退出，完成密码修改后必须重新登录。 | 8、22.1 |
| `BR-IAM-005` | Access Token 表达主体和凭据状态，不携带完整权限、角色、菜单或资源共享关系；权限变更不得依赖 Token 自然过期。 | 2.5、9、10、22.2 |
| `BR-IAM-006` | Refresh Token 必须轮换；重用旧 Refresh Token 时撤销整个 AuthSession 和该会话凭据并记录审计。 | 5.11、9.3、21、22.2 |
| `BR-IAM-007` | 当前登出、全局登出、密码修改、用户禁用必须撤销相应会话和凭据；旧凭据不得继续访问。 | 9.4、9.5、14.1、22.2 |
| `BR-IAM-008` | 有效角色只来自用户直接角色和静态用户组角色，并过滤禁用、未生效或过期授权；当前不支持角色继承和互斥。 | 3.2、5.2、5.6-5.8、10 |
| `BR-IAM-009` | 权限定义由各模块登记；各 domain 的 `default_roles` 必须由 Identity 聚合并物化为内置角色的 RolePermissionGrant，管理员只能分配已登记权限；后端必须按权限码判定，不得硬编码角色名称。 | 2.4、10、13、22.3 |
| `BR-IAM-010` | PrincipalContext 区分 USER、SERVICE_ACCOUNT 与 AGENT_WORKLOAD，并可携带受控 `actor_user_id`；客户端不得伪造委托用户或工作负载范围。 | 5.13、13.1、15、23 |
| `BR-IAM-011` | 资源 domain 拥有 owner、created_by、visibility、project、namespace 和资源状态；owner 不得由客户端直接指定。 | 2.2、12.1、13.1、22.4 |
| `BR-IAM-012` | ResourceAccessGrant 只对声明接入共享的资源 domain 生效；Identity 不凭该记录证明资源存在、可见或状态有效。 | 5.9、12.2-12.3、19.4、22.4 |
| `BR-IAM-013` | 跨 owner 管理必须拥有目标 domain 登记的显式 manage_all 权限，并记录 principal、actor、owner、目标和结果。 | 12.3-12.4、13.1、21、22.4 |
| `BR-IAM-014` | ServiceAccount 只能通过独立短期凭据访问受控服务边界，不使用普通用户登录或 Refresh Token，并遵守最小权限、轮换和撤销。 | 5.13、15、22.5 |
| `BR-IAM-015` | 登录、凭据、授权变化、权限拒绝、服务主体和跨 owner 操作必须向 platform-management 写入脱敏 AuditLog；审计不得包含密码、完整 Token 或 Secret。 | 13.1、15、21、22.5 |
| `BR-IAM-016` | SystemAuthConfig 由 platform-management 持有，统一约束注册模式、密码、登录失败保护、在线窗口和 Token 生命周期；Identity 只能消费当前生效配置。 | 5.1.2、9.6、17、18.8 |
| `BR-IAM-017` | 删除用户前必须以完整且未过期的跨域依赖检查处理资源、未完成任务、服务账号和共享关系；任何来源不可用时 fail closed，不得级联删除业务事实或最后一个有效 SUPER_ADMIN。 | 14.2、18.3、22.4 |
| `BR-IAM-018` | 当前版本不提供企业/租户、LDAP/SSO、OAuth2/OIDC、MFA、可信设备、动态组、复杂 ABAC 和 PAT。 | 文档头部、3.2、5.12、16、23 |
| `BR-IAM-019` | 其他 domain 只通过 PrincipalContext、受控授权结果、稳定 ID、一跳摘要、不可变快照或可靠事件协作，不读取 Identity 私有表。 | 2.2、12、13.1、23 |
| `BR-IAM-020` | Identity API 使用 `/api/v1/iam` 和 HTTP 200 业务结果；业务错误通过稳定 code/value 表达，业务资源不可见不得用 404 泄露存在性。 | 19、20、24.2 |
| `BR-IAM-021` | 用户密码使用固定 OPAQUE 配置完成注册、登录和改密；服务端只保存 registration record，绝不接收或保存明文、前端哈希或可逆密文。 | 5.1、7、9.5、17、22.1、22.2 |
| `BR-IAM-022` | 用户在线状态由 ACTIVE 用户的有效 AuthSession 和最近 `lastActiveAt` 派生；默认窗口为 300 秒，多设备任一会话在线即在线，撤销或过期会话不参与判断。 | 5.1、5.10、9.6、22.2、22.4 |
| `BR-IAM-023` | ADMIN_APPROVAL 注册必须创建不可变 RegistrationApplication 历史；待审批不创建角色、会话或 Token，批准分配默认角色，拒绝须有原因并允许同一身份重新申请。 | 5.14、6.1、18.1、18.3、22.1 |
| `BR-IAM-024` | 登录、Refresh 和独立查询返回同一版本化授权投影，包含有效角色来源、去重权限码和会话限制；角色仅用于展示解释，后端继续实时按权限码鉴权。 | 2.5、7、9.3、10.3、22.3 |
| `BR-IAM-025` | 授权变化必须递增每个受影响主体的 authorizationVersion 并发布失效通知；客户端看到更高版本后整体重新读取投影，不能从事件或旧缓存拼装授权。 | 10.3、11、18.4、22.3 |
| `BR-IAM-026` | ServiceAccount 只通过有效直接角色获得权限；owner 创建时受控校验，owner 不可用时凭据交换 fail closed，禁止静默改绑。 | 5.13、15.2-15.4、18.5、22.5 |
| `BR-IAM-027` | ServiceAccount Secret 与管理员初始密码只返回一次；凭据投影只暴露前缀、状态、到期、最后使用和轮换历史，遗失后只能轮换。 | 6.2、15.3、17、18.3、18.5、22.5-22.6 |
| `BR-IAM-028` | 用户删除由 Identity 聚合各事实 domain 的受控摘要；资源转移、任务处理和 owner 校验由目标 domain 完成，删除必须使用最新完整检查并在提交前重验。 | 14.2、18.3、19.2、22.4 |
| `BR-IAM-029` | 用户/组共享目录只返回最小摘要，资源共享只展示目标 domain 支持的等级；禁用、删除或过期主体不得继续产生有效访问。 | 12.3、18.6-18.7、22.4 |
| `BR-IAM-030` | 认证策略和 AuditLog 页面、API 与事实属于 platform-management；Identity 只提供跨域入口、配置应用结果和脱敏审计提交失败边界。 | 4、5.1.2、18.8、21、22.6 |
| `BR-IAM-031` | `AGENT_WORKLOAD` JWT 必须固定 audience、Agent/generation、Application、Runtime、Grant 和过期时间；不继承创建者角色、不提供 Refresh Token，资源服务每请求重新校验 Grant。 | 23.1 |

### 24.2 用户故事

| 编号 | 用户故事 | 相关章节 |
| --- | --- | --- |
| `US-IAM-001` | 作为用户，我可以使用用户名或邮箱注册、登录并获得可撤销的会话凭据。 | 6、7、9、22.1 |
| `US-IAM-002` | 作为管理员，我可以创建、查询、更新、禁用、恢复、解锁和删除用户，但不能读取用户密码或完整 Token。 | 6.2、14、17、22.1 |
| `US-IAM-003` | 作为首次登录用户，我可以完成密码和个人信息引导，完成后重新登录进入正常系统。 | 8、22.1 |
| `US-IAM-004` | 作为用户，我可以查看和撤销当前登录会话，并使用 Refresh Token 安全刷新登录凭据。 | 9.3-9.4、18.1、19.1、22.2 |
| `US-IAM-005` | 作为管理员，我可以管理角色、权限分配、静态用户组及用户组成员关系。 | 5.2-5.8、10、18.4、19.3 |
| `US-IAM-006` | 作为业务 domain，我可以请求当前主体的权限判定，并获得经过资源 domain 规则裁剪的访问结果。 | 2.3、10、12、13.1 |
| `US-IAM-007` | 作为接入共享的资源 owner，我可以向用户或用户组授予、修改、过期和撤销资源访问等级。 | 5.9、12.3、19.4、22.4 |
| `US-IAM-008` | 作为受控 Worker、Agent Runtime 或 AppStudio 组件，我可以使用独立 ServiceAccount 获取短期凭据访问被授权的服务边界。 | 5.13、15、22.5 |
| `US-IAM-009` | 作为安全管理员，我可以通过 platform-management 查询登录、凭据、授权变化、权限拒绝和服务主体行为的脱敏审计记录。 | 13、18.8、21 |
| `US-IAM-010` | 作为系统管理员，我可以通过 platform-management 维护注册、密码、登录保护、在线窗口和 Token 生命周期配置。 | 5.1.2、9.6、17、18.8 |
| `US-IAM-011` | 作为用户发起的 Agent、AppStudio、Task 或 MCP 操作，我希望保留原始用户授权语义，并能在服务主体审计中识别委托用户。 | 13.1、15、23 |
| `US-IAM-012` | 作为调用方，我希望不可见资源、无权资源和无效主体返回不泄露存在性的稳定业务错误。 | 7、12.2、13、20、22.4 |
| `US-IAM-013` | 作为用户或受权管理员，我可以查看当前用户管理范围内的在线状态，而普通资源共享目录不会泄露在线信息。 | 9.6、18.1、19.1、22.2 |
| `US-IAM-014` | 作为已认证客户端，我可以通过当前会话的 presence heartbeat 更新最近活动时间，维持准确的在线状态。 | 9.6、19.1、22.2 |
| `US-IAM-015` | 作为审批注册用户，我可以看到待审批或拒绝结果并在拒绝后重新申请；作为管理员，我可以批准或带原因拒绝且不能覆盖历史决策。 | 5.14、6.1、18.1、18.3、22.1 |
| `US-IAM-016` | 作为已认证客户端，我可以获得包含有效角色来源、权限码、会话限制和 authorizationVersion 的当前主体投影，并在版本变化后刷新。 | 7、9.3、10.3、18.1、22.3 |
| `US-IAM-017` | 作为管理员，我可以查看用户删除依赖摘要，进入各事实 domain 完成转移或清理，并在完整重检后安全删除用户。 | 14.2、18.3、19.2、22.4 |
| `US-IAM-018` | 作为管理员，我可以完整管理 ServiceAccount 的归属、直接角色、状态和凭据生命周期，并只在创建或轮换时查看一次 Secret。 | 5.13、15、18.5、19.5、22.5 |
| `US-IAM-019` | 作为资源 owner，我可以在不泄露用户邮箱、手机号、角色或在线状态的目录中选择用户/组，并理解直接、组来源和最终有效访问。 | 12.3、18.6-18.7、19.4、22.4 |
| `US-IAM-020` | 作为用户或管理员，我可以理解账号、会话、授权和敏感操作失败后的可恢复结果，而认证策略和审计查询仍由 platform-management 提供。 | 7、9、18、21、22.6 |
