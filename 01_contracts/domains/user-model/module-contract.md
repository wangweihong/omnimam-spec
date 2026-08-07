# User Model 模块契约

本文档定义 `user-model` S2 模块边界。产品语义以 `00_product/domains/user-model/product-spec.md` 为准。

## 1. 模块职责

| 模块 | 职责 | 非职责 |
| --- | --- | --- |
| `provider-type` | 读取 Model Gateway 提供的稳定 ProviderType 目录并返回无内部 ID 的只读投影 | 不注册 Adapter、Executor 或 ProviderType |
| `provider` | 管理当前用户 Provider、凭证引用、配置版本和启用状态 | 不实现 Provider 协议、鉴权应用或专用 HTTP 客户端 |
| `model` | 管理当前用户模型清单、用户维护字段、启用状态和能力关闭范围 | 不允许用户声明实际可执行能力 |
| `default-model` | 管理当前用户 `assistant.default`、`quick`、`translation`、`agent.chat`、`agent.coding` 默认模型 | 不跨用户或静默 fallback 到平台模型 |
| `health` | 持久化 Provider/模型检测结果和用户模型健康事实 | 不实现网络探测，不发布 Gateway 重复健康事件 |
| `option` | 提供当前用户权限裁剪的只读模型选项 | 不复制到下游领域私有表 |
| `execution-context` | 校验 owner、enabled、health、能力和配置版本并签发短期执行上下文或 AgentModelAccessGrant | 不执行 Operation，不持久化 ResolvedModelRoute/grant |

## 2. 输入与输出

| 模块 | 输入 | 输出 |
| --- | --- | --- |
| provider-type | 当前 Gateway Registry 投影 | `ProviderType[]` |
| provider | principal、Provider 表单、凭证引用 | `ModelProvider` |
| model | principal、providerId、远端发现结果或手动模型表单 | `ProviderModel`、`ModelSyncResult` |
| default-model | principal、usage、providerId、modelId | `DefaultModelConfig` |
| option | principal、usage、capability_definition_id | 当前用户模型选项 |
| execution-context | principal、modelId、capabilityDefinitionId | `UserModelExecutionContext` |
| execution-context | 受信 Agent principal、agentId、`agent.chat|agent.coding`、primary binding | `AgentModelAccessGrant` |

## 3. 对 Model Gateway 的内部依赖

User Model 只通过受控模块接口调用 Gateway：

```text
ListProviderTypes() -> ProviderType[]
TestProviderConnection(providerType, endpoint, authType, credentialHandle, config) -> ProviderProbeResult
DiscoverProviderModels(providerType, endpoint, authType, credentialHandle, config) -> DiscoveredModel[]
ProbeProviderModel(providerType, endpoint, authType, credentialHandle, remoteModel, config) -> ModelProbeResult
ResolveUserModelCapabilities(providerType, remoteModel, probeFacts, disabledCapabilityDefinitionIds) -> CapabilityResolution
```

约束：

- User Model 不维护 Provider 专用 HTTP 客户端、Header、签名、超时或上游错误映射。
- User Model 传递受控凭证句柄，不传递凭证明文；Gateway 不读取 User Model 私有表。
- `providerType` 必须解析到 Gateway Runtime Registry 已注册 Adapter；客户端提交的 `adapter_id` 或 `operation_executor_id` 必须拒绝。
- Gateway 返回 Adapter/探测事实，User Model 负责把用户模型健康事实持久化并映射为既有 `ERR_MODEL_*`。

## 4. 执行上下文接口

```text
ResolveUserModelExecutionContext(
  principal,
  modelId,
  capabilityDefinitionId
) -> UserModelExecutionContext
```

`UserModelExecutionContext` 至少包含：

```text
owner_user_id
provider_id
model_id
remote_model
provider_type
capability_definition_id
config_version
credential_handle
issued_at
expires_at
issuer
```

签发前必须按同一 owner 边界验证：Provider 和模型存在、均启用、模型 `health_status=healthy`、能力解析为 `resolved`、请求能力在最终 `capability_definition_ids` 内、默认模型用途约束已满足、配置版本为当前版本。

上下文必须短期有效、不可由客户端自行构造，并绑定 principal、模型、能力和配置版本。User Model 不创建 `ResolvedModelRoute` 表，也不把执行上下文作为长期业务资源保存。

Agent 内部接口 `IssueAgentModelAccessGrant(principal, agentId, usage, modelBinding)` 只接受 `agent.chat|agent.coding`，返回绑定 owner、Agent、用途、模型、配置版本和有效期的 `agent-model-access-grant://` 引用。Infrastructure 可在 Runtime 启动/恢复时解析并注入；Task Worker 的 agent-executor 仅可在匹配当前 Agent/Invocation/Attempt 的 `agent-invocation-grant://` 委托下临时解析为 ModelAccessSpec。grant 不建表、不返回客户端、不允许跨 Agent/用途或跨 Attempt 复用，解析结果不得进入 Task、结果、事件或日志。

## 5. 同步与能力解析

- `DiscoverProviderModels` 的结果只能创建新模型或更新远端发现事实。
- 同步不得静默覆盖 `display_name`、`model_group`、`enabled`、`feature_labels_json` 或 `disabled_capability_definition_ids_json`。
- `feature_labels` 只用于展示和筛选；最终能力来自 Gateway Adapter 支持能力、ProviderCapability 或探测结果与用户启用范围的交集。
- 用户只能关闭已验证能力；未知能力 ID、未注册 Operation 或由标签推导的能力必须拒绝。
- ProviderCapability 或 Runtime Registry 更新不得删除或改写用户模型；只通过只读派生字段改变执行资格。

## 6. 健康与事件边界

- 未保存 Provider 测试不写 `user_model_providers`、`model_health_checks` 或其他持久事实。
- 已保存 Provider/模型测试由 Gateway 执行；User Model 保存 `model_health_checks` 和 `user_provider_models.health_status`。
- 旧配置版本的探测结果不得覆盖新配置结果。
- `model_health_status_changed` 继续由 `user-model.health` 发布；Gateway 不发布同义事件。
- 事件失败不回滚 User Model 事实，下游通过查询恢复。

## 7. 数据归属与权限边界

- `user_model_providers`、`user_provider_models`、`user_default_model_configs`、`model_health_checks` 全部归 `user-model`。
- `ApplicationEngineInstance`、`EngineCapabilityBinding`、Gateway Registry、Adapter 和 Executor 全部归 `modelgateway`。
- 两域不新增共享表、跨域外键或双写模型事实。
- 所有 User Model 读写都以 principal 对应的 `owner_user_id` 为边界；`MODEL_*` 权限不扩大 owner 可见性。

## 8. 下游调用规则

- ai-chatting 继续引用 `UserProviderModel.id`，生成前调用 `ResolveUserModelExecutionContext`，再调用 Gateway `ExecuteOperation`。
- ai-chatting 保存 GenerationRun 以及模型 ID、CapabilityDefinition ID、配置版本和非敏感模型快照；User Model 和 Gateway 均不拥有 GenerationRun。
- Application Platform 继续使用 `PlatformEngineTarget`，ApplicationRun、Engine 与 Binding 的既有语义不因 User Model 重构而改变。
- 下游不得读取 User Model 私有表、Provider 地址、凭证引用明细或凭证明文。
- Agent 启动/恢复和 Invocation 执行必须使用用途匹配的短期 grant；缺失默认用途、模型不健康或无资格时 fail closed，且不得执行 Runtime 或 Invocation。Infrastructure 只在 Runtime 启动阶段解析注入，agent-executor 只在当前 Attempt 内解析协议执行所需的 ModelAccessSpec。

## 9. API 与错误映射

- canonical HTTP API 仅使用 `/api/v1/user-model/...`；不保留旧路由、重定向或兼容别名。
- 保留现有 Schema 名、operationId、`MODEL_*` 权限、`ERR_MODEL_*` 错误和事件名。
- Gateway Adapter 错误必须映射为对应 User Model 业务错误，不得使用 `ERR_AIAPP_ENGINE_*` 表达用户 Provider 错误。

## 10. 相关 S1 引用

- user_stories: US-USER-MODEL-01..US-USER-MODEL-15
- business_rules: BR-USER-MODEL-01..BR-USER-MODEL-48
