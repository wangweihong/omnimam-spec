# OmniMAM Model Gateway 与统一 Provider Account 功能设计

> 文档状态：方案 B 重构草稿
>
> 本次重构不兼容旧 Engine 与 User Model Provider 合同；受影响开发数据清空后按新设计态 Schema 重建。

## 1. 文档目的

本文定义 Model Gateway 对 Provider 类型、账号、远端资源、能力绑定、健康、凭证引用、Adapter、OperationExecutor、目标解析与执行授权的统一产品语义。

核心目标是将“账号归属”和“Provider 能力类型”彻底解耦：

```text
ProviderAccount.scope = USER | PLATFORM
ProviderType = LLM | RunningHub | ComfyUI | SaaS | Generic API 等协议或平台类型
```

统一执行链路为：

```text
ApplicationNode
→ ApplicationVersion
→ TargetSelection(FIXED | DEFAULT | REQUEST)
→ ProviderAccount / ProviderResource
→ Gateway ProviderExecutionGrant
→ ExecuteOperation
```

Model Gateway 拥有：

- `CapabilityDefinition`、`ProviderCapability` 与加载诊断；
- `ProviderType`、`ProviderAccount`、`ProviderResource`；
- `ProviderAccountCapabilityBinding`；
- Provider 账号与资源健康事实；
- 凭证引用、Provider Adapter、OperationExecutor 和 Runtime Registry；
- ComfyUI 当前 `object_info`；
- Provider 网络策略；
- 目标资格查询、目标解析、Grant 签发和 Operation 执行。

本领域不拥有 Application、Canvas、GenerationRun、Agent、AtomicTask 或模型展示偏好；这些领域只保存稳定 ID、非敏感快照或不透明 Grant 引用。

## 2. 破坏性迁移边界

下列旧概念立即废弃，不保留 API、DTO、表、权限、错误码、事件或兼容别名：

```text
ApplicationEngineType
ApplicationEngineInstance
EngineCapabilityBinding
PlatformEngineTarget
UserModelTarget
UserModelExecutionContext
ResolvedModelRoute
```

旧 `aiapp_engine_*`、`user_model_providers`、`user_provider_models`、`model_health_checks` 设计态表不迁移。开发环境必须清空受影响数据并按新 Schema 重建；历史发布文档可以保留旧名称，但当前合同不得继续返回或接受旧字段。

## 3. 领域对象

### 3.1 CapabilityDefinition

`CapabilityDefinition` 表达平台统一业务能力，例如：

```text
text.chat_completion
text.translate
image.text_to_image
image.edit
video.text_to_video
video.image_to_video
```

它只定义输入输出语义、分类和可追溯标识，不包含账号、endpoint、凭证或 Provider 私有请求结构。

### 3.2 ProviderType

`ProviderType` 是 Runtime Registry 中只读注册的稳定 Provider 类型。它至少声明：

- 稳定 `id` 与多语言显示名；
- 支持的账号作用域 `USER`、`PLATFORM`；
- 支持的 `resource_kind`；
- 认证结构与非敏感配置 Schema；
- endpoint 是固定、可选自定义还是必须自定义；
- 是否支持资源发现、手动资源维护、账号探测、资源探测和 `object_info`；
- 内部 Adapter 与 `capability_definition_id → executor` 映射。

公共投影不得返回 Adapter ID、Executor ID、实现类名、内部路径或凭证结构值。

RunningHub、ComfyUI、OpenAI Compatible、DeepSeek 等当前 ProviderType 默认同时允许 `USER` 和 `PLATFORM`。只有外部协议在产品语义上确实不支持某一作用域时，Registry 才能显式收窄；不得因现有页面或旧表结构而收窄。

### 3.3 ProviderCapability

`ProviderCapability` 继续由只读清单提供，引用 `provider_type`，不再引用 `application_engine_type_id`。它描述 Provider 类型可提供的模型、Operation、Variant、参数边界和修订，不保存账号、凭证或健康事实。

公共目录列表只返回稳定摘要。开发者或管理员可以按 Capability ID 读取当前可用修订的详情，用于选择模型、Operation、Variant 和构建参数表单；详情不得返回 Adapter/Executor ID、清单来源路径、凭证、Provider 原始响应或其他内部运行配置。

清单从内置内容和 `provider_capability_directory` 第一层 `.yaml` / `.yml` 文件启动加载，不递归、不热加载。内置清单失败阻止启动；目录清单逐文件隔离失败。运行态 `availability`、失败原因、来源文件和加载时间不写回清单。

### 3.4 ProviderAccount

`ProviderAccount` 表达一个真实 Provider 账号或连接环境：

```text
id
scope: USER | PLATFORM
owner_user_id
provider_type
endpoint
auth_type
credential_ref
extra_config
enabled
config_version
health_status
health_reason
routing_priority
max_concurrency
timeouts
resource_version
```

规则：

- `scope=USER` 时 `owner_user_id` 必填且由服务端固定为当前主体；用户不能代他人创建账号。
- `scope=PLATFORM` 时 `owner_user_id` 必须为空，仅平台管理权限可创建、修改、测试或删除。
- 凭证只保存受控 `credential_ref`，任何普通响应、事件、日志或快照不得返回凭证明文。
- `config_version` 在 endpoint、认证、凭证引用或影响执行的配置变化时单调递增。
- `resource_version` 用于资源本身的乐观并发；不能替代 `config_version` 的执行指纹语义。
- `routing_priority` 仅用于 `PLATFORM + DEFAULT` 目标确定，数值越小优先级越高。

### 3.5 ProviderResource

`ProviderResource` 表达账号下可选择的远端对象：

```text
resource_kind: MODEL | WORKFLOW | APPLICATION | DEPLOYMENT
remote_resource_id
provider_account_id
capability_definition_ids
enabled
disabled_capability_definition_ids
discovery_status
health_status
resource_revision
non_sensitive_metadata
```

语义约束：

- LLM 模型保存为 `kind=MODEL`；RunningHub Workflow 保存为 `kind=WORKFLOW`。
- ComfyUI API Workflow 正文仍归 Application Platform；Gateway 只保存 ComfyUI 账号、当前 `object_info` 和运行能力，不复制 Workflow 正文为 ProviderResource。
- `capability_definition_ids` 是 Gateway 根据 Registry、清单和探测结果维护的可执行能力事实。
- 用户可以对 ProviderType 允许手动维护的类型添加资源。
- 同步只更新远端事实、修订与非敏感 metadata，不覆盖本地 `enabled` 或 `disabled_capability_definition_ids`。
- 远端同步缺失的资源标记为 `missing` 且不可执行，不静默删除；恢复出现后可回到已发现状态。
- `resource_revision` 在会影响执行或复用资格的远端事实变化时更新。

### 3.6 ProviderAccountCapabilityBinding

Binding 连接一个 ProviderAccount 与当前可用的 ProviderCapability 修订，并允许账号级收窄。它不能扩张 ProviderType、ProviderCapability 或 ProviderResource 已验证的能力。

有效能力为：

```text
ProviderCapability 当前修订
∩ ProviderAccountCapabilityBinding 限制
∩ ProviderResource capability_definition_ids
− ProviderResource.disabled_capability_definition_ids
```

Binding 的创建、修改和删除必须校验账号 ProviderType 一致、能力当前可用且限制只收窄。

### 3.7 ProviderHealthCheck

Gateway 统一持久化账号和资源健康事实。健康结果包含目标类型、目标 ID、状态、检查时间、安全失败摘要和被检查的配置/资源修订。

- 失败摘要不得包含 endpoint 完整查询、凭证、Header、签名或未经处理的 Provider 响应。
- 旧检查结果不得覆盖更新配置或资源修订后的结果。
- `enabled=false`、`missing` 或不受支持的目标不进入可执行集合。
- 健康事实是带时间的当前状态，不改写历史运行快照。

### 3.8 ComfyUI 当前 object_info

每个 ComfyUI ProviderAccount 最多保存一份当前 `object_info`。刷新成功必须完整校验后原子替换；刷新失败保留最后成功正文。工作流、版本、运行、Canvas 和事件不得复制 `object_info` 正文。

目录缺失、过期、账号停用或账号不健康时，依赖节点能力的解析、模板发布和执行在访问外部 ComfyUI 前失败。受权用户可读取当前正文、ComfyUI 版本、刷新时间和派生 stale 状态，但不能读取账号凭证或私有配置。

### 3.9 ProviderNetworkPolicy

网络策略模式为：

```text
ALLOW_ALL | PUBLIC_ONLY | ALLOWLIST
```

默认值为 `ALLOW_ALL`。默认策略不阻断回环、私网、链路本地、云元数据或平台控制面地址。这是用户明确接受的高危安全风险，必须在 S1、架构参考和 Release implementation gate 中持续显式记录，不能以“已有 Adapter”作为风险已消除的理由。

管理员可以收紧允许的 host、CIDR、scheme 和 port。无论策略模式如何，所有外部请求仍必须：

- 由已注册 Adapter 发起，只使用 Adapter 声明的方法、路径和 Header；
- 强制连接/读取/任务超时、响应大小和重定向次数上限；
- 对凭证、Header、URL 查询和 Provider 响应进行脱敏；
- 记录可审计的主体、账号、资源、ProviderType、方法类别和策略判定结果。

## 4. Runtime Registry 与执行职责

Runtime Registry 直接维护：

```text
provider_type → adapter
capability_definition_id → executor
```

Adapter 负责 endpoint 处理、认证应用、协议请求、远端资源发现、账号/资源探测、提交、轮询、取消、下载和公共错误归一化。OperationExecutor 负责标准输入校验、Provider 请求转换、状态/结果解释和结构化输出提取。

Application Platform、AI Chat、Agent 与 Canvas 不实现 Provider 专用 HTTP 客户端，也不能解析 Grant 得到 endpoint、凭证、Header 或 Provider 私有配置。

## 5. 目标资格、解析与 Grant

### 5.1 TargetSelection

调用方提交类型化选择：

```text
FIXED:  provider_account_id + provider_resource_id?
DEFAULT: 不携带账号 ID
REQUEST: 运行请求携带 provider_account_id + provider_resource_id?
```

Gateway 依据主体、目标策略、账号作用域、ProviderType、ResourceKind、能力、owner/project/namespace、enabled、健康和修订验证资格。

USER 与 PLATFORM 作用域之间禁止自动回退。指定目标不可用时直接失败，不得换用另一作用域或另一个用户账号。

### 5.2 统一内部接口

```text
ListEligibleProviderTargets(principal, target_policy)

ResolveProviderTarget(principal, target_selection, capability, execution_ref)
  -> ProviderExecutionGrant

ExecuteOperation(grant_ref, input, execution_options)
  -> OperationExecutionResult
```

`ListEligibleProviderTargets` 只返回当前主体有权使用的非敏感一跳摘要。`ResolveProviderTarget` 是唯一目标资格判定和 Grant 签发入口。`ExecuteOperation` 只接受有效的不透明 Grant 引用。

### 5.3 ProviderExecutionGrant

Grant 必须绑定：

```text
principal
account_scope
provider_account_id
provider_resource_id?
provider_type
capability_definition_id
account_config_version
resource_revision?
provider_capability_revision
purpose
application_run_id / generation_run_id / invocation_id / attempt_id
issued_at
expires_at
```

Grant 使用不透明 `provider-execution-grant://` 引用，不建立公共 CRUD，不允许客户端解析或自行构造。Grant 过期、主体/用途/运行引用不匹配、账号配置版本或资源修订失配时，在调用 Provider 前拒绝。

Grant 引用可以在受信任的 Worker 边界短时传递，但 Task、CanvasVersion、ApplicationRun、GenerationRun、Agent 事件、日志和结果中不得保存 Grant 解析结果。历史业务对象只保存非敏感目标快照与修订。

## 6. 默认与固定目标解析

- `USER + DEFAULT` 当前只允许 `MODEL`，由 Model Preferences 按用途返回 `provider_resource_id`，Gateway 再完成最终资格校验。
- `PLATFORM + DEFAULT` 由 Gateway 在合法候选中按 `routing_priority ASC, account_id ASC` 确定唯一目标。
- USER RunningHub/ComfyUI 不支持默认用途解析，必须使用 `FIXED` 或 `REQUEST`。
- `PROJECT` 场景禁止固定 USER 账号；允许固定调用者有权使用的 PLATFORM 账号，或使用 `DEFAULT` / `REQUEST`。
- `DEFAULT` 与 `REQUEST` 不得在版本化配置中偷偷保存当前用户账号 ID。

## 7. 资源发现、同步与测试

未保存账号测试不创建 ProviderAccount、ProviderResource 或健康历史，只返回安全结果。已保存账号/资源测试可以更新相应健康事实。

同步过程：

1. 校验主体对账号的管理权限与网络策略；
2. 由 ProviderType 对应 Adapter 获取远端资源；
3. 校验并归一化远端 ID、kind、能力与非敏感 metadata；
4. 幂等新增或更新远端事实；
5. 保留本地 enabled 与能力关闭范围；
6. 将本轮缺失资源标记为 `missing`，不删除；
7. 发布资源变化事件并返回逐项结果。

同步、探测和执行必须受到账号 `max_concurrency`、timeouts 与全局安全上限共同约束。

## 8. 跨域协作

### 8.1 Model Preferences

Model Preferences 只拥有用户对 `MODEL` ProviderResource 的展示偏好和用途默认值。它不缓存健康、能力或 executable，不签发执行上下文或 Grant。Gateway 提供当前资源的一跳投影并负责最终资格校验。

### 8.2 Application Platform 与 Canvas

ApplicationVersion 声明目标策略，ApplicationRun 保存非敏感目标快照。ApplicationExecutor 负责输入、编排、Task 协作、请求 Grant 和输出交付；Provider 提交、轮询、取消、鉴权、下载和结果解析全部由 Gateway 完成。

Canvas 只保存 `TargetSelection` 的非敏感稳定 ID；Application Platform 在 Worker 创建 ApplicationRun 时向 Gateway 请求 Grant。

### 8.3 AI Chat 与 Agent

AI Chat 和 Agent 直接引用 `ProviderResource(kind=MODEL)`。默认用途可由 Model Preferences 返回资源 ID，但启动/生成/Attempt 执行前必须由 Gateway 重新验证并签发 Grant。GenerationRun 与 Agent Invocation/Attempt 生命周期仍归来源领域。

### 8.4 Task Center

Task arguments 只能携带非敏感 TargetSelection ID 和必要运行引用。Task、Attempt、日志和结果禁止出现 endpoint、credential、Header、Grant 解析结果或 Provider 私有配置。

## 9. 业务规则

1. `BR-MGW-001`：ProviderAccount 的 `scope` 与 ProviderType 完全解耦；USER 必须绑定当前 owner，PLATFORM 不得绑定 owner_user_id。
2. `BR-MGW-002`：Gateway 统一拥有 Provider 账号、资源、能力绑定、健康、凭证引用、Adapter 和执行；其他领域不得复制这些可变事实。
3. `BR-MGW-003`：ProviderType 必须声明支持作用域、资源类型、认证与 endpoint 结构、发现/探测能力；公共投影不得暴露 Adapter/Executor 实现信息。
4. `BR-MGW-004`：ProviderCapability 引用 `provider_type`，只读启动加载，不提供写入或热加载 API。
5. `BR-MGW-005`：ProviderResource 表达账号下远端对象；同步不得覆盖本地 enabled 与能力关闭范围，缺失资源必须标记 missing 而非静默删除。
6. `BR-MGW-006`：ProviderAccountCapabilityBinding 只能收窄当前 ProviderCapability，不能创造 ProviderType、资源或 Executor 不支持的能力。
7. `BR-MGW-007`：Gateway 统一持久化账号和资源健康事实；旧配置/修订的检测结果不得覆盖新事实，安全摘要不得泄露敏感信息。
8. `BR-MGW-008`：ComfyUI API Workflow 正文归 Application Platform；Gateway 只拥有账号、当前 object_info 与运行能力。
9. `BR-MGW-009`：USER 与 PLATFORM 之间禁止自动回退；明确目标不可用时必须直接失败。
10. `BR-MGW-010`：PROJECT 场景禁止固定 USER 私有账号；PRIVATE 场景只能固定创建者自己的 USER 账号。
11. `BR-MGW-011`：USER + DEFAULT 仅解析 MODEL 且依赖 Model Preferences；PLATFORM + DEFAULT 按 routing_priority、account_id 稳定排序。
12. `BR-MGW-012`：目标解析必须通过 `ResolveProviderTarget` 完成并签发绑定主体、作用域、账号、资源、能力、修订、用途与运行引用的短期 Grant。
13. `BR-MGW-013`：ExecuteOperation 只接受不透明 Grant 引用；客户端提供 endpoint、凭证、Header、Adapter ID 或 Executor ID 必须拒绝。
14. `BR-MGW-014`：Grant 解析结果不得进入 Task、Canvas、ApplicationRun、GenerationRun、事件或日志；上层只保存非敏感快照。
15. `BR-MGW-015`：Provider 提交、轮询、取消、鉴权、下载与结果解析只能由已注册 Adapter/Executor 执行。
16. `BR-MGW-016`：默认 ProviderNetworkPolicy 为 ALLOW_ALL，且不阻断回环、私网、链路本地、云元数据或平台控制面；该风险必须显式进入 Release gate。
17. `BR-MGW-017`：管理员可用 PUBLIC_ONLY 或 ALLOWLIST 收紧 host、CIDR、scheme 和 port；所有模式仍强制 Adapter 方法/路径/Header、超时、响应大小、重定向、脱敏与审计边界。
18. `BR-MGW-018`：未保存账号测试不落库；已保存账号/资源测试可以更新 Gateway 健康事实。
19. `BR-MGW-019`：RunningHub、ComfyUI、OpenAI Compatible、DeepSeek 默认允许 USER 与 PLATFORM，协议无真实限制时不得收窄。
20. `BR-MGW-020`：破坏性迁移不保留旧 Engine/User Model API、DTO、权限、错误码、事件和表；开发数据清空重建。

## 10. 用户故事与验收标准

### US-MGW-001 管理统一 Provider 账号

作为用户或平台管理员，我希望按作用域管理 ProviderAccount，使账号归属不再决定 Provider 类型。

- `AC-MGW-001-01`：USER 创建账号时 owner 被固定为当前主体，无法创建或修改 PLATFORM 账号。
- `AC-MGW-001-02`：平台管理员创建 PLATFORM 账号时 owner 为空，并可配置稳定路由优先级。
- `AC-MGW-001-03`：普通响应、事件和日志不返回 credential_ref 的解析值或凭证明文。

### US-MGW-002 管理与同步 Provider 资源

作为账号管理者，我希望发现或手动维护远端资源，同时保留本地启用决定。

- `AC-MGW-002-01`：MODEL、WORKFLOW、APPLICATION、DEPLOYMENT 只能用于 ProviderType 声明支持的类型。
- `AC-MGW-002-02`：同步更新远端事实但不覆盖 enabled 和 disabled_capability_definition_ids。
- `AC-MGW-002-03`：远端缺失资源标记 missing 且不可执行，不被静默删除。

### US-MGW-003 解析并执行合法目标

作为能力消费者，我希望 Gateway 统一解析目标并签发短期 Grant，使 Provider 私密配置不泄露到上层。

- `AC-MGW-003-01`：FIXED、DEFAULT、REQUEST 均按策略、主体、作用域、能力、健康和修订校验。
- `AC-MGW-003-02`：目标不可用时不跨 USER/PLATFORM 回退。
- `AC-MGW-003-03`：Grant 过期或绑定信息不匹配时在 Provider 调用前失败。
- `AC-MGW-003-04`：ExecuteOperation 返回结构化文本或媒体结果，不暴露 Provider 私有响应与凭证。

### US-MGW-004 维护账号与资源健康

作为账号管理者，我希望测试账号、资源并查看安全健康原因。

- `AC-MGW-004-01`：健康事实绑定被测 config_version/resource_revision，旧结果不能覆盖新配置。
- `AC-MGW-004-02`：失败原因经过脱敏且有长度上限。
- `AC-MGW-004-03`：健康变化发布可靠事件，单纯检查时间变化不制造竞争事件。

### US-MGW-005 使用 ComfyUI 当前能力目录

作为应用创建者，我希望使用账号当前 object_info 校验工作流，同时不复制该大型正文。

- `AC-MGW-005-01`：成功刷新原子替换，失败保留最后成功正文。
- `AC-MGW-005-02`：目录 stale、账号停用或不健康时运行前失败。
- `AC-MGW-005-03`：Application、Canvas 和运行快照均不保存 object_info 正文。

### US-MGW-006 配置 Provider 网络策略

作为平台管理员，我希望显式查看并收紧 Provider 出站网络范围。

- `AC-MGW-006-01`：初始策略为 ALLOW_ALL，并在 API、架构与 Release gate 中标记高危风险。
- `AC-MGW-006-02`：切换 PUBLIC_ONLY 或 ALLOWLIST 后，解析后的每个重定向目标都重新进行策略校验。
- `AC-MGW-006-03`：任何模式都不能绕过 Adapter 方法、路径、Header、超时、响应大小、脱敏和审计限制。

### US-MGW-007 查看 Provider 类型与能力诊断

作为开发者或管理员，我希望读取稳定 ProviderType、ProviderCapability 和加载结果。

- `AC-MGW-007-01`：普通读取不返回 Adapter/Executor ID 或来源文件私密路径。
- `AC-MGW-007-02`：只有诊断权限可读取文件级加载失败详情。
- `AC-MGW-007-03`：目录清单失败只隔离对应能力，内置清单失败阻止启动。
- `AC-MGW-007-04`：普通读取可先分页获取 Capability 摘要，再按 ID 获取当前可用修订的脱敏详情；详情包含模型、Operation、Variant 与参数 schema，足以支持目标选择和模板编写。
- `AC-MGW-007-05`：Capability 不存在、不可用或当前主体不可见时统一按不存在处理，不泄露目录或可见性信息。

## 11. 非目标

- 不维护 Application、ApplicationVersion、Canvas、GenerationRun、Agent、AtomicTask、Artifact 或 Asset。
- 不维护模型展示名、分组、标签或用途默认值；这些属于 Model Preferences。
- 不保存 ComfyUI API Workflow 正文。
- 不提供 ProviderCapability、ProviderType、Adapter 或 Executor 写入 API。
- 不为旧 Engine/User Model 合同提供兼容路由、映射表或双写。
- 不在本仓库维护正式实现代码、实际 migration 或运行时配置。
