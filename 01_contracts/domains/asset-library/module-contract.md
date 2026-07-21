# 用户素材管理模块契约

## 1. 模块边界

| 模块 | 职责 | S1 来源 |
| --- | --- | --- |
| `asset` | 维护用户素材 metadata、`sha256`、上传去重命中、轻量引用摘要和素材返回 | `US-USER-ASSET-31`、`US-USER-ASSET-40`、`BR-USER-ASSET-41`、`BR-USER-ASSET-42`、`BR-USER-ASSET-57`、`BR-USER-ASSET-58` |
| `upload` | 维护普通/分片上传会话、分片校验、StorageAdapter 写入、完成事务和取消清理 | `US-USER-ASSET-05`..`US-USER-ASSET-09`、`US-USER-ASSET-31`、`BR-USER-ASSET-11`..`BR-USER-ASSET-19`、`BR-USER-ASSET-41`、`BR-USER-ASSET-42` |
| `content-access` | 沿 Representation 所属链路执行所有权校验，提供受控读取、下载和短期访问地址 | `US-USER-ASSET-11`..`US-USER-ASSET-13`、`BR-USER-ASSET-07`、`BR-USER-ASSET-21`..`BR-USER-ASSET-23`、`BR-USER-ASSET-27` |
| `labeling` | 维护素材 Labels/Tags、来源、字段约束、数量上限和逐项批量写入 | `US-USER-ASSET-19`..`US-USER-ASSET-30`、`BR-USER-ASSET-35`、`BR-USER-ASSET-36`、`BR-USER-ASSET-40` |
| `selector-parser` | 将受限统一选择器解析、校验并规范化为查询 AST，不生成或执行 SQL | `US-USER-ASSET-03`、`US-USER-ASSET-20`、`US-USER-ASSET-22`、`US-USER-ASSET-24`、`US-USER-ASSET-28`、`BR-USER-ASSET-37`、`BR-USER-ASSET-39` |
| `natural-language-resolver` | 将自然语言转换为候选结构化条件，或明确返回“无结构化意图” | `US-USER-ASSET-04`、`BR-USER-ASSET-09`、`BR-USER-ASSET-10` |
| `group` | 维护素材分组、分组排序、素材与分组的多对多关联 | `US-USER-ASSET-34`..`US-USER-ASSET-39`、`BR-USER-ASSET-49`..`BR-USER-ASSET-56` |
| `artifact` | 维护跨应用、画布和 AtomicTask 的 Artifact 身份、owner、受控内容、处理、保留、登记状态与源事件 | `US-USER-ASSET-42`、`US-USER-ASSET-45`、`BR-USER-ASSET-64`..`BR-USER-ASSET-68`、`BR-USER-ASSET-76`..`BR-USER-ASSET-78` |
| `artifact-registration` | 在同一事务中将 ready Artifact 登记为 Asset/AssetVersion，复用 Blob 创建 original Representation | `US-USER-ASSET-41`、`US-USER-ASSET-43`、`BR-USER-ASSET-65`..`BR-USER-ASSET-69` |
| `representation` | 维护 expected policy、AssetRepresentation、build request、状态汇总和 backfill 缺口 | `US-USER-ASSET-43`..`US-USER-ASSET-45`、`BR-USER-ASSET-69`..`BR-USER-ASSET-77` |
| `processing-task` | 解释 Representation build、backfill 和 `sha256_backfill` 的业务语义；执行由 Task Center 完成 | `US-USER-ASSET-09`、`US-USER-ASSET-32`、`US-USER-ASSET-43`、`US-USER-ASSET-44` |

## 2. SHA256 计算与去重

- 素材库负责按 S1 规则计算原始内容 SHA256 checksum，并写入 `user_assets.sha256`。
- 上传前重复命中、跳过二进制上传和返回已存在素材属于 `asset` 模块职责。
- `sha256` 为空的素材不参与重复命中判断。

## 3. SHA256 Backfill 协作

- 任务中心可以周期性触发 `asset.sha256_backfill` AtomicTask。
- 素材库负责解释 `asset.sha256_backfill` 的业务语义，包括扫描缺失 `sha256` 的素材、读取内容、计算 checksum、更新 metadata 和汇总失败结果。
- 任务中心只负责 AtomicTask 调度、状态、重试和运行记录，不直接读取素材内容或计算 checksum。

## 3.1 上传派生任务协作

- `POST /api/v1/asset-uploads` 每个 item 独立创建会话或返回当前用户可见的 SHA256 去重命中；客户端不得指定 owner。
- `single` 与 `chunked` 共用 `/asset-uploads/{upload_id}/content`。chunked 写入必须校验 part_number、Content-Range、分片 SHA256、完整大小和最终 SHA256；第一阶段不启用 S3/MinIO presign。
- 上传取消只清理当前用户会话和未登记临时内容；完成后会话不可取消，重复 complete 必须幂等返回同一 Asset/AssetVersion。
- 素材上传或 Artifact 登记事务必须同步创建 original Representation，并写 `asset_version_representation_requested` outbox；事务回滚时不得发布事件。
- Task Center 按 `asset-representations:<asset_version_id>:<profile_version>` 幂等创建 Representation build DAGTaskGroup。
- inspect 后只创建 asset-library 计划中需要的 generate 节点；节点使用 `representation_type + profile` 稳定 childKey。
- AtomicTask 只保存 AssetVersion/Representation/Blob 引用，Representation 事实由 asset-library 拥有。

## 4. 素材分组

- 对外 API 使用 S1 术语 `Collection`/`CollectionItem`；设计态表沿用 `user_asset_groups`/`user_asset_group_memberships`，两者是同一产品对象，不得形成两套事实源。
- `group` 模块负责创建、重命名、删除和排序当前用户自己的素材分组。
- `group` 模块负责维护素材与分组的关联关系；同一素材可加入多个分组，同一素材重复加入同一分组时忽略重复添加。
- 删除分组只删除分组及其关联关系，不删除 `user_assets` 中的素材本体。
- 分组内素材默认按加入时间倒序展示；手动排序写入 `user_asset_group_memberships.sort_order`。
- 父子层级最大深度为 8，不允许环或跨用户父节点；`pinned_version_id` 必须属于同一成员 Asset。
- 视图模式偏好属于前端本地呈现状态，不进入服务端 S2 契约。

## 5. 轻量引用摘要

- `asset` 模块负责保存素材的 `reference_count` 和 `reference_sources_json`。
- 画布等外部模块可以通过回调或等价协作方式维护引用摘要。
- 引用摘要用于前端提示和详情展示，不作为强一致权限判断、删除保护或完整依赖图事实源。

## 5.0 关联资源可读投影

- UserAsset 列表和写动作返回 `current_version`；Collection 返回 `parent_collection`，CollectionItem 返回 `pinned_version`；AssetRelation 返回 `source_asset` 与 `target_asset`。这些同域关系按 owner 批量读取，目标删除或不可见时保留 ID 并省略摘要。
- Artifact 返回 producer 及可用的 AtomicTask、ApplicationRun、CanvasRun 一跳摘要；跨领域摘要只能通过 Task Center、application-platform、workflow-canvas 的受控批量只读能力或创建时非敏感快照获取，禁止查询目标领域私有表。
- Artifact 登记后的 `asset_id`、`asset_version_id` 同时返回同域摘要。`task_attempt_id`、`node_run_id`、`node_id` 是所属任务/运行内的审计定位字段，由已返回的父任务或运行上下文解析，不再递归展开。
- 所有列表查询次数必须与行数无关；摘要不返回任务参数、运行输入输出、canonical 内容、metadata、凭证或受保护 URL。

## 5.1 删除与回收站

- `DELETE /api/v1/assets/{asset_id}` 只设置 `status=deleted` 与 `deleted_at`，保留 AssetVersion、Representation、Blob、来源和引用。
- `POST /api/v1/assets/{asset_id}/restore` 只恢复当前用户已软删除素材；不得借恢复绕过所有权或 canWrite 校验。
- 永久删除先向画布、应用、Task Center、Collection 和素材关系的事实源执行强引用检查；`reference_count` 与 `reference_sources_json` 仅用于提示，不能单独授权删除。
- 只有未被任何 Representation 或 Artifact 引用的 Blob 才物理删除；部分 Blob 仍被共享时返回 retained_blob_ids。

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

## 10. Artifact 与 Asset 登记

- 受信 ApplicationExecutor、画布执行器或 Worker 通过 `POST /api/v1/artifacts` 和受控内容上传端点创建 Artifact；owner 由服务端上下文解析。
- Artifact producer key 在 owner 范围唯一；同一 AtomicTask 自动 Attempt 重试复用同一 Artifact，冲突内容返回稳定幂等错误。
- ApplicationExecutor 负责 Provider 协议和下载，只能推送字节流、受控上传会话或可信存储引用，不得传递凭证、任意 URL、私网地址或原始响应。
- `POST /api/v1/artifacts/{artifact_id}/register` 只接受 ready Artifact；同一事务创建或命中 Asset/AssetVersion、复用 Blob 创建 original Representation、更新登记状态并写 outbox。
- 登记失败由 asset-library Artifact 保存；不得创建空 AssetVersion，也不得改变 AtomicTask 终态。
- `POST /api/v1/artifact-registrations` 是兼容入口，行为和事实源与 canonical register 动作相同。
- Artifact complete 事务写 `artifact_content_completed`；Task Center 按 `artifact-process:<artifact_id>:<processing_profile_version>` 幂等创建 `asset-library.artifact.process` AtomicTask。handler 只接收 Artifact/profile 引用，并通过 asset-library 受控能力读写内容和状态。

## 10.1 Representation Build

- asset-library 根据媒体类型、policy 和 profile version 形成 expected set；Task Center 不得自行增加或删除派生类型。
- 首次生成使用 DAGTaskGroup，周期补全使用相同 `asset-library.representation.generate` handler 的独立 AtomicTask。
- Worker 只能通过 `asset.representation.write` 幂等写入所请求的 type/profile；相同键不同 Blob 返回冲突。
- 必需项失败使 AssetVersion failed；可选项失败使其 ready_with_warnings；缺口补齐后允许提升为 ready。

## 10.2 Representation Backfill

- asset-library 向 Task Center ReconcileRegistry 注册 `asset-library.representation-backfill`，Task Center 以同名 system_key 创建唯一 SYSTEM RECONCILE TaskSchedule。
- 默认每日 `03:30 UTC`，按稳定 AssetVersion ID checkpoint 分块扫描；健康项不创建任务，重叠轮次跳过。
- 缺失、可重试或可重建项返回 `asset-library.representation.generate` AtomicTask 动作，幂等键为 `asset-representation:<asset_version_id>:<representation_type>:<profile_version>`。
- 删除中、transient 或源内容不可恢复的条目不创建任务；不可恢复项记录稳定原因。巡检限制扫描、action、并发和失败退避。
- 摘要包含 scanned、missing、actions_created、deferred、irreparable、repaired；checkpoint 只在完整分块完成后推进。

## 11. 兼容与迁移边界

- `schema.sql` 只表达目标设计，不是实际 migration。实现从旧标签 JSON 切换时，必须先 trim、校验并回填到规范化表，再切换读写，最后停止读取旧字段。
- 回填遇到大小写不同的 Label key 或 Tag 时必须保留为不同值；超出数量上限或字段约束的数据进入迁移异常报告，不得静默丢弃或折叠。
- 普通素材读取、创建、更新、删除、内容读取、上传、Collection、标签和引用摘要分别使用 `asset.*` 权限；所有后端操作仍必须执行 owner 与 `canWrite` 校验，前端隐藏不替代鉴权。
- Artifact 创建、登记、删除和 Representation 写入分别使用受控权限并发布 asset-library 源事件。

## 12. S2 最小契约说明

OpenAPI 覆盖 S1 第 23 章全部 41 个显式 endpoint，并保留批量打标、Representation 列表/Worker 登记和 Artifact 兼容登记扩展入口。所有 operation 必须包含 `x-permission` 与 `x-s1-refs`；未 release 的本轮修订不得作为正式实现依据。
