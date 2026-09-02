# Model Preferences Context

## 1. 领域职责

`model-preferences` 管理当前用户对 Gateway ProviderResource 的展示偏好和默认用途引用。它不拥有 Provider 连接、健康、能力、凭证或执行资格；Provider Adapter、模型发现、探测和 Operation 执行实现归 `modelgateway`。

## 2. 核心对象

- `ModelPreference`、`DefaultModelPreference`：当前用户对 Gateway ProviderResource 的展示覆盖和用途默认引用。

## 3. 核心规则

- 提供商、模型、默认配置和密钥引用都属于当前用户，禁止跨用户读取或复用。
- 密钥只保存受控引用，列表、详情、事件和关联摘要不得返回明文。
- Provider 删除、停用或不可用时，关联模型和默认选择必须按 S1 规则处理。
- 远端模型同步不能静默覆盖用户维护的展示信息和启用决策。
- `feature_labels` 仅用于用户展示和筛选，不参与执行能力判断。
- 用户选择稳定 `providerType`，不得提交内部 Adapter 或 Executor ID；Provider 测试、模型同步和单模型测试均委托 Gateway Adapter。
- 下游只读取可见 ProviderResource 的受控摘要，不维护自己的模型清单副本；执行资格和 Grant 始终由 Gateway 重新解析。
- 默认模型按当前用户和用途解析；不可用时按明确规则提示或选择替代项。
- ProviderResource 不等于 ProviderCapability；ProviderAccount、健康、能力和执行授权均归 modelgateway。
- Agent Invocation 创建前必须具有 ACTIVE primary ModelBinding；`agent.chat` 与 `agent.coding` 授权使用短期 Model Access Grant，grant 过期或 Attempt 不匹配时拒绝解析。

## 4. 领域边界

本领域拥有 ModelPreference、DefaultModelPreference 及其用户隔离和默认用途引用。AI Topic、Assistant、Message 与 GenerationRun 归 ai-chatting；ProviderAccount/Resource、Adapter、发现、探测、Operation 执行、Capability、Binding、健康和 Grant 归 modelgateway；应用语义归 application-platform；身份与主体归 identity。

## 5. 上游与下游

上游是 identity 的当前用户和 modelgateway 的 Provider Type 目录、能力派生与 Adapter 内部接口。下游主要是 ai-chatting，也可包括经授权的其他模型消费者。跨域只通过非敏感一跳摘要、受控模块接口和请求级执行上下文协作；Gateway 不读取本领域私有表，本领域不维护 Provider 专用 HTTP 客户端。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/model-preferences/product-spec.md` | S1 | 模型展示偏好和默认选择语义 |
| `01_contracts/domains/model-preferences/openapi.yaml` | S2 | 模型偏好、默认值与 `/api/v1/model-preferences/` canonical API |
| `01_contracts/domains/model-preferences/schema.sql` | S2 | 设计态模型偏好配置结构 |
| `01_contracts/domains/model-preferences/events.yaml` | S2 | 模型配置与状态事件 |
| `01_contracts/domains/model-preferences/module-contract.md` | S2 | Gateway 委托、执行上下文和下游读取边界 |
| `02_architecture/domains/model-preferences.md` | 参考 | Gateway 协作、核心链路和风险 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改模型偏好或默认模型 | S1 product-spec | 涉及接口或数据时读 OpenAPI/Schema |
| 修改 Provider 健康检测 | S1 product-spec | 涉及事件时读 events/module-contract |
| 修改聊天模型选择 | 当前 Context | 再读 ai-chatting Context |
| 修改 Provider Type、Adapter 或平台能力目录 | modelgateway Context | 涉及用户选择与资格时返回当前 Context |

## 8. 当前状态

`model-preferences` 接替 `user-model` 的展示偏好和默认用途职责，待方案 B release 确认。Agent 的 ModelBinding 与 Grant 门禁由 agent/modelgateway 事实源负责。Provider Type 或 Adapter 仍只有在 Gateway Runtime Registry 实际注册并加载后才视为可用，本 Context 不扩张运行时支持范围。

## 9. 不在本领域定义的内容

- Topic、Message、Assistant 和生成运行不在本领域定义。
- Provider Adapter、OperationExecutor、ProviderCapability、ProviderAccount、ProviderResource、Binding 和健康状态不在本领域定义。
- 用户认证、Token 和 RBAC 计算不在本领域定义。
- Provider 专用 HTTP 客户端、外部模型服务的内部能力、可用性承诺和凭证明文不在本领域定义。
