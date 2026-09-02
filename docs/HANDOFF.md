# OmniMAM Spec Handoff

## Current goal and status

- Goal: 修复 `spec-v1.25.0`/`spec-v1.25.1` 的 Capability 查询与 Agent/AppStudio 模型绑定冲突，发布 `spec-v1.25.2`。
- Status: `spec-v1.25.2` release commit、annotated tag、分支/tag 推送及 tag 后发布元数据均已完成。

## Work completed in this session

- 从 `spec-v1.25.1` tag target `bdf05de2955028f10e8fab9a63098dad623cb3f3` 创建 `codex/spec-v1.25.2`，未合并分叉的 `master`。
- Model Gateway S1/S2 新增 ProviderCapability 按 ID 脱敏详情，列表继续返回轻量摘要；详情公开 models、operations、variants 与参数 schema。
- Agent S1 的 ModelBinding 对齐现有 S2：`PROVIDER_RESOURCE | MODEL_PREFERENCE_DEFAULT`，分别引用 ProviderResource ID 与用途键。
- AppStudio S1/S2/Context 删除 User Model/ModelAccessSpec 残留；创建和替换 Coding Agent 只接受显式 `PROVIDER_RESOURCE`。
- `CHANGELOG.md` 已明确区分 v1.25.1/v1.25.2；`RELEASE.md` 已补录 v1.25.1 的真实 tag target。
- Release commit `e0e698674f480f1c31cb9f9657eabf707b3167ef` 已创建并标记、推送为 `spec-v1.25.2`。
- tag 后发布元数据提交 `35f65631c8c10fddc569346451ce74463236de09` 已推送到 `codex/spec-v1.25.2`，未移动 tag。
- Web 已将 submodule 与 `SSOT_VERSION` 固定到 tag target `e0e698674f480f1c31cb9f9657eabf707b3167ef`，而不是 tag 后提交。

## Current in-progress work

- 无 SSOT 发布工作进行中。

## Files added, modified, renamed, or removed

- Modified: Model Gateway、Agent、AppStudio 的目标 S1/S2，`domains/appstudio/context.md`、`CHANGELOG.md`、`RELEASE.md`、`docs/HANDOFF.md`。
- No files added, renamed, or removed.
- `01_contracts/domains/task-center/function-registry.yaml` 未修改。

## Key architectural or design decisions

- Capability 详情复用既有清单事实，但禁止返回 Adapter/Executor ID、来源路径、凭证、Provider 原始响应、URL、extensions 或内部运行配置。
- Capability 列表与详情复用 `model_gateway.provider_capability.read`；不存在、不可用或不可见统一返回 `ERR_MODEL_GATEWAY_PROVIDER_CAPABILITY_NOT_FOUND`。
- Capability 详情从内存中的已加载清单按主键一次读取，不访问账号/资源私表，不产生 N+1 查询。
- AppStudio 不提供 `MODEL_PREFERENCE_DEFAULT`、隐式回退或旧模型来源兼容；Agent 自身仍支持默认用途绑定。
- `agent.runtime.ensure@1.0/@1.1` 继续 RETAINED，`@1.2` 继续 ACTIVE；已发布 schema/digest 不变。

## API, schema, dependency, or configuration changes

- 新增 `GET /api/v1/model-gateway/provider-capabilities/{provider_capability_id}` 和公开 `ProviderCapability` 详情 schema。
- `StudioCodingModelSelection.source_type` 收紧为唯一值 `PROVIDER_RESOURCE`；替换请求复用同一结构化 schema。
- 未新增错误码、权限码、数据库字段、依赖或运行时配置。

## Verification performed and remaining checks

- 3 份目标 YAML 解析、Model Gateway/AppStudio OpenAPI 本地 `$ref`、新增 schema/trace 断言通过。
- 3 个 ProviderCapability 清单通过 Draft 2020-12 schema 校验。
- 目标 Agent/AppStudio S1/S2/Context 无旧 User Model 枚举、类型或 `ModelAccessSpec` 残留。
- Function Registry 相对 `spec-v1.25.1` 无 diff，`git diff --check` 通过。
- Release commit、annotated tag 和 tag 后发布元数据均已推送；远端 tag target 已复核为 `e0e698674f480f1c31cb9f9657eabf707b3167ef`。

## Outstanding tasks

- 无 SSOT outstanding task；后续 Web 实现与验证在 `omnimam-web/docs/HANDOFF.md` 跟踪。

## Known issues and risks

- `ProviderCapabilityParameterSchema` 保留清单允许的嵌套 JSON Schema 片段；公开响应必须按声明字段投影，不能直接序列化整个清单对象。
- tag 后发布元数据提交不属于 tag target；Web 必须固定到 tag target，而不是该后续提交。

## Exact recommended next step

保持 `spec-v1.25.2` tag 不变；后续规范修改使用新的小版本发布。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
