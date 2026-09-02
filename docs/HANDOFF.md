# OmniMAM Spec Handoff

## Current goal and status

- Goal: 按“方案 B”完成统一 `ProviderAccount` 与全能力画布架构修复，覆盖 Model Gateway、Model Preferences、Application Platform、Workflow Canvas，以及 AI Chat、Agent、Task Center 的直接依赖契约。
- Status: 方案 B 已提交并发布；Model Gateway、Model Preferences、Application Platform、Workflow Canvas 及直接依赖域已按方案 B 同步。

## Work completed in this session

- 已确认本次为跨领域 S1/S2 破坏性重构，不兼容旧 API、表、DTO、权限、错误码和事件。
- 已确认目标架构将账号作用域与 Provider 类型解耦，并由 Model Gateway 统一拥有账号、资源、能力绑定、健康、凭证引用、Adapter 与执行。
- 已读取 `skills/spec-workflow/SKILL.md`、`S1.md`、`S2.md`、`GLOBAL_CONTEXT.md` 与 `CONTEXT_MAP.md`。
- 已重建 Model Gateway S1，删除 Engine/User Model 双轨并建立 ProviderAccount、ProviderResource、Binding、健康、NetworkPolicy、TargetSelection 与 ProviderExecutionGrant。
- 已重建 Model Gateway OpenAPI、设计态 Schema、错误、权限、事件、模块合同和 Runtime Registry；ProviderCapability 清单改为引用 `provider_type`。
- 已将 `user-model` 的 S1/S2/Context/架构路径移动到 `model-preferences`，并重建其 S1 与完整 S2，只保留展示偏好和用途默认值。
- 已审计并补全 Application Platform S1/S2：补齐内置 LLM Application ProviderType 约束，移除剩余 Engine DTO/错误/示例命名，并将无效 S1 追溯引用收口到现行 BR/US。
- 已同步 AI Chat、Agent、Task Center 的 ProviderResource/ProviderExecutionGrant 依赖语义；Agent ModelBinding 改为 ProviderResource/Model Preferences 默认引用，Task Center Provider 健康巡检归 Model Gateway。
- 已更新 Model Preferences、AI Chat、Model Gateway、Application Platform 架构参考及 `GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、Glossary、CHANGELOG。

## Current in-progress work

- Workflow Canvas 的 target_binding、REQUEST 运行选择、PROJECT/PRIVATE 约束与执行指纹已完成审计；当前转入直接依赖域同步。
- 无实现工作；`spec-v1.25.0` 已登记，待远端推送完成。

## Files added, modified, renamed, or removed

- Modified: `00_product/domains/modelgateway/product-spec.md`、`01_contracts/domains/modelgateway/` 的核心合同与清单、`docs/HANDOFF.md`。
- Renamed and rebuilt: `domains/user-model`、`00_product/domains/user-model`、`01_contracts/domains/user-model`、`02_architecture/domains/user-model.md` 到 `model-preferences`。

## Key architectural or design decisions

- `ProviderAccount.scope = USER | PLATFORM` 与 `ProviderType` 完全解耦。
- `ApplicationVersion` 仅声明 `execution_target_policy`，不冻结账号、凭证或健康事实。
- Canvas 不新增 `ModelNode`；LLM 继续作为带 `application.llm` renderer 的普通 `ApplicationNode`。
- USER 与 PLATFORM 之间禁止自动回退；PROJECT Canvas 禁止固定 USER 私有账号。
- Gateway Grant 使用不透明 `provider-execution-grant://` 引用，敏感连接信息不得传播至上层运行、Task、事件或日志。

## API, schema, dependency, or configuration changes

- 已新增 `/api/v1/model-gateway/` Provider Account/Resource/Binding/Object Info/Network Policy canonical API。
- 已将用户模型域 canonical API 改为 `/api/v1/model-preferences/`，仅保留展示偏好与用途默认值。
- 已替换旧 Engine/User Model 设计态表，并登记两域全新错误码、权限码与事件。
- 计划引入默认 `ALLOW_ALL` 的 Provider 网络策略；其无限制出站风险必须在 S1、架构参考与 Release gate 中明确记录。

## Verification performed and remaining checks

- 已核对工作树在任务开始时无未提交变更。
- 已使用 `python3` 完成 13 个核心 YAML 解析、两份 OpenAPI 本地 Schema `$ref` 检查和三个 ProviderCapability 清单的 Draft 2020-12 Schema 校验。
- Application Platform 的 OpenAPI/errors/events/permissions YAML、OpenAPI 本地 `$ref`、S1 BR/US 追溯和旧 Engine DTO 残留检查已通过；`BR-AIAPP-209` 中仅保留对删除 `engine_instance_id` 的明确历史说明。
- 首次校验命令因环境没有 `python` 命令未运行逻辑，改用 `python3` 后通过。
- 本次限定校验：7 个受影响领域全部 YAML 解析通过；7 份 OpenAPI 本地 `$ref` 全部通过；全局错误码扫描 178 个值无重复；`git diff --check` 通过。

## Outstanding tasks

- 已登记 `spec-v1.25.0`，commit 为 `a78f5e0146018cea611d38ec4e0b1bdd6d1dd4d6`，允许作为正式实现依据。
- 推送后核对远端分支与工作树清洁状态。

## Known issues and risks

- 本次跨域改动面大，需避免用新 Context 反向补造正式事实；所有 S2 必须可追溯到已更新 S1。
- 默认 `ALLOW_ALL` 允许访问回环、私网、链路本地、云元数据和平台控制面，属于用户明确接受但必须进入 Release gate 的高危风险。

## Exact recommended next step

推送完成后读取 `docs/HANDOFF.md`，按用户下一项任务继续，不重复方案 B 已完成工作。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
