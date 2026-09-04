# Model Deployment 产品规格

## 1. 文档目的

本文定义 OmniMAM 平台共享本地模型的高级自定义部署、不可变配置版本、Rollout 历史、运行状态和管理页面语义。`spec-v1.25.3` 彻底替换 `spec-v1.24.x` 的 DTO、数据与 Function Registry 合同，不兼容旧部署数据和旧任务。

当前版本只通过 Task Center 和 Infrastructure 在受控 Docker 节点运行 vLLM 或 LM Studio，不定义模型调用协议或 Model Gateway Adapter。Kubernetes 仅固定未来的事实归属和映射边界，不提供可提交的 Kubernetes DTO。

本领域拥有：

- `ModelDeployment` 稳定业务身份、当前配置选择与生命周期投影。
- 不可变 `ModelDeploymentSpecRevision`，即部署期望配置的唯一事实源。
- `ModelDeploymentRollout`，即配置每次物化为 Runtime 的执行历史。
- 管理员校验配置、创建、应用 Revision、启动、停止、重启、回滚、删除和查看日志的入口。

本领域不拥有：

- Docker Runtime、Endpoint、InfraNode、RuntimeProfile 和 Provider 原始执行事实。
- AtomicTask、TaskAttempt、DAG 重试、取消和执行日志正文。
- Model Gateway Adapter、ProviderAccount、ProviderResource、Binding 或模型调用路由。

## 2. 核心对象

### 2.1 ModelDeployment

`ModelDeployment` 只保存稳定身份、当前 Revision 选择与生命周期投影：

```text
id
name
description
active_spec_revision_id
pending_spec_revision_id
current_rollout_id
desired_state
status
health_status
infra_runtime_id
endpoint_ref
current_atomic_task_id
failure_code
failure_message
resource_version
created_at
updated_at
```

`active_spec_revision_id` 指向最后一次成功达到 `RUNNING/HEALTHY` 的完整配置。Runtime 暂时不可用、停止或重启失败时仍保留该引用。`pending_spec_revision_id` 只在 Rollout 执行期间指向候选配置，Rollout 终态后必须清空。

`current_rollout_id` 用于创建、应用、启动、重启和回滚；`current_atomic_task_id` 只用于停止和删除。两者不得同时存在。`PATCH` 只允许修改 `name` 和 `description`；所有配置变更必须创建新的 Spec Revision。

### 2.2 ModelDeploymentSpecRevision

`ModelDeploymentSpecRevision` 是部署期望配置的唯一事实源：

```text
id
model_deployment_id
revision_no
configuration_mode
serving_engine
runtime_provider
model_source_json
serving_spec_json
runtime_spec_json
runtime_profile_revision_id
spec_digest
created_by
created_at
```

Revision 创建后不可修改或删除；`revision_no` 在单个部署内从 1 严格递增。同一部署内 `spec_digest` 唯一；重复提交经规范化后相同的最终有效配置时返回既有 Revision，不创建重复版本。

`spec_digest` 对以下最终有效配置整体执行 RFC 8785 JSON 规范化，再计算 `sha256:<64 lowercase hex>`：

```text
configuration_mode
serving_engine
runtime_provider
model_source
serving_spec
runtime_spec
runtime_profile_revision_id
```

`serving_engine` 与 `runtime_provider` 是唯一判别字段，JSON 内不得重复保存 `engine` 或 `provider`。可选 RuntimeProfile 必须在创建 Revision 时解析为固定 `runtime_profile_revision_id`；模板与用户输入合并后的最终有效配置必须完整写入 Revision 并参与摘要，Apply 时不得重新读取可漂移模板。

配置模式只允许：

```text
ENGINE_MANAGED
  runtime_spec.mode = STRUCTURED
  serving_spec.mode = STRUCTURED | ARGUMENTS

PROVIDER_NATIVE
  runtime_spec.mode = NATIVE
  serving_spec.mode = METADATA_ONLY
```

不允许其他组合。`ENGINE_MANAGED` 由 Serving Adapter 生成或接收完整有序启动参数；`PROVIDER_NATIVE` 的完整启动命令由 Docker Native 配置拥有，Serving Spec 只保存 Endpoint、健康探测和服务名称等引擎元数据，不能再次表达启动命令。

当前 `serving_engine` 只允许 `vllm`、`lmstudio`，`runtime_provider` 只允许 `docker`。未来增加 Kubernetes 时必须新增独立 `KubernetesRuntimeSpec`，不得把 Docker 字段复用为通用配置。

### 2.3 模型来源与挂载

模型来源支持：

```text
LOCAL_MODEL  逻辑模型名，由 Revision 选定的 ONLINE Docker InfraNode 使用 local_model_root 解析
HOST_PATH    指定节点上的绝对宿主机目录
VOLUME       指定 Docker Volume 和可选 subpath
```

每个来源都必须生成一个规范化、只读的 `MODEL_FILES` 主挂载。`LOCAL_MODEL` 必须是长度 1..128 的单路径段；`HOST_PATH` 必须是目标节点上的绝对目录；`VOLUME` 必须使用合法 Volume 名称且 subpath 不得逃逸。模型主挂载 target 不得与额外挂载 target 重复。

Docker `STRUCTURED` 配置显式保存节点、镜像、Entrypoint、环境变量、额外挂载、端口、网络、设备、资源、健康检查、重启、安全和日志配置；最终 Cmd 来自 `serving_spec`。Docker `NATIVE` 配置保存版本化 Docker Engine 接受的 `container_config`、`host_config` 和 `networking_config`，并由其中的 Entrypoint/Cmd 完整拥有启动命令。

环境变量当前只保存管理员提交的明文字符串值，不支持 SecretRef 或 ConfigRef。环境变量和值可以出现在 Revision 详情中，但不得进入部署列表、Rollout 摘要、可靠事件、Task 参数、普通日志和失败摘要。

### 2.4 ModelDeploymentRollout

`ModelDeploymentRollout` 记录某个 Spec Revision 每次物化为 Runtime 的历史：

```text
id
model_deployment_id
spec_revision_id
kind
status
phase
previous_active_spec_revision_id
previous_infra_runtime_id
dag_task_group_id
infra_runtime_id
rollback_on_failure
rollback_rollout_id
idempotency_key
failure_code
failure_message
created_by
created_at
started_at
completed_at
```

`kind` 固定为：

```text
INITIAL
APPLY
MANUAL_ROLLBACK
START
RESTART
AUTO_ROLLBACK
```

同一部署只能存在一个未终态 Rollout。重新 Apply 较早 Revision 创建 `MANUAL_ROLLBACK`，不创建新 Revision；Apply 当前 active Revision 返回 `REVISION_ALREADY_ACTIVE`，需要重新物化相同配置时必须使用 Restart。`rollback_rollout_id` 在自动回滚记录中指回失败的 Rollout。

## 3. 校验、创建与应用

配置校验入口无副作用。它解析 RuntimeProfile、规范化最终有效配置、检查模式组合、Serving Engine、Runtime Provider、模型来源、目标节点状态、Native JSON 与挂载冲突，并返回规范化配置、`spec_digest`、错误和警告；不创建 Deployment、Revision、Rollout、Task 或 Runtime。

创建 Deployment 时必须在一个业务事务中保存 Deployment、Revision 1、`INITIAL` Rollout 和 outbox，然后异步提交 Rollout DAG。创建 Revision 请求携带部署 `resource_version` 和 `idempotency_key`，只保存通过相同校验的最终有效配置。

Apply 请求携带 `resource_version`、`idempotency_key` 和默认值为 `true` 的 `rollback_on_failure`。Apply 可用于 `STOPPED` 部署，此时表示“应用并启动”，并把 `desired_state` 改为 `RUNNING`。

只有候选 Runtime 达到 RUNNING、命名 Endpoint READY 且健康检查成功后，才能原子切换 `active_spec_revision_id`、`infra_runtime_id` 和 `endpoint_ref`。成功后清理旧 Runtime，并将 Rollout 置为成功终态。

Apply 失败且存在旧 active Revision、`rollback_on_failure=true` 时，服务必须创建关联的 `AUTO_ROLLBACK` Rollout，按旧 Revision 的完整快照重新物化，而不是继续使用旧 Runtime 的未验证状态。自动回滚成功后继续运行旧 Revision；自动回滚失败时 Deployment 进入 `FAILED`，保留两个 Rollout 的失败摘要以供诊断。

## 4. 生命周期

`desired_state`：`RUNNING | STOPPED`。

`status`：

```text
CREATING
DEPLOYING
APPLYING
RUNNING
STOPPING
STOPPED
RESTARTING
ROLLING_BACK
FAILED
DELETING
```

`health_status`：`UNKNOWN | HEALTHY | UNHEALTHY`。

创建、Apply、Start、Restart、Manual Rollback 和 Auto Rollback 都创建 Rollout；Stop 与 Delete 只创建独立 AtomicTask。Start 以 active Revision 创建 `START` Rollout；Restart 以 active Revision 创建 `RESTART` Rollout并受控替换 Runtime。

停止保留 Deployment 和 active Revision，撤销 Endpoint 并停止 Runtime 后进入 `STOPPED/UNKNOWN`。删除先进入 `DELETING`，底层 Runtime 和 Endpoint 清理成功后才删除 Deployment；Revision 与 Rollout 历史随 Deployment 按领域保留策略处理，运行层清理不能单独删除它们。

相同动作和幂等键返回既有执行；同一幂等键对应不同请求摘要必须冲突。不同动作在已有 Rollout 或停止/删除任务运行时返回状态冲突。自动 TaskAttempt 重试必须恢复同一 Rollout 和稳定 Runtime 引用，不能创建并行 Service。

## 5. Task Center 与 Infrastructure 协作

Model Deployment 不直接调用 Infrastructure。vLLM 与 LM Studio 继续使用各自的 `model.validate`、`runtime.ensure`、`runtime.stop` functionRef，但 `spec-v1.24.x` 的 `1.0` 合同全部删除且不设 `RETAINED`；同名合同以 `2.0` 重新定义。

```text
model-deployment.vllm.model.validate@2.0
model-deployment.vllm.runtime.ensure@2.0
model-deployment.vllm.runtime.stop@2.0

model-deployment.lmstudio.model.validate@2.0
model-deployment.lmstudio.runtime.ensure@2.0
model-deployment.lmstudio.runtime.stop@2.0
```

Rollout DAG 使用对应 Serving Engine 的 `model.validate -> runtime.ensure`；需要替换既有 Runtime 时，在 ensure 过程中按 Rollout fence 受控创建候选 Runtime并在成功切换后清理旧 Runtime。停止和删除使用对应 `runtime.stop` AtomicTask。

Task arguments 只携带 `deployment_id`、`rollout_id`、`revision_id`、`spec_digest`、既有 Runtime ID、授权引用和部署资源版本，不复制完整配置、环境变量、模型路径或 Provider Native JSON。Worker 必须通过 Model Deployment 内部 resolver 读取完整 Revision，并同时校验 Revision ID、digest、Rollout 绑定和部署资源版本；任一漂移都必须在调用 Infrastructure 前失败。

Infrastructure source policy 固定为 `MODEL_DEPLOYMENT_SPEC_REVISION`。`CreateRuntimeRequest` 使用 `runtime_provider` 判别联合结构，当前只存在 `DockerRuntimeSpec`。Infrastructure 保存选中 `node_id`、最终 Provider Spec、摘要、Provider Runtime 引用和完整运行身份；STRUCTURED 与 NATIVE 的所有挂载最终都规范化为 `RuntimeMount`。

## 6. 管理页面与信息裁剪

管理页面只对管理员开放，包含：

- 按名称搜索，并按 `serving_engine`、`runtime_provider`、状态和健康筛选的部署列表。
- 配置校验、创建 Deployment、创建 Revision 和应用 Revision 的高级表单。
- Deployment 详情、Revision 完整配置、Rollout 历史、当前任务与运行日志。
- 根据当前状态启用或禁用 Start、Stop、Restart、Apply、Rollback 和 Delete。

Deployment 详情和 Revision 详情可返回完整配置；部署列表、Revision 列表、Rollout 列表/详情摘要和可靠事件只返回摘要及稳定引用，不返回环境变量、完整 `serving_spec`、完整 `runtime_spec` 或模型宿主路径。普通日志和失败摘要必须执行相同裁剪与脱敏。

## 7. 未来 Kubernetes 边界

- `ModelDeploymentSpecRevision` 永远是业务期望配置 SSOT。
- Kubernetes `resourceVersion` 只用于集群对象并发，`generation/observedGeneration` 只表示控制器进度，Deployment rollout revision 只表示 PodTemplate/ReplicaSet 历史；它们都是 Infrastructure Provider 观测事实，不能替代 Spec Revision。
- 一个 Spec Revision 可以生成 Deployment、Service、ConfigMap、PVC 等多个对象，也可以因重建或迁移对应多个 Kubernetes rollout revision，不建立一一对应约束。
- 生成对象必须携带 `deployment_id`、`spec_revision_id`、`spec_digest`、`infra_runtime_id` 标签或注解。
- 业务回滚必须重新 Apply 完整 Spec Revision，不得把 `kubectl rollout undo` 直接暴露为业务回滚。
- Kubernetes 历史清理或集群对象删除不得删除 Spec Revision 和 Rollout 历史。

## 8. 业务规则

1. `BR-MODELDEP-001`：ModelDeployment 是平台共享、管理员管理的模型部署事实。
2. `BR-MODELDEP-002`：`serving_engine` 与 `runtime_provider` 是独立且唯一的判别字段；当前分别只支持 vLLM/LM Studio 与 Docker。
3. `BR-MODELDEP-003`：ModelDeployment 只保存稳定身份、Revision 选择和生命周期投影；PATCH 只允许修改名称与说明。
4. `BR-MODELDEP-004`：Spec Revision 是完整期望配置 SSOT，创建后不可修改或删除，编号严格递增，同部署相同 digest 去重。
5. `BR-MODELDEP-005`：最终有效配置必须按 RFC 8785 规范化并计算 SHA-256；Profile 在创建 Revision 时固定，Apply 时不得重新解析漂移配置。
6. `BR-MODELDEP-006`：配置模式组合必须严格符合 ENGINE_MANAGED 或 PROVIDER_NATIVE 约束，启动命令只能有一个事实拥有者。
7. `BR-MODELDEP-007`：LOCAL_MODEL、HOST_PATH、VOLUME 必须在固定节点安全解析，模型主挂载 target 不得与额外挂载重复。
8. `BR-MODELDEP-008`：环境变量只支持明文 Revision 配置，并从列表、事件、Task 参数、普通日志和失败摘要中排除。
9. `BR-MODELDEP-009`：创建 Deployment 必须原子保存 Deployment、Revision 1 和 INITIAL Rollout，再异步执行。
10. `BR-MODELDEP-010`：同一 Deployment 只允许一个未终态 Rollout；Rollout 与 Stop/Delete AtomicTask 不得并发。
11. `BR-MODELDEP-011`：只有候选 Runtime RUNNING、Endpoint READY 且健康检查成功后才能切换 active Revision 和运行引用。
12. `BR-MODELDEP-012`：Apply 较早 Revision 创建 MANUAL_ROLLBACK；Apply active Revision 必须拒绝，重新物化使用 Restart。
13. `BR-MODELDEP-013`：Apply 失败且允许回滚时创建 AUTO_ROLLBACK；成功继续运行旧 Revision，失败则 Deployment 进入 FAILED。
14. `BR-MODELDEP-014`：Task 参数只保存稳定引用和摘要；Worker resolver 必须校验 Revision、digest、Rollout 和资源版本。
15. `BR-MODELDEP-015`：vLLM 与 LM Studio 使用独立 `2.0` functionRef；旧 `1.0` 合同和数据不兼容、不保留、不迁移。
16. `BR-MODELDEP-016`：Infrastructure 只接受按 runtime_provider 判别的配置，当前仅 Docker，并把两种模式挂载统一物化为 RuntimeMount。
17. `BR-MODELDEP-017`：详情可返回完整配置；列表、Rollout 摘要、事件和普通日志不得泄漏完整配置或环境变量。
18. `BR-MODELDEP-018`：停止保留 Deployment 与 active Revision；删除必须先完成 Runtime 和 Endpoint 清理。
19. `BR-MODELDEP-019`：Kubernetes 的版本、generation 和 rollout revision 仅为 Provider 事实，不得替代或删除业务 Spec Revision/Rollout。
20. `BR-MODELDEP-020`：本版本不新增或修改 Model Gateway Adapter、Binding、ProviderResource 或调用路由。

## 9. 用户故事与验收标准

### US-MODELDEP-001 创建并校验高级部署

作为平台管理员，我希望在保存前校验完整 Serving/Runtime 配置，并创建可追溯的初始部署。

- `AC-MODELDEP-001-01`：校验返回规范化配置、稳定 digest、错误和警告，且不产生任何持久化或运行副作用。
- `AC-MODELDEP-001-02`：创建成功原子产生 Deployment、Revision 1 和 INITIAL Rollout；非法模式、来源、节点、Native JSON 或挂载冲突不创建任何对象。
- `AC-MODELDEP-001-03`：相同最终有效配置得到相同 digest；同部署重复配置返回既有 Revision。
- `AC-MODELDEP-001-04`：Revision 创建后不可更新或删除，并发创建得到唯一且严格递增的 revision_no。

### US-MODELDEP-002 管理配置版本与 Rollout

作为平台管理员，我希望创建、查看并应用不可变 Revision，能够显式回滚到历史配置并查看每次物化记录。

- `AC-MODELDEP-002-01`：应用新 Revision 创建 APPLY；应用较早 Revision 创建 MANUAL_ROLLBACK；应用当前 active Revision 返回稳定错误。
- `AC-MODELDEP-002-02`：Apply 到 STOPPED 部署会设置期望状态为 RUNNING 并启动候选 Runtime。
- `AC-MODELDEP-002-03`：新 Runtime 通过运行、Endpoint 和健康三重门禁后才切换 active Revision。
- `AC-MODELDEP-002-04`：Apply 失败可自动创建关联 AUTO_ROLLBACK，成功恢复旧 Revision，双重失败进入 FAILED。

### US-MODELDEP-003 管理运行生命周期

作为平台管理员，我希望启动、停止、重启和删除部署，并通过稳定历史恢复失败操作。

- `AC-MODELDEP-003-01`：Start 与 Restart 为一等 Rollout；Stop 与 Delete 使用独立 AtomicTask，二者不能与 Rollout 并发。
- `AC-MODELDEP-003-02`：幂等重放恢复同一执行和 Runtime，不创建第二个 Service。
- `AC-MODELDEP-003-03`：停止后 Endpoint 不可解析但 active Revision 保留；删除仅在 Runtime/Endpoint 清理后完成。

### US-MODELDEP-004 安全查看部署诊断

作为平台管理员，我希望查看部署、Revision、Rollout 与日志，同时避免敏感运行配置扩散。

- `AC-MODELDEP-004-01`：详情和 Revision 详情可读取完整配置；列表和 Rollout 只返回摘要与引用。
- `AC-MODELDEP-004-02`：Task 参数、事件、普通日志和失败摘要均不包含环境变量值、完整配置、宿主路径或 Provider 原始响应。
- `AC-MODELDEP-004-03`：状态事件携带 Revision/Rollout/digest/Engine/Provider 稳定字段，客户端据此失效缓存并重新查询 REST 事实。

## 10. 不兼容切换与非目标

发布前必须进入维护窗口：禁止旧部署写操作；等待或取消旧 `model-deployment.*` Task/DAG；按 owner 与稳定引用清理旧 Runtime、Endpoint 和 Docker 对象；按部署 ID 与 functionRef 前缀定向删除旧 Task/Attempt/DAG；清空旧 Model Deployment 表和事件投影；部署新 Schema、API、resolver 与 Function Registry `2.0` 后，验证所有可选 InfraNode 都是 ONLINE Docker 节点再开放。

本版本不迁移、回填或兼容 `spec-v1.24.x` 的 DTO、数据、Runtime、Task 和 Function Registry 合同。

非目标：

- 不新增 Model Gateway Adapter、OperationExecutor、Binding 或 ProviderResource。
- 不支持远程模型自动下载、仓库凭证、Secret/Config 引用或用户私有部署。
- 不提供 Kubernetes、Edge 或 Local Process DTO，不执行多节点自动调度或自动扩缩容。
- 不在本仓库维护 Docker image、实际运行时配置、数据库 migration 或实现代码。
