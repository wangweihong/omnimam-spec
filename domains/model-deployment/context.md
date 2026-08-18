# Model Deployment Context

## 1. 领域职责

`model-deployment` 管理平台共享 vLLM/LM Studio 本地模型部署、生命周期、健康和管理页面投影。所有 Docker 写操作通过 Task Center 与 Infrastructure 执行。

## 2. 核心规则

- 管理员只提交 Provider 和逻辑 `model_name`，不提交模型路径、能力或 Docker 参数。
- Infrastructure 使用 `local_model_root/model_name` 生成实际只读模型挂载路径。
- vLLM 与 LM Studio 使用完全独立的验证 Job Profile、Service Profile、DAG 模板、functionRef 和模型校验。
- 部署、启动、重启使用 Provider 专属 DAG；同一部署只允许一个未终态生命周期执行。停止保留部署，删除先清理 Runtime。
- 管理投影聚合部署、DAG/Task、Runtime、Endpoint、健康和日志诊断。
- 本阶段不新增 Model Gateway Adapter，不修改 EngineInstance 或 Binding。

## 3. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/model-deployment/product-spec.md` | S1 | 部署管理、生命周期和页面语义 |
| `01_contracts/domains/model-deployment/openapi.yaml` | S2 | 管理 API |
| `01_contracts/domains/model-deployment/schema.sql` | S2 | 设计态部署结构 |
| `01_contracts/domains/model-deployment/errors.yaml` | S2 | 部署与 Runtime 错误 |
| `01_contracts/domains/model-deployment/permissions.yaml` | S2 | 管理权限 |
| `01_contracts/domains/model-deployment/events.yaml` | S2 | 状态和删除事件 |
| `01_contracts/domains/model-deployment/module-contract.md` | S2 | Task Center 与 Infrastructure 边界 |
| `02_architecture/domains/model-deployment.md` | 参考 | 部署链路与事实归属 |

## 4. 直接依赖

- `task-center`：AtomicTask、重试、取消、日志和 Infra Adapter。
- `infrastructure`：Docker Service、固定 RuntimeProfile、模型根路径解析、Endpoint 和健康。

## 5. 当前状态

本领域为 `spec-v1.24.0` 待发布内容。Release 前不得作为正式实现、合并或验收依据。
