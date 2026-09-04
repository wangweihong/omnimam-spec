# OmniMAM Spec Handoff

## Current goal and status

- Goal: 在已发布 `spec-v1.25.2` 基线上实现模型部署高级自定义重构计划，并以未占用版本 `spec-v1.25.3` 发布。
- Status: 模型部署 S1/S2 重构、冲突审计与目标验证均已完成；正在创建 `spec-v1.25.3` 规格提交与发布记录。

## Work completed in this session

- 完整读取 `skills/spec-workflow/SKILL.md`、`S1.md`、`S2.md` 和用户计划附件。
- 确认远端 `spec-v1.25.1` 已用于 Task Center 历史合同修复，`spec-v1.25.2` 已用于 Provider Capability/Agent/AppStudio 对齐，二者均不可移动。
- 从远端已完成发布链 `origin/codex/spec-v1.25.2` 创建 `codex/spec-v1.25.3`。
- 已重放本地规格提交 `f44cb30f97046be7c17ddfc491542ffba7aa6fba`；唯一文本冲突为本文件。
- Model Deployment S1 已彻底替换 `spec-v1.24.x`：拆分 `serving_engine`/`runtime_provider`，新增不可变 `ModelDeploymentSpecRevision` 与一等 `ModelDeploymentRollout`。
- 固化 ENGINE_MANAGED/PROVIDER_NATIVE 组合、LOCAL_MODEL/HOST_PATH/VOLUME、RFC 8785 + SHA-256、Revision 去重/不可变、Apply/手动回滚/自动回滚和 active Revision 三重健康门禁。
- Model Deployment OpenAPI 升级为 2.0，新增无副作用 Validation、Revision 创建/查询/Apply、Rollout 查询；同步设计态 Schema、错误、权限说明、事件和模块合同。
- Task Center 六个 `model-deployment.*@1.0` 条目已删除且不设 RETAINED，同名合同升级为 `2.0`；Infrastructure Runtime 合同同步为 Docker STRUCTURED/NATIVE 联合结构。
- 已把重构新增事实中的版本标记从已占用的 `spec-v1.25.1` 统一顺延为 `spec-v1.25.3`；既有 `v1.25.1/v1.25.2` 发布记录未改写。

## Current in-progress work

- 创建规格提交与 annotated tag，然后登记 Release 元数据并推送新分支和 tag。

## Files added, modified, renamed, or removed

- Modified: `00_product/domains/model-deployment/product-spec.md`。
- Modified: `01_contracts/domains/model-deployment/openapi.yaml`、`schema.sql`、`errors.yaml`、`permissions.yaml`、`events.yaml`、`module-contract.md`。
- Modified: `00_product/domains/task-center/product-spec.md`、`01_contracts/domains/task-center/function-registry.yaml`、`function-registry.schema.yaml`、`module-contract.md`。
- Modified: `00_product/domains/infrastructure/product-spec.md`、`01_contracts/domains/infrastructure/openapi.yaml`、`schema.sql`、`errors.yaml`、`permissions.yaml`、`events.yaml`、`module-contract.md`。
- Modified: `02_architecture/domains/model-deployment.md`、`02_architecture/domains/task-center.md`、`02_architecture/domains/infrastructure.md`。
- Modified: `domains/model-deployment/context.md`、`domains/task-center/context.md`、`domains/infrastructure/context.md`、`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`。
- Modified: `01_contracts/error-code-index.md`、`CHANGELOG.md`、`docs/HANDOFF.md`。
- Added/renamed/removed: 无。

## Key architectural or design decisions

- 已发布 tag 不可复用或移动；原计划版本号由 `spec-v1.25.1` 顺延为 `spec-v1.25.3`，业务与契约语义不变。
- 以远端 `spec-v1.25.2` 发布链为基线，保留其中已发布的 Agent/AppStudio/Model Gateway 合同。
- `agent.runtime.ensure@1.0/@1.1` 必须继续 RETAINED，`@1.2` 必须继续 ACTIVE；它们不属于本计划要求定向删除的六个 Model Deployment 合同。
- ModelDeployment 不保存可变配置正文；完整期望配置只存在于不可变 Spec Revision。
- Rollout 是 INITIAL/APPLY/MANUAL_ROLLBACK/START/RESTART/AUTO_ROLLBACK 的持久历史；Stop/Delete 继续使用独立 AtomicTask，并与 Rollout 互斥。
- 候选 Runtime 必须同时达到 RUNNING、Endpoint READY、HEALTHY 后才能切换 active Revision；失败可用旧 Revision 创建 AUTO_ROLLBACK。
- Task 参数不复制完整配置。Worker resolver 同时校验 Deployment、Rollout、Revision、digest 与资源版本，解析结果只存在于当前 Attempt 内存。
- 当前只定义 Docker DTO。未来 Kubernetes 的 resourceVersion、generation/observedGeneration 与 Provider rollout revision 归 Infrastructure 观测，不能替代业务 Spec Revision/Rollout。
- `spec-v1.25.3` 不兼容旧模型部署 DTO、数据、Runtime、Task 和六个 Model Deployment Function Registry `1.0` 合同，必须维护窗口定向清理，不迁移。

## API, schema, dependency, or configuration changes

- 新增 `POST /api/v1/model-deployment-spec-validations`。
- 新增 Revision list/create/get/apply 与 Rollout list/get API。
- 新增 `model_deployment_spec_revisions`、`model_deployment_rollouts`；重构 `model_deployments` active/pending/current 执行字段。
- Model Deployment 列表筛选改为 `serving_engine/runtime_provider/status/health_status`。
- Task Center 六个同名合同固定为 `2.0`，并登记新的精确摘要。
- Infrastructure Runtime API/Schema 使用 `runtime_provider` 与 DockerRuntimeSpec；Model Deployment Runtime 保存 Spec Revision/digest 和最终 Provider 运行身份。
- 不新增运行时实现、migration、依赖或 CI/CD 配置。

## Verification performed and remaining checks

- 已核对远端 `spec-v1.25.1` tag target 为 `bdf05de2955028f10e8fab9a63098dad623cb3f3`。
- 已核对远端 `spec-v1.25.2` tag target 为 `e0e698674f480f1c31cb9f9657eabf707b3167ef`。
- 已确认自动合并保留 `agent.runtime.ensure@1.0/@1.1/@1.2`，六个 Model Deployment 合同均为唯一 `2.0` ACTIVE。
- 10 份目标 YAML 解析通过；Model Deployment/Infrastructure OpenAPI 本地 `$ref` 与 `/api/v1` 路径检查通过。
- Function Registry 通过 Draft 2020-12 meta-schema；六个 Model Deployment `2.0` 合同摘要复算一致。
- 21 个 Model Deployment 错误码的 code/value 文件内唯一；目标 `provider_type` 残留检查和 `git diff --check` 通过。
- Remaining: 核对规格提交、tag、Release 记录和远端推送状态。

## Outstanding tasks

- 在 `RELEASE.md` 登记 `spec-v1.25.3` 与 implementation gate。
- 创建并推送 `spec-v1.25.3` tag、`codex/spec-v1.25.3` 分支与 tag 后发布元数据。

## Known issues and risks

- 发布实施必须先停止旧模型部署写入并清除旧 Model Deployment Runtime/Endpoint、Task/Attempt/DAG、领域表和事件投影；任何旧 `1.0` 任务都不能用 `2.0` 恢复。
- Model Deployment 环境变量按计划为 Revision 中的管理员明文配置；虽从列表、事件、Task 与日志裁剪，持久化访问控制和审计仍是实施门禁。
- 本地旧 `master` 与远端发布链已分叉；本任务只推送新分支，不直接推送本地 `master`。
- `f44cb30` 基于旧基线创建；组合审计已确认非目标 Agent/AppStudio/Model Gateway 文件未被本次重构修改。

## Exact recommended next step

提交当前版本顺延与验证检查点，以该规格提交创建 `spec-v1.25.3` annotated tag。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
