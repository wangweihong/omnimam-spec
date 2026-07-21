# Release Records

## spec-v1.6.5

- commit: 9de8a07
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - model-management
- S1:
  - 00_product/domains/model-management/product-spec.md
- S2:
  - 01_contracts/domains/model-management/openapi.yaml
  - 01_contracts/domains/model-management/module-contract.md
- architecture:
  - 02_architecture/domains/model-management.md

## spec-v1.6.4

- commit: 6b4a112
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - asset-library
- S1:
  - 00_product/domains/asset-library/product-spec.md
- S2:
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/module-contract.md
- architecture:
  - 02_architecture/domains/asset-library.md

## spec-v1.6.3

- commit: 5fb52fbc91c4d8611d99e48894617a24a8450972
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - ai-chatting
- S1:
  - 00_product/domains/ai-chatting/product-spec.md
- S2:
  - 01_contracts/domains/ai-chatting/openapi.yaml
  - 01_contracts/domains/ai-chatting/module-contract.md
- architecture:
  - 02_architecture/domains/ai-chatting.md

## spec-v1.6.2

- commit: 73f37510a92d6b697773188a85a449a2cb06183e
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - workflow-canvas
- S1:
  - 00_product/domains/workflow-canvas/product-spec.md
- S2:
  - 01_contracts/domains/workflow-canvas/openapi.yaml
  - 01_contracts/domains/workflow-canvas/module-contract.md
- architecture:
  - 02_architecture/domains/workflow-canvas.md

## spec-v1.6.1

- commit: 47948e29dd208a6f4c73a22a15636114da5f15aa
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md

## spec-v1.6.0

- commit: 81d9788e2ca4b772e93e735d4e5663caf6fc5996
- status: released
- confirmed_by: user（2026-07-21 明确要求修改 SSOT、Server 和 Web，并把关联资源响应要求固化为 spec 规则）
- allowed_as_formal_implementation_basis: true
- domains:
  - global
  - task-center
- S1:
  - 00_product/global-business-rules.md
  - 00_product/domains/task-center/product-spec.md
- S2:
  - skills/spec-workflow/S2.md
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md

## spec-v1.5.1

- commit: 069a43778d82de87ab69b0885148f74c177a85ee
- status: released
- confirmed_by: user（2026-07-20 明确要求提交代码、发布小版本并推送）
- allowed_as_formal_implementation_basis: true
- domains:
  - asset-library
- S1:
  - 00_product/domains/asset-library/product-spec.md
- S2:
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/schema.sql
  - 01_contracts/domains/asset-library/errors.yaml
  - 01_contracts/domains/asset-library/permissions.yaml
  - 01_contracts/domains/asset-library/events.yaml
  - 01_contracts/domains/asset-library/module-contract.md
  - 01_contracts/error-code-index.md

## spec-v1.5.0

- commit: ecd9381adb1afff5dd5acaf3d705814acd43ca8c
- status: released
- confirmed_by: user（2026-07-20 明确要求推送并发布 Artifact-to-asset-library coordinated release）
- allowed_as_formal_implementation_basis: true
- implementation_gate: 正式服务端切换前必须完成 Artifact/Representation 数据回填、领域源事件切换、ApplicationPlatform 引用投影重建、兼容消费者验证和旧处理路径退役方案。
- domains:
  - asset-library
  - task-center
  - application-platform
  - sse
  - workflow-canvas
- S1:
  - 00_product/domains/asset-library/product-spec.md
  - 00_product/domains/task-center/product-spec.md
  - 00_product/domains/application-platform/product-spec.md
  - 00_product/domains/sse/product-spec.md
  - 00_product/glossary.md
- S2:
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/schema.sql
  - 01_contracts/domains/asset-library/errors.yaml
  - 01_contracts/domains/asset-library/permissions.yaml
  - 01_contracts/domains/asset-library/events.yaml
  - 01_contracts/domains/asset-library/module-contract.md
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/events.yaml
  - 01_contracts/domains/task-center/module-contract.md
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
  - 01_contracts/domains/sse/openapi.yaml
  - 01_contracts/domains/sse/schema.sql
  - 01_contracts/domains/sse/events.yaml
  - 01_contracts/domains/sse/module-contract.md
  - 01_contracts/domains/workflow-canvas/module-contract.md
  - 01_contracts/error-code-index.md
- architecture:
  - 02_architecture/domains/asset-library.md
  - 02_architecture/domains/task-center.md
  - 02_architecture/domains/application-platform.md
  - 02_architecture/domains/sse.md
  - 02_architecture/domains/workflow-canvas.md
  - 02_architecture/global-architecture.md

## spec-v1.4.0

- commit: 9819f0e6eebbd06ae04a8c81393bf63bedad21a8
- status: released
- confirmed_by: user（2026-07-19 明确要求基于 EngineInstance 当前 object_info 方案修改 SSOT 并发布）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/permissions.yaml
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md

## spec-v1.3.0

- commit: 82b59cf0baf5d147052676b42d4903f554ae14e9
- status: released
- confirmed_by: user（2026-07-18 明确要求发布 release 并完成后端与前端实现）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
  - application-platform
- S1:
  - 00_product/domains/task-center/product-spec.md
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/errors.yaml
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/events.yaml
  - 01_contracts/domains/task-center/module-contract.md
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md
  - 02_architecture/domains/application-platform.md

## spec-v1.1.0

- commit: b3c402b
- status: released
- confirmed_by: user（2026-07-18 明确要求执行 ComfyUI 双来源导入、API 转换和任务中心试运行计划）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
  - task-center
- S1:
  - 00_product/domains/application-platform/product-spec.md
  - 00_product/domains/task-center/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/permissions.yaml
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md
  - 02_architecture/domains/task-center.md

## spec-v1.0.4

- commit: bdfc39c987a23ff00b585f5cb1b02669a95f64e2
- status: released
- confirmed_by: user（2026-07-18 明确要求 EngineInstance 列表返回 endpoint）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml

## spec-v1.0.3

- commit: aa900201ac82ab01a8bc85f0f4953e12a92decab
- status: released
- confirmed_by: user（2026-07-18 明确要求实施调度运行关联，客户端生成校验发现并修正响应字段归属）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
- S2:
  - 01_contracts/domains/task-center/openapi.yaml

## spec-v1.0.2

- commit: a1d86a592c7e41cf95b55b71867198b4c54644eb
- status: released
- confirmed_by: user（2026-07-18 明确要求实施调度目标关联，实施校验发现并修正周期轮次唯一索引冲突）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
- S2:
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/module-contract.md

## spec-v1.0.1

- commit: 19c02f9a837dd1f49cf90d98404dfb1e439fed40
- status: released
- confirmed_by: user（2026-07-18 明确要求实施调度计划目标与运行历史关联修复）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
- S1:
  - 00_product/domains/task-center/product-spec.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md

## spec-v1.0.0

- commit: b928ab5e13d809f837da81ee362b9218c4629fdb
- status: released
- confirmed_by: user（2026-07-17 明确要求直接修改 SSOT 并发布）
- allowed_as_formal_implementation_basis: true
- implementation_gate: 正式服务端切换前仍须完成 Conductor/Go Worker/重启恢复/幂等与禁止重叠 PoC。
- domains:
  - task-center
  - workflow-canvas
  - application-platform
  - asset-library
  - ai-chatting
- S1:
  - 00_product/domains/task-center/product-spec.md
  - 00_product/domains/workflow-canvas/product-spec.md
  - 00_product/domains/application-platform/product-spec.md
  - 00_product/domains/asset-library/product-spec.md
  - 00_product/glossary.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/errors.yaml
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/events.yaml
  - 01_contracts/domains/task-center/module-contract.md
  - 01_contracts/domains/workflow-canvas/openapi.yaml
  - 01_contracts/domains/workflow-canvas/schema.sql
  - 01_contracts/domains/workflow-canvas/errors.yaml
  - 01_contracts/domains/workflow-canvas/permissions.yaml
  - 01_contracts/domains/workflow-canvas/events.yaml
  - 01_contracts/domains/workflow-canvas/module-contract.md
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/permissions.yaml
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/events.yaml
  - 01_contracts/domains/asset-library/module-contract.md
  - 01_contracts/domains/ai-chatting/module-contract.md
  - 01_contracts/error-code-index.md
- architecture:
  - 02_architecture/domains/task-center.md
  - 02_architecture/domains/workflow-canvas.md
  - 02_architecture/domains/application-platform.md
  - 02_architecture/domains/asset-library.md
  - 02_architecture/global-architecture.md

## spec-v0.9.1

- commit: 339cc89c1060389ea7d18715af11ab60b1481fa4
- status: released
- confirmed_by: user（2026-07-17 明确要求实施 AppEngine 周期健康检测计划）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/errors.yaml
  - 01_contracts/domains/application-platform/permissions.yaml
  - 01_contracts/domains/application-platform/events.yaml
  - 01_contracts/domains/application-platform/module-contract.md
# spec-v0.9.2

- AppEngine 健康检测迁移至 Task Center 与 PARALLEL TaskGroup。
- TaskGroup 运行机制和动态子任务契约完成 release。
# spec-v0.9.3

- 修复系统周期任务通用幂等作用域的 schema 约束。
## spec-v1.2.0

- commit: 4edf0a34359fcb743c1262a78fc7b1848ddcd817
- status: released
- confirmed_by: user（2026-07-18 明确要求实施试运行配置快照、详情与再次运行计划）
- allowed_as_formal_implementation_basis: true
- domains:
  - application-platform
- S1:
  - 00_product/domains/application-platform/product-spec.md
- S2:
  - 01_contracts/domains/application-platform/openapi.yaml
  - 01_contracts/domains/application-platform/schema.sql
  - 01_contracts/domains/application-platform/module-contract.md
- architecture:
  - 02_architecture/domains/application-platform.md
