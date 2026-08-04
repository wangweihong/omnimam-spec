# AppStudio Context

## 1. 领域职责

`appstudio` 管理 Agent 辅助开发的生成式 Web/BFF 应用，拥有 StudioApplication 从源码编辑、不可变快照、构建、发布到运行实例的业务链路。用户只感知应用、源码和 Revision；StudioWorkspace 是后端内部持久化与绑定事实。AppStudio 独立于将 AI 能力封装给用户和画布的 `application-platform`。

## 2. 核心对象

- `StudioApplication`、`StudioApplicationVersion`：生成应用身份及固定 Source Snapshot 的发布版本。
- `StudioSourceRepository`、`StudioWorkspace`、Revision、`StudioChangeSet`：内部逻辑源码仓库、默认编辑上下文和原子变更历史；公共投影为应用级 Source/Revision。
- `StudioSourceSnapshot`：供正式 Build 使用的不可变源码版本事实。
- `StudioBuild`：Source Snapshot 到可运行 Bundle 的业务投影，引用 Task Center 和 Artifact。
- `StudioPreviewRuntime`：基于应用当前源码 Revision 的编辑态快速预览，内部仍固定 Workspace Revision。
- `StudioRelease`、`StudioRuntimeInstance`：固定 Artifact digest 的环境发布及当前部署实例事实。
- `RuntimeConfig`：按环境保存公开配置、Secret/Integration 引用和乐观版本的可变配置事实。
- `StudioDeploymentProvider`：AppStudio 内部注册的发布 Task 编排组件，不拥有第二套 Release/RuntimeInstance 状态。

## 3. 核心规则

- StudioApplication 与 application-platform.Application 不共享身份、版本、运行对象或私有数据。
- `CreateStudioApplication` 不接受 Workspace 输入；后端自动创建唯一默认 Repository/StudioWorkspace、Coding Agent 和 Session。
- Coding Agent 仅通过 Agent 内部 `CreateCodingAgentForStudio` 创建，固定引用默认 StudioWorkspace，并复用 AgentSession/AgentInvocation；AppStudio 不建立第二套 Agent 执行记录。
- 公共 API、页面、权限、错误、通知和 SSE 以 StudioApplication、源码和 Revision 表达，不投影 Workspace ID。
- 所有源码写入必须形成带 `base_revision` 的 ChangeSet；冲突时不得自动覆盖或部分应用。
- 正式 Build 只能读取不可变 StudioSourceSnapshot；生产运行只能读取固定 digest 的 Artifact。
- Task Center 拥有 AtomicTask、TaskAttempt、TaskGroup、重试、取消和调度状态；StudioBuild/Release 只保存业务投影，Preview/Build/Production 的 Infra 操作均经 Task Worker。
- asset-library 拥有 Artifact 身份、内容、处理和存储；AppStudio 只保存 Artifact ID 与历史 digest 快照。
- StudioBuild 只有在 AtomicTask 成功、Artifact READY 且 digest 一致后才能成功；Task 成功不能单独推断 Artifact ready。
- 新 StudioRuntimeInstance 健康后才能切换当前入口；回滚必须基于历史不可变内容创建新的 StudioRelease 和候选 RuntimeInstance。
- Agent 删除或挂起不影响 StudioWorkspace、Build、Release 或 StudioRuntimeInstance。
- 第一阶段只使用 Infrastructure 的单机 Docker 能力；Kubernetes、Edge、Local Process 和多节点属于后续版本。

## 4. 领域边界

本领域拥有 StudioApplication、StudioApplicationVersion、源码 Repository、Workspace、Revision、ChangeSet、Snapshot、Build、Preview Runtime、RuntimeConfig、Release 和 StudioRuntimeInstance。Agent 交互事实归 agent；任务状态归 task-center；Artifact 内容归 asset-library；通知归 notification-center。

## 5. 上游与下游

上游是管理应用源码的用户和内部固定绑定 StudioWorkspace 的 Coding Agent。下游包括 Task Center/Task Worker、infrastructure、asset-library，以及消费不含 Workspace 字段的可靠 AppStudio 事件的 notification-center 和 sse。

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
| Build Artifact | AppStudio S1 | 内容、处理或存储再读 asset-library Context |
| Release/StudioRuntimeInstance | AppStudio S1 | 通知投影再读 notification-center Context |

## 8. 当前状态

AppStudio S1/S2 已由 `spec-v1.16.0` 发布并允许作为正式实现依据；当前事件幂等键修复在 `spec-v1.16.1` 发布前仍不可作为正式实现依据。S2 使用 `US-APPSTUDIO-001`、`BR-APPSTUDIO-001`、`R-STUDIO-*` 和源章节追溯。

## 9. 不在本领域定义的内容

- AI 能力 Application、ApplicationVersion、ApplicationRun 和 RuntimeFormSchema。
- AgentSession、AgentInvocation、AgentMemory 和 AgentRuntime 状态机。
- AtomicTask/TaskGroup 执行状态和 Artifact 内容生命周期。
- Notification、UserEvent 和底层部署实现合同。
