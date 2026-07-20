# Error Code Index

本文档登记所有 domain 的错误码文件位置和错误码区间。

## 1. Domain 错误码文件索引

| Domain | 错误码文件 | 说明 |
| --- | --- | --- |
| ai-chatting | `01_contracts/domains/ai-chatting/errors.yaml` | AI 聊天话题、消息、助手、生成、翻译和访问控制错误码 |
| model-management | `01_contracts/domains/model-management/errors.yaml` | 用户模型提供商、模型清单、默认模型、健康检测和访问控制错误码 |
| application-platform | `01_contracts/domains/application-platform/errors.yaml` | ProviderCapability 启动加载、引擎与绑定、ComfyUI 工作流、应用契约、运行和访问错误码 |
| task-center | `01_contracts/domains/task-center/errors.yaml` | AtomicTask、Group/DAG、Schedule、运行时、Attempt 与权限错误码 |
| asset-library | `01_contracts/domains/asset-library/errors.yaml` | 素材查询、标签写入、Artifact、AssetVersion 与 Representation 错误码 |
| workflow-canvas | `01_contracts/domains/workflow-canvas/errors.yaml` | Canvas、不可变版本、运行、节点引用和访问错误码 |
| sse | `01_contracts/domains/sse/errors.yaml` | 实时连接、游标重放、事件投影和访问错误码 |

## 2. 错误码区间分配

| 区间 | Domain | Module | 说明 |
| --- | --- | --- | --- |
| 110200-110399 | ai-chatting | topic | 话题可见性、状态和分支错误 |
| 110400-110599 | ai-chatting | message | 消息输入、版本和可见性错误 |
| 110600-110799 | ai-chatting | assistant | 助手可见性、系统助手保护和唯一性错误 |
| 110800-110999 | ai-chatting | quick-phrase | 快捷短语作用域和校验错误 |
| 111000-111199 | ai-chatting | generation | generation 并发、停止、重生成和可见性错误 |
| 111200-111399 | ai-chatting | translation | 翻译默认模型和翻译状态错误 |
| 111400-111599 | ai-chatting | access | AI 聊天访问和所有权错误 |
| 120200-120399 | model-management | provider | 模型提供商可见性、唯一性和连接检测错误 |
| 120400-120599 | model-management | model | 提供商模型可见性、唯一性和模型标识错误 |
| 120600-120799 | model-management | default-model | 默认模型缺失、候选不可用和用途错误 |
| 120800-120999 | model-management | health | 模型健康检测错误 |
| 121000-121199 | model-management | access | 用户模型配置访问控制错误 |
| 130200-130399 | application-platform | provider-capability | 目录、YAML、Schema、重复 ID、执行依赖和能力可用性错误 |
| 130400-130599 | application-platform | engine | EngineInstance、鉴权、Binding、限制与健康可用性错误 |
| 130600-130799 | application-platform | application | 模板来源、不可变版本、RuntimeForm 和输入校验错误 |
| 130800-130999 | application-platform | application-run | ApplicationRun、AtomicTask 投影和平台能力不匹配错误 |
| 131000-131199 | application-platform | access | 能力诊断、Engine、Application 和 Run 访问控制错误 |
| 131200-131399 | application-platform | comfyui-workflow | ComfyUI 工作流导入、解析、实例校验、归档和模板转换错误 |
| 140200-140399 | task-center | orchestration | functionRef、TaskGroup 和 DAGTaskGroup 校验错误 |
| 140400-140599 | task-center | atomic-task | AtomicTask、Group/DAG 状态、幂等和可见性错误 |
| 140600-140799 | task-center | runtime | WorkflowRuntime 可用性和请求错误；140600 保留旧 Worker 错误 |
| 140800-140999 | task-center | legacy-lease | 已废弃 ExecutionLease 错误码保留区间 |
| 141000-141199 | task-center | attempt | TaskAttempt 状态与结果回写错误 |
| 141200-141399 | task-center | access | 任务中心权限与访问控制错误 |
| 141400-141599 | task-center | schedule | TaskSchedule 校验、状态和可见性错误 |
| 150200-150399 | asset-library | query | 统一选择器、自然语言解析与素材列表查询错误 |
| 150400-150599 | asset-library | labeling | Label/Tag 校验、数量限制与批量打标错误 |
| 150600-150799 | asset-library | access | 素材所有权、删除状态与可写性错误 |
| 150800-150999 | asset-library | artifact-registration | Artifact 所有权、受控内容、状态与幂等登记错误 |
| 151000-151199 | asset-library | representation | AssetRepresentation 计划、写入、不可恢复与 backfill 错误 |
| 160200-160399 | workflow-canvas | canvas | Canvas 草稿、图、引用和规模错误 |
| 160400-160599 | workflow-canvas | version | CanvasVersion 查询、编译和发布错误 |
| 160600-160799 | workflow-canvas | run | CanvasRun 状态、幂等和可见性错误 |
| 160800-160999 | workflow-canvas | access | 工作流画布权限与访问控制错误 |
| 170200-170399 | sse | stream | 连接上限与实时流可用性错误 |
| 170400-170599 | sse | replay | 恢复游标冲突、不可见与过期错误 |
| 170600-170799 | sse | projection | 上游事件字段与版本投影错误 |
| 170800-170999 | sse | access | 实时流与历史事件访问控制错误 |

## 3. 分配规则

- 每个模块默认预留连续错误码区间；新增 domain 优先预留 200 个连续错误码。
- 新增 domain 或模块时，必须先在本文件登记区间。
- 新增错误码时，必须确认 value 落在已登记区间内。
- 已 release 的 value 不得复用。
- 废弃错误码必须在 domain `errors.yaml` 中标记 `deprecated: true`。
