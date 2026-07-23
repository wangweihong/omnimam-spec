# Release Records

## spec-v1.7.4

- commit: 81e6cfd（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-23 确认继续实施管理员 Blob/StorageBackend 独立详情接口，并明确管理员全量返回物理定位与配置）
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
  - 01_contracts/domains/asset-library/module-contract.md
- architecture:
  - 02_architecture/domains/asset-library.md
- implementation_gate: Server 必须对 Blob 详情及 StorageBackend 列表/详情/创建/更新执行 ADMIN/SUPER_ADMIN 鉴权，管理员响应原样返回 object_key、root 与 config，普通素材和跨域摘要不得传播这些字段；StorageBackend 列表的 items/backends 必须来自同一次查询且内容相同。

## spec-v1.7.3

- commit: ab677e7（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-23 明确要求实施系统任务名称多语言方案，且方案要求先发布 SSOT）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
- S1:
  - 00_product/domains/task-center/product-spec.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md
- implementation_gate: Server 必须保留原 `name`，仅对持久化为 SYSTEM 且具有有效 name key/参数的新资源返回至少包含 `zh-CN` 和 `en-US` 的多语言映射；公开请求不得注入系统名称元数据，历史资源不得按文本或 createdBy 启发式回填。

## spec-v1.7.2

- commit: 4d601ce（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-22 明确要求直接补充缺失 S1/S2 并发布 spec-v1.7.2）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
  - asset-library
- S1:
  - 00_product/domains/task-center/product-spec.md
  - 00_product/domains/asset-library/product-spec.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/events.yaml
  - 01_contracts/domains/task-center/module-contract.md
  - 01_contracts/domains/asset-library/openapi.yaml
  - 01_contracts/domains/asset-library/permissions.yaml
  - 01_contracts/domains/asset-library/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md
  - 02_architecture/domains/asset-library.md
- implementation_gate: Server 必须先实现 DAG trigger/时间与 dag_node_key migration、确定性节点聚合、规范化事件/时间线、日志 cursor/筛选/下载、admin-only executor 裁剪及 Asset Library 有界批量摘要，再允许 Web 以本 release 作为 DAG 运行工作台正式契约；不得新增第二套运行历史、暴露运行时 payload/Worker 内部标识、跨域读取私表或形成 Artifact N+1。

## spec-v1.7.1

- commit: 865741c（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-22 明确要求实施 Task Center 执行日志修复方案并先发布 SSOT）
- allowed_as_formal_implementation_basis: true
- domains:
  - task-center
- S1:
  - 00_product/domains/task-center/product-spec.md
- S2:
  - 01_contracts/domains/task-center/openapi.yaml
  - 01_contracts/domains/task-center/schema.sql
  - 01_contracts/domains/task-center/errors.yaml
  - 01_contracts/domains/task-center/permissions.yaml
  - 01_contracts/domains/task-center/module-contract.md
- architecture:
  - 02_architecture/domains/task-center.md
- implementation_gate: Server 必须通过 WorkflowRuntime 消费方接口代理 Conductor task log，执行 AtomicTask/Attempt 归属授权、双重脱敏、分页排序和 best-effort 写入；不得新增日志业务表、复用 Asset Library 媒体存储、暴露 Conductor API/UI 或把日志写入失败变成任务失败。

## spec-v1.7.0

- commit: 467abaa（规格变更提交；release 记录提交随后追加）
- status: released
- confirmed_by: user（2026-07-22 明确要求发布 Canvas release 并推送到远端仓库）
- allowed_as_formal_implementation_basis: true
- domains:
  - workflow-canvas
  - sse
- S1:
  - 00_product/domains/workflow-canvas/product-spec.md
  - 00_product/domains/sse/product-spec.md
- S2:
  - 01_contracts/domains/workflow-canvas/openapi.yaml
  - 01_contracts/domains/workflow-canvas/schema.sql
  - 01_contracts/domains/workflow-canvas/errors.yaml
  - 01_contracts/domains/workflow-canvas/permissions.yaml
  - 01_contracts/domains/workflow-canvas/events.yaml
  - 01_contracts/domains/workflow-canvas/module-contract.md
  - 01_contracts/domains/sse/openapi.yaml
  - 01_contracts/domains/sse/events.yaml
  - 01_contracts/domains/sse/module-contract.md
  - 01_contracts/error-code-index.md
- architecture:
  - 02_architecture/domains/workflow-canvas.md
  - 02_architecture/global-architecture.md
- implementation_gate: 正式 Server/Web 实施前仍需完成人工 API 兼容评审、Task Center 内容寻址 DAG 注册/批量摘要协作、Asset Library producer context 协作、identity 权限绑定和旧 DTO/schema 迁移门禁。

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
