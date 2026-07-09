# Error Code Index

本文档登记所有 domain 的错误码文件位置和错误码区间。

## 1. Domain 错误码文件索引

| Domain | 错误码文件 | 说明 |
| --- | --- | --- |
| ai-chatting | `01_contracts/domains/ai-chatting/errors.yaml` | AI 聊天话题、消息、助手、生成、翻译和访问控制错误码 |
| model-management | `01_contracts/domains/model-management/errors.yaml` | 用户模型提供商、模型清单、默认模型、健康检测和访问控制错误码 |
| application-platform | `01_contracts/domains/application-platform/errors.yaml` | AI 应用平台第一阶段模板、应用、字段映射、应用运行和应用引擎相关错误码 |
| task-center | `01_contracts/domains/task-center/errors.yaml` | 任务中心任务定义、运行、Worker、Lease、Attempt 与权限相关错误码 |

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
| 130200-130299 | application-platform | template | 应用模板解析、唯一性、不可变与引用保护错误 |
| 130300-130399 | application-platform | field-mapping | 字段映射路径、唯一性和完整性错误 |
| 130400-130499 | application-platform | application | 应用创建、更新和删除错误 |
| 130500-130599 | application-platform | access | 权限、可见性与所有权错误 |
| 130600-130699 | application-platform | app-engine | 应用引擎可见性、认证配置和健康检测错误 |
| 140200-140399 | task-center | definition | 任务定义、TaskGroup 和 DAGFlowTask 校验错误 |
| 140400-140599 | task-center | run | TaskRun 状态、取消、重试和可见性错误 |
| 140600-140799 | task-center | worker | Worker 注册、心跳和能力匹配错误 |
| 140800-140999 | task-center | lease | ExecutionLease 获取、续约、过期和归属错误 |
| 141000-141199 | task-center | attempt | TaskAttempt 状态与结果回写错误 |
| 141200-141399 | task-center | access | 任务中心权限与访问控制错误 |

## 3. 分配规则

- 每个模块默认预留连续错误码区间；新增 domain 优先预留 200 个连续错误码。
- 新增 domain 或模块时，必须先在本文件登记区间。
- 新增错误码时，必须确认 value 落在已登记区间内。
- 已 release 的 value 不得复用。
- 废弃错误码必须在 domain `errors.yaml` 中标记 `deprecated: true`。
