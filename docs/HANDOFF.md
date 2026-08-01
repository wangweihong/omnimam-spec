# OmniMAM Spec Handoff

## 当前目标与状态

提交并发布已完成验证的 `agent` 与 `appstudio` S1/S2 为 `spec-v1.10.0`。状态：发布进行中；远端 `origin/master` 已同步，正在创建 Spec 内容提交，尚未写入 Release 记录或创建 tag。

## 本次已完成

- 为 Agent S1 新增 `BR-AGENT-001..014` 与 `US-AGENT-001..008`，为 AppStudio S1 新增 `BR-APPSTUDIO-001..014` 与 `US-APPSTUDIO-001..009`；只增加追溯锚点，不改变既有产品语义。
- 新增 Agent 完整 S2：31 个 REST/SSE operation、10 张设计表、21 个错误码、8 个权限码、7 个可靠事件与模块合同。
- 新增 AppStudio 完整 S2：31 个 REST operation、15 张设计表、27 个错误码、9 个权限码、7 个可靠事件与模块合同。
- 固定 Coding Agent 的有界 Workspace Tool 授权、ChangeSet `base_revision` 原子写入、Session/Invocation/AtomicTask、Runtime 幂等与一跳摘要规则。
- 固定 Workspace/Revision、Snapshot/Version、Build/Task/Artifact、Preview、RuntimeConfig/Secret 引用、Release/健康切换/回滚端到端合同。
- 登记 Agent `200200-201199` 与 AppStudio `210200-211399` 错误区间，所有新增 API 使用 `/api/v1` 和 HTTP 200 业务错误模型。
- 同步 Agent/AppStudio Domain Context、Global Context、Context Map 与 Changelog；`RELEASE.md` 保持不变。

## 当前进行中

- 仅暂存 Agent/AppStudio S1/S2、Context、全局索引与 handoff，创建 Spec 内容提交。
- 使用内容提交的完整 commit hash 更新 `RELEASE.md`，随后创建发布提交、annotated tag 并推送 `master` 与 tag。

## 文件变化

- 修改：`00_product/domains/agent/product-spec.md`、`00_product/domains/appstudio/product-spec.md`。
- 新增：`01_contracts/domains/agent/{openapi.yaml,schema.sql,errors.yaml,permissions.yaml,events.yaml,module-contract.md}`。
- 新增：`01_contracts/domains/appstudio/{openapi.yaml,schema.sql,errors.yaml,permissions.yaml,events.yaml,module-contract.md}`。
- 修改：`01_contracts/error-code-index.md`、`domains/agent/context.md`、`domains/appstudio/context.md`、`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、`CHANGELOG.md`、`docs/HANDOFF.md`。
- 未修改：`RELEASE.md`、领域架构、正式 migration、实现代码和运行配置。
- 保留用户已有无关改动：`archive/`、`设计图/`、`skills/archive/`。

## 关键设计决策

- `Application` 专指 application-platform 的 AI 能力应用；`StudioApplication` 专指 AppStudio 的生成式 Web/BFF 应用。
- Platform Agent 使用 AgentWorkspace；Coding Agent 固定引用一个 StudioWorkspace，Session/Invocation 不得切换。
- Coding Agent 不直接挂载 AppStudio 存储，只使用绑定当前用户、Agent、Session、Invocation、Workspace、动作和有效期的 Tool 授权。
- Agent 只拥有交互、Memory、AgentWorkspace 和 AgentRuntime；AppStudio 拥有源码、Build、Release 和生成应用 Runtime。
- AgentRuntimeProvider 与 StudioDeploymentProvider 是不同产品组件，不形成共享业务状态。
- Task Center 拥有 AtomicTask、TaskAttempt、TaskGroup、调度、重试、取消和执行状态；Agent/AppStudio 只保存稳定引用与业务投影。
- asset-library 拥有 Artifact 身份、内容、处理、存储、保留和登记；AppStudio 不保存 Artifact `storage_uri`。
- Build 只能读取不可变 Snapshot；正式 Runtime 只能读取固定 digest 的 Build Artifact；健康检查通过前不得切换当前入口。
- Notification Center 只消费可靠源事件并维护收件箱事实；Agent/AppStudio 不定义通知已读或聚合状态。

## API、Schema、依赖与配置变化

- Agent OpenAPI 3.0.3 定义 23 个 path/31 个 operation；AppStudio 定义 23 个 path/31 个 operation。
- Agent Schema 定义 10 张表；AppStudio Schema 定义 15 张表。跨域 ID 均不建外键，目标事实通过受控模块接口解析。
- Agent 新增 21 个 `ERR_AGENT_*`、8 个 `agent.*` 权限和 7 个可靠事件；AppStudio 新增 27 个 `ERR_APPSTUDIO_*`、9 个 `appstudio.*` 权限和 7 个可靠事件。
- `X-Workspace-Tool-Authorization`、`Last-Event-ID` 和 BCP 47 语言标签均声明命名例外；其他请求/响应字段使用 `lower_snake_case`。
- 没有新增运行时依赖、正式 migration、运行配置或实现代码。

## 验证结果

- 49 份当前 S2 YAML 全部可解析。
- 两域各 31 个 operation 均有权限、S1 引用、HTTP 200 响应和真实错误码；Agent 217 个、AppStudio 261 个本地 `$ref` 全部可解析。
- Redocly CLI `2.43.2` 对两份 OpenAPI 校验为零 error；保留 76 条推荐性 warning，其中 62 条是与仓库 HTTP 200 业务错误规则冲突的 4XX 建议，其余为 license/tag 描述元数据。
- 全仓 293 个错误码 code/value 唯一，均落入已登记领域区间；83 个权限码唯一，新增委托权限真实存在。
- 全仓 92 张设计表无重名；新增 25 张表包含通用资源字段、字段名为 `lower_snake_case`，且不存在跨域外键。
- 新增 S2 的 BR/US 引用均真实存在且无缩写编号；事件必填合同完整，Markdown 围栏和 Context 路径有效。
- 未发现 TaskRun、ExecutionLease、ApplicationBuild、ApplicationRuntime、DeployService 或 Worker claim 残留；`git diff --check` 通过。
- `RELEASE.md` 未修改；工作区原有 `archive/`、`设计图/` 和 `skills/archive/` 调整未回退。

## 待办、问题与风险

- `agent` 与 `appstudio` S1/S2 尚未获得用户 Release 确认，不能用于正式实现、合并或验收。
- 两域仍没有 `02_architecture/domains/agent.md` 与 `02_architecture/domains/appstudio.md`；本任务只要求 S2，未扩展到领域架构。
- Redocly 的 4XX warning 是仓库 HTTP 状态码规范与通用推荐规则的预期差异，不是 OpenAPI 结构错误。

## 推荐下一步

按限定文件清单暂存并复核 staged diff，然后创建 `spec: define agent and appstudio contracts` 内容提交。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
