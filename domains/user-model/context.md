# User Model Context

## 1. 领域职责

`user-model` 管理当前用户私有 Provider、密钥引用、模型清单、默认用途模型和用户模型健康事实。它校验 owner、启用状态、健康状态、默认值与使用资格，向 ai-chatting 等下游签发带配置版本的 `UserModelExecutionContext`；Provider Adapter、模型发现、探测和 Operation 执行实现归 `modelgateway`。

## 2. 核心对象

- `UserModelProvider`：当前用户私有的模型服务连接与非敏感配置。
- `UserProviderModel`：Provider 下的远端模型标识、用户展示信息、特征标签、启用范围和 Gateway 派生能力投影。
- `UserDefaultModelConfig`：按用途保存的当前用户默认模型选择。
- `ModelHealthCheck`：由 Gateway Adapter 执行、由 User Model 持久化的一次 Provider 或模型检测结果。
- `UserModelExecutionContext`：请求级受信任执行上下文，绑定 owner、稳定 Provider/模型 ID、Provider Type、能力、配置版本和不透明凭证句柄，不建表。
- `AgentModelAccessGrant`：绑定 Agent Invocation/Attempt、用户模型、能力和过期时间的短期授权；Worker 通过引用临时解析 ModelAccessSpec，不在 Task 中传递凭证或 Provider 配置。

## 3. 核心规则

- 提供商、模型、默认配置和密钥引用都属于当前用户，禁止跨用户读取或复用。
- 密钥只保存受控引用，列表、详情、事件和关联摘要不得返回明文。
- Provider 删除、停用或不可用时，关联模型和默认选择必须按 S1 规则处理。
- 远端模型同步不能静默覆盖用户维护的展示信息和启用决策。
- 健康检测是带时间的结果，不等于模型永久可用，也不能改写历史生成记录。
- `feature_labels` 仅用于用户展示和筛选；`capability_definition_ids`、`executable` 和不可用原因由 Gateway 事实派生且只读，用户只能关闭已验证能力，不能通过标签扩张执行能力。
- 用户选择稳定 `providerType`，不得提交内部 Adapter 或 Executor ID；Provider 测试、模型同步和单模型测试均委托 Gateway Adapter。
- 下游只读取可见、启用且满足用途的模型投影，不维护自己的模型清单副本；只有通过 owner、enabled、health、能力和配置版本校验后才能签发执行上下文。
- 默认模型按当前用户和用途解析；不可用时按明确规则提示或选择替代项。
- `UserModelProvider` 不等于 `ProviderCapability` 或 `ApplicationEngineInstance`，不得转换为平台 Engine。
- Agent Invocation 创建前必须具有 ACTIVE primary ModelBinding；`agent.chat` 与 `agent.coding` 授权使用短期 Model Access Grant，grant 过期或 Attempt 不匹配时拒绝解析。

## 4. 领域边界

本领域拥有用户私有模型服务配置、模型清单、默认选择、用户模型健康事实和执行资格校验。AI Topic、Assistant、Message 与 GenerationRun 归 ai-chatting；Provider Adapter、发现、探测、Operation 执行、平台 Capability、EngineInstance、Binding 和平台健康事实归 modelgateway；应用语义归 application-platform；身份与主体归 identity。

## 5. 上游与下游

上游是 identity 的当前用户和 modelgateway 的 Provider Type 目录、能力派生与 Adapter 内部接口。下游主要是 ai-chatting，也可包括经授权的其他模型消费者。跨域只通过非敏感一跳摘要、受控模块接口和请求级执行上下文协作；Gateway 不读取本领域私有表，本领域不维护 Provider 专用 HTTP 客户端。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/user-model/product-spec.md` | S1 | 用户模型、健康、默认选择和执行资格语义 |
| `01_contracts/domains/user-model/openapi.yaml` | S2 | Provider、模型、检测与 `/api/v1/user-model/` canonical API |
| `01_contracts/domains/user-model/schema.sql` | S2 | 设计态用户模型配置结构 |
| `01_contracts/domains/user-model/events.yaml` | S2 | 模型配置与状态事件 |
| `01_contracts/domains/user-model/module-contract.md` | S2 | Gateway 委托、执行上下文和下游读取边界 |
| `02_architecture/domains/user-model.md` | 参考 | Gateway 协作、核心链路和风险 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改 Provider 或模型管理 | S1 product-spec | 涉及接口或数据时读 OpenAPI/Schema |
| 修改健康检测或默认模型 | S1 product-spec | 涉及事件时读 events/module-contract |
| 修改聊天模型选择 | 当前 Context | 再读 ai-chatting Context |
| 修改 Provider Type、Adapter 或平台能力目录 | modelgateway Context | 涉及用户选择与资格时返回当前 Context |

## 8. 当前状态

`user-model` 接替 `model-management` 已由 `spec-v1.17.0` 发布；Agent Model Access Grant、`agent.chat`/`agent.coding` 用途和 ModelBinding 前置门禁待 `spec-v1.18.0` 发布。Provider Type 或 Adapter 仍只有在 Gateway Runtime Registry 实际注册并加载后才视为可用，本 Context 不扩张运行时支持范围。

## 9. 不在本领域定义的内容

- Topic、Message、Assistant 和生成运行不在本领域定义。
- Provider Adapter、OperationExecutor、ProviderCapability、ApplicationEngineInstance、Binding 和平台健康状态不在本领域定义。
- 用户认证、Token 和 RBAC 计算不在本领域定义。
- Provider 专用 HTTP 客户端、外部模型服务的内部能力、可用性承诺和凭证明文不在本领域定义。
