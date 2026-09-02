# Model Gateway 模块契约

## 1. 职责

Model Gateway 是 Provider 执行面的唯一事实源，负责：

- ProviderType、CapabilityDefinition、ProviderCapability 与加载诊断；
- USER/PLATFORM ProviderAccount、ProviderResource 与账号能力绑定；
- 凭证引用、账号/资源健康、ComfyUI 当前 object_info；
- ProviderNetworkPolicy；
- Provider Adapter、OperationExecutor 和 Runtime Registry；
- 合格目标查询、目标解析、ProviderExecutionGrant 与 ExecuteOperation。

相关 S1：`US-MGW-001..007`、`BR-MGW-001..020`。

## 2. 不负责

- ModelPreference、DefaultModelPreference；
- Application、ApplicationVersion、ApplicationRun 或 Canvas 图；
- Topic、GenerationRun、Agent Invocation、AtomicTask、Artifact 或 Asset；
- 正式 migration、运行时配置和 Provider 实现代码。

## 3. 数据所有权

Gateway 独占以下设计态数据：

```text
model_gateway_provider_accounts
model_gateway_provider_resources
model_gateway_account_capability_bindings
model_gateway_health_checks
model_gateway_comfyui_object_info
model_gateway_network_policy
model_gateway_outbox
```

其他领域不得读取这些私表。跨域只能使用稳定 ID、权限裁剪的一跳摘要、不可变非敏感快照、内部接口或可靠事件。

## 4. 内部执行接口

### 4.1 ListEligibleProviderTargets

```text
ListEligibleProviderTargets(principal, target_policy)
  -> ProviderTargetSummary[]
```

输入包含主体和 ApplicationVersion/调用场景给出的目标策略。输出只包含可见账号/资源稳定 ID、作用域、ProviderType、kind、健康、修订和资格原因；不得包含 endpoint、credential_ref、extra_config、Header 或 Adapter/Executor ID。

### 4.2 ResolveProviderTarget

```text
ResolveProviderTarget(principal, target_selection, capability, execution_ref)
  -> ProviderExecutionGrantRef
```

必须原子验证：

- 主体、owner、project、namespace 与账号作用域；
- TargetSelection 结构与策略；
- ProviderType、ResourceKind 与 CapabilityDefinition；
- 账号/资源 enabled、discovery、健康和修订；
- ProviderCapability、Binding、Adapter、Executor；
- USER + DEFAULT 的 Model Preferences 资源 ID，或 PLATFORM + DEFAULT 稳定排序；
- execution_ref 与 purpose。

失败不跨 USER/PLATFORM 回退，不签发部分 Grant。

### 4.3 ExecuteOperation

```text
ExecuteOperation(grant_ref, input, execution_options)
  -> OperationExecutionResult
```

仅接受 `provider-execution-grant://` 不透明引用。Gateway 在调用 Provider 前验证 Grant 的签发者、过期时间、主体、purpose、execution_ref、account_config_version、resource_revision 与 ProviderCapability revision。

结果可包含结构化 `output_values` 和受控媒体输出 descriptor；不得把 Provider 下载 URL、原始响应、endpoint、凭证或 Header 作为上层稳定结果。

## 5. HTTP 边界

公共/管理 API 的 canonical 前缀为 `/api/v1/model-gateway/`。HTTP API 只提供 ProviderType/Capability 读取、账号/资源/Binding 管理、测试、同步、object_info 与网络策略；Grant 解析和 ExecuteOperation 是受信任内部接口，不提供客户端可直接调用的凭证解析 API。

所有业务失败使用 HTTP 200 + 稳定 `code`/`value`。业务资源 ID 响应必须返回一跳摘要或在 OpenAPI 中明确说明无需继续读取。

## 6. 权限边界

- USER 账号：服务端强制 `scope=USER`、`owner_user_id=current_user`；普通用户无 PLATFORM 写权限。
- PLATFORM 账号：只有平台管理权限可以创建、修改、测试、同步和删除。
- 读取目标必须按当前 principal 裁剪；拥有资源 ID 不代表可见或可执行。
- NetworkPolicy 只允许平台管理员修改，所有读取方均看到默认 ALLOW_ALL 的高危提示。
- 诊断权限与普通 ProviderCapability 读取权限分离。

## 7. Model Preferences 协作

Gateway 提供按 `provider_resource_id` 批量获取当前 MODEL 资源摘要的受控接口。Model Preferences 不读取私表、不缓存健康/能力/executable，只保存展示偏好与默认 ID。

USER + DEFAULT 解析步骤：

1. Application/AI Chat/Agent 按 usage 调用 Model Preferences；
2. Model Preferences 返回 `provider_resource_id`；
3. 调用方将 ID 交给 `ResolveProviderTarget`；
4. Gateway 完成 owner、scope、能力、健康、修订和策略校验并签发 Grant。

## 8. Application Platform 与 Canvas 协作

ApplicationVersion 只保存 `execution_target_policy`；RuntimeForm/Canvas 保存非敏感 TargetSelection。Application Platform 在创建 ApplicationRun 的 Worker 边界请求 Grant。

Gateway 不读取 Application/Canvas 私表；调用方通过 execution_ref 传入已经权限校验的 run/invocation/attempt ID。Gateway 不能修改 ApplicationRun、CanvasRun 或 AtomicTask 状态。

## 9. AI Chat 与 Agent 协作

AI Chat 与 Agent 使用 `ProviderResource(kind=MODEL)`。GenerationRun、Invocation 与 Attempt 保存非敏感资源快照和修订；Gateway 只签发/验证 Grant 并执行 Operation，不拥有来源生命周期。

Infrastructure 只接收短期不透明 Grant 引用。Grant 解析只在受信任 Gateway 执行边界发生。

## 10. Task Center 协作

`application-platform.run` 仍是 Application 的唯一 functionRef。Task arguments 可以携带 TargetSelection 的稳定 ID，但禁止携带：

```text
endpoint
credential / credential_ref resolution
authorization headers
extra_config
Provider 私有 metadata
Grant 解析结果
```

AtomicTask 状态机不因本次重构改变。

## 11. 事件边界

Gateway 发布：

```text
provider_account_changed
provider_account_health_changed
provider_resource_changed
provider_resource_health_changed
provider_network_policy_changed
provider_capability_correction_required
```

事件只用于失效缓存、提示重查和审计，不替代 Gateway REST/内部接口事实。敏感字段遵守 `events.yaml` 的 forbidden_payload。

## 12. 网络与安全边界

默认 `ALLOW_ALL` 不阻断回环、私网、链路本地、云元数据或平台控制面，是明确接受的高危风险。Gateway 必须在每次请求及每个重定向目标上应用当前策略，并始终强制 Adapter 声明的方法/路径/Header、超时、响应大小、重定向次数、脱敏与审计。

## 13. 破坏性迁移

不兼容旧 `ApplicationEngineType`、`ApplicationEngineInstance`、`EngineCapabilityBinding`、`PlatformEngineTarget`、`UserModelTarget`、`UserModelExecutionContext`、`ResolvedModelRoute`。不提供旧 API、DTO、权限、错误码、事件、表或双写；开发数据清空重建。
