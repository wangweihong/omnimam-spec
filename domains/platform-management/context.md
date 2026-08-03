# Platform Management Context

## 1. 领域职责

`platform-management` 管理平台级只读信息、`SystemAuthConfig` 和跨 domain 的脱敏 `AuditLog`。它提供管理入口，但不拥有用户、角色、会话、业务资源、Engine、用户模型、StorageBackend、任务状态或其他 domain 的统计事实。

## 2. 核心对象

- `SystemAuthConfig`：注册模式、密码策略、登录失败保护、在线窗口和 Token 生命周期等平台认证策略。
- `AuditLog`：由平台管理追加、脱敏、查询和发布可靠事件的跨 domain 管理审计记录。
- `PlatformOverview`：当前阶段仅包含平台基础信息和最近审计摘要；跨 domain 业务统计延期。

## 3. 核心规则

- `SystemAuthConfig` 的事实、版本和管理 API 归平台管理；Identity 只读取当前生效版本并执行认证策略。
- `allow_registration` 是 `registration_mode` 的只读兼容派生值；客户端不得绕过注册模式写入冲突语义。
- `SystemAuthConfig` 使用结构化策略和 `resource_version` 乐观并发；配置、审计和 Outbox 在平台管理边界内原子提交。
- `AuditLog` 只允许平台管理追加，其他 domain 通过受控内部接口提交脱敏上下文；任何 domain 不得写平台审计表。
- AuditLog 区分来源 `occurred_at` 与平台 `created_at`，幂等作用域为来源 domain/module/key；Identity 可靠事件不替代同步审计确认。
- 登录、密码、Token、授权、服务账号、跨 owner 和认证配置等敏感操作无法写入审计时必须 fail closed。
- 审计记录不得包含密码、完整 Token、Secret、凭据哈希、原始请求 payload 或大型业务正文。
- 跨 domain 业务统计不属于当前阶段；后续只能使用事实源提供的权限裁剪、一跳、批量摘要，并标明来源可用性和时间。
- `ADMIN` 默认拥有平台概览、认证配置读取和审计读取权限；`SUPER_ADMIN` 额外拥有认证配置管理权限。Platform 只声明 `default_roles`，由 Identity 物化和对账实际 `RolePermissionGrant`。

## 4. 跨域边界

- Identity 拥有 User、AuthSession、Token、RBAC、ResourceAccessGrant 和 ServiceAccount；Platform 只消费 Identity 的主体/授权结果和认证配置读取请求。
- Identity 通过受控内部接口读取 `SystemAuthConfig`，并向 Platform 提交审计记录；Platform 不读取 Identity 私有表。
- modelgateway、model-management、asset-library、task-center、notification-center、application-platform、agent 和 appstudio 继续拥有各自业务事实与凭据。
- Platform Overview 当前不复制任何 domain 的统计表；素材、应用、模型、任务和通知统计延期到下一阶段。

## 5. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/platform-management/product-spec.md` | S1 | 平台只读信息、SystemAuthConfig、审计和概览延期边界 |
| `01_contracts/domains/platform-management/openapi.yaml` | S2 | PlatformOverview、SystemAuthConfig 查询/替换、AuditLog 查询和内部追加接口 |
| `01_contracts/domains/platform-management/schema.sql` | S2 | 平台认证配置、审计和 Outbox 设计态结构 |
| `01_contracts/domains/platform-management/errors.yaml` | S2 | 概览、认证配置和审计错误码 |
| `01_contracts/domains/platform-management/permissions.yaml` | S2 | 概览、认证配置和审计权限码 |
| `01_contracts/domains/platform-management/events.yaml` | S2 | 配置变更与审计记录可靠事件 |
| `01_contracts/domains/platform-management/module-contract.md` | S2 | Identity 配置消费和审计写入边界 |
| `02_architecture/domains/platform-management.md` | 参考 | 模块关系、认证配置链路和同步审计边界 |

## 6. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改认证策略或注册开关 | Platform S1/S2 | 认证执行再读 Identity Context/S2 |
| 修改审计字段或审计查询 | Platform S1/S2 | 产生审计的 domain 再读其事件/模块合同 |
| 修改平台概览 | Platform S1 | 涉及来源统计再读对应 domain Context/S2 |

## 7. 当前状态

本领域 S1/S2 为未 Release 草稿。完成用户确认和 `RELEASE.md` 记录前，不得作为正式实现、合并或验收依据。

## 8. 不在本领域定义的内容

- 用户、角色、权限计算、认证会话和服务账号生命周期。
- Model Gateway Engine 鉴权、用户模型 Provider、StorageBackend、Task 状态或通知收件箱。
- 正式实现代码、实际 migration、运行时 Secret 和基础设施运维操作。
