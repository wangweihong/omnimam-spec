# OmniMAM Spec Handoff

## 当前目标与状态

- 目标：新增并发布独立 `gitlab` domain 第一阶段 S1/S2，供 omnimam-server 实施 GitLab Server、Project 和 Pipeline 任务。
- 状态：GitLab 与 Task Center 最小契约已完成并通过结构校验；正在创建内容提交，尚未写 release 记录或 tag。
- 基线：`spec-v1.21.0`，release commit `5a654a1c1e14c1f454e17a5b4190af379f13bb5c`。

## 本次已完成

- 用户确认 GitLab 是独立 domain，不得混入 AppStudio。
- 用户确认 PAT 持久化在 GitLabServer credential 字段、Pipeline 使用回调式异步执行、API 仅管理员访问、有关联 Project 时阻止删除 Server。
- 已核对当前 Task Center 的版本化 Agent/AppStudio Function Registry 仅适用于 Infra-backed JOB/SERVICE；`gitlab.pipeline.run` 将登记为非 Infra-backed 外部 AtomicTask，不伪造 Infra 映射。
- 已新增 GitLab S1、Domain Context、OpenAPI、设计态 Schema、错误、权限、空事件和模块合同。
- 已同步 Task Center S1/module contract/context、Global Context、Context Map、错误码索引和 Changelog，未修改 AppStudio 文件。

## 当前进行中

- 创建并推送 GitLab 内容提交与 `spec-v1.22.0` release。

## 文件变化

- Added: `00_product/domains/gitlab/product-spec.md`、`domains/gitlab/context.md`、`01_contracts/domains/gitlab/*`。
- Modified: Task Center S1/module contract/context、`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、`01_contracts/error-code-index.md`、`CHANGELOG.md`、`docs/HANDOFF.md`。

## 关键决定

- GitLab 拥有 GitLabServer、GitLabProject、GitLabClient 与 Pipeline 外部执行语义。
- AppStudio S1/S2、Schema、API 和创建流程保持不变。
- GitLab Pipeline 终态由 Task Center AtomicTask/TaskAttempt 表达；GitLab 第一阶段不发布领域事件。
- `gitlab.pipeline.run` 输入只使用内部 GitLabProject ID、ref 和 variables，不包含 URL、PAT 或远端 numeric project ID。

## API、Schema、依赖或配置变化

- 计划新增 `/api/v1/gitlab/servers`、`/api/v1/gitlab/projects` 及 Server test action。
- 计划新增 `gitlab_servers`、`gitlab_projects` 设计态表和 `250200-250999` 错误码区间。
- 计划新增四个管理员权限；不新增依赖或运行配置。

## 验证与风险

- `yq` 已解析新增 YAML/OpenAPI；错误 code/value 无重复，四个权限仅默认授予 ADMIN/SUPER_ADMIN。
- Redocly 确认 OpenAPI 有效；仅报告仓库 HTTP 200 规则对应的 4XX warning 及非阻断 license/tag warning。
- 已确认 SQL 包含 `ON DELETE RESTRICT` 和两个 Server 内唯一约束，`git diff --check` 通过，AppStudio 文件无变更。
- 尚需内容 commit、release record、tag/push 和远端校验。
- spec worktree 既有未跟踪 `archive/`、`docs/identity_fix.md`、`设计图/`，本任务不得提交或修改。

## 未完成事项

- 完成并验证 GitLab/Task Center 契约。
- 创建内容提交，记录并发布 `spec-v1.22.0`，推送 release commit 和 annotated tag。
- 下游 server 更新 SSOT pin 后实施；devops 完成幂等用户和 PAT bootstrap。

## 推荐下一步

只暂存本任务文件并创建 GitLab 内容提交，然后用该 commit 写入 `spec-v1.22.0` release 记录。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
