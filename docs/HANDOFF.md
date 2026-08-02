# OmniMAM Spec Handoff

## 当前目标与状态

目标：在已对齐 `agent`、`appstudio`、`infrastructure` 三域的基础上，补齐 Task Center 第一阶段 Infra-backed function registry 的精确 S1/S2 合同。

状态：`spec-v1.12.0` 已发布，四域规格与 Release 记录均已提交；本次发布按用户要求未执行新增校验，也未推送远端。

## 本次完成

- Agent 统一为 `AgentInvocation`；固定 `kind/workspace_type/workspace_id`，禁止 Session、Invocation 和 Runtime 切换 Workspace。
- 纯 CHAT 且不启动 Runtime/工具/后台工作的 Invocation 可不建 Task；CODING、TOOL_OPERATION、BACKGROUND_OPERATION 和 Runtime 生命周期 Invocation 必须关联 AtomicTask。
- Coding Agent 不挂载 StudioWorkspace；每次源码访问使用绑定 Principal、Agent、Session、Invocation、Workspace、动作和有效期的短期 Workspace Tool 授权，写入通过带 `base_revision` 的原子 ChangeSet。
- AgentRuntimeProvider 只承载 Hermes/OpenCode 业务生命周期；Infrastructure RuntimeProvider 第一阶段只承载 Docker。
- AppStudio canonical 链路统一为 `StudioApplication -> StudioSourceRepository -> StudioWorkspace/Revision/ChangeSet -> StudioSourceSnapshot -> StudioApplicationVersion/StudioBuild -> RuntimeConfig -> StudioRelease -> StudioRuntimeInstance`。
- StudioBuild 只有在 AtomicTask 成功、Artifact READY 且 digest 一致后成功；Infra 只返回 output descriptor，Task Worker 使用 producer context 调用 Asset Library 登记 Artifact。
- 新 StudioRuntimeInstance 只有健康后才能切换当前入口；每个 Application/Environment 最多一个 current 实例；回滚创建新 Release 和候选实例，不修改或重新激活旧 Release。
- Infrastructure 固化 Docker-only、`requestingService + requestId` 请求指纹幂等、Provider 超时恢复、受控挂载、Endpoint 授权和安全孤儿清理。
- 三域分别新增 8、12、10 条 S1 验收标准；Agent/Infrastructure 中的 Go interface 已改写为产品逻辑能力。
- 同步未 Release S2 的追溯、权限、错误、事件、OpenAPI 和设计态 Schema；同步 Glossary、Domain Context、Global Context、Context Map、Infrastructure 架构参考和 Changelog。
- 补充 Build 成功门禁、current RuntimeInstance 健康门禁、回滚 Release 自引用、Agent Workspace 双层引用一致性和 Infra 内部请求摘要规则。
- 修复 Endpoint S1/S2 枚举冲突，统一为 `visibility=INTERNAL/USER_ACCESSIBLE/PUBLIC`；为 SSE 标准请求头 `Last-Event-ID` 补充显式命名例外。
- Task Center S1 固定 7 个 canonical Infra-backed functionRef、合同版本生命周期、`BR-TASK-153` 和 `US-TASK-026`；Build 取消等进行中动作继续使用 AtomicTask 通用取消，不新增 cancel functionRef。
- 新增只读 Function Registry 与 meta-schema，逐项定义 12 个 I/O JSON Schema、JOB/SERVICE、能力、幂等、重试、取消、超时、Infra Adapter、Artifact 登记、结果 transform、安全边界和跨域追溯。
- Registry 支持 `ACTIVE/RETAINED/DISABLED` 历史版本；每个合同登记 RFC 8785 + SHA-256 摘要，AtomicTask 固定 version/digest，恢复不得回退到新版本。
- Task Center OpenAPI、设计态 Schema、错误、事件、module contract、架构和 Context 已同步；AppStudio 补充 StopPreview API，Agent/AppStudio module contract 固定 exact functionRef 映射。
- 已创建规格提交 `2f71a836006d5f35f48144fa03d1176232ea70c6`（`spec: release agent appstudio infrastructure task registry`）。
- 已在 `RELEASE.md` 登记 `spec-v1.12.0`，四域允许作为正式实现依据，并写明七个 canonical functionRef 与严格 implementation gate。

## 当前进行中

无。

## 文件变化

- S1：`00_product/domains/agent/product-spec.md`、`00_product/domains/appstudio/product-spec.md`、`00_product/domains/infrastructure/product-spec.md`、`00_product/glossary.md`
- Task Center S1：`00_product/domains/task-center/product-spec.md`
- Agent S2：`01_contracts/domains/agent/errors.yaml`、`events.yaml`、`module-contract.md`、`openapi.yaml`、`permissions.yaml`、`schema.sql`
- AppStudio S2：`01_contracts/domains/appstudio/errors.yaml`、`events.yaml`、`module-contract.md`、`openapi.yaml`、`permissions.yaml`、`schema.sql`
- Infrastructure S2：`01_contracts/domains/infrastructure/errors.yaml`、`events.yaml`、`module-contract.md`、`openapi.yaml`、`permissions.yaml`、`schema.sql`
- Task Center S2：`01_contracts/domains/task-center/function-registry.schema.yaml`、`function-registry.yaml`、`errors.yaml`、`events.yaml`、`module-contract.md`、`openapi.yaml`、`schema.sql`
- 架构与导航：`02_architecture/domains/infrastructure.md`、`02_architecture/domains/task-center.md`、`domains/agent/context.md`、`domains/appstudio/context.md`、`domains/infrastructure/context.md`、`domains/task-center/context.md`、`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`
- 维护文档：`CHANGELOG.md`、`docs/HANDOFF.md`
- Release 记录：`RELEASE.md`
- 新增两份 Task Center 正式 S2 草稿：`function-registry.schema.yaml` 和 `function-registry.yaml`；未删除其他正式 Spec 文件。用户已有的 `skills/archive/` 删除及 `archive/`、`docs/identity_fix.md`、`设计图/` 未跟踪内容未处理。

## 关键设计决定

- Workspace 是 Agent 创建时固定事实；更换 Workspace 必须创建新 Agent。
- AppStudio 独占生成应用源码事实；不存在独立 Workspace Service、StudioConversation 或 Deploy Service 事实域。
- StudioDeploymentProvider 是 AppStudio 内部注册组件，不拥有第二套 Release/RuntimeInstance 状态。
- Build、Preview、发布、升级、停止和回滚的 Infra 操作统一走 `Task Center -> Task Worker -> Infra Adapter -> Infra Service`。
- Production 只读使用固定 Artifact ID/digest；携带 Workspace、Revision 或 Snapshot 的请求必须拒绝。
- `USER_ACCESSIBLE` Endpoint 必须校验 owner 与当前授权；`PUBLIC` 第一阶段默认禁用。
- 第一阶段 registry 只允许七个 canonical functionRef；新任务选择唯一 ACTIVE 合同，RETAINED 只恢复历史，DISABLED 不执行，同版本内容摘要不得漂移。
- Task 级幂等使用合同模板与 retry generation；Infra request ID 使用 `atomic_task_id:attempt_no`，同 Attempt 恢复重放，新 Attempt 使用新 ID。
- 只有 `appstudio.build.execute` 可以由 Task Worker 登记 Artifact；其他 Worker 不拥有或登记 Artifact，所有业务投影仍由来源领域消费 Task 结果后更新。

## API、Schema、错误与事件变化

- Agent 将可变 Workspace Binding API 收敛为单个只读 `GET /api/v1/agents/{agent_id}/workspace-binding`。
- AppStudio 新增 Version 创建、RuntimeInstance 列表和 RuntimeInstance 停止契约；Release 请求固定 Version、RuntimeConfig、Artifact 和环境。
- AppStudio 新增 `POST /api/v1/studio-workspaces/{workspace_id}/preview-runtime/stop`，与 `appstudio.preview.stop` 合同对齐。
- Agent Schema 增加 kind/workspace_type 匹配约束、异步 Invocation 必须关联 AtomicTask 的约束和每 Agent 唯一 Workspace Binding。
- AppStudio Schema 增加 Version 幂等键、RuntimeInstance environment/AtomicTask、Build 成功门禁，以及每 Application/Environment 唯一且必须 `READY/HEALTHY` 的 current 实例。
- Infrastructure Schema 增加 `request_fingerprint`，并允许合法 ownerDomain 为 agent、appstudio、task-center 或 asset-library。
- Infrastructure 与 AppStudio Endpoint 契约统一使用 `visibility=INTERNAL/USER_ACCESSIBLE/PUBLIC`，移除 S1 未定义的 `USER_PROXY`。
- 新增 AppStudio Workspace Tool/Artifact 门禁错误、Infrastructure 幂等冲突/Endpoint 授权错误和 RuntimeInstance 状态事件。
- Task Center OpenAPI 更新为 `1.6.0-draft`，AtomicTask 返回可选 function contract version/digest，capability 由 registry 派生；设计态 Schema 对七个 Infra-backed functionRef 强制合法 SHA-256 摘要。
- Task Center 新增 `ERR_TASK_FUNCTION_INPUT_INVALID`、`OUTPUT_INVALID`、`CONTRACT_UNAVAILABLE` 和 `CAPABILITY_UNAVAILABLE`，`atomic_task_created` 事件携带可选合同 version/digest。
- 未新增依赖、运行时配置、正式 migration、前后端实现或 CI/CD 变更。

## 验证结果

- `git diff --check` 通过。
- Agent/AppStudio/Infrastructure/Task Center 共 18 个 OpenAPI、错误、权限、事件和 registry YAML 文件通过 `yq` 解析。
- 四份 S1 的 9 个 JSON 示例全部通过 `JSON.parse`。
- 四份设计态 Schema 的 `CREATE TABLE` 与闭合数量一致：Task Center 8、Agent 12、AppStudio 14、Infrastructure 8。
- 四域 OpenAPI 共 116 个 operationId；本地 Schema `$ref`、operationId 唯一性、`/api/v1` 前缀和 operation 权限定义检查通过。
- OpenAPI 请求与响应字段均为 `lower_snake_case` 或已记录协议命名例外；Endpoint visibility 的 S1/S2 对齐检查通过。
- 所有 OpenAPI `source_sections` 均能匹配当前 S1 标题；四域 S2 的 US/BR/R 引用均能在对应 S1 中解析。
- Registry meta-schema、12 个嵌套 JSON Schema、最小实例、7 个登记摘要复算、唯一 ACTIVE 版本、模板变量、source policy、Artifact 登记范围、结果映射、跨域引用和 retryable 错误属性检查通过。
- 全仓 15 个错误码文件共 344 组 code/value 唯一；新增错误落在已登记区间，四域共 77 个错误、34 个权限和 24 个事件结构检查通过。
- S1/Module Contract 代码围栏数量为偶数；旧 AgentOperation、StudioProject、StudioConversation、StudioApp、StudioDeployment、Workspace Service 和直接 Infra 调用残留检查通过。

## 已知问题与风险

- 当前环境没有 `mmdc`，Mermaid 已做图文和围栏检查，但未执行渲染器语法验证。
- 本轮是规格修改，没有运行后端构建或实现测试。
- 用户明确要求本次直接发布且不检验，因此不会重新执行契约校验；发布依据为本 handoff 中已记录的上一轮验证结果。

## 推荐下一步

基于 `spec-v1.12.0` 的 implementation gate 开始实现或验收；工作区中的用户已有归档删除和未跟踪内容继续保持隔离。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
