# Model Deployment Module Contract

本文档定义 `model-deployment` 的 S2 模块边界。产品语义以 `00_product/domains/model-deployment/product-spec.md` 为准。

## 1. 模块职责

| 模块 | 负责 | 不负责 |
| --- | --- | --- |
| deployment-api | 管理员 CRUD、生命周期动作、列表详情和日志 facade | Docker、模型路径拼接、模型调用 |
| deployment-lifecycle | 状态机、幂等键、Provider 专属 DAG/Task 创建和结果单调投影 | DAG/AtomicTask 执行、Runtime 状态机 |
| deployment-task-observer | 消费 DAG/Task 终态并更新部署、Runtime/Endpoint 引用和安全错误 | 修改 Task 或 Infra 私有事实 |

## 2. Task Center 边界

- vLLM 使用 `model-deployment.vllm.model.validate/runtime.ensure/runtime.stop@1.0`；LM Studio 使用对应 `model-deployment.lmstudio.*@1.0`，两组合同不得共享 Provider 分支 handler。
- DEPLOY/START 固定创建 `validate -> ensure` DAG；RESTART 固定创建 `stop -> validate -> ensure` DAG；STOP/DELETE 创建 Provider 专属 stop AtomicTask。
- 创建 DAG/Task 前必须校验管理员权限、资源版本、状态和部署内唯一活动生命周期执行。
- arguments 只包含部署 ID、模型名、Provider 专属固定 Profile ID/Revision、既有 InfraRuntime ID、授权引用和资源版本。
- arguments 使用 Provider 专属精确 Schema，并且不包含 `capability_definition_ids`。
- Task 结果只允许 `infra_runtime_id`、`endpoint_ref`、Runtime/健康状态和诊断摘要。
- 自动 Attempt 重试使用同一部署和 DAG 节点幂等作用域；手动动作使用新的业务幂等键，但不得并发创建第二个生命周期执行。

## 3. Infrastructure 边界

- Model Deployment 不直接调用 Infrastructure；Task Worker 使用唯一 Infra Adapter。
- Provider 到 Profile 映射固定为 `vllm -> model.vllm`、`lmstudio -> model.lmstudio`。
- Infrastructure 根据 Profile 和 `model_name` 生成内部 `local-model://` source binding，并在 Docker Provider 前解析为 `local_model_root/model_name`。
- Runtime owner 固定为 `owner_domain=model-deployment`、`owner_reference=ModelDeployment.id`。
- Endpoint 固定 `INTERNAL`；普通 Model Deployment API 返回稳定 `endpoint_ref`，不返回解析后的地址。
- 日志 facade 通过部署 owner 范围读取 Task/Infra 日志投影。

## 4. 状态投影

| Task 动作 | 接受后状态 | 成功状态 | 失败状态 |
| --- | --- | --- | --- |
| DEPLOY DAG | DEPLOYING | RUNNING/HEALTHY | FAILED |
| START DAG | DEPLOYING | RUNNING/HEALTHY | FAILED |
| RESTART DAG | RESTARTING | RUNNING/HEALTHY | FAILED |
| STOP | STOPPING | STOPPED/UNKNOWN | FAILED |
| DELETE | DELETING | 删除资源并发布 deleted 事件 | FAILED |

DAG/Task/Infra 事件乱序时只接受与 `current_dag_task_group_id` 或 `current_atomic_task_id` 匹配且资源版本不回退的结果。旧执行终态不得覆盖新动作。

## 5. 依赖与被依赖

- 依赖 `identity` PrincipalContext 和权限结果。
- 依赖 `task-center` AtomicTask、TaskAttempt、日志和版本化 function registry。
- 依赖 `infrastructure` Docker Service、RuntimeProfile、MODEL_FILES 挂载、Endpoint 和健康检查。
- 当前没有 Model Gateway、User Model、Application Platform 或 AI Chat 依赖。

## 6. S1 追溯

- 用户故事：`US-MODELDEP-001`、`US-MODELDEP-002`
- 业务规则：`BR-MODELDEP-001` 至 `BR-MODELDEP-010`
