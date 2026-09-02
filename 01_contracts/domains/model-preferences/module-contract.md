# Model Preferences 模块契约

## 1. 职责

Model Preferences 只拥有：

- `ModelPreference`：用户对 Gateway MODEL 资源的显示名覆盖、分组与标签；
- `DefaultModelPreference`：用户按 usage 保存的默认 `provider_resource_id`；
- 两类偏好变化事件与可靠 outbox。

相关 S1：`US-MODELPREF-001..003`、`BR-MODELPREF-001..010`。

## 2. 不负责

不拥有 ProviderAccount、ProviderResource、凭证、健康、能力、发现、同步、探测、Adapter、OperationExecutor、执行资格或 Grant。不实现 Provider HTTP，不保存 `executable`，不签发 `UserModelExecutionContext` 或 `AgentModelAccessGrant`。

## 3. 数据所有权

```text
model_preferences
default_model_preferences
model_preferences_outbox
```

`provider_resource_id` 是跨域稳定 ID，不建立到 Gateway 私表的数据库外键。Gateway 不读取本领域私表；跨域调用使用受控接口。

## 4. Gateway 投影接口

模型列表、详情和 options 使用 Gateway 批量一跳投影。请求包含当前 principal、资源 ID 或筛选条件、usage/capability；Gateway 返回权限裁剪的 MODEL 摘要。

投影可含账号作用域、ProviderType、当前健康、能力、修订、瞬时 executable 与安全不可用原因，但不得含 endpoint、credential_ref、Header、extra_config、Provider 私有 metadata 或 Grant。

列表实现必须批量查询或 JOIN 受控投影，禁止逐条跨服务 N+1。Gateway 不可用时返回 `ERR_MODEL_PREFERENCE_GATEWAY_PROJECTION_UNAVAILABLE`，不得用缓存健康事实冒充当前结果。

## 5. 默认解析接口

受信任内部消费者按 `(owner_user_id, usage)` 读取 Default，输出只有：

```text
provider_resource_id
usage
default_preference_resource_version
```

该结果不是执行授权。调用方必须交给 Model Gateway `ResolveProviderTarget` 重新校验并签发 `ProviderExecutionGrant`。

## 6. HTTP API

canonical 前缀为 `/api/v1/model-preferences/`：

```text
GET /models
GET /models/{provider_resource_id}
PUT /models/{provider_resource_id}
GET /defaults/{usage}
PUT /defaults/{usage}
DELETE /defaults/{usage}
GET /options
```

旧 `/api/v1/user-model/` 不保留兼容路由。所有业务失败使用 HTTP 200 + 稳定 `code`/`value`。

## 7. 权限与可见性

- owner_user_id 始终由当前主体确定，不接受客户端传入。
- 写入前调用 Gateway 验证资源当前可见且 `kind=MODEL`。
- 跨用户 USER 资源不能读取或引用；可见 PLATFORM MODEL 可以引用。
- 持有 provider_resource_id 不代表可见或可执行。

## 8. AI Chat、Application Platform 与 Agent

调用方只使用用途默认 ID。Model Preferences 不参与 GenerationRun、ApplicationRun、Invocation 或 Attempt 状态，不接收 Grant 解析结果，不负责执行失败回退。

默认资源不可用时，Gateway 直接失败；调用方不得让 Model Preferences 自动寻找替代账号或跨 USER/PLATFORM 回退。

## 9. 事件边界

仅发布：

```text
model_preference_changed
default_model_preference_changed
```

事件不携带 Gateway 健康、能力、executable、endpoint、凭证、metadata 或 Grant。旧 Provider/模型健康事件全部移除。

## 10. 破坏性迁移

`user-model` 整域重命名为 `model-preferences`。不保留 Provider CRUD、测试、同步、探测、健康表、ExecutionContext、AgentModelAccessGrant、旧权限、错误码、事件或表；开发数据清空后按新设计态 Schema 重建。
