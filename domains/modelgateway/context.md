# Model Gateway Context

## 1. 领域职责

`modelgateway` 维护统一能力定义、只读 ProviderCapability 目录、ProviderType、ProviderAccount、ProviderResource、能力绑定、Provider Adapter、资源发现与探测、OperationExecutor、健康检测和 ComfyUI 当前 `object_info`。它通过统一 `ResolveProviderTarget`/`ExecuteOperation` 支持 USER 与 PLATFORM 账号，不拥有 Model Preferences 展示偏好事实。

## 2. 核心对象

- `CapabilityDefinition`、`ProviderCapability`：统一业务能力分类及平台、模型、Operation、Variant 和参数约束。
- `ProviderType`、`ProviderAccount`、`ProviderResource`：能力类型、账号连接和账号下远端资源。
- `ProviderAccountCapabilityBinding`：账号与能力目录的绑定及实例级收紧。
- `ProviderAdapter`、`OperationExecutor`：平台公共协议与具体 Operation 执行职责。
- Runtime Registry、ProviderCapability Loader：只读注册、启动加载与诊断，并维护 `provider_type -> adapter_id`、`capability -> operation_executor_id` 的内部映射。
- ComfyUI 当前 `object_info`：ProviderAccount 一对一的当前节点能力目录。
- `ProviderExecutionGrant`、`ResolvedExecutionRoute`：统一执行入口的不透明授权引用和请求级派生结果，不建表、不提供 CRUD。

## 3. 核心规则

- ProviderCapability 从内置和目录 YAML 启动加载，不提供写入或热加载 API。
- ProviderType、CapabilityDefinition、Adapter、Executor 及映射由只读 Runtime Registry 提供。
- Binding 只能收窄 ProviderCapability；`required_immutable` 绑定由系统原子维护。
- ProviderAccount/ProviderResource 保存真实连接、健康事实和安全失败摘要，凭证不得进入普通投影。
- ComfyUI `object_info` 只保存当前一份，失败刷新保留最后成功事实，消费者不得复制正文。
- Gateway 负责 Provider 协议、鉴权应用、模型发现、探测、错误归一化和 Operation 执行；Provider Type 是客户端可见稳定标识，Adapter/Executor ID 仅限内部 Registry。
- Gateway 根据 principal、TargetSelection、ProviderResource、能力和 execution_ref 签发短期 `provider-execution-grant://`；Grant 绑定账号/资源/能力修订，敏感连接信息只在 Gateway 与受信 Worker 边界解析。
- USER 与 PLATFORM 账号均由 ProviderAccount.scope 表达；不允许跨作用域自动回退。Model Preferences 只保存 ProviderResource 引用、展示覆盖和默认用途。
- 已发布 `AIAPP` 编号、`aiapp.*` 权限码、错误码、API 路径、表名和调度 key 均保持稳定。

## 4. 领域边界

本领域不拥有 `ApplicationExecutor`、ComfyUIWorkflow、ApplicationTemplate、Application、ApplicationVersion、RuntimeFormSchema、ApplicationRun、GenerationRun、ModelPreference 或 DefaultModelPreference。Application Platform、AI Chat 和 Agent 均通过 `ResolveProviderTarget` 获取 Grant 后调用 `ExecuteOperation`；调用方不得读取 Gateway 私有表或复制可变 Registry 事实。

## 5. 上游与下游

上游包括 identity 的主体与权限、只读能力清单、Model Preferences 的资源引用，以及外部 SaaS、ComfyUI、本地推理和 OpenAI Compatible 平台。下游包括 application-platform 的应用编排、ai-chatting/agent 的生成调用和 task-center 的 Provider 健康 Reconcile 调度。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/modelgateway/product-spec.md` | S1 | Gateway 产品语义、业务规则和验收标准 |
| `01_contracts/domains/modelgateway/openapi.yaml` | S2 | ProviderCapability、ProviderType、ProviderAccount、Binding 与 object_info API |
| `01_contracts/domains/modelgateway/schema.sql` | S2 | ProviderAccount、Binding 与当前 object_info 设计态结构 |
| `01_contracts/domains/modelgateway/runtime-registry.yaml` | S2 | Runtime Registry 与执行职责登记 |
| `01_contracts/domains/modelgateway/module-contract.md` | S2 | Gateway 模块与跨域协作边界 |
| `02_architecture/domains/modelgateway.md` | 参考 | 加载、执行、健康检测和失败隔离 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改能力目录或 Runtime Registry | S1 product-spec | 涉及结构时读 runtime-registry/provider-capabilities |
| 修改 Provider、Binding、健康或 object_info | S1 product-spec | 涉及接口或数据时读 OpenAPI/Schema |
| 修改 Adapter 或 OperationExecutor 边界 | S1 product-spec | 涉及调用关系时读 module-contract/architecture |
| 修改 Application 消费行为 | 当前 Context | 再读 application-platform Context |
| 修改用户模型执行或 Provider Type | 当前 Context | 再读 model-preferences Context |

## 8. 当前状态

本领域由既有已发布 `application-platform` 事实迁移形成，本次迁移与 model-preferences 重构已由 `spec-v1.17.0` 按实施门禁确认为正式实现依据。

## 9. 不在本领域定义的内容

- Application、模板、版本、运行表单和 ApplicationRun 不在本领域定义。
- ComfyUIWorkflow、工作流校验历史、模板转换和试运行不在本领域定义。
- AtomicTask、Artifact、Asset 和 Canvas 不在本领域定义。
- 用户 Provider、用户模型、默认配置、用户模型健康事实和 GenerationRun 不在本领域定义。
- 正式实现代码、实际 migration 和运行时配置不在本仓库定义。
