# OmniMAM Spec Handoff

## 当前目标与状态

将 Gateway 核心从 `application-platform` 原样迁移到新领域 `modelgateway`，保留业务术语、行为和兼容标识。状态：已完成实现与结构化验证，尚未 Release。

## 本次已完成

- 新增 `modelgateway` S1、完整 S2、领域架构和 Domain Context。
- 迁移 CapabilityDefinition、ProviderCapability、ApplicationEngineType、ApplicationEngineInstance、EngineCapabilityBinding、EngineAdapter、OperationExecutor、Runtime Registry、健康检测和 ComfyUI 当前 `object_info`。
- 原样迁移指定 `BR-AIAPP`、`US-AIAPP` 与 AC；Application Platform 只保留应用、工作流、表单、运行和消费语义。
- 将 11 个 Gateway API path、完整 DTO、三张 Engine 表、26 个错误码、5 个权限码和 2 个事件迁入新领域。
- 原样移动 Runtime Registry、ProviderCapability Schema 和三份清单；Provider 文件逐字未变，Registry 只调整领域归属描述。
- ApplicationExecutor、ComfyUIWorkflow、ApplicationTemplate/Version、RuntimeFormSchema、ApplicationRun 与 Artifact 交付继续归 Application Platform。
- 删除未完成的 `domains/model-integration/context.md`，并清理其 Global Context、Context Map 与 Changelog 草稿声明。
- 更新 glossary、全局特性矩阵、全局架构、错误码索引、相关 Domain Context 和 `CHANGELOG.md`；`RELEASE.md` 未修改。

## 当前进行中

- 无。

## 文件变化

- 新增：`00_product/domains/modelgateway/product-spec.md`。
- 新增：`01_contracts/domains/modelgateway/` 下 OpenAPI、Schema、errors、permissions、events、module contract、Runtime Registry 和 ProviderCapability 清单。
- 新增：`02_architecture/domains/modelgateway.md`、`domains/modelgateway/context.md`。
- 修改：`application-platform` 的 S1、全部 S2 主合同、架构和 Context。
- 修改：`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、glossary、全局特性矩阵、全局架构、错误码索引、相关 Context、`CHANGELOG.md`、本 Handoff。
- 删除/移动来源：Application Platform 的 Runtime Registry、ProviderCapability 目录及已迁移合同片段；删除 `domains/model-integration/context.md`。
- 保留用户已有无关改动：`agent/`、`appstudio/`、`mcp/`、`archive/`、`设计图/` 与 `skills/archive/`。

## 关键设计决策

- 领域 ID 固定为 `modelgateway`。
- `AIAPP` BR/US/AC、`ERR_AIAPP_*` code/value、`aiapp.*` 权限、`aiapp_*` 表、API path/DTO、事件名和调度 key 均保持稳定。
- `owning_domain` 及事件 producer/consumer 调整为 Model Gateway；通用 `ERR_AIAPP_PERMISSION_DENIED` 留在 Application Platform 作为兼容共享错误。
- Application Platform 通过稳定 ID、权限裁剪投影和受控模块接口消费 Gateway，不读取其私有表。
- 本次不修改 `RELEASE.md`；用户确认新的 Release 前，本次迁移不能作为正式实现依据。

## API、Schema、依赖与配置变化

- 公开 Wire Contract 不变；OpenAPI 仅按领域拆分，Gateway 11 个 path 与 Application Platform 27 个 path 均和拆分前结构等价。
- `aiapp_engine_instances`、`aiapp_comfyui_engine_object_info`、`aiapp_engine_capability_bindings` DDL、索引和约束未变化。
- Application Platform Schema 保留现有跨文件 FK，Model Gateway Schema 是其前置设计依赖。
- `application-platform.engine-health` 与 `application-platform.comfyui-object-info-refresh` system_key 未重命名。

## 验证结果

- 41 份当前 S2 YAML 全部可解析；两份 OpenAPI 本地 `$ref` 全部可解析。
- 拆分前后公开 path/method/参数/响应结构化等价，`info.version=1.7.0` 保持不变。
- ProviderCapability JSON Schema 校验通过：`comfyui.yaml`、`deepseek.yaml`、`seedance.yaml`。
- Runtime Registry 的 3 个 EngineType、CapabilityDefinition、Adapter、Executor 和清单引用均可解析。
- 组合 Schema 共 12 张表，无重复定义，所有 FK 可解析；三张迁移表 DDL 与原文一致。
- 全仓 218 个错误码、61 个权限、124 个事件唯一；迁移集合无遗漏或重复。
- 420 个 S1 BR/US/AC 定义唯一，236 个 BR/US 追溯目标可解析；指定 24 个 Gateway BR/US 只在新 S1 定义。
- Provider 文件逐字等价，Runtime Registry 除领域归属描述外等价；Context 文件路径全部存在。
- Markdown/代码围栏平衡、`git diff --check` 通过，`RELEASE.md` 无差异。
- 当前环境无 Mermaid CLI，未执行渲染器级解析。

## 待办、问题与风险

- 本次迁移尚未 Release，历史 Release 仍引用原 application-platform 文件，这是保留的正式历史。
- 新领域继续使用含 `AIAPP` 或 `application-platform` 的稳定兼容标识，不能在后续实现中自行重命名。
- Mermaid 图未经过 CLI 渲染验证，后续 Release 前如环境提供 `mmdc` 应补跑。

## 推荐下一步

由用户评审本次事实迁移；确认后按 Spec 工作流创建新的 Release 记录，并在实施仓库按相同兼容边界迁移模块所有权。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
