# OmniMAM Spec Handoff

## 当前项目目标

完成 Artifact 到 `asset-library` 的跨域迁移，使 Artifact、Asset、AssetVersion、Blob 与 AssetRepresentation 的所有权、Task Center 任务编排和 SSE 用户事件形成一致的 S1/S2 契约。本轮仍为未 release 的破坏性草案。

## 本次完成

2026-07-20 已完成以下工作：

- 将 Artifact 的身份、受控内容、处理、保留、登记状态和源事件事实源迁移到 `asset-library`。
- 将 ApplicationPlatform 收敛为 ApplicationRun 输出到 Artifact 的引用映射和只读投影；Provider 调用、轮询、凭证使用和下载仍由 ApplicationExecutor/Worker 负责。
- 明确 Task Center 只拥有 AtomicTask、TaskAttempt、TaskGroup、DAGTaskGroup、TaskSchedule 等任务事实，只保存 `artifact_refs`、`representation_refs` 等小型引用。
- 增加 `artifact_content_completed` 源事件和幂等 `asset-library.artifact.process` AtomicTask。
- Artifact 登记事务复用 Blob 同步创建 original Representation，并写 `asset_version_representation_requested` 源事件。
- 增加 `asset-library.representation.build` DAGTaskGroup，以及 inspect、thumbnail、preview、playback、manifest、finalize functionRef。
- 增加 `asset-library.representation-backfill` SYSTEM RECONCILE 周期巡检；只为缺失、可重试或可重建项创建幂等 `asset-library.representation.generate` AtomicTask，健康 AssetVersion 不物化任务。
- SSE Artifact 生命周期事件改由 asset-library 源事件投影；新增 `asset_version.processing_started`、`processing_progressed`、`ready`、`ready_with_warnings`、`processing_failed`。
- 统一命名边界：领域源事件使用下划线，SSE 客户端事件使用点号。
- 同步更新 S1、S2、glossary、错误码索引、模块契约、架构参考和 `CHANGELOG.md`。

## 文件变化

本轮修改覆盖：

- `00_product/domains/asset-library/product-spec.md`
- `00_product/domains/task-center/product-spec.md`
- `00_product/domains/application-platform/product-spec.md`
- `00_product/domains/sse/product-spec.md`
- `00_product/glossary.md`
- 上述四个领域的 `01_contracts/domains/*` S2 契约
- `01_contracts/error-code-index.md`
- 相关 `02_architecture/` 领域与全局架构参考
- `CHANGELOG.md`
- `docs/HANDOFF.md`

工作区还包含用户原有修改：`AGENTS.md` 已修改，`00_product/domains/asset-library/backup/统一资产设计.md` 已删除。这些变更未被回退。

## 关键设计决策

- Artifact、Asset、AssetVersion、Blob 和 AssetRepresentation 归 `asset-library`。
- Artifact 使用独立 `processing_status` 与 `registration_status`；AtomicTask 成功不代表 Artifact 或 AssetVersion ready。
- Artifact producer key 在 owner 范围稳定；自动 TaskAttempt 重试复用同一键，手动重试创建新 AtomicTask。
- asset-library 只接受字节流、受控上传会话或可信存储引用，不接受 Provider 凭证、任意 URL、私网地址或原始响应。
- `original` Representation 在登记事务中复用 Artifact Blob；其他派生 Representation 异步生成。
- required Representation 失败使 AssetVersion failed；optional 失败使其 ready_with_warnings；修复后可提升为 ready。
- 周期 backfill 是首次事件驱动生成的兜底，不替代主链路，不产生专用用户 SSE 事件。
- ApplicationPlatform 的 Artifact 投影可由 asset-library 更高 `resource_version` 事件重建，不是竞争事实源。

## API、Schema 与事件变化

- asset-library 增加 Artifact 创建、受控内容写入、complete、register、AssetVersion/Representation 查询与受控 Representation 写入契约。
- asset-library 设计态 schema 增加 `artifacts`、`asset_versions`、`asset_representations`、`representation_build_requests` 和 `artifact_asset_registrations`。
- ApplicationPlatform 原 Artifact 表替换为 `aiapp_application_artifact_refs` 引用投影。
- Task Center 输出增加 `artifact_refs`、`representation_refs`，并定义首次 build、Artifact processing 和 backfill action 协作事件。
- asset-library 源事件包括 `artifact_created`、`artifact_processing_changed`、`artifact_content_completed`、`artifact_registration_changed`、`asset_version_representation_requested`、`asset_version_processing_changed`。
- SSE 客户端继续使用 `artifact.*`，并增加 `asset_version.*` 状态事件。
- `RELEASE.md` 未修改。

## 验证结果

2026-07-20 已通过：

- `git diff --check`。
- 32/32 份 YAML 契约解析。
- Redocly 校验四份 OpenAPI，均为 valid、0 error；仅有仓库既有 license、4XX 风格警告及 ApplicationPlatform 组合 schema/未使用组件警告。
- OpenAPI 本地引用：asset-library 75、task-center 137、application-platform 283、sse 27，全部可解析。
- 159 个错误码的 code/value 全局唯一。
- S2/架构引用的 BR/US 在 S1 中均存在。
- 七个领域 SQL schema 未发现重复列、缺失本地引用表或后定义外键目标。
- Artifact、Artifact registration、AssetVersion 与 Representation 关键状态枚举在 asset-library OpenAPI/schema 中一致。
- 主动搜索未发现有效的 `aiapp_artifacts`、`artifact.promoted`、`asset.processing.*` 或 ApplicationPlatform Artifact 生命周期源事件残留。
- `TaskRun` 仅出现在明确的历史/废弃语义与 deprecated 错误码中。

## 待办、风险与技术债

- 本轮是跨域破坏性草案，未经用户明确 release，不得作为正式实现、合并或验收依据。
- Redocly 的 ApplicationPlatform `oneOf.required` 警告和未使用组件为既有结构问题，不由 Artifact 迁移引入；后续可单独整理。
- asset-library 仍保留旧 `asset_uploaded` 兼容源事件和历史 `user_asset_processing_tasks` 设计；已明确兼容/旧处理语义，后续迁移实现应制定停用窗口。
- `schema.sql` 是目标设计，不是实际 migration；实现迁移需要另行设计数据回填、双读切换和旧表退役步骤。
- 本轮规格迁移提交后，工作区仍保留用户原有的 `AGENTS.md` 未提交修改。

## 推荐下一任务

对迁移后的跨域 S1/S2 做用户评审，确认破坏性边界和兼容窗口；确认后再决定 coordinated release 版本，并在实现仓库设计实际数据迁移与事件切换方案。

## Next Prompt

```text
读取 AGENTS.md、skills/spec-workflow/SKILL.md 和 docs/HANDOFF.md，评审已完成的 Artifact-to-asset-library 跨域迁移。重点核对 asset_uploaded 与 user_asset_processing_tasks 的兼容停用策略、ApplicationPlatform 引用投影重建、Artifact/Representation 数据回填、事件切换顺序和回滚边界。不要修改 RELEASE.md，除非我明确确认 coordinated release。发现问题时先修 S1，再同步 S2、架构、CHANGELOG 和 HANDOFF，并复跑现有全部校验。
```
