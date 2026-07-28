# OmniMAM Spec Handoff

## 当前项目目标

发布 Asset Library 单项/批量软删除、直接硬删除与回收站清空契约，并作为 Server/Web 实现依据。

## 本次完成

1. 扩展 `US-USER-ASSET-15`，新增 `US-USER-ASSET-49..50` 与 `BR-USER-ASSET-84..88`。
2. 单删增加 `hard_delete` 查询参数，新增 `POST /api/v1/assets/batch-delete` 与 `POST /api/v1/assets/trash/empty`。
3. 批量请求限制为 1 至 200 个唯一素材 ID；批量和清空均逐项提交并返回结果，失败项不回滚成功项。
4. 扩展 `asset.delete` 权限，新增批量请求无效与删除执行失败错误码。
5. 同步 Asset Library 模块契约、架构与变更记录；OpenAPI 升级为 0.7.0。

## 文件变化

- `00_product/domains/asset-library/product-spec.md`
- `01_contracts/domains/asset-library/openapi.yaml`
- `01_contracts/domains/asset-library/errors.yaml`
- `01_contracts/domains/asset-library/permissions.yaml`
- `01_contracts/domains/asset-library/module-contract.md`
- `02_architecture/domains/asset-library.md`
- `CHANGELOG.md`
- `docs/HANDOFF.md`

## 关键设计决策

- 现有 DELETE 默认软删除，显式 `hard_delete=true` 才绕过回收站，保持向后兼容。
- 直接硬删除、回收站永久删除和清空回收站复用同一强引用检查，只清理无共享引用 Blob。
- 批量删除整批统一模式；清空回收站只遍历当前用户 deleted 素材。两者均逐项隔离，阻塞或失败项保留。
- 清空回收站首期为同步操作，不新增 Task Center 任务或领域事件。

## API、Schema 与配置变化

- Asset Library OpenAPI 0.7.0。
- 新增 `POST /api/v1/assets/batch-delete`、`POST /api/v1/assets/trash/empty`。
- `DELETE /api/v1/assets/{asset_id}` 新增可选 `hard_delete` 查询参数。
- 新增错误码 150613、150614；复用 `asset.delete` 权限。
- schema、事件与运行时配置不变。

## 待办与风险

- 规格尚需提交并登记 release。
- omnimam-server 与 omnimam-web 必须更新 SSOT pin 并实现对应接口、确认交互和回归测试。
- 同步清空超大回收站可能形成长请求；首期按用户明确范围实现，后续根据观测数据评估异步任务化。

## 推荐下一任务

提交并发布下一版 spec，然后在 omnimam-server 实现并验证单项/批量软删除、直接硬删除和回收站清空完整链路。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
