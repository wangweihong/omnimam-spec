# Model Deployment Module Contract

本文档定义 `model-deployment` 的 S2 模块边界。产品语义以 `00_product/domains/model-deployment/product-spec.md` 为准；本合同从 `spec-v1.25.3` 起不兼容 `spec-v1.24.x`。

## 1. 模块职责

| 模块 | 负责 | 不负责 |
| --- | --- | --- |
| deployment-api | 管理员 CRUD、无副作用校验、Revision/Rollout 查询、生命周期和脱敏日志 facade | Docker 调用、Task 执行、模型调用 |
| spec-service | 最终配置解析、模式/来源/挂载/节点/Native JSON 校验、RFC 8785 摘要、Revision 幂等与不可变性 | Apply 时重新读取可漂移模板 |
| rollout-service | Rollout 状态机、唯一活动执行、active/pending 切换、自动回滚、幂等键和资源版本 fence | AtomicTask/InfraRuntime 状态机 |
| task-spec-resolver | 按受信 Worker 请求解析完整 Revision，并校验 deployment/rollout/revision/digest/resource_version | 向 Task 参数或日志返回完整配置 |
| task-observer | 消费 DAG/Task 终态，单调投影 Runtime/Endpoint/健康和安全错误 | 修改 Task Center 或 Infrastructure 私有事实 |

## 2. Revision 与摘要边界

- `ModelDeploymentSpecRevision` 是期望配置 SSOT，应用角色不得获得 UPDATE/DELETE 权限。
- 同一 Deployment 内 `revision_no` 通过事务锁或等效串行化机制严格递增；`spec_digest` 唯一，重复配置返回既有 Revision。
- `CreateRevision` 的幂等键只在同一 Deployment 的创建 Revision 操作内唯一，不占用 Rollout 动作的键。`request_digest` 是对提交对象 `{"spec": <请求中的 spec>, "resource_version": <请求中的 resource_version>}` 执行 RFC 8785 JSON 规范化后的 SHA-256；不包含键或 Profile 解析后的配置。同键先查询不可变请求映射：摘要相同直接返回所指 Revision，不重新解析 Profile 或检查当前资源版本；摘要不同返回 `ERR_MODELDEP_IDEMPOTENCY_CONFLICT`。
- 新键经配置校验后若 `spec_digest` 已存在，返回既有 Revision 并在同一事务保存新键映射，沿用既有的配置去重优先于资源版本检查的语义；新键且配置摘要不存在时，须通过资源版本检查再原子创建 Revision 与映射。映射仅保存键、两个摘要、时间及同部署目标关系，不保存配置正文，不作为公开资源更新或删除。升级时映射为空，不回填无法还原的旧键；精确冲突保证从首次记录该键起生效。
- 摘要输入是 Profile 已解析后的最终有效配置，使用 RFC 8785 + SHA-256；`serving_engine` 和 `runtime_provider` 不得在 JSON 子对象重复。
- `ENGINE_MANAGED` 只接受 Docker STRUCTURED 与 Serving STRUCTURED/ARGUMENTS；`PROVIDER_NATIVE` 只接受 Docker NATIVE 与 Serving METADATA_ONLY。
- 环境变量为 Revision 详情中的明文管理员配置，不支持 Secret/Config 引用，并从所有摘要、事件、Task 参数、日志与普通错误中裁剪。

## 3. Rollout 与状态 fence

- 创建必须原子保存 Deployment、Revision 1、INITIAL Rollout 和 outbox；异步 Task 提交失败保留可恢复 reservation。
- APPLY、MANUAL_ROLLBACK、START、RESTART、AUTO_ROLLBACK 都创建 Rollout；STOP/DELETE 创建 AtomicTask。
- `current_rollout_id` 与 `current_atomic_task_id` 互斥；同一 Deployment 的 PENDING/RUNNING Rollout 由数据库部分唯一索引和服务事务双重保证。
- Task/Infra 事件只有在 deployment ID、current rollout/task ID 与资源版本 fence 全部匹配时才能推进投影；旧执行迟到事件不得覆盖新状态。
- 候选 Runtime 必须满足 RUNNING、命名 Endpoint READY、健康检查成功，才能原子切换 active Revision、Runtime 与 Endpoint。
- Apply 失败且允许回滚时，先将失败 Rollout 置为终态，再原子创建关联 AUTO_ROLLBACK；自动回滚重新解析旧 Revision 的完整快照，不读取漂移模板。

## 4. Task Center 边界

- vLLM 使用 `model-deployment.vllm.model.validate/runtime.ensure/runtime.stop@2.0`；LM Studio 使用对应 `model-deployment.lmstudio.*@2.0`。
- 六个 `1.0` 合同不设 RETAINED，部署前必须清除其非终态/历史 Task、Attempt 和 DAG 后再加载 registry `2.0`。
- arguments 只包含 `deployment_id`、可选 `rollout_id`、`revision_id`、`spec_digest`、既有 Runtime ID、授权引用和 `expected_resource_version`，不得包含完整配置或环境变量。
- validate/ensure Worker 必须先调用 `ResolveModelDeploymentSpecRevision`，同时校验 Revision ID、digest、Rollout 和部署资源版本，再生成 Infrastructure 请求。
- source policy 固定为 `MODEL_DEPLOYMENT_SPEC_REVISION`；结果只返回稳定 Runtime/Endpoint 引用、运行/健康状态与安全诊断。

内部 resolver 合同：

```text
ResolveModelDeploymentSpecRevision(
  caller = task-worker,
  deployment_id,
  rollout_id,
  revision_id,
  spec_digest,
  expected_resource_version,
  authorization_ref
) -> FinalEffectiveSpec
```

返回结果只能在当前 Attempt 内存中转换为 Infra 请求，禁止写入 AtomicTask arguments/result、事件、普通日志或 Task 数据库。

## 5. Infrastructure 边界

- Model Deployment 的 Runtime 生命周期写入不直接调用 Infrastructure；Task Worker 使用唯一 Infra Adapter。管理员配置候选与提交前校验是只读例外：Model Deployment API 以受信 apiserver 服务身份读取 Infrastructure 的节点/Profile 列表与详情，只向持有 `modeldeployment.deployment.manage` 的用户返回当前有资格的脱敏投影，且在创建 Deployment/Revision 时重新校验资格。不得将服务凭证或 Infrastructure 原始响应透传浏览器。
- `CreateRuntimeRequest.runtime_provider` 当前固定 `docker`，并选择 `DockerRuntimeSpec` STRUCTURED/NATIVE 分支。
- Runtime owner 固定 `owner_domain=model-deployment`、`owner_reference=ModelDeployment.id`；请求同时携带 `spec_revision_id` 与 `spec_digest` 作为运行身份。
- Infrastructure 持久化 `node_id`、最终 Provider Spec/digest、Provider Runtime 引用和运行身份；所有模型与额外挂载规范化为 `RuntimeMount`。
- Endpoint 为 INTERNAL；普通响应只返回稳定 `endpoint_ref`，不返回解析地址、Host Port、宿主路径或 Provider 原始响应。

## 6. 不兼容清理与未来 Kubernetes

- 维护窗口内按 owner 和稳定引用定向清理旧 Runtime、Endpoint、Docker 对象与 `model-deployment.*@1.0` Task/DAG；不得影响其他领域任务。
- 清空旧 Model Deployment 表和事件投影后部署 v2 Schema，不做数据回填。
- Kubernetes Provider 未来必须保存自身 `resourceVersion`、generation/observedGeneration、rollout revision 与对象引用，但这些仅是 Infra Provider 观测事实。
- 一个业务 Spec Revision 可映射多个 Kubernetes 对象或多个 Provider rollout；业务回滚始终 Apply 完整 Spec Revision，不直接调用 `kubectl rollout undo`。

## 7. S1 追溯

- 用户故事：`US-MODELDEP-001` 至 `US-MODELDEP-004`
- 业务规则：`BR-MODELDEP-001` 至 `BR-MODELDEP-021`

## spec-v1.25.4 Endpoint 传递与恢复

Model Deployment Worker 必须将固定 Revision 的 Endpoint 映射到 `endpoint_request.endpoint_name/protocol/container_port/healthcheck`，协议显式转换为 `http/https/tcp`。Infrastructure 将完整请求纳入请求指纹和现有运行快照；Provider 按快照发布内部端口和执行 HTTP/TCP 探活，只有映射和探活成功才 READY。恢复、Health 和 resolve 都读取同一快照。TCP 使用 `tcp://host:port`；现有授权和摘要裁剪不变。PROFILE 请求继续使用固定 Profile 声明，不允许覆盖。探活组合、时序、失败阈值遵守 `RuntimeEndpointHealthcheck` 与两域 S1 的 spec-v1.25.4 Endpoint 规则。
