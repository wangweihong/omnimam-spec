# Model Deployment Context

## 1. 领域职责

`model-deployment` 管理平台共享 vLLM/LM Studio 模型部署、不可变期望配置、Rollout 历史、生命周期、健康和管理投影。Docker 写操作全部通过 Task Center 与 Infrastructure 执行。

## 2. 核心对象与规则

- `ModelDeployment` 只保存稳定身份、active/pending Spec Revision 和生命周期投影；PATCH 只改名称/说明。
- `ModelDeploymentSpecRevision` 是完整期望配置 SSOT，创建后不可变；最终有效配置经 RFC 8785 + SHA-256 摘要，同部署重复 digest 去重。
- `ModelDeploymentRollout` 记录 INITIAL/APPLY/MANUAL_ROLLBACK/START/RESTART/AUTO_ROLLBACK；同部署只允许一个未终态 Rollout。
- `serving_engine=vllm|lmstudio` 与 `runtime_provider=docker` 分离；配置模式只允许 ENGINE_MANAGED 或 PROVIDER_NATIVE 的固定组合。
- 模型来源支持 LOCAL_MODEL、HOST_PATH、VOLUME；模型主挂载与额外挂载 target 不得冲突。
- Task 参数只保存 Deployment/Rollout/Revision/digest 等稳定引用，Worker 通过内部 resolver 校验并读取完整 Revision。
- 新 Runtime 达到 RUNNING、Endpoint READY、健康成功后才切换 active Revision；Apply 失败可创建 AUTO_ROLLBACK。
- 列表、Rollout、事件、Task 和普通日志不返回完整配置、环境变量或宿主路径。
- `spec-v1.25.1` 不兼容 `spec-v1.24.x` DTO、数据、Runtime、Task 和 Function Registry `1.0` 合同。

## 3. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/model-deployment/product-spec.md` | S1 Released (`spec-v1.25.1`) | Revision、Rollout、高级配置、生命周期和页面语义 |
| `01_contracts/domains/model-deployment/openapi.yaml` | S2 Released (`spec-v1.25.1`) | 管理、校验、Revision、Apply 与 Rollout API |
| `01_contracts/domains/model-deployment/schema.sql` | S2 Released (`spec-v1.25.1`) | Deployment、Spec Revision、Rollout 设计态结构 |
| `01_contracts/domains/model-deployment/errors.yaml` | S2 Released (`spec-v1.25.1`) | 配置、Revision、Rollout 与 Runtime 错误 |
| `01_contracts/domains/model-deployment/permissions.yaml` | S2 Released (`spec-v1.25.1`) | 管理权限 |
| `01_contracts/domains/model-deployment/events.yaml` | S2 Released (`spec-v1.25.1`) | 状态、Rollout 和删除事件 |
| `01_contracts/domains/model-deployment/module-contract.md` | S2 Released (`spec-v1.25.1`) | Task Center resolver 与 Infrastructure 边界 |
| `02_architecture/domains/model-deployment.md` | 参考 (`spec-v1.25.1`) | Revision、Rollout、回滚和 Provider 映射 |

## 4. 直接依赖

- `task-center`：AtomicTask、DAG、`model-deployment.*@2.0`、重试、取消和日志。
- `infrastructure`：DockerRuntimeSpec、InfraNode、InfraRuntime、RuntimeMount、Endpoint 和 Provider 对账。

## 5. 当前状态

本领域当前 S1/S2 由 `spec-v1.25.1` 发布并彻底替换 `spec-v1.24.x`；实施必须先按 Release gate 清理旧数据和旧执行，不得兼容恢复 `1.0` 合同。
