# OmniMAM Spec Handoff

## 当前项目目标

发布 ComfyUI API-ready 工作流直接选择引擎、可重复转换独立应用模板，以及 ApplicationEngineType 多语言能力选项契约。

## 本次完成

1. 所有 `api_conversion_status=ready` 的 ComfyUIWorkflow 均可直接选择当前可用 ComfyUI EngineInstance 转换模板，包括 Visual-to-API 后的工作流。
2. 转换请求以 `engine_instance_id` 替换 `workflow_validation_id`；历史 WorkflowValidation 只用于独立诊断。
3. 同一工作流可使用不同幂等键创建多个独立 ApplicationTemplate 与 v1 draft，相同 owner、工作流和幂等键返回首次结果。
4. 移除工作流 converted 状态、单一模板引用、转换筛选和 TemplateVersion 的 validation 来源。
5. ApplicationEngineType 返回 `operation_executors` 与按 key 字典序排列的 `capability_definitions.zh-CN/en-US` 名称数组。
6. 设计态 schema 将转换幂等键放在 ApplicationTemplate，不新增转换历史表。
7. 明确 Server 必须破坏性删除重建全部 Application Platform 表，不迁移或回填旧 aiapp 数据。
8. Application Platform OpenAPI 升级为 1.6.0，规格变更提交为 `0c89181`，`spec-v1.7.9` 已发布。

## 文件变化

- `00_product/domains/application-platform/product-spec.md`
- `01_contracts/domains/application-platform/openapi.yaml`
- `01_contracts/domains/application-platform/schema.sql`
- `01_contracts/domains/application-platform/errors.yaml`
- `01_contracts/domains/application-platform/module-contract.md`
- `01_contracts/domains/application-platform/events.yaml`
- `01_contracts/domains/application-platform/runtime-registry.yaml`
- `02_architecture/domains/application-platform.md`
- `CHANGELOG.md`
- `RELEASE.md`
- `docs/HANDOFF.md`

## 关键设计决策

- 转换所选 EngineInstance 只用于当前 object_info 实时校验，不自动写入模板 `engine_restrictions`。
- 工作流不承担转换历史或单一转换状态；模板版本保留 `source_comfyui_workflow_id`，模板内部字段承担幂等重试。
- 能力 value 始终来自 `operation_executors` key；中英文数组必须与排序后的 key 等长同序。
- 已发布旧错误码只标记 deprecated，不在新 DTO、数据库或运行路径保留兼容分支。

## API、Schema 与配置变化

- `ComfyUIWorkflowConvertRequest` 新增 `engine_instance_id` 并移除 `workflow_validation_id`。
- `ComfyUIWorkflow` 移除 converted 相关字段，列表移除 converted 查询参数。
- `ApplicationTemplateVersion` 移除 `source_workflow_validation_id`。
- `ApplicationEngineType` 移除 `capability_definition_ids`，新增 `operation_executors` 和多语言 `capability_definitions`。
- `comfyui_workflow_converted` 事件改为携带 `engine_instance_id`。

## 待办与风险

- Server 和 Web 必须 pin `spec-v1.7.9` 后再正式实现。
- Server 启动将删除全部现有 Application Platform 数据；部署前必须明确接受该破坏性行为。

## 推荐下一任务

在 omnimam-server 与 omnimam-web 更新 submodule pin 到 `spec-v1.7.9`，完成后端与转换界面实现和端到端验收。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
