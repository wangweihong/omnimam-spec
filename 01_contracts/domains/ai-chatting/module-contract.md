# ai-chatting 模块契约

本文档定义 `ai-chatting` S2 模块边界。产品语义以 `00_product/domains/ai-chatting/product-spec.md` 为准。

## 模块职责

- `topic` 负责当前用户话题列表、话题详情、置顶、当前助手、当前模型引用和分支来源。
- `message` 负责消息创建、消息列表、版本关系、父消息关系、模型快照和助手快照。
- `generation` 负责聊天/翻译 generation 生命周期、SSE 增量事件、停止、重新生成、编辑后重生成。
- `assistant` 负责助手创建、编辑、删除保护和建议模型引用。
- `quick-phrase` 负责全局和助手级快捷短语。
- `translation` 负责输入区或消息内容翻译结果展示。

## 不负责

- 不维护独立模型配置、模型提供商或模型清单。
- 不创建独立模型配置表或同等模型事实源。
- 不提供模型创建、同步、检测、默认模型保存等能力；这些能力属于 `model-management`。
- 不创建 TaskRun，不依赖 `task-center` 实现后台完成提醒。
- 不持久化图片附件原始媒体；图片附件仅作为请求输入和消息图标语义。

## 输入与输出

| 模块 | 输入 | 输出 |
| --- | --- | --- |
| topic | 当前用户、assistantId、modelId、标题、分支来源 | Topic |
| message | topicId、用户输入、图片附件输入、slashCommand | userMessage、assistantMessage |
| generation | topicId、assistantMessageId、operation、模型和助手快照 | GenerationRun、SSE delta/done/failed/interrupted |
| assistant | 助手配置、suggestedModelId | Assistant |
| quick-phrase | 标题、内容、scope、assistantId | QuickPhrase |
| translation | content、targetLanguage、默认翻译模型 | MessageTranslation |

## 依赖与被依赖

- 依赖 identity 或统一登录态提供当前用户身份。
- 依赖 `model-management` 读取当前用户可用模型、`assistant.default`、`translation` 默认模型、capability 和健康状态。
- 被 Web `/ai-chatting` 页面依赖。

## 跨模块调用规则

- `modelId` 和 `suggestedModelId` 必须引用 `model-management.UserProviderModel.id`。
- `modelSnapshot` 只记录生成或翻译当时的模型事实快照，不代表 ai-chatting 拥有模型配置。
- 当前选中模型 unhealthy 时不得发送、重新生成、编辑后重生成或携带图片附件发送。
- 后台完成提醒由 ai-chatting generation 状态和应用内 UI 提醒实现，不创建 task-center TaskRun。

## 数据归属与权限边界

- Topic、Assistant、Message、QuickPhrase、GenerationRun、MessageTranslation 均按 ownerUserId 或所属 Topic 的 ownerUserId 隔离。
- 当前 S2 不引入独立 `ai_chat.*` 业务权限；访问依赖登录态和当前用户个人数据隔离。

## 事件边界

- generation 事件用于应用内提醒、SSE 状态刷新和 UI 恢复，不替代数据库状态。
- 事件失败不得回滚消息或 generation 事实。

## 相关 S1 引用

- user_stories: US-AICHAT-01, US-AICHAT-02, US-AICHAT-03, US-AICHAT-04, US-AICHAT-05, US-AICHAT-06, US-AICHAT-07, US-AICHAT-08, US-AICHAT-09, US-AICHAT-10
- business_rules: BR-AICHAT-01, BR-AICHAT-02, BR-AICHAT-03, BR-AICHAT-04, BR-AICHAT-05, BR-AICHAT-06, BR-AICHAT-07, BR-AICHAT-08, BR-AICHAT-09, BR-AICHAT-10, BR-AICHAT-11, BR-AICHAT-12, BR-AICHAT-13, BR-AICHAT-14, BR-AICHAT-15, BR-AICHAT-16, BR-AICHAT-17, BR-AICHAT-18, BR-AICHAT-19, BR-AICHAT-20, BR-AICHAT-21, BR-AICHAT-22, BR-AICHAT-23, BR-AICHAT-24
