# Release Records

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
