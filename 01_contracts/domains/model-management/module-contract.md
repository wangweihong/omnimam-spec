# model-management 模块契约

本文档定义 `model-management` S2 模块边界。产品语义以 `00_product/domains/model-management/product-spec.md` 为准。

## 模块职责

- `provider` 负责当前用户模型提供商的查询、创建、编辑、删除和连接检测。
- `model` 负责当前用户提供商下模型清单的同步、手动添加、编辑、删除和单模型检测。
- `default-model` 负责当前用户 `assistant.default`、`quick`、`translation` 默认模型配置。
- `health` 负责记录提供商和模型健康检测结果，并更新模型健康状态。
- `option` 负责向 ai-chatting、翻译和快捷任务等下游提供只读模型选项。

## 不负责

- 不提供平台级共享模型配置。
- 不跨用户读取、复用、修改或删除模型配置。
- 不直接执行真实文本生成、翻译、图片理解或其他模型推理任务。
- 不维护 ai-chatting 的话题、消息、助手或 generation 生命周期。

## 输入与输出

| 模块 | 输入 | 输出 |
| --- | --- | --- |
| provider | 当前用户、提供商表单、检测请求 | ModelProvider、HealthCheckResult |
| model | 当前用户、providerId、远端同步结果、手动模型表单 | ProviderModel、ModelSyncResult |
| default-model | 当前用户、usage、providerId、modelId | DefaultModelConfig |
| option | 当前用户、usage、capability | 当前用户可用 ProviderModel 列表 |

## 依赖与被依赖

- 依赖 identity 或统一登录态提供当前用户身份。
- 被 ai-chatting 依赖，用于读取当前用户可用模型、默认模型、capability 和健康状态。
- 被翻译、快捷任务等下游功能依赖，用于读取默认模型和模型选项。

## 跨模块调用规则

- 下游只能通过只读查询能力读取当前用户模型选项和默认模型配置。
- ai-chatting 不得创建、同步、编辑或删除模型提供商和模型清单。
- 默认模型候选必须来自当前用户已启用提供商下的模型；unhealthy 模型不得被下游选中或调用。
- ProviderModel 的 `provider_id` 必须同时返回 `provider_name`，列表、同步结果、默认模型和 option 复用同一 ProviderModel 投影并按 owner 批量组合，禁止客户端逐模型补查 Provider。
- `owner_user_id` 只表达当前登录用户的数据隔离边界；DefaultModelConfig 已内嵌 model，HealthCheckResult 由当前检测 endpoint 目标上下文解析，这些 ID 不再重复展开关联摘要。

## 数据归属与权限边界

- 所有模型提供商、模型清单、默认模型配置和 API 密钥引用均归属于当前用户。
- 后端所有读写必须以当前用户作为 ownerUserId 边界。
- 当前 S2 不引入平台管理员共享模型语义。

## 事件边界

- 事件用于内部一致性和下游刷新，不替代查询事实。
- 事件失败不得回滚模型配置事实；下游必须能够通过查询接口恢复。

## 相关 S1 引用

- user_stories: US-USER-MODEL-01, US-USER-MODEL-02, US-USER-MODEL-03, US-USER-MODEL-04, US-USER-MODEL-05, US-USER-MODEL-06, US-USER-MODEL-07, US-USER-MODEL-08, US-USER-MODEL-09, US-USER-MODEL-10, US-USER-MODEL-11, US-USER-MODEL-12, US-USER-MODEL-13, US-USER-MODEL-14
- business_rules: BR-USER-MODEL-01, BR-USER-MODEL-02, BR-USER-MODEL-03, BR-USER-MODEL-04, BR-USER-MODEL-05, BR-USER-MODEL-06, BR-USER-MODEL-07, BR-USER-MODEL-08, BR-USER-MODEL-09, BR-USER-MODEL-10, BR-USER-MODEL-11, BR-USER-MODEL-12, BR-USER-MODEL-13, BR-USER-MODEL-14, BR-USER-MODEL-15, BR-USER-MODEL-16, BR-USER-MODEL-17, BR-USER-MODEL-18, BR-USER-MODEL-19, BR-USER-MODEL-20, BR-USER-MODEL-21, BR-USER-MODEL-22, BR-USER-MODEL-23, BR-USER-MODEL-24, BR-USER-MODEL-25, BR-USER-MODEL-26, BR-USER-MODEL-27, BR-USER-MODEL-28, BR-USER-MODEL-29, BR-USER-MODEL-30, BR-USER-MODEL-31
