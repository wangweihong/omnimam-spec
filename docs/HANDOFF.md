# OmniMAM Spec Handoff

## 当前项目目标

发布 Asset Library 管理员存储检查契约，使 Server/Web 可以从 AssetRepresentation 的 `blob_id` 逐级查看 Blob 和 StorageBackend 详情。

## 本次完成

1. 新增 `US-USER-ASSET-48`、`BR-USER-ASSET-82..83`，明确 Blob/StorageBackend 是管理员可见的全局基础设施事实。
2. Asset Library OpenAPI 升级到 0.6.0，新增 Blob 与 StorageBackend 详情，并将现有 StorageBackend 列表、创建、更新纳入契约。
3. 新增 `asset.storage.read/manage` 权限及 `150610..150612` 业务错误。
4. StorageBackend 设计态 schema 对齐运行态 `type/root/config/enabled/readonly/quota`。
5. 模块契约和架构增加 `storage-inspection` 边界；事件契约不变。
6. 规格变更提交为 `81e6cfd`，`spec-v1.7.4` release 记录与标签已创建。
7. 保留用户原有 `AGENTS.md` 修改，不纳入本任务提交。

## 文件变化

- 修改 Asset Library S1、OpenAPI、schema、errors、permissions、module contract 和领域架构。
- 修改 `CHANGELOG.md` 和本文件。
- 无事件、全局错误码区间或其他领域契约变化。

## 关键设计决策

- Blob 详情及 StorageBackend 列表、详情、创建、更新仅允许 `ADMIN`、`SUPER_ADMIN`；兼容 Server 的 `system-admin` 开发主体。
- 管理员响应按用户确认原样返回 Blob `object_key`、StorageBackend `root` 和完整 `config`，不做凭证脱敏。
- 普通素材、Representation、Artifact、任务输出和跨域摘要不得传播上述敏感字段。
- StorageBackend 列表新增规范 `items`，同时保留内容相同的 deprecated `backends` 兼容字段。

## API、Schema 与配置变化

- 新增 `GET /api/v1/blobs/{blob_id}`。
- 新增 `GET /api/v1/storage-backends/{backend_id}`。
- 正式定义 `GET/POST /api/v1/storage-backends` 与 `PATCH /api/v1/storage-backends/{backend_id}`。
- 新增 `AssetBlobDetail`、`StorageBackend`、StorageBackend 请求与列表 DTO。

## 待办与风险

- 推送 `master` 与 `spec-v1.7.4` 标签。
- Server 需更新 submodule/`SSOT_VERSION`，实现管理员鉴权、Blob 查询、StorageBackend 详情与兼容列表字段。
- Web 后续需重新生成 Asset Library client 并接入详情导航。
- 原样返回 `config` 可能暴露凭证；这是本轮明确确认的管理员契约，后续若需脱敏必须再次修改并 release SSOT。

## 推荐下一任务

在 `omnimam-server` pin `spec-v1.7.4` 并实现已发布的存储检查 API 与测试。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
