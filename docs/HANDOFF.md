# OmniMAM Spec Handoff

## Current goal and status

- Goal: 发布平台共享本地模型部署管理的小版本，覆盖 vLLM/LM Studio Docker Service、Provider 专属 DAG、Infrastructure 挂载契约和管理 API。
- Status: `spec-v1.24.0` 已发布，规格提交为 `2982d43`；待完成 release commit/tag 后的最终状态检查。

## Work completed in this session

- 新增独立 `model-deployment` S1/S2、Domain Context 和架构参考。
- 明确只接收 `provider_type`、逻辑 `model_name` 和管理字段；不新增 Model Gateway Adapter、EngineInstance、Binding 或 capability 选择。
- vLLM 与 LM Studio 使用独立的 validate/ensure/stop functionRef、Profile、DAG 模板和结果投影。
- Infrastructure 增加 `local_model_root`、`MODEL_FILES` 挂载、`model.vllm`/`model.lmstudio` Profile 语义，以及 `model-deployment` Runtime owner。
- Task Center Function Registry 已登记六个 Provider 专属合同，并已生成真实 RFC8785 + SHA-256 contract digest。
- 更新全局上下文、Context Map、Glossary、错误码索引和 CHANGELOG。

## Files added, modified, renamed, or removed

- Added: `00_product/domains/model-deployment/`, `01_contracts/domains/model-deployment/`, `domains/model-deployment/`, `02_architecture/domains/model-deployment.md`.
- Modified: Infrastructure/Task Center S1/S2, `GLOBAL_CONTEXT.md`, `CONTEXT_MAP.md`, `00_product/glossary.md`, `01_contracts/error-code-index.md`, `CHANGELOG.md`, `docs/HANDOFF.md`.

## Key architectural or design decisions

- Model Deployment 只拥有部署资源、生命周期和管理投影；Task Center 拥有 DAG/Task，Infrastructure 拥有 Runtime/Profile/挂载。
- DEPLOY/START 使用 `model.validate -> runtime.ensure`；RESTART 使用 `runtime.stop -> model.validate -> runtime.ensure`；STOP/DELETE 使用 Provider 专属 stop AtomicTask。
- Infrastructure 节点以 `local_model_root` 与 `model_name` 派生 `local-model://{model_name}` 的模型目录，使用 `MODEL_FILES` 挂载。
- vLLM 与 LM Studio 不共享 Provider 专用 handler、模型校验或 RuntimeProfile；不修改现有 Model Gateway 适配器、EngineInstance 或 Binding。

## API, schema, dependency, or configuration changes

- 新增 `/api/v1/model-deployments` CRUD、生命周期动作和日志查询契约。
- Infrastructure owner domain 与挂载枚举增加 `model-deployment`、`MODEL_FILES`；设计态 schema 增加 `infra_local_model_config`。
- 新增 Infrastructure 本地模型错误码 `241000-241199`，Model Deployment 错误码区间为 `260200-260599`。

## Verification performed and remaining checks

- 已通过目标 YAML 解析、Model Deployment/Infrastructure OpenAPI 本地 `$ref` 检查、Function Registry JSON Schema 校验、S1 引用检查和六个 function contract digest 复算。
- 已执行 `git diff --check`、最终变更审阅，并将 `RELEASE.md` 更新为 `spec-v1.24.0` released。

## Outstanding tasks

- 创建并校验 `spec-v1.24.0` release tag，确认工作树干净。

## Known issues and risks

- RuntimeProfile 的镜像、Entrypoint、端口和健康检查具体值仍属于 Infrastructure Profile Revision 实现事实。
- `local_model_root` 是 Infrastructure 节点配置，部署前必须由运行环境提供；本仓库只维护配置语义。

## Exact recommended next step

创建 `spec-v1.24.0` release tag，确认工作树干净，并将 tag/提交引用同步到实现仓库的发布流程。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
