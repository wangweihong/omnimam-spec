# AppStudio Context

## 1. 领域职责

`appstudio` 管理 Agent 辅助开发的生成式 Web/BFF 应用，拥有 StudioApplication 从源码编辑、不可变快照、构建、发布到运行实例的业务链路。用户只感知应用、源码和 Revision；StudioWorkspace 是后端内部持久化与绑定事实。AppStudio 独立于将 AI 能力封装给用户和画布的 `application-platform`。

## 2. 核心对象

- `StudioApplication`、`StudioApplicationVersion`：生成应用身份及固定 Source Snapshot 的发布版本；创建流程先持久化不可用的 `CREATING` reservation，完成 GitLab Project、源码 Revision 0 和内部 Agent 绑定后才进入 `READY`。
- `StudioApplication` 当前 Coding Agent 投影：保存 Agent、默认 Session 和 generation；替换 Agent 创建新 generation，旧 Agent/Session/Invocation 历史保留。
- `StudioSourceRepository`、`StudioWorkspace`、Revision、`StudioChangeSet`：内部逻辑源码仓库、默认编辑上下文和原子变更历史；GitLab 保存文件正文，Revision 通过 `commit_sha` 固定 Git commit，公共投影仍为应用级 Source/Revision。
- `web-react@v1` Blueprint：随 Server 发布的内置只读 Starter Template、Prompt、validation 和外部 CI include 引用，不形成公共 Blueprint Service。
- `StudioSourceSnapshot`：供正式 Build 使用的不可变源码版本事实。
- `StudioBuild`：Source Snapshot 到可运行 Bundle 的业务投影，拥有 canonical `owner_user_id`，引用 Task Center、GitLab Pipeline 和 Artifact，并向 Asset Library 提供受控 producer 摘要。
- `StudioPreviewRuntime`：基于应用当前源码 Revision 的编辑态快速预览，内部仍固定 Workspace Revision。
- `StudioRelease`、`StudioRuntimeInstance`：固定 Artifact digest 的环境发布及当前部署实例事实。
- `RuntimeConfig`：按环境保存公开配置、Secret/Integration 引用和乐观版本的可变配置事实。
- `StudioDeploymentProvider`：AppStudio 内部注册的发布 Task 编排组件，不拥有第二套 Release/RuntimeInstance 状态。

## 3. 核心规则

- StudioApplication 与 application-platform.Application 不共享身份、版本、运行对象或私有数据。
- `CreateStudioApplication` 不接受 Workspace 输入；请求携带初始需求、用户模型选择、可选 Coding Agent Profile、附件和幂等键，后端原子创建唯一默认 Repository/StudioWorkspace、Revision 0、Coding Agent、Session、WorkspaceBinding 和 ACTIVE primary ModelBinding。
- Coding Agent 仅通过 Agent 内部 `CreateCodingAgentForStudio` 创建，固定引用默认 StudioWorkspace，并复用 AgentSession/AgentInvocation；Coding Runtime 直接操作 `/workspace` Git working tree，Worker 把单个 fast-forward commit 投影为原有 ChangeSet/Revision，AppStudio 不建立第二套 Agent 执行记录。
- AppStudio 只通过 application-level Agent facade 暴露当前 Agent 状态、消息、Invocation 查询/取消/SSE 和 suspend/resume/replace，并校验 owner、generation 与绑定关系；Coding Agent 不进入公共 `/api/v1/agents`。
- 公共 API、页面、权限、错误、通知和 SSE 以 StudioApplication、源码和 Revision 表达，不投影 Workspace ID。
- 所有源码写入最终必须形成带 `base_revision` 和 base `commit_sha` 的 ChangeSet；API 写入先提交 Git commit 再原子投影，Coding Invocation 写入由 Worker 在终态前幂等投影；冲突时不得 force push、自动覆盖、隐式合并或部分应用。
- Invocation 阶段 Revision 取其已应用 ChangeSet 最大 `target_revision`；恢复调用现有 source restore 创建新的 Restore ChangeSet/Revision，保留原 Session、Message、Invocation、ChangeSet 和 Revision 历史。
- 正式 Build 只能读取不可变 StudioSourceSnapshot；生产运行只能读取固定 digest 的 Artifact。
- Task Center 拥有 AtomicTask、TaskAttempt、TaskGroup、重试、取消和调度状态；StudioBuild/Release 只保存业务投影，Preview/Build/Production 的 Infra 操作均经 Task Worker。
- asset-library 拥有 Artifact 身份、内容、处理和存储；AppStudio 只保存 Artifact ID 与历史 digest 快照。
- StudioBuild 是受信 Artifact producer；Bundle 固定使用 `StudioBuild.id`、`studio-build:<studio_build_id>:bundle` 和 `StudioBuild.owner_user_id`，自动 TaskAttempt 重试复用同一 Artifact，新逻辑 Build 使用新 ID。
- AppStudio 通过最多 200 项且保持顺序的批量 API 提供 `id/owner_user_id/name/status` 投影；Artifact 创建按原任务委托用户校验，列表/详情按当前调用者校验，不存在或不可见统一返回 null。
- Build `authorized_editor` 和管理员角色可以按 AppStudio 授权查看 Build，但不继承 Asset Library Artifact 权限；服务身份也不能绕过委托用户权限。
- StudioBuild 只有在 AtomicTask 成功、Artifact READY 且 digest 一致后才能成功；Task 成功不能单独推断 Artifact ready。
- StudioApplication 创建先返回持久化的 `CREATING` reservation 与内部 DAGTaskGroup ID；初始化固定聚合 GitLab Project、Webhook、应用初始化和首次 Invocation 四阶段，全部成功并通过当前 DAG owner fence 后才进入 `READY`。公共初始化接口只返回安全阶段诊断；`ERROR` reservation 通过显式幂等 retry 复用原对象创建新 DAG，旧 DAG 迟到事件不得覆盖当前轮次。
- GitLab Push Hook 按 Project/CommitSHA 幂等触发 Snapshot -> StudioBuild -> Pipeline -> Bundle Artifact -> Preview DAG；CommitSHA 尚未投影为 canonical Revision 时只能有界重试，不能伪造 Revision。
- 新 StudioRuntimeInstance 健康后才能切换当前入口；回滚必须基于历史不可变内容创建新的 StudioRelease 和候选 RuntimeInstance。
- Agent 删除或挂起不影响 StudioWorkspace、Build、Release 或 StudioRuntimeInstance。
- 第一阶段只使用 Infrastructure 的单机 Docker 能力；Kubernetes、Edge、Local Process 和多节点属于后续版本。

## 4. 领域边界

本领域拥有 StudioApplication、StudioApplicationVersion、源码 Repository、Workspace、Revision、ChangeSet、Snapshot、Build、StudioBuild owner/一跳摘要、Preview Runtime、RuntimeConfig、Release 和 StudioRuntimeInstance。Agent 交互事实归 agent；任务状态归 task-center；Artifact 身份、内容与 owner-only 权限归 asset-library；通知归 notification-center。

## 5. 上游与下游

上游是管理应用源码的用户和内部固定绑定 StudioWorkspace 的 Coding Agent。下游包括 GitLab、Task Center/Task Worker、infrastructure、asset-library，以及消费不含 Workspace 字段的可靠 AppStudio 事件的 notification-center 和 sse。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/appstudio/product-spec.md` | S1 | 源码、构建、发布和生成应用运行产品语义 |
| `01_contracts/domains/appstudio/openapi.yaml` | S2 | StudioApplication、应用级 Source/Revision、Build、Preview、Release 和 Runtime API |
| `01_contracts/domains/appstudio/schema.sql` | S2 | AppStudio 设计态 Schema |
| `01_contracts/domains/appstudio/errors.yaml`、`permissions.yaml`、`events.yaml`、`module-contract.md` | S2 | 错误、权限、事件和模块边界 |
Context 只负责导航，Task Center 的任务执行契约和 infrastructure 的运行层合同必须按跨域任务继续读取。

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| StudioApplication/Source/Revision | AppStudio S1 | Agent 修改行为或内部 Workspace 绑定再读 agent Context |
| Snapshot/Build | AppStudio S1 | 执行与重试再读 task-center Context |
| Build Artifact producer/owner/摘要 | AppStudio S1 | 必须继续读 asset-library Context；涉及 Attempt 重试或 Function Registry 再读 task-center Context |
| Release/StudioRuntimeInstance | AppStudio S1 | 通知投影再读 notification-center Context |

## 8. 当前状态

AppStudio 既有 Source/Build/Release 基线分别由 `spec-v1.16.0`、`spec-v1.16.1` 和 `spec-v1.17.1` 发布；创建模型选择、Coding Agent generation/application facade、首次 Invocation 和 Invocation-to-Revision 恢复契约已由后续 release 发布；GitLab-only Source、`web-react@v1` Blueprint、Runtime Git workspace 与 pre-remote `CREATING` reservation 由 `spec-v1.23.1` 发布；异步初始化 DAG、Webhook 和 Push 自动 Build/Artifact/Preview 由 `spec-v1.23.2` 发布；四阶段安全诊断、结构化失败原因、显式幂等恢复和 DAG owner fence 由 `spec-v1.23.3` 发布。S2 使用 `US-APPSTUDIO-001`、`BR-APPSTUDIO-001`、`R-STUDIO-*` 和源章节追溯。

## 9. 不在本领域定义的内容

- AI 能力 Application、ApplicationVersion、ApplicationRun 和 RuntimeFormSchema。
- AgentSession、AgentInvocation、AgentMemory 和 AgentRuntime 状态机。
- AtomicTask/TaskGroup 执行状态和 Artifact 内容生命周期。
- Notification、UserEvent 和底层部署实现合同。
