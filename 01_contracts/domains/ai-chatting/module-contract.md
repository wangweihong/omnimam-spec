# ai-chatting 模块契约

本文档定义 `ai-chatting` S2 模块边界。产品语义以 `00_product/domains/ai-chatting/product-spec.md` 为准。

## 模块职责

- `topic` 负责当前用户话题列表、话题详情、置顶、当前助手、当前模型引用和分支来源。
- `message` 负责消息创建、消息列表、版本关系、父消息关系、模型快照和助手快照。
- `generation` 负责聊天/翻译 GenerationRun 生命周期、模型/能力/配置版本快照、SSE 增量事件、停止、重新生成和编辑后重生成。
- `assistant` 负责助手创建、编辑、删除保护和建议模型引用。
- `quick-phrase` 负责全局和助手级快捷短语。
- `translation` 负责输入区或消息内容翻译结果展示。

## 不负责

- 不维护独立模型配置、模型提供商或模型清单。
- 不创建独立模型配置表或同等模型事实源。
- 不提供模型创建、同步、检测、默认模型保存等能力；这些能力属于 `user-model`。
- 不实现 Provider 专用客户端、鉴权应用、Adapter 或 OperationExecutor；这些能力属于 `modelgateway`。
- 不创建 AtomicTask，不依赖 `task-center` 实现后台完成提醒。
- 不持久化图片附件原始媒体；图片附件仅作为请求输入和消息图标语义。

## 输入与输出

| 模块 | 输入 | 输出 |
| --- | --- | --- |
| topic | 当前用户、assistantId、modelId、标题、分支来源 | Topic |
| message | topicId、用户输入、图片附件输入、slashCommand | userMessage、assistantMessage |
| generation | principal、topicId、assistantMessageId、operation、模型/能力/配置版本和助手快照 | GenerationRun、SSE delta/done/failed/interrupted |
| assistant | 助手配置、suggestedModelId | Assistant |
| quick-phrase | 标题、内容、scope、assistantId | QuickPhrase |
| translation | content、targetLanguage、默认翻译模型 | MessageTranslation |

## 依赖与被依赖

- 依赖 identity 或统一登录态提供当前用户身份。
- 依赖 `user-model` 读取当前用户模型、`assistant.default`、`translation` 默认模型、只读能力、执行资格和健康状态，并解析 `UserModelExecutionContext`。
- 依赖 `modelgateway` 通过 `UserModelTarget` 执行标准 Operation。
- 被 Web `/ai-chatting` 页面依赖。

## 跨模块调用规则

- `modelId` 和 `suggestedModelId` 必须引用 `user-model.UserProviderModel.id`。
- `modelSnapshot` 只记录生成或翻译当时的模型事实快照，不代表 ai-chatting 拥有模型配置。
- Topic 和 Assistant 的模型引用通过 User Model 当前用户受控批量只读能力返回一跳摘要；Topic 与助手级 QuickPhrase 的 Assistant 摘要由 ai-chatting 同域批量读取。关联缺失或不可见时保留原 ID、摘要为空，列表不得逐行补查。
- Message 的模型/助手快照是历史展示事实；同 Topic 父消息、Generation 对应消息和 MessageTranslation 来源均由当前操作响应上下文解析，明确不递归展开。
- AI Chat 只使用 `capability_definition_ids` 判断执行能力，不使用 `feature_labels` 扩张能力；`chat`、`translate` 和携带图片的聊天分别要求 `text.chat_completion`、`text.translate` 和 `image.understanding`。
- 每次执行先调用 `ResolveUserModelExecutionContext(principal, modelId, capabilityDefinitionId)`；跨用户、停用、非 healthy、能力不匹配或配置版本失效时不得创建 Provider 调用。
- 解析成功后以 `UserModelTarget` 调用 Gateway `ExecuteOperation`。AI Chat 不提交客户端构造的 Provider 地址、凭证、Adapter ID 或 Executor ID。
- GenerationRun 必须保存 `model_id`、`capability_definition_id`、`model_config_version` 和非敏感 `model_snapshot_json`；Gateway 返回只推进 AI Chat 自有状态。
- 后台完成提醒由 ai-chatting generation 状态和应用内 UI 提醒实现，不创建 task-center AtomicTask。

## 数据归属与权限边界

- Topic、Assistant、Message、QuickPhrase、GenerationRun、MessageTranslation 均按 ownerUserId 或所属 Topic 的 ownerUserId 隔离。
- S2 使用 `ai_chat.*` 业务权限控制工作区、话题、消息、生成、助手、快捷短语和翻译操作。`USER`、`ADMIN`、`SUPER_ADMIN` 默认获得对应基础权限，但权限判定之后仍必须按 owner_user_id、作用域和 Topic 归属裁剪资源；本轮不提供跨用户代管权限。

## 事件边界

- generation 事件用于应用内提醒、SSE 状态刷新和 UI 恢复，不替代数据库状态。
- 事件失败不得回滚消息或 generation 事实。

## 相关 S1 引用

- user_stories: US-AICHAT-01, US-AICHAT-02, US-AICHAT-03, US-AICHAT-04, US-AICHAT-05, US-AICHAT-06, US-AICHAT-07, US-AICHAT-08, US-AICHAT-09, US-AICHAT-10
- business_rules: BR-AICHAT-01, BR-AICHAT-02, BR-AICHAT-03, BR-AICHAT-04, BR-AICHAT-05, BR-AICHAT-06, BR-AICHAT-07, BR-AICHAT-08, BR-AICHAT-09, BR-AICHAT-10, BR-AICHAT-11, BR-AICHAT-12, BR-AICHAT-13, BR-AICHAT-14, BR-AICHAT-15, BR-AICHAT-16, BR-AICHAT-17, BR-AICHAT-18, BR-AICHAT-19, BR-AICHAT-20, BR-AICHAT-21, BR-AICHAT-22, BR-AICHAT-23, BR-AICHAT-24, BR-AICHAT-25, BR-AICHAT-26, BR-AICHAT-27, BR-AICHAT-28
