# OmniMAM Spec Handoff

## Current goal and status

- Goal: 在已发布 `spec-v1.25.2` 基线上实现模型部署高级自定义重构计划，并以未占用版本 `spec-v1.25.3` 发布。
- Status: 已完成远端发布链与版本冲突审计；正在把本地已完成的模型部署 S1/S2 重构重放到 `codex/spec-v1.25.3`。

## Work completed in this session

- 完整读取 `skills/spec-workflow/SKILL.md`、`S1.md`、`S2.md` 和用户计划附件。
- 确认远端 `spec-v1.25.1` 已用于 Task Center 历史合同修复，`spec-v1.25.2` 已用于 Provider Capability/Agent/AppStudio 对齐，二者均不可移动。
- 从远端已完成发布链 `origin/codex/spec-v1.25.2` 创建 `codex/spec-v1.25.3`。
- 确认待重放的本地规格提交为 `f44cb30f97046be7c17ddfc491542ffba7aa6fba`。

## Current in-progress work

- 重放 `f44cb30`，解决 Task Center Function Registry 冲突：保留 `agent.runtime.ensure@1.0/@1.1/@1.2` 历史，只替换计划明确要求删除的六个 Model Deployment `1.0` 合同。

## Files added, modified, renamed, or removed

- Modified: `docs/HANDOFF.md`。
- 待重放文件范围：Model Deployment、Task Center、Infrastructure 的目标 S1/S2/架构/Context，以及 `GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、`01_contracts/error-code-index.md`、`CHANGELOG.md`。
- Added/renamed/removed: 无。

## Key architectural or design decisions

- 已发布 tag 不可复用或移动；原计划版本号由 `spec-v1.25.1` 顺延为 `spec-v1.25.3`，业务与契约语义不变。
- 以远端 `spec-v1.25.2` 发布链为基线，保留其中已发布的 Agent/AppStudio/Model Gateway 合同。
- `agent.runtime.ensure@1.0/@1.1` 必须继续 RETAINED，`@1.2` 必须继续 ACTIVE；它们不属于本计划要求定向删除的六个 Model Deployment 合同。

## API, schema, dependency, or configuration changes

- 本阶段尚未在新分支落入模型部署契约；目标 API/Schema 以用户计划与 `f44cb30` 为准。
- 不新增运行时实现、migration、依赖或 CI/CD 配置。

## Verification performed and remaining checks

- 已核对远端 `spec-v1.25.1` tag target 为 `bdf05de2955028f10e8fab9a63098dad623cb3f3`。
- 已核对远端 `spec-v1.25.2` tag target 为 `e0e698674f480f1c31cb9f9657eabf707b3167ef`。
- Remaining: 重放冲突审计、目标 YAML/OpenAPI/Function Registry/digest/错误码与 diff 校验。

## Outstanding tasks

- 重放模型部署重构并解决目标冲突。
- 完成定向验证，登记并发布 `spec-v1.25.3`。
- 推送 `codex/spec-v1.25.3` 与 `spec-v1.25.3` tag，并刷新最终 handoff。

## Known issues and risks

- 本地旧 `master` 与远端发布链已分叉；不得直接推送本地 `master`。
- `f44cb30` 基于 `spec-v1.25.0` 后状态创建，重放时可能覆盖 `spec-v1.25.1/v1.25.2` 的已发布合同，必须逐个冲突核对。
- 模型部署重构不兼容旧 DTO、数据、Runtime、Task 和六个 Model Deployment `1.0` 合同，实施仍需维护窗口定向清理。

## Exact recommended next step

执行 `git cherry-pick f44cb30f97046be7c17ddfc491542ffba7aa6fba`，逐项解决冲突并首先复核 `01_contracts/domains/task-center/function-registry.yaml`。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
