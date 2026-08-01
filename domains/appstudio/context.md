# AppStudio Context

## 1. 领域职责

`appstudio` 管理 Agent 辅助开发的生成式 Web/BFF 应用，拥有 StudioApplication 从源码编辑、不可变快照、构建、发布到运行实例的业务链路。它独立于将 AI 能力封装给用户和画布的 `application-platform`。

## 2. 核心对象

- `StudioApplication`、`StudioApplicationVersion`：生成应用身份及固定 Source Snapshot 的发布版本。
- `StudioSourceRepository`、`StudioWorkspace`、Revision、`StudioChangeSet`：逻辑源码仓库、编辑事实和原子变更历史。
- `StudioSourceSnapshot`：供正式 Build 使用的不可变源码版本事实。
- `StudioBuild`：Source Snapshot 到可运行 Bundle 的业务投影，引用 Task Center 和 Artifact。
- `StudioPreviewRuntime`：基于当前 Workspace Revision 的编辑态快速预览。
- `StudioRelease`、`StudioRuntimeInstance`：固定 Artifact digest 的环境发布及当前部署实例事实。
- `StudioDeploymentProvider`：部署 Build Artifact 并管理底层运行单元的系统注册组件。

## 3. 核心规则

- StudioApplication 与 application-platform.Application 不共享身份、版本、运行对象或私有数据。
- Coding Agent 固定引用一个 StudioWorkspace，并复用 AgentSession/AgentInvocation；AppStudio 不建立第二套 Agent 执行记录。
- 所有源码写入必须形成带 `base_revision` 的 ChangeSet；冲突时不得自动覆盖或部分应用。
- 正式 Build 只能读取不可变 StudioSourceSnapshot；生产运行只能读取固定 digest 的 Artifact。
- Task Center 拥有 AtomicTask、TaskAttempt、TaskGroup、重试、取消和调度状态；StudioBuild/Release 只保存业务投影。
- asset-library 拥有 Artifact 身份、内容、处理和存储；AppStudio 只保存 Artifact ID 与历史 digest 快照。
- Agent 删除或挂起不影响 StudioWorkspace、Build、Release 或 StudioRuntimeInstance。

## 4. 领域边界

本领域拥有 StudioApplication、源码、Workspace、Revision、ChangeSet、Snapshot、Build、Preview Runtime、运行配置、Release 和 StudioRuntimeInstance。Agent 交互事实归 agent；任务状态归 task-center；Artifact 内容归 asset-library；通知归 notification-center。

## 5. 上游与下游

上游是用户和固定绑定 StudioWorkspace 的 Coding Agent。下游包括 Task Center、Build Service、asset-library、StudioDeploymentProvider，以及消费可靠 AppStudio 事件的 notification-center 和 sse。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/appstudio/product-spec.md` | S1 | 源码、构建、发布和生成应用运行产品语义 |
| `01_contracts/domains/appstudio/openapi.yaml` | S2 | StudioApplication、Workspace、Snapshot、Build、Release 与 Runtime HTTP 合同 |
| `01_contracts/domains/appstudio/schema.sql` | S2 | AppStudio 设计态数据结构 |
| `01_contracts/domains/appstudio/errors.yaml` | S2 | AppStudio 业务错误码 |
| `01_contracts/domains/appstudio/permissions.yaml` | S2 | AppStudio 权限码与强制校验规则 |
| `01_contracts/domains/appstudio/events.yaml` | S2 | AppStudio 可靠领域事件 |
| `01_contracts/domains/appstudio/module-contract.md` | S2 | 源码、构建、Artifact、发布和跨域模块边界 |

当前无 AppStudio 领域架构参考；Context 只负责导航，具体产品语义和实现合同必须读取上述 S1/S2。

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| StudioApplication/Workspace/Revision | AppStudio S1 | Agent 修改行为再读 agent Context |
| Snapshot/Build | AppStudio S1 | 执行与重试再读 task-center Context |
| Build Artifact | AppStudio S1 | 内容、处理或存储再读 asset-library Context |
| Release/StudioRuntimeInstance | AppStudio S1 | 通知投影再读 notification-center Context |

## 8. 当前状态

AppStudio S1/S2 均为未 Release 草稿，不能作为正式实现、合并或验收依据。

## 9. 不在本领域定义的内容

- AI 能力 Application、ApplicationVersion、ApplicationRun 和 RuntimeFormSchema。
- AgentSession、AgentInvocation、AgentMemory 和 AgentRuntime 状态机。
- AtomicTask/TaskGroup 执行状态和 Artifact 内容生命周期。
- Notification、UserEvent 和底层部署实现合同。
