# Application Platform 模块契约

## 1. 模块职责

| 模块 | 负责 | 不负责 | S1 |
| --- | --- | --- | --- |
| application-catalog | Application、ApplicationTemplate/Version、ApplicationVersion 与发布 | Provider 账号、资源、健康或凭证 | US-AIAPP-042、053；BR-AIAPP-142、147、205、208 |
| runtime-form | 按能力来源、`execution_target_policy`、当前 Gateway 合格目标和权限计算 RuntimeFormSchema | 持久化 RuntimeForm、缓存 Gateway 健康或自动跨作用域回退 | US-AIAPP-043、053；BR-AIAPP-146、205..207 |
| application-run | 固定输入、目标与能力非敏感快照，幂等协作 AtomicTask，保存结构化输出与 Artifact 引用 | AtomicTask 状态机、Provider 执行、Artifact 生命周期 | US-AIAPP-043、050、053；BR-AIAPP-143、149、181..184、194、209、212 |
| comfyui-workflow | ComfyUI API Workflow、转换、校验、模板映射和试运行业务事实 | ProviderAccount、凭证和 object_info 当前事实 | US-AIAPP-044..048；BR-AIAPP-153..192 |

## 2. Model Gateway 边界

- ProviderType、ProviderCapability、ProviderAccount、ProviderResource、ProviderAccountCapabilityBinding、健康、凭证引用、ProviderAdapter、OperationExecutor、ProviderNetworkPolicy 和当前 object_info 由 `modelgateway` 拥有。
- Application Platform 只使用稳定 ID、权限裁剪摘要、非敏感快照与受控内部接口，不查询 Gateway 私表，不建立跨域数据库外键。
- RuntimeForm 使用 `ListEligibleProviderTargets(principal, execution_target_policy)`。
- ApplicationExecutor 使用 `ResolveProviderTarget(principal, target_selection, capability, execution_ref)` 取得不透明 `provider-execution-grant://`，再调用 `ExecuteOperation`。
- Application Platform 不解析 Grant，不接收 endpoint、credential、Header、extra_config 或 Provider 私有 metadata。
- Provider 提交、轮询、取消、鉴权、下载与结果解析全部由 Gateway Adapter/Executor 完成。

## 3. ApplicationVersion

ApplicationVersion 必须包含：

```text
execution_target_policy.allowed_account_scopes
execution_target_policy.allowed_provider_types
execution_target_policy.allowed_resource_kinds
execution_target_policy.allowed_selection_sources
execution_target_policy.default_account_scope?
execution_target_policy.default_model_usage?
```

发布后 policy 不可变。发布只验证至少一种结构合法解析方式，不冻结当前账号、凭证、健康或 Grant。

系统内置 `system.llm.text-generation@1.0.0` 使用 `text.chat_completion`、MODEL、USER/PLATFORM 与 FIXED/DEFAULT/REQUEST，renderer 为 `application.llm`。

## 4. TargetSelection

```text
FIXED: provider_account_id + provider_resource_id?
DEFAULT: 不携带账号 ID
REQUEST: 运行请求携带 provider_account_id + provider_resource_id?
```

DEFAULT 的 USER MODEL 资源 ID由 Model Preferences `application.default` 返回；PLATFORM DEFAULT 由 Gateway 稳定排序。任一失败不跨 USER/PLATFORM 回退。

RuntimeForm、独立 ApplicationRun 和 Canvas `EnsureCanvasApplicationRun` 都必须使用同一 TargetSelection 结构和 policy 校验。

## 5. ApplicationRun

ApplicationRun 固定：

```text
target_selection_source
account_scope
provider_account_id + provider_account_snapshot + provider_account_config_version
provider_resource_id? + provider_resource_snapshot? + provider_resource_revision?
provider_capability_id/revision
capability_definition_id
input_snapshot + execution_snapshot + output_mapping_snapshot
```

快照不包含敏感字段或 Grant 解析结果。同域摘要优先使用运行创建时快照；目标随后删除或不可见不改写历史。

独立运行先保存 ApplicationRun，再以 `application_run_id + idempotency_key` 幂等创建唯一 `application-platform.run` AtomicTask。失败保留可恢复 `task_creation_status=failed`。

Canvas Worker 在上游输入解析完成后调用 `EnsureCanvasApplicationRun`，以 owner、`canvas_run_id`、`execution_key` 幂等创建并绑定已经存在的 AtomicTask；不得再创建第二个 Task。

## 6. 输出

- 文本/JSON 结果保存到 ApplicationRun `output_values`，直接供 Canvas string/json 端口使用，不要求 Artifact。
- 媒体结果由 asset-library 按 `application_run_id + output_key + sequence` 幂等形成 Artifact。
- Application Platform 只维护 Artifact 一跳引用投影，不拥有内容、处理、登记或保留事实。

## 7. ComfyUI

- ComfyUIWorkflow 正文归本领域；Gateway 不创建相应 ProviderResource。
- 转换、校验、试运行请求使用 `provider_account_id`，通过 Gateway 读取当前账号与 object_info；不保存 object_info 正文或 checksum。
- 历史 validation/test run 保存 ProviderAccount 非敏感快照，不以当前账号投影覆盖历史。
- object_info stale、账号停用或不健康时在调用 ComfyUI 前失败。

## 8. Task Center

`application-platform.run` 是唯一 Application functionRef。Task arguments 只包含稳定 ApplicationRun/Canvas 引用、输入映射和非敏感 TargetSelection ID，禁止包含 endpoint、credential、Header、Grant 解析结果或 Provider 私有配置。

AtomicTask 状态机、Attempt、重试、取消和终态归 task-center。ApplicationRun 只接受更高 `task_resource_version` 的单调投影。

## 9. Workflow Canvas

- Canvas 固定已发布 ApplicationVersion 与其 target policy；不复制 Gateway 当前事实。
- `application_version_published` 与发布事务原子提交，Canvas 幂等登记普通 Application NodeDefinition。
- LLM 不新增 ModelNode；`system.llm.text-generation` 通过同一事件形成 renderer=`application.llm` 的 ApplicationNode。
- `application_run_projection_changed` 可携带结构化 `output_values`；`application_run_artifact_ref_changed` 只表达媒体 Artifact 引用。

## 10. 权限与事件

Application Platform 保持自身 Application/Workflow/Run 权限。ProviderAccount/Resource/Binding/NetworkPolicy 权限由 Model Gateway 定义，调用 Gateway 时传递当前 principal 并接受同等裁剪。

事件不得出现 endpoint、credential、Header、Grant 解析结果或 Provider 私有配置。ApplicationRun 事件只使用账号/资源快照与修订。

## 11. 非职责

- Provider 账号、资源、健康、凭证、Adapter、Executor 或网络策略所有权。
- Model Preferences 的展示偏好和用途默认值所有权。
- Canvas 图、AtomicTask 状态机、Artifact/Asset 生命周期。
- 旧执行引擎双轨、用户模型目标或执行上下文兼容合同。
