# AI Chatting Context

## 1. 领域职责

`ai-chatting` 提供围绕素材、任务、代码说明、翻译和日常问答的连续 AI 对话工作区。它管理话题、消息、助手、生成运行、分支续聊、快捷短语、图片附件和翻译展示，并消费 User Model 投影、通过 Model Gateway 执行生成。

## 2. 核心对象

- `Topic`：当前用户的连续会话、标题和上下文边界。
- `Message`：用户、助手或系统消息及其分支关系和历史快照。
- `GenerationRun`：一次模型生成、流式状态、中止、错误和重生成记录。
- `Assistant`：系统或用户助手预设、系统提示和建议模型。
- `QuickPhrase`：当前用户或助手范围的快捷输入内容。
- `ImageAttachmentInput`：经权限校验的图片附件输入引用。
- `MessageTranslation`：输入或消息的翻译展示，不改写原消息事实。
- `ModelSettingsModelRef`：来自 user-model 的非敏感模型投影与 Gateway 派生能力。

## 3. 核心规则

- Topic、消息、助手和快捷短语按 owner 与可见性隔离，不得跨用户泄漏。
- AI Chat API 使用已登记的 `ai_chat.*` 权限码；`USER`、`ADMIN`、`SUPER_ADMIN` 默认获得对应基础操作权限，但权限不扩大 owner、作用域或 Topic 可见性边界。
- 发送消息必须固定所用模型、助手、上下文和输入快照，历史不能被后续配置改写。
- token/delta/done/failed/interrupted 流属于聊天请求协议，不进入通用 SSE UserEvent 历史。
- 停止、重生成和编辑后重生成保留原消息与分支追溯，不覆盖既有历史。
- Assistant 可建议模型，但实际模型必须来自当前用户可用的 user-model 投影。
- GenerationRun 执行前必须解析 UserModelExecutionContext，再通过 Model Gateway 执行，并保存模型、能力和配置版本快照。
- 图片附件只保存受控素材引用和必要快照，不复制 Asset 生命周期或任意 URL。
- 翻译结果是派生展示，原始输入和消息正文保持可追溯。
- 后台完成提醒可投影为通知，但 Notification 已读和聚合不归本领域。

## 4. 领域边界

本领域拥有对话、消息、生成运行、助手、快捷短语和翻译语义。用户模型与健康状态归 user-model，Provider Adapter 与 Operation 执行归 modelgateway；素材内容与权限归 asset-library；通用实时 UserEvent 归 sse；用户通知归 notification-center；身份和授权基础归 identity。

## 5. 上游与下游

上游包括 identity 当前用户、user-model 的可用模型投影与执行上下文、modelgateway 的统一执行入口和 asset-library 的受控附件。下游是 Web 流式响应，以及按合同消费生成完成事件的通知或其他投影。跨域引用最多展开一跳并执行源领域权限。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/ai-chatting/product-spec.md` | S1 | 对话、生成、助手、附件和翻译语义 |
| `01_contracts/domains/ai-chatting/openapi.yaml` | S2 | Topic、Message、Assistant 与生成 API |
| `01_contracts/domains/ai-chatting/schema.sql` | S2 | 设计态会话与消息结构 |
| `01_contracts/domains/ai-chatting/events.yaml` | S2 | 对话和生成事件合同 |
| `01_contracts/domains/ai-chatting/module-contract.md` | S2 | 模型、素材和生成模块边界 |
| `02_architecture/domains/ai-chatting.md` | 参考 | 生成链路、状态与外部依赖 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改会话、消息或分支 | S1 product-spec | 涉及接口或数据时读 OpenAPI/Schema |
| 修改助手或快捷短语 | S1 product-spec | 涉及权限或事件时读相应 S2 |
| 修改模型选择 | 当前 Context | 再读 user-model Context；涉及执行再读 modelgateway Context |
| 修改图片附件或素材引用 | 当前 Context | 再读 asset-library Context |

## 8. 当前状态

AI 对话、助手、模型引用、流式生成和附件已有 S1/S2 与发布记录并正在实施。具体正式能力和门禁以 `RELEASE.md` 为准；仓库实际领域名为 `ai-chatting`，不另建 `ai-chat` 别名目录。

## 9. 不在本领域定义的内容

- 用户模型 Provider、密钥、健康检测和默认模型不在本领域定义；Provider Adapter 和 Operation 执行也不在本领域定义。
- Asset、Blob、Representation 和素材生命周期不在本领域定义。
- 通用 SSE 重放、Notification 已读和聚合不在本领域定义。
- 外部模型服务内部实现、计费和可用性承诺不在本领域定义。
