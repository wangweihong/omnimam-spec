# 用户素材管理模块契约

## 1. 模块边界

| 模块 | 职责 | S1 来源 |
| --- | --- | --- |
| `asset` | 维护用户素材 metadata、`sha256`、上传去重命中、轻量引用摘要和素材返回 | `US-USER-ASSET-31`、`US-USER-ASSET-40`、`BR-USER-ASSET-41`、`BR-USER-ASSET-42`、`BR-USER-ASSET-57`、`BR-USER-ASSET-58` |
| `group` | 维护素材分组、分组排序、素材与分组的多对多关联 | `US-USER-ASSET-34`..`US-USER-ASSET-39`、`BR-USER-ASSET-49`..`BR-USER-ASSET-56` |
| `processing-task` | 维护缩略图、派生预览和 `sha256_backfill` 等内部处理任务 | `US-USER-ASSET-09`、`US-USER-ASSET-32`、`BR-USER-ASSET-19`、`BR-USER-ASSET-43` |

## 2. SHA256 计算与去重

- 素材库负责按 S1 规则计算原始内容 SHA256 checksum，并写入 `user_assets.sha256`。
- 上传前重复命中、跳过二进制上传和返回已存在素材属于 `asset` 模块职责。
- `sha256` 为空的素材不参与重复命中判断。

## 3. SHA256 Backfill 协作

- 任务中心可以周期性触发 `asset.sha256_backfill` TaskRun。
- 素材库负责解释 `asset.sha256_backfill` 的业务语义，包括扫描缺失 `sha256` 的素材、读取内容、计算 checksum、更新 metadata 和汇总失败结果。
- 任务中心只负责 TaskRun 调度、领取、状态、重试和运行记录，不直接读取素材内容或计算 checksum。

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

## 6. S2 最小契约说明

本文件只补充 SHA256 去重、backfill、素材分组和轻量引用摘要有关的最小契约，不新增 OpenAPI、错误码、权限码或事件定义。
