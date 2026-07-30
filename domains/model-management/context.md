# Model Management Context

## 1. 领域职责

`model-management` 管理当前用户个人范围内的模型提供商、密钥引用、模型清单、能力标签、健康状态和默认用途模型。它向 ai-chatting 等下游提供权限裁剪的用户模型只读投影，不管理平台级 ProviderCapability。

## 2. 核心对象

- `UserModelProvider`：当前用户私有的模型服务连接与非敏感配置。
- `UserProviderModel`：提供商下的远端模型标识、展示信息、能力标签和启用状态。
- `UserDefaultModelConfig`：按用途保存的当前用户默认模型选择。
- `ModelHealthCheck`：提供商或模型的一次连接检测及结果。

## 3. 核心规则

- 提供商、模型、默认配置和密钥引用都属于当前用户，禁止跨用户读取或复用。
- 密钥只保存受控引用，列表、详情、事件和关联摘要不得返回明文。
- Provider 删除、停用或不可用时，关联模型和默认选择必须按 S1 规则处理。
- 远端模型同步不能静默覆盖用户维护的展示信息和启用决策。
- 健康检测是带时间的结果，不等于模型永久可用，也不能改写历史生成记录。
- 下游只读取可见、启用且满足用途的模型投影，不维护自己的模型清单副本。
- 默认模型按当前用户和用途解析；不可用时按明确规则提示或选择替代项。
- 本领域的用户模型 Provider 不等于 application-platform 的只读 ProviderCapability。

## 4. 领域边界

本领域拥有用户私有模型服务配置、模型清单、默认选择和健康检测。AI Topic、Assistant、Message 与生成流归 ai-chatting；平台应用能力、EngineInstance 和 ProviderCapability 归 application-platform；身份与主体归 identity。

## 5. 上游与下游

上游是 identity 的当前用户和受控外部 OpenAI Compatible、本地或其他模型服务。下游主要是 ai-chatting，也可包括经授权的其他模型消费者。跨域通过非敏感一跳摘要或模块接口读取，不共享凭证或私有表。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/model-management/product-spec.md` | S1 | 用户模型、健康和默认选择语义 |
| `01_contracts/domains/model-management/openapi.yaml` | S2 | Provider、模型和检测 API |
| `01_contracts/domains/model-management/schema.sql` | S2 | 设计态模型配置结构 |
| `01_contracts/domains/model-management/events.yaml` | S2 | 模型配置与状态事件 |
| `01_contracts/domains/model-management/module-contract.md` | S2 | 凭证、下游读取和模块边界 |
| `02_architecture/domains/model-management.md` | 参考 | 外部依赖、核心链路和风险 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改 Provider 或模型管理 | S1 product-spec | 涉及接口或数据时读 OpenAPI/Schema |
| 修改健康检测或默认模型 | S1 product-spec | 涉及事件时读 events/module-contract |
| 修改聊天模型选择 | 当前 Context | 再读 ai-chatting Context |
| 修改应用能力目录 | application-platform Context | 不读取本域用户模型合同 |

## 8. 当前状态

用户模型管理已有 S1/S2 和发布记录并正在实施。具体模型操作、错误和实施门禁以 `RELEASE.md` 及对应 S2 为准；Context 不把未来 Provider 类型声明为已支持。

## 9. 不在本领域定义的内容

- Topic、Message、Assistant 和生成运行不在本领域定义。
- ProviderCapability、ApplicationEngineInstance 和应用路由不在本领域定义。
- 用户认证、Token 和 RBAC 计算不在本领域定义。
- 外部模型服务的内部能力、可用性承诺和凭证明文不在本领域定义。
