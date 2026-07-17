# 用户素材管理模块契约

## 1. 模块边界

| 模块 | 职责 | S1 来源 |
| --- | --- | --- |
| `asset` | 维护用户素材 metadata、`sha256`、上传去重命中、轻量引用摘要和素材返回 | `US-USER-ASSET-31`、`US-USER-ASSET-40`、`BR-USER-ASSET-41`、`BR-USER-ASSET-42`、`BR-USER-ASSET-57`、`BR-USER-ASSET-58` |
| `labeling` | 维护素材 Labels/Tags、来源、字段约束、数量上限和逐项批量写入 | `US-USER-ASSET-19`..`US-USER-ASSET-30`、`BR-USER-ASSET-35`、`BR-USER-ASSET-36`、`BR-USER-ASSET-40` |
| `selector-parser` | 将受限统一选择器解析、校验并规范化为查询 AST，不生成或执行 SQL | `US-USER-ASSET-03`、`US-USER-ASSET-20`、`US-USER-ASSET-22`、`US-USER-ASSET-24`、`US-USER-ASSET-28`、`BR-USER-ASSET-37`、`BR-USER-ASSET-39` |
| `natural-language-resolver` | 将自然语言转换为候选结构化条件，或明确返回“无结构化意图” | `US-USER-ASSET-04`、`BR-USER-ASSET-09`、`BR-USER-ASSET-10` |
| `group` | 维护素材分组、分组排序、素材与分组的多对多关联 | `US-USER-ASSET-34`..`US-USER-ASSET-39`、`BR-USER-ASSET-49`..`BR-USER-ASSET-56` |
| `processing-task` | 维护缩略图、派生预览和 `sha256_backfill` 的业务结果；执行由 task-center AtomicTask 完成 | `US-USER-ASSET-09`、`US-USER-ASSET-32`、`BR-USER-ASSET-19`、`BR-USER-ASSET-43` |
| `artifact-registration` | 校验 application-platform Artifact 并幂等登记 UserAsset | `US-USER-ASSET-41`、`BR-USER-ASSET-59`..`BR-USER-ASSET-63` |

## 2. SHA256 计算与去重

- 素材库负责按 S1 规则计算原始内容 SHA256 checksum，并写入 `user_assets.sha256`。
- 上传前重复命中、跳过二进制上传和返回已存在素材属于 `asset` 模块职责。
- `sha256` 为空的素材不参与重复命中判断。

## 3. SHA256 Backfill 协作

- 任务中心可以周期性触发 `asset.sha256_backfill` AtomicTask。
- 素材库负责解释 `asset.sha256_backfill` 的业务语义，包括扫描缺失 `sha256` 的素材、读取内容、计算 checksum、更新 metadata 和汇总失败结果。
- 任务中心只负责 AtomicTask 调度、状态、重试和运行记录，不直接读取素材内容或计算 checksum。

## 3.1 上传派生任务协作

- 素材上传完成事务必须同时写 `asset_uploaded` outbox 记录，事务回滚时不得发布事件。
- task-center 消费事件并按 `thumbnail:<asset_id>:<profile_version>` 幂等创建 `asset.thumbnail.generate` AtomicTask。
- 重复投递不得创建重复 AtomicTask；缩略图失败不回滚素材上传，也不阻塞素材列表。
- AtomicTask 只保存 asset/profile 输入和结果引用，缩略图事实仍由 `preview` 模块拥有。

## 4. 素材分组

- `group` 模块负责创建、重命名、删除和排序当前用户自己的素材分组。
- `group` 模块负责维护素材与分组的关联关系；同一素材可加入多个分组，同一素材重复加入同一分组时忽略重复添加。
- 删除分组只删除分组及其关联关系，不删除 `user_assets` 中的素材本体。
- 分组内素材默认按加入时间倒序展示；手动排序写入 `user_asset_group_memberships.sort_order`。
- 视图模式偏好属于前端本地呈现状态，不进入服务端 S2 契约。

## 5. 轻量引用摘要

- `asset` 模块负责保存素材的 `reference_count` 和 `reference_sources_json`。
- 画布等外部模块可以通过回调或等价协作方式维护引用摘要。
- 引用摘要用于前端提示和详情展示，不作为强一致权限判断、删除保护或完整依赖图事实源。

## 6. 标签数据归属与约束

- `user_asset_labels` 和 `user_asset_tags` 是素材标签事实源；`user_assets` 不保存重复的标签 JSON 快照。
- 标签表通过 `(owner_user_id, asset_id)` 复合外键绑定同一用户素材；通用资源字段 `name` 只镜像 `label_key` 或 `tag` 并由 SQL CHECK 保持一致，不是独立标签值。
- Label key/value 和 Tag 写入前均 trim，按 Unicode code point 校验长度并区分大小写；实现不得使用 `lower()` 或等价大小写折叠参与匹配和去重。
- Label 同一素材同 key 只保留一条有效记录；Tag 同一素材同值只保留一条有效记录。有效记录数量上限分别为 20 和 30，由 `labeling` 在同一素材事务中校验。
- 自动生成或建议采纳写入 `source=auto`；任何用户手动添加或覆盖写入 `source=manual`。
- 上传会话的 `pending_labels_payload`、`pending_tags_payload` 仅保存尚未完成上传的临时输入；完成登记时必须交由 `labeling` 规范化写入标签事实表，不得成为第二事实源。

## 7. Selector Parser 契约

- parser 输入最大 4096 字符，输出受类型约束的 AST；最大嵌套深度 8、谓词总数 100，单个 `in/notin` 最多 100 个非空值。
- AST 节点只允许 Label、Tag、`@group`、AND、OR；AND 优先于 OR，括号覆盖优先级。`group` 不是保留 Label key，只有 `@group` 表示分组。
- 空 Label value 只接受 `key=""`。含空白或保留字符的 value、Tag、分组名使用 JSON 风格双引号和转义。
- parser 返回规范化 selector 或带位置、实际 token、预期 token 的 `asset_selector_invalid`；超出复杂度限制返回 `asset_selector_too_complex`。
- parser 不接收 owner_user_id，不查询数据库，不拼接 SQL。查询模块只把 AST 编译为参数化查询条件。

## 8. 查询与自然语言降级

- 查询模块必须先从已校验的 Bearer Token 注入 `owner_user_id` 和 `deleted_at IS NULL` 基础范围，再组合 selector、keyword、精确过滤和排序条件；任何分支不得移除该基础范围。
- `selector` 与 `natural_language_query` 互斥；`natural_language_query` 还与 `keyword` 互斥。keyword、selector、精确过滤之间按 AND 组合。
- natural-language-resolver 只允许返回：合法候选结构化条件、明确的“无结构化意图”，或解析失败。
- 候选结构化条件必须再次经过 selector-parser 校验后才能查询。明确“无结构化意图”时，才可降级模糊匹配 `display_name`、`original_name`、`description`。
- resolver 无法形成合法结构化条件或候选 selector 非法时返回 `asset_search_parse_failed`；resolver 超时、异常或不可用时返回 `asset_search_dependency_failed`；查询执行失败时返回 `asset_list_failed`。这些场景均不得关键词降级。
- 列表响应通过 `query_resolution` 披露请求模式、实际模式和可选规范化 selector；不得暴露解析器内部提示词、模型响应或 SQL。

## 9. 批量打标事务边界

- `POST /api/v1/assets/batch-labels` 先进行请求级校验：1-100 个不重复的 `{id}`、至少一项标签变更、Tag 添加与删除集合无交集。
- 通过请求级校验后，每个素材使用独立事务校验存在性、当前用户所有权、软删除状态、可写状态和变更后数量上限。
- Label upsert、Tag add/remove 均为幂等写入；单项提交后递增该素材 `resource_version`，返回完整标签结果。
- 单项失败仅回滚该素材事务并写入对应 result.error，不影响其他素材；不得通过错误差异泄露其他用户素材是否存在。

## 10. Application Artifact 登记

- `POST /api/v1/artifact-registrations` 仅接收 application-platform 产生的 Artifact，并要求 Artifact、ApplicationRun、运行发起用户、输出名、媒体类型和内容引用完整。
- 素材库校验 owner、内容可读性和媒体信息后，在同一事务内创建 `source_type=application_output` 的 UserAsset 与 `artifact_asset_registrations` 成功映射。
- `artifact_id` 全局唯一；完全相同的重复请求返回既有 UserAsset，内容、owner 或 ApplicationRun 不一致时返回幂等冲突。
- 校验失败不创建 UserAsset 或成功映射；失败原因由 application-platform Artifact 保存，且不得改变 AtomicTask 终态。
- UserAsset 和成功登记映射归 asset-library 所有；Artifact、ApplicationRun、AtomicTask 状态归各自领域所有，素材库不得反向改写。

## 11. 兼容与迁移边界

- `schema.sql` 只表达目标设计，不是实际 migration。实现从旧标签 JSON 切换时，必须先 trim、校验并回填到规范化表，再切换读写，最后停止读取旧字段。
- 回填遇到大小写不同的 Label key 或 Tag 时必须保留为不同值；超出数量上限或字段约束的数据进入迁移异常报告，不得静默丢弃或折叠。
- 素材查询与标签操作继续沿用当前登录用户、所有权和 `canWrite` 语义；Artifact 登记使用 `asset.artifact.register` 跨域权限并发布 `artifact_registered` 事件。

## 12. S2 最小契约说明

本次 OpenAPI 覆盖素材列表查询、批量打标和 Application Artifact 登记；上传、预览、下载、重命名、删除及完整分组管理 API 仍是后续 S2 缺口。
