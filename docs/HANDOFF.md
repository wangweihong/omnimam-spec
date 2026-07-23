# OmniMAM Spec Handoff

## 当前项目目标

发布 ComfyUI 工作流导入与 EngineInstance 解耦契约，使实例目录只在 Visual Workflow 显式转换和后续解析、校验、运行阶段使用。

## 本次完成

1. ComfyUI 单文件导入不再接收、保存或查询 EngineInstance/object_info。
2. Visual Workflow 导入后只保存源画布并保持 `pending`；API Workflow 完成基础节点结构校验后直接进入 `ready`。
3. Visual 转 API 请求新增必填 `engine_instance_id`，要求实例类型为 comfyui、enabled、online 且当前目录未过期。
4. 转换实例不持久化到工作流，失败不保存部分 API Workflow。
5. 工作流 schema 删除 `source_engine_instance_id`；列表筛选与公共响应同步删除该字段。
6. 新增 `BR-AIAPP-186..187` 与 `AC-AIAPP-047-04`，Application Platform OpenAPI 升级为 1.4.0。
7. 规格变更提交为 `a26b029`，`spec-v1.7.7` 已发布。
8. 保留用户原有 `AGENTS.md` 修改，不纳入本任务提交。

## 文件变化

- `00_product/domains/application-platform/product-spec.md`
- `01_contracts/domains/application-platform/openapi.yaml`
- `01_contracts/domains/application-platform/schema.sql`
- `01_contracts/domains/application-platform/module-contract.md`
- `02_architecture/domains/application-platform.md`
- `CHANGELOG.md`
- `RELEASE.md`
- `docs/HANDOFF.md`

## 关键设计决策

- 导入只验证上传文件和来源基础结构，不依赖任何运行实例能力事实。
- Visual 转 API 是首次需要 object_info 的阶段，所选实例是单次操作输入，不成为工作流来源属性。
- 现有部署不要求保留旧 Application Platform 数据；server 实现可以破坏性重建相关表并清理跨域引用。

## API、Schema 与配置变化

- `ComfyUIWorkflowImportRequest` 删除 `source_engine_instance_id`。
- `ComfyUIWorkflow` 响应及列表筛选删除 `source_engine_instance_id`。
- `ComfyUIWorkflowAPIConversionRequest` 包含必填 `engine_instance_id` 与 `resource_version`。
- `aiapp_comfyui_workflows` 删除 `source_engine_instance_id` 外键列。
- 无新 endpoint、权限、事件或错误码编号。

## 待办与风险

- Server 尚未更新 submodule pin、运行时模型、破坏性重建和导入/转换实现。
- Web 需要同步移除导入实例选择，并在 Visual 转换操作中增加实例选择。
- release 尚待推送远端。

## 推荐下一任务

在 omnimam-server pin `spec-v1.7.7`，实现后端契约并完成破坏性数据重建测试。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
