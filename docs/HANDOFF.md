# OmniMAM Spec Handoff

## 当前目标与状态

按用户最新请求，完全基于当前 S1 草稿重新生成 `agent`、`appstudio`、`infrastructure` 三个领域的 S2 契约。当前状态：三域 S2 已生成并通过结构校验，未创建新的 Release；旧版 Agent/AppStudio S2 不作为输入。

## 本次完成

- 已确认本轮不读取或恢复旧版 `agent`、`appstudio` S2；契约只从当前 S1 和当前 Task Center/Infrastructure 边界推导。
- 已发现当前三个 S1 没有标准 `US-*`/`BR-*` 编号，仅保留 `R-AGENT-*`、`R-STUDIO-*`、`R-INFRA-*` 规则和章节语义；新 S2 将显式记录该追溯缺口，不虚构编号。
- 已生成 `agent`、`appstudio`、`infrastructure` 各自的 `openapi.yaml`、`schema.sql`、`errors.yaml`、`permissions.yaml`、`events.yaml` 和 `module-contract.md`。
- 已新增 Infrastructure 错误码索引区间 `240200-240999`，并将三域 S2 草稿变更写入 `CHANGELOG.md`。
- 已同步三个 Domain Context、`GLOBAL_CONTEXT.md` 和 `CONTEXT_MAP.md`，使导航指向当前 S2 Draft。

## 上一阶段已完成

- 将所有 Agent/AppStudio 的 Infra-backed 操作统一为：
  `Agent/AppStudio -> Task Center -> Task Worker -> Infra Adapter -> Infra Service -> DockerRuntimeProvider`。
- 在 Task Center S1、S2 module-contract 和架构参考中定义 Task Worker/Infra Adapter：只消费已注册 `functionRef`，处理 Attempt 级恢复、取消、超时、幂等和小型结果映射，不拥有业务状态。
- 为 Agent S1 修正 Runtime 创建、启动、恢复、挂起、停止、Secret 注入和系统上下文中的直接 Infra 调用。
- 为 AppStudio S1 修正 Coding Agent、Preview、Build、Production 发布/升级/回滚的调用链；Deploy Service 只保留发布业务控制，不直接调用 Infra。
- 明确 Workspace 挂载矩阵：
  - `AgentWorkspace`：Infra 按 Agent 有效授权挂载。
  - `StudioWorkspace`：只能通过 AppStudio Workspace Tool 和受控授权访问。
  - `Preview`：挂载启动时授权的当前 Workspace Revision，源代码默认只读。
  - `Build`：只读挂载固定 Workspace Snapshot digest。
  - `Production`：只读使用固定 Artifact digest，禁止 Workspace、Revision、Snapshot 或其他可写目录。
- Infrastructure S1 保持第一阶段单机 Docker 范围，统一 `requestingService=task-center`、`ownerDomain`、`ownerReference`，不再使用含义混杂的 `ownerService`。
- 新增 `domains/infrastructure/context.md` 和 `02_architecture/domains/infrastructure.md`，同步 `GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、CHANGELOG 和 Release 门禁说明。
- 将旧 Agent/AppStudio Release 记录标为 `superseded`；本轮新增的 S2 不使用旧版文件或旧版编号。

## 文件变化

本次直接修改：

- `00_product/domains/agent/product-spec.md`
- `00_product/domains/appstudio/product-spec.md`
- `00_product/domains/task-center/product-spec.md`
- `01_contracts/domains/task-center/module-contract.md`
- `02_architecture/domains/task-center.md`
- `02_architecture/global-architecture.md`
- `00_product/glossary.md`
- `00_product/domains/infrastructure/product-spec.md`
- `01_contracts/domains/agent/`
- `01_contracts/domains/appstudio/`
- `01_contracts/domains/infrastructure/`
- `01_contracts/error-code-index.md`
- `02_architecture/domains/infrastructure.md`
- `domains/agent/context.md`
- `domains/appstudio/context.md`
- `domains/task-center/context.md`
- `domains/infrastructure/context.md`
- `GLOBAL_CONTEXT.md`
- `CONTEXT_MAP.md`
- `CHANGELOG.md`
- `RELEASE.md`
- `docs/HANDOFF.md`

用户已有或并行的删除/未跟踪内容保留：`archive/`、`设计图/`、`skills/archive/`；本轮已在 Agent/AppStudio 目录重新生成当前 S2 文件。

## 关键设计决定

- Task Worker 是 Task Center 的执行边界，不是新的业务状态中心，也不恢复旧 Worker claim/Lease/Dispatcher 语义。
- Infra 只拥有 Docker Job/Service、InfraRuntime、Endpoint、挂载和 Provider 对账事实；AgentRuntime、StudioPreviewRuntime、StudioBuild、StudioRuntimeInstance、Artifact 和 Workspace 仍由来源领域拥有。
- Infra 只接受 Task Worker 的受信服务身份；业务归属使用 `ownerDomain + ownerReference`，请求方使用 `requestingService` 分开表达。
- `source_ref` 必须由来源领域授权生成，不能被解释为宿主机路径；生产请求带有 Workspace 类引用时必须拒绝。
- 第一阶段只支持 `DockerRuntimeProvider`。Kubernetes、Edge、Local Process、多节点调度、自动扩缩容和跨 Provider 兼容延期到下一版本。
- 本轮 S2 只使用当前 S1 和当前 Task Center/Infrastructure 边界；旧版 Agent/AppStudio S2 不作为输入。

## API、Schema、依赖与配置

- 新增 Agent、AppStudio、Infrastructure 三域的 API、Schema、错误码、权限码、事件和模块契约草稿。
- 更新了已有 Task Center module-contract 的执行边界，但没有新增 Task Center HTTP endpoint 或设计态表。
- Infrastructure S2 已新增；其写操作要求 `requesting_service=task-center`，只支持 Docker Provider。
- 未新增正式实现代码、实际 migration、运行时配置、CI/CD 实现或依赖。

## 验证结果

- `git diff --check` 通过。
- 12 个新 YAML 文件均通过 `yq` 解析。
- 三个 OpenAPI 的组件引用、路径参数、重复路径/Schema、`/api/v1` 前缀和操作级权限/S1 追溯字段检查通过。
- 三个 domain 错误码无重复 code/value，均使用允许的 HTTP 状态码并落在登记区间内；R-* 引用均能在当前 S1 找到。
- 三份 Schema 共 34 张表，表级 S1 注释、通用资源字段和 snake_case 检查通过。
- Agent、AppStudio、Infrastructure 和 Task Center 相关文件的代码围栏数量均为偶数。
- 已搜索并清除 Agent/AppStudio 到 Infra 的直接调用箭头；剩余的 Worker/Infra 交互均属于受控执行链路。
- 已搜索并清除 Infrastructure 相关 `ownerService` 引用。
- 未运行后端构建或实现测试；本轮只涉及 Spec、Context、架构参考和 Release 草稿门禁。

## 未完成事项、风险

- S2 结构和语法校验已完成；未执行后端构建或实现测试，因为本轮没有正式实现代码。
- 当前 S1 缺少标准用户故事/业务规则编号，S2 只能引用现有 `R-*` 规则和源章节；正式 Release 前需要补齐可机器校验的 `US/BR` 追溯编号。

- 当前工作区的 Agent/AppStudio S1、Task Center 本轮修订和 Infrastructure S1 均未 Release，不能作为正式实现、合并或验收依据。
- Task Center 的 function registry、Infra Adapter 的具体输入/输出 schema 与本轮三域合同之间仍需下一阶段产品确认后收敛。
- Secret Service/Infra 的运行期解析协议、Endpoint 展示策略和 Artifact 登记接口仍只定义了产品边界，未形成实现合同。
- `RELEASE.md` 中 `spec-v1.10.0` 作为历史记录保留，但已标记 `superseded`；不得引用其中旧 implementation gate。

## 推荐下一步

下一步由用户确认当前 S1/S2 草稿及 `R-*` 到标准 `US/BR` 的追溯补齐方案；确认后再更新 Release，不要直接将当前草稿作为正式实现依据。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
