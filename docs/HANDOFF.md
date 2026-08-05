# OmniMAM Spec Handoff

## 当前目标与状态

- 当前目标：正式提交并发布 User Model 重构与 Model Gateway 融合规格，发布版本为 `spec-v1.17.0`。
- 状态：发布进行中。用户已于 2026-08-05 明确要求“提交并发布”；规格内容已提交为 `f7f43b2f42ac961441e2227b7c9117baf122aa00`，正在写入 `spec-v1.17.0` Release 记录并准备发布提交、tag 和远端推送。

## 本次已完成

- 已读取 `skills/spec-workflow/SKILL.md`、`S1.md` 和完整 `S2.md`。
- 已确认工作区存在无关未跟踪内容 `archive/`、`docs/identity_fix.md`、`设计图/`，本任务保持不动。
- 已锁定重构决策：新 domain_id 为 `user-model`，展示名为 `User Model`；保留现有对象名、`MODEL_*` 权限、`ERR_MODEL_*` 错误、事件名和 `user_*` 表名；旧 API 路由立即移除且不提供兼容别名。
- 已将 S1、S2、Domain Context 和架构目录从 `model-management` 重命名为 `user-model`。
- 已重写 `00_product/domains/user-model/product-spec.md`，明确 ProviderType、用户维护字段、Gateway 派生能力、执行资格、UserModelExecutionContext 和无旧路由兼容期。
- 已更新 `00_product/domains/modelgateway/product-spec.md`，在两个 S1 中固化职责表、职责模型、两类执行目标、请求级 ResolvedModelRoute 和 Gateway 内部接口。
- 已修复新增 Gateway S1 编号与 Application Platform 既有 `BR-AIAPP-194`、`US-AIAPP-050` 的冲突；新增规则使用 `BR-AIAPP-195..204`，新增用户故事使用 `US-AIAPP-051..052`。
- 已更新 Gateway `runtime-registry.yaml` 和 `module-contract.md`，定义 ProviderType 内部映射、两类执行目标、四个内部接口、请求级路由及不保存/不穿透 User Model 私有事实的约束。
- 已同步 AI Chat S1/S2、Schema、OpenAPI、Context 和架构：GenerationRun 经 User Model 解析执行上下文并通过 Gateway 执行，同时保存模型、能力和配置版本快照。
- 已同步 Application Platform S1、模块契约、Context 和架构：ApplicationExecutor 只使用 `PlatformEngineTarget` 调用 Gateway `ExecuteOperation`；Provider 协议、鉴权应用、下载和 Operation 实现归 Gateway，ApplicationRun 编排和执行快照仍归 Application Platform。
- 已更新 User Model 与 Model Gateway Domain Context、`GLOBAL_CONTEXT.md` 和 `CONTEXT_MAP.md`，同步新 domain_id、执行目标、事实归属、读取导航和未 Release 状态。
- 已更新全局术语、错误码索引、User Model/Gateway/全局架构参考和 `CHANGELOG.md`，统一新 domain_id、canonical API、执行链路及请求级派生对象。
- 已同步 Notification Center 事件来源及 Agent、AppStudio、Infrastructure 的活跃依赖引用到 `user-model`；保留 Agent Runtime 既有 ModelAccessSpec/直连模型架构，本次不扩张为未定义的 Runtime 代理协议。
- 已将 Notification Center 中 `ApplicationEngineInstance` 和 `engine_instance_health_changed` 的事实源改为 `modelgateway`，事件名和通知主题保持不变。

## 当前进行中

- 校验 Release 与 Context 正式状态一致性，准备发布提交。

## 文件变化

- 已修改：`docs/HANDOFF.md`；User Model、Model Gateway、AI Chat 和 Application Platform 的目标 S1/S2、Domain Context 与架构参考。
- 已重命名：`00_product/domains/model-management/` → `00_product/domains/user-model/`、`01_contracts/domains/model-management/` → `01_contracts/domains/user-model/`、`02_architecture/domains/model-management.md` → `02_architecture/domains/user-model.md`、`domains/model-management/` → `domains/user-model/`。
- 不修改：历史 Release 记录、正式实现代码、数据库 migration、无关未跟踪内容。

## 关键决定

- `UserModelProvider` 不转换为 `ApplicationEngineInstance`。
- User Model 拥有用户 Provider、模型、默认配置和用户模型健康事实；Model Gateway 拥有 Adapter、发现、探测、能力验证、Operation 执行以及平台 Engine/Binding/健康事实。
- 用户选择稳定 `providerType`，不得提交内部 `adapter_id` 或 Executor ID。
- `ResolvedModelRoute` 和 `UserModelExecutionContext` 是请求级派生结果，不建表；Gateway 不读取 User Model 私有表。
- Provider 能力由 Gateway 事实与用户启用范围求交集，用户标签不能扩张可执行能力。

## API、Schema、依赖或配置变化

- S1 已声明 canonical API 迁移到 `/api/v1/user-model/...`，删除当前正式 Spec 中旧 `/model-providers`、`/provider-models`、`/default-models` 和 `/model-options` 路由。
- 已新增只读 Provider Type 目录、ProviderModel 能力解析只读字段，以及 User Model/Gateway 内部调用契约。
- 不新增共享表、跨域外键或 `ResolvedModelRoute` 表。

## 验证与风险

- 首次尝试使用 Ruby 解析目标 YAML 时发现当前环境未安装 Ruby（`/bin/bash: ruby: 未找到命令`）；该命令未进入规范校验阶段，不计为失败重试。后续必须先确认可用的结构化 YAML 解析器，再执行目标文件校验。
- 已使用 PyYAML 6.0.1 成功解析 User Model、Model Gateway、AI Chat、Application Platform 和 Notification Center 事件共 22 个目标 YAML。
- 已校验 4 份目标 OpenAPI：共 88 个 `operationId`，文件内及跨文件均唯一；411 个本地 `$ref` 全部可解析。
- 已校验 187 个目标 S2 的 S1 引用，均能在直接相关 S1 或全局规则中找到。
- 已校验 User Model 11 条 canonical 路径精确匹配计划，目标规范中不存在旧模型 API 路由。
- 已校验 Provider Type 与请求 DTO 不暴露 Adapter/Executor ID；ProviderModel 的 4 个能力派生字段存在且为只读。
- 已校验 Gateway schema 不创建 User Model 私有表或 `ResolvedModelRoute` 表；AI Chat GenerationRun 包含模型、能力、配置版本和非敏感快照字段。
- 活跃规范中的 `model-management` 仅用于说明本次 domain 迁移；其他命中均为 `CHANGELOG.md` 历史记录，`RELEASE.md` 未修改。
- `git diff --check` 已通过。
- 已确认 User Model 的 S1、完整 S2、架构和 Domain Context 入口文件均存在，旧 `model-management` 的 4 个活跃路径均已移除。
- 已确认无关未跟踪内容 `archive/`、`docs/identity_fix.md`、`设计图/` 未被修改。
- 已知风险：`spec-v1.17.0` Release 记录已准备但发布提交、tag 和远端推送尚未完成；Agent Runtime 既有 ModelAccessSpec/直连模型架构仍未纳入统一 Gateway 执行链路，且已在实施门禁中明确排除。
- 验证约束：只运行目标 Spec 校验和相关模块检查，同一失败检查最多修复并重试两次。

## 未完成事项

- 创建 `spec-v1.17.0` 发布提交。
- 创建 `spec-v1.17.0` tag，推送 `master` 与 tag 到 `origin`。

## 推荐下一步

- 校验 `RELEASE.md` 引用路径、内容 commit 和 Context 发布状态；通过后创建发布提交与 tag。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
