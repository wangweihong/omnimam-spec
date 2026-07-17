# Release Records

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
