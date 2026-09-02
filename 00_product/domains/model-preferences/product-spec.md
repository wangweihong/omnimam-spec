# Model Preferences 产品规格

> 文档状态：方案 B 重构草稿
>
> 本领域由 `user-model` 破坏性重命名并收窄职责，不兼容旧 Provider、模型健康与执行授权合同；文中旧名称仅用于迁移追溯。

## 1. 产品目标

Model Preferences 只管理当前用户对 Model Gateway `ProviderResource(kind=MODEL)` 的展示偏好和用途默认值。Provider 账号、远端资源、能力、健康、凭证引用、发现、同步、探测、Adapter 与执行全部归 Model Gateway。

本领域不再拥有或提供：

- Provider CRUD、连接测试、资源发现、同步和探测；
- Provider/模型健康状态持久化；
- `UserModelExecutionContext`、`AgentModelAccessGrant` 或任何执行 Grant；
- Provider/模型健康事件；
- endpoint、认证配置、凭证引用或 Provider 私有 metadata。

## 2. 核心对象

### 2.1 ModelPreference

```text
owner_user_id
provider_resource_id
display_name_override
model_group
feature_labels
```

`provider_resource_id` 必须引用当前用户可见的 Gateway `ProviderResource(kind=MODEL)`。Preference 只保存用户维护的展示属性，不复制以下 Gateway 当前事实：

```text
provider_account_id
provider_type
remote_resource_id
enabled / executable
health_status / health_reason
capability_definition_ids
resource_revision
non_sensitive_metadata
```

列表和详情可返回上述事实的当前一跳只读投影，但每次由 Gateway 提供，不在本领域缓存。

### 2.2 DefaultModelPreference

```text
owner_user_id
usage
provider_resource_id
```

支持用途：

```text
assistant.default
quick
translation
agent.chat
agent.coding
application.default
```

每个用户、每个 usage 最多一个默认资源。默认记录仅表达用户选择，不承诺该资源此刻可执行。

## 3. 可见性与写入规则

- 用户只能读取和修改自己的 Preference 与 Default。
- ModelPreference 引用的资源必须是当前用户可见的 `MODEL`；跨用户 USER 账号资源不可见。
- 用户可以为 PLATFORM MODEL 资源创建展示偏好或默认值，只要 Gateway 判定其可见。
- `display_name_override` 为空时显示 Gateway 当前资源名；非空值不改写 Gateway 资源。
- `model_group` 与 `feature_labels` 只用于展示和筛选，不能扩张能力或执行资格。
- 删除 Preference 不自动删除 Default；如果仍被 Default 引用，必须先删除或替换 Default。
- Gateway 资源缺失、停用、删除或不可见时，Preference/Default 可以保留稳定引用用于诊断，但普通可选项不得将其呈现为可执行目标。

## 4. 默认解析

按 usage 解析默认模型时，Model Preferences 只返回 `provider_resource_id`。Model Gateway 负责验证：

- 主体与账号 owner/作用域；
- 资源 `kind=MODEL`；
- 账号和资源 enabled、发现状态与健康状态；
- CapabilityDefinition、ProviderCapability、Binding 和修订；
- 目标策略与用途；
- ProviderExecutionGrant 签发资格。

若默认资源当前不可用，Model Preferences 不自动替换为其他资源，也不在 USER 与 PLATFORM 之间回退。调用方获得明确的默认缺失或当前不可用结果，由用户修改 Default 或显式选择其他目标。

## 5. 当前一跳投影

模型列表、详情和 options 通过 Gateway 受控接口批量读取当前资源摘要，避免逐项 N+1。投影最多一跳，不能继续展开 ProviderAccount 私有详情。

建议投影字段：

```text
provider_resource_id
provider_account_id
account_scope
provider_type
resource_kind
remote_resource_id
display_name
enabled
discovery_status
health_status
capability_definition_ids
resource_revision
executable
unavailable_reason
```

其中 `executable` 与 `unavailable_reason` 是 Gateway 对当前主体和查询用途的瞬时派生结果，不在 Model Preferences 表中持久化。响应不得包含 endpoint、credential_ref、Header、extra_config 或完整 Provider metadata。

## 6. 产品操作

### 6.1 浏览模型

用户可以分页浏览当前可见 MODEL 资源与自己的 Preference 合并投影，并按关键词、ProviderType、账号作用域、分组、标签、能力和当前可执行性筛选。

### 6.2 保存展示偏好

用户按 `provider_resource_id` 整体保存显示名覆盖、分组和标签。首次 PUT 创建，后续 PUT 替换当前 Preference；空的展示字段允许恢复为 Gateway 当前展示。

### 6.3 管理用途默认值

用户可以读取、保存或删除每个 usage 的默认 MODEL。保存时验证资源当前可见且 kind 正确；真正执行前仍由 Gateway 重新校验，不把保存时健康状态冻结为授权。

### 6.4 获取选择器 options

options 返回当前用途、能力和作用域条件下的轻量候选，以及现有 Default。该接口只服务 UI 选择，不签发 Grant，也不允许客户端将 `executable=true` 当作长期授权。

## 7. 跨域协作

### 7.1 Model Gateway

Gateway 是账号、资源、健康、能力与执行资格的唯一事实源。Model Preferences 通过稳定 `provider_resource_id` 和受控批量摘要接口消费当前事实，不读取 Gateway 私表。

Gateway 发布账号/资源变化事件时，本领域不复制健康或 executable。可选的投影失效处理只清理本地查询缓存，不能改变 Preference/Default 事实。

### 7.2 AI Chat、Application Platform 与 Agent

调用方按用途向 Model Preferences 查询默认 `provider_resource_id`，随后携带该稳定 ID 直接请求 Gateway 解析目标和签发 Grant。Model Preferences 不参与 Attempt 生命周期，也不接收 Grant 解析结果。

## 8. 业务规则

1. `BR-MODELPREF-001`：Model Preferences 只拥有模型展示偏好与用途默认值，不拥有 Provider 账号、资源、健康、能力、凭证或执行事实。
2. `BR-MODELPREF-002`：ModelPreference 与 DefaultModelPreference 必须引用 Gateway `ProviderResource(kind=MODEL)`。
3. `BR-MODELPREF-003`：用户只能管理自己的 Preference 和 Default；跨用户 USER 资源不可见、不可引用。
4. `BR-MODELPREF-004`：display_name_override、model_group 和 feature_labels 只影响展示与筛选，不能改变资源能力或执行资格。
5. `BR-MODELPREF-005`：模型响应中的健康、能力、修订与 executable 必须由 Gateway 当前一跳投影提供，不得持久化到本领域。
6. `BR-MODELPREF-006`：默认解析只返回 provider_resource_id；最终资格校验和 Grant 签发必须由 Gateway 完成。
7. `BR-MODELPREF-007`：默认资源不可用时不得自动选择另一账号或跨 USER/PLATFORM 回退。
8. `BR-MODELPREF-008`：默认用途只允许 assistant.default、quick、translation、agent.chat、agent.coding、application.default。
9. `BR-MODELPREF-009`：删除仍被 Default 引用的 Preference 必须拒绝，直到 Default 被替换或删除。
10. `BR-MODELPREF-010`：旧 user-model Provider、健康、ExecutionContext、AgentModelAccessGrant、API、表、权限、错误码和事件不保留兼容合同。

## 9. 用户故事与验收标准

### US-MODELPREF-001 管理模型展示偏好

作为用户，我希望为可见模型设置显示名、分组和标签，使模型选择器符合个人使用习惯。

- `AC-MODELPREF-001-01`：只能为当前可见的 Gateway MODEL 资源保存 Preference。
- `AC-MODELPREF-001-02`：展示覆盖不改写 Gateway 资源，也不扩张能力。
- `AC-MODELPREF-001-03`：模型列表合并 Gateway 当前摘要且不出现 endpoint、凭证或私有配置。

### US-MODELPREF-002 管理用途默认模型

作为用户，我希望为不同使用场景保存唯一默认模型。

- `AC-MODELPREF-002-01`：每个 usage 最多保存一个 provider_resource_id。
- `AC-MODELPREF-002-02`：未知 usage、非 MODEL 或不可见资源被拒绝。
- `AC-MODELPREF-002-03`：删除 Default 后解析返回明确未配置结果，不自动寻找替代模型。

### US-MODELPREF-003 为执行方解析默认引用

作为 AI Chat、Application 或 Agent，我希望只获得用户默认资源 ID，并由 Gateway 完成最终授权。

- `AC-MODELPREF-003-01`：解析结果不包含 endpoint、凭证、Header 或 Grant。
- `AC-MODELPREF-003-02`：保存后资源健康变化不会改写 Default，但 Gateway 可以拒绝本次执行。
- `AC-MODELPREF-003-03`：不可用时不跨账号作用域回退。

## 10. 非目标

- 不创建、更新、测试或删除 ProviderAccount/ProviderResource。
- 不执行发现、同步、探测或健康检查。
- 不持久化 executable、health、capability 或 Provider metadata。
- 不签发 UserModelExecutionContext、AgentModelAccessGrant 或 ProviderExecutionGrant。
- 不实现 Provider HTTP、认证、轮询、取消或结果解析。
- 不兼容 `/api/v1/user-model/` 或旧设计态表。
