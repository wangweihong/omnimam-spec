# OmniMAM Spec Handoff

## 当前项目目标

补齐 asset-library 已发布 S1 对应的可实现 S2，使普通用户上传、素材读取与管理、Collection 和回收站能力形成 OpenAPI、权限、错误码、设计态 schema 与模块边界闭环。

## 本次完成

2026-07-20 完成 asset-library S2 补齐草案：

- OpenAPI 从 12 个扩展不完整 operation 增至 45 个 operation，完整覆盖 S1 第 23 章 41 个显式 endpoint，并保留批量标签、Representation 列表/Worker 登记和 Artifact 兼容登记 4 个扩展入口。
- 补齐 Asset canonical 创建、详情、重命名/描述/归档、软删除、恢复、永久删除与引用阻塞结果。
- 补齐普通/分片/多文件上传会话、逐文件 SHA256 去重、内容写入、完成事务与取消。
- 补齐 AssetVersion canonical 创建、详情和 current version 切换；补齐 Representation 单项详情、内容读取/下载与短期访问地址。
- 补齐 Collection CRUD、层级、批量加入、固定版本、角色、metadata、排序与移除。
- 补齐 Label/Tag 单项操作、Artifact 删除、关系、来源链、引用摘要和使用位置。
- 为全部 operation 绑定已定义的 `x-permission` 和 `x-s1-refs`。
- 新增上传、Collection、Asset 访问/版本/内容/永久删除错误，并登记 `151200-151399`、`151400-151599` 区间。

## 文件变化

- `01_contracts/domains/asset-library/openapi.yaml`
- `01_contracts/domains/asset-library/permissions.yaml`
- `01_contracts/domains/asset-library/errors.yaml`
- `01_contracts/domains/asset-library/schema.sql`
- `01_contracts/domains/asset-library/module-contract.md`
- `01_contracts/error-code-index.md`
- `CHANGELOG.md`
- `docs/HANDOFF.md`

未修改 S1、事件、架构参考或 `RELEASE.md`。工作区仍有用户原有的 `AGENTS.md` 修改，未回退或改动。

## 关键设计决策

- 普通用户二进制上传使用 AssetUpload；Artifact 上传继续只服务受信 producer，二者不互相替代。
- `POST /api/v1/assets` 和 `POST /api/v1/assets/{asset_id}/versions` 只处理 text、prompt、prompt_template canonical 内容；二进制新素材/版本统一经过 AssetUpload。
- single 与 chunked 共用 `/asset-uploads/{upload_id}/content`；chunked 使用 part_number、content_range 和 part_sha256，不启用已延期的 S3/MinIO parts/presign 路径。
- 对外使用 `Collection`/`CollectionItem`，设计态表沿用 `user_asset_groups`/`user_asset_group_memberships`；它们是同一对象，不形成双事实源。
- 回收站软删除保留版本、Representation、Blob 和引用；永久删除必须执行强引用检查，轻量 reference summary 不能授权删除。
- Bearer 认证不替代 operation 权限；前端隐藏操作也不替代 owner、canWrite 和状态校验。

## API、Schema 与配置变化

- OpenAPI 版本更新为 `0.3.0-draft`，共 34 个 path、45 个 operation、67 个 schema。
- 权限从 5 项扩展为 16 项，新增 `asset.read/create/update/delete/content.read/upload/collection.read/collection.manage/label.manage/reference.read` 和 `asset.artifact.delete`。
- asset-library 错误从 23 项扩展为 43 项；全仓错误码共 179 个，code/value 全局唯一。
- `user_asset_upload_sessions.checksum` 收敛为 `sha256`，新增 client key、MIME、目标 Asset、版本说明、profile 和 upload_mode。
- Collection 设计态表新增父节点；成员新增 pinned version、role、metadata 和 created_by。
- 未新增事件或运行时配置。

## 验证结果

- 29 份 S2 YAML 全部可解析。
- Redocly：asset-library OpenAPI valid、0 error；仅有既有 license 和 4XX 通用规则警告，业务错误按仓库规则继续使用 HTTP 200。
- 45 个 operation 均有唯一 operationId、有效权限和有效 S1 引用。
- 67 个 schema 的本地 `$ref` 全部可解析，所有 path template 参数均已声明。
- 新增 BR/US 引用均在 asset-library S1 中存在。
- 179 个全仓错误码的 code/value 全局唯一；asset-library 43 个错误全部落入登记区间并使用允许的 HTTP 状态码。
- `git diff --check` 通过。

## 待办、风险与技术债

- 本轮是对已发布 `spec-v1.5.0` 的未 Release 修订，尚不能作为正式实现、合并或验收依据。
- 实现仓库需要为上传 session 字段和 Collection 层级/成员字段设计实际 migration；本仓 `schema.sql` 不是 migration。
- 来源、引用与使用位置 API 包含跨领域聚合；实现必须从各事实源读取并过滤可见性，不能把轻量摘要升级为强一致事实源。
- S3/MinIO presign、分片直传仍属于后续阶段，不应因本轮 chunked 本地上传而提前启用。
- Redocly 的 4XX 警告与仓库 HTTP 200 业务错误规范冲突，属于预期警告。

## 推荐下一任务

评审本轮 S2 草案的 DTO 和权限粒度；确认后提交并发布新的 spec 版本，再在实现仓库设计 migration、接口实现顺序与端到端验收。

## Next Prompt

```text
读取 AGENTS.md、skills/spec-workflow/SKILL.md 和 docs/HANDOFF.md，评审 asset-library 本轮 S2 补齐草案。重点核对 45 个 OpenAPI operation 的请求/响应、普通与分片上传状态、Collection 对外术语与表映射、永久删除强引用检查、16 项权限粒度和 43 个错误码。运行完整 YAML/OpenAPI/S1 引用/错误码/schema 校验；发现问题直接修正并更新 CHANGELOG 与 HANDOFF。完成后汇报差异，但未经我明确确认不要写 RELEASE.md 或声明新 release。
```
