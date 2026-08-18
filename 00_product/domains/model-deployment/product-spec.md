# Model Deployment 产品规格

## 1. 文档目的

本文定义 OmniMAM 平台共享本地模型的部署、运行状态和管理页面语义。当前版本只通过 Task Center 和 Infrastructure 在受控 Docker 节点启动 vLLM 或 LM Studio Service，不定义模型调用协议或 Model Gateway Adapter。

本领域拥有：

- `ModelDeployment` 部署配置与生命周期事实。
- 管理员部署、启动、停止、重启、删除和日志查看入口。
- 当前关联 AtomicTask、InfraRuntime、Endpoint 引用和安全失败摘要的业务投影。

本领域不拥有：

- Docker Runtime、Endpoint 和 RuntimeProfile 实现事实。
- AtomicTask、TaskAttempt、重试、取消和执行日志正文。
- Model Gateway Adapter、ApplicationEngineInstance、EngineCapabilityBinding 或模型调用路由。
- 用户私有 Provider、用户默认模型或模型能力目录。

## 2. 核心对象

`ModelDeployment` 表示一个平台管理员创建的本地模型运行实例。

核心字段：

```text
id
name
description
provider_type
model_name
desired_state
status
health_status
infra_runtime_id
endpoint_ref
current_dag_task_group_id
failure_code
failure_message
last_health_check_at
resource_version
created_at
updated_at
```

`provider_type` 只允许：

```text
vllm
lmstudio
```

用户只提交逻辑 `model_name`，底层部署参数由对应 Provider 的 RuntimeProfile 派生。`model_name` 必须是一个长度 1..128 的单路径段，只允许 ASCII 字母、数字、点、下划线和短横线，且首字符必须是字母或数字。

Infrastructure 使用启动配置 `local_model_root` 与固定规则拼接实际路径：

```text
<local_model_root>/<model_name>
```

拼接、规范化、存在性、可读性和目录类型校验都在 Infrastructure 边界完成。

## 3. 生命周期

`desired_state`：

```text
RUNNING
STOPPED
```

`status`：

```text
CREATING
DEPLOYING
RUNNING
STOPPING
STOPPED
RESTARTING
FAILED
DELETING
```

`health_status`：

```text
UNKNOWN
HEALTHY
UNHEALTHY
```

创建部署时，服务先持久化 `CREATING` 资源，再以部署 ID 和资源版本幂等创建 Provider 专属 `DAGTaskGroup`。DAG 被接受后状态进入 `DEPLOYING`；模型校验、Docker Service 启动和 Provider 就绪验证依次成功后进入 `RUNNING/HEALTHY`。

启动用于 `STOPPED` 部署。停止保留 `ModelDeployment`，撤销 Endpoint 并将 Runtime 停止后进入 `STOPPED`。重启针对当前部署执行受控替换，必须复用同一 `ModelDeployment`，不能创建第二个部署资源。删除先进入 `DELETING`，底层 Runtime 和 Endpoint 清理成功后才删除部署资源；清理失败时保留资源和安全失败摘要以便重试。

同一部署同一时间只允许一个未终态生命周期 DAG 或停止 AtomicTask。相同动作和幂等键返回既有执行，不同动作在已有执行运行时返回状态冲突。自动 TaskAttempt 重试必须恢复同一 InfraRuntime 或受控替换流程，不能重复创建并行模型 Service。

## 4. Task Center 与 Infrastructure 协作

Model Deployment 不直接调用 Infrastructure。部署、启动和重启必须先创建 Provider 专属 DAGTaskGroup；停止和删除创建 Provider 专属 AtomicTask。所有节点均由 Task Worker 通过唯一 Infra Adapter 调用 Infrastructure。

vLLM 与 LM Studio 使用完全独立的 DAG 模板和 functionRef，不允许由一个通用 handler 根据 `provider_type` 分支：

```text
model-deployment.vllm.model.validate@1.0
model-deployment.vllm.runtime.ensure@1.0
model-deployment.vllm.runtime.stop@1.0

model-deployment.lmstudio.model.validate@1.0
model-deployment.lmstudio.runtime.ensure@1.0
model-deployment.lmstudio.runtime.stop@1.0
```

创建和启动使用固定两节点 DAG：`model.validate -> runtime.ensure`。重启使用固定三节点 DAG：`runtime.stop -> model.validate -> runtime.ensure`。停止和删除使用各 Provider 独立的 `runtime.stop` AtomicTask。Task 输入只携带部署 ID、模型名、Provider 专属固定 RuntimeProfile 引用、授权引用、既有 InfraRuntime ID 和资源版本，不携带模型路径。

Provider 与 RuntimeProfile 固定映射：

```text
vllm     -> model.vllm
lmstudio -> model.lmstudio
```

两个 RuntimeProfile 均为 Docker `SERVICE`，只发布 `INTERNAL` Endpoint，模型文件以只读方式挂载。它们必须分别定义镜像、Entrypoint、容器端口、模型格式校验、启动参数和健康检查，不能共享 Provider 专用配置、handler 或结果解析器。调用方不能覆盖这些 Profile 事实。

## 5. 管理页面

管理页面仅对拥有管理权限的管理员开放，包含：

- 按名称搜索，按 Provider、状态和健康状态筛选的部署列表。
- 创建部署表单，只输入名称、说明、Provider 和模型名。
- 详情中的状态、健康、当前任务、创建更新时间和安全失败摘要。
- 根据当前状态启用或禁用启动、停止、重启和删除动作。
- 当前部署的运行日志分页查看。

页面展示 Model Deployment、DAG/Task 和 Infrastructure 合同提供的运行诊断信息。

## 6. 业务规则

1. `BR-MODELDEP-001`：ModelDeployment 是平台共享、管理员管理的本地模型部署事实，不属于用户私有模型。
2. `BR-MODELDEP-002`：创建请求只接受稳定 Provider 和逻辑 model_name，不接受任何模型路径、能力列表或 Docker 参数。
3. `BR-MODELDEP-003`：Infrastructure 必须使用 `local_model_root/model_name` 派生实际路径，并拒绝绝对路径、分隔符、遍历、符号链接逃逸、缺失、不可读或非目录目标。
4. `BR-MODELDEP-004`：部署、启动和重启必须创建 Provider 专属固定 DAGTaskGroup；所有 Docker 生命周期写操作由 DAG 节点或停止 AtomicTask 经 Task Worker 和 Infra Adapter 执行，Model Deployment 不得直连 Docker 或 Infrastructure。
5. `BR-MODELDEP-005`：vLLM 与 LM Studio 分别固定使用独立 RuntimeProfile、DAG 模板、functionRef 和模型校验，不得用 Provider 分支共享专用 handler。
6. `BR-MODELDEP-006`：同一部署只允许一个未终态生命周期 DAG 或停止任务；幂等重放返回原执行，冲突动作不得启动第二个 Runtime。
7. `BR-MODELDEP-007`：只有 Runtime RUNNING、INTERNAL Endpoint READY 且 Profile 健康检查成功时，部署才能进入 RUNNING/HEALTHY。
8. `BR-MODELDEP-008`：停止保留部署资源，删除必须先完成 Runtime 和 Endpoint 清理；失败时保留可重试事实。
9. `BR-MODELDEP-009`：管理投影聚合部署状态、当前 DAG/Task、Runtime、Endpoint、健康和日志诊断，并保持来源事实的引用关系。
10. `BR-MODELDEP-010`：现有 Model Gateway Adapter、EngineInstance、Binding 和模型调用路由在本版本保持不变。

## 7. 用户故事与验收标准

### US-MODELDEP-001 管理本地模型部署

作为平台管理员，我希望输入 Provider 和模型名部署本地模型，使平台通过受控 Docker Service 管理其生命周期，而无需输入文件路径或 Docker 参数。

- `AC-MODELDEP-001-01`：创建 vLLM 或 LM Studio 部署后返回持久化资源和对应 Provider 的异步 DAG 摘要。
- `AC-MODELDEP-001-02`：合法模型名由 Infrastructure 拼接到配置根目录；目标不存在、不可读、不是目录或逃逸根目录时部署失败且不启动容器。
- `AC-MODELDEP-001-03`：Provider 自动映射到固定 RuntimeProfile，任意镜像、命令、端口、路径或能力字段均被请求 Schema 拒绝。
- `AC-MODELDEP-001-04`：Provider 专属模型校验与 Runtime ensure 节点全部成功后部署才进入 RUNNING；任一节点失败时保存失败原因。

### US-MODELDEP-002 管理运行生命周期

作为平台管理员，我希望启动、停止、重启和删除本地模型部署，并查看当前任务和日志，以便恢复失败实例和释放资源。

- `AC-MODELDEP-002-01`：STOPPED 部署可以启动，RUNNING 部署可以停止或重启，非法状态动作返回稳定业务错误。
- `AC-MODELDEP-002-02`：同一动作幂等重放不创建重复 Runtime；已有生命周期任务运行时拒绝冲突动作。
- `AC-MODELDEP-002-03`：停止后部署保留且 Endpoint 不可解析；删除只有在底层清理完成后才移除资源。
- `AC-MODELDEP-002-04`：列表、详情和日志返回管理所需的状态、任务与运行诊断，并保持部署与来源任务、Runtime 的稳定引用关系。

## 8. 非目标

- 不新增或修改 Model Gateway Adapter、OperationExecutor、EngineInstance 或 Binding。
- 不接受 `capability_definition_ids` 或其他模型能力声明。
- 不支持远程模型 ID、自动下载、模型仓库凭证或缓存管理。
- 不支持用户私有部署、多节点调度、Kubernetes、Edge 或 Local Process。
- 不在本仓库维护 Docker image、实际运行时配置、实现代码或数据库 migration。
