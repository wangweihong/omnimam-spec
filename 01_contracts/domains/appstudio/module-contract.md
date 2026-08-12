# AppStudio Module Contract

产品语义以 `00_product/domains/appstudio/product-spec.md` 为准。本合同只覆盖当前 S1 草稿；旧版 S2 不属于输入。`StudioApplication`、`StudioSourceRepository`、`StudioWorkspace`、`StudioWorkspaceRevision`、`StudioChangeSet`、`StudioSourceSnapshot`、`StudioApplicationVersion`、`StudioBuild`、`RuntimeConfig`、`StudioRelease`、`StudioRuntimeInstance` 是唯一 canonical 对象；旧 Project/StudioApp/Deployment 名称不再构成产品事实或兼容别名。

## 1. 追溯状态

当前 AppStudio S1 使用 `US-APPSTUDIO-001`、`BR-APPSTUDIO-001`、`AC-APPSTUDIO-001-01..19` 及 `R-STUDIO-*` 规则。OpenAPI、Schema、错误、权限和事件必须同时遵守 Workspace 后端内化、GitLab-only 正文、Blueprint 固定版本、初始化诊断与显式恢复、Coding Agent generation、消息/事件 facade、Runtime 脱敏诊断、canonical 源码谱系、Artifact 成功门禁和健康切换/回滚语义。

## 2. 模块边界

| 模块 | 拥有 | 不拥有 |
| --- | --- | --- |
| application | StudioApplication reservation、初始化 DAG 引用、元数据、归档和内部默认 Workspace 引用 | AI 能力 Application、Agent Session、运行时容器、公共 Workspace 资源 |
| source | 内部 Repository、Workspace、文件索引、Revision/CommitSHA、ChangeSet、Snapshot、Version、`SourceProvider` 消费接口及应用级源码投影 | GitLab 私表、远端 numeric ID/PAT、Agent 会话、生产 Runtime、Workspace 页面或选择器 |
| preview | 基于当前 Workspace Revision 的 StudioPreviewRuntime 和诊断摘要 | 正式 Snapshot、Build Artifact、Release |
| build | StudioBuild 业务投影、canonical owner、Build Gate、Task/Artifact 稳定引用和受控 producer 批量摘要 | TaskAttempt/重试状态、Artifact 内容、源码当前目录 |
| release-runtime | RuntimeConfig 引用、StudioRelease、StudioRuntimeInstance、健康切换和回滚 | Docker/Provider 私有状态、Secret 明文、Artifact 内容 |
| access | 应用/源码/版本/发布权限、Runtime Git access 与 Invocation base context | Identity 用户、Agent 业务生命周期、明文 Git token |
| event-outbox | AppStudio 可靠事件、重试和重放 | Notification 收件箱、SSE 历史事实 |

## 3. 输入与输出

- 公共 `CreateStudioApplication` 接收初始需求、附件、显式 Coding 模型选择、可选 Agent Profile 和创建幂等键，但不接受 Workspace、Blueprint 或 GitLab 参数；当前 `STATIC_WEB` 固定使用内置 `web-react@v1` 和 `agent.coding@1.0`。
- 初始化先按 owner/创建幂等键在事务内持久化不可用的 `CREATING` Application/Repository/Workspace/Project 保留记录与初始化 DAG ID并提交受信 DAG，HTTP 200 返回 `application + dag_task_group_id`。DAG 固定为 `GITLAB_PROJECT`、`GITLAB_WEBHOOK`、`APPLICATION_INITIALIZATION`、`FIRST_CODING_INVOCATION` 四阶段，依次幂等确保 private Project/Starter commit、Project Hook、Revision 0/Agent/Session/Bindings 和首次 Message/Invocation reservation 与 Task 提交；全部完成并通过当前 DAG owner fence 后才切换 `READY`。
- 初始化使用 Blueprint `system.md + initial.md` 持久化首条 Message 和 CODING Invocation；后续使用 `system.md + followup.md`，`fix.md` 随 Blueprint 发布但本阶段不路由。首次 Task 提交失败保留同一 Message/Invocation 并将 Application 投影为 `ERROR`；显式恢复复用该 reservation。进入 `READY` 后 Invocation 执行失败只影响 Invocation，不回退 Application 初始化状态。
- `GET /api/v1/studio-applications/{id}/initialization` 只按 Application 当前 DAG 聚合固定四阶段、0..1 进度、状态、Attempt、失败时间、安全业务错误和更新时间。不得透传 Task arguments/output、Workspace、credential、authorization reference、Agent Message、Provider response、Conductor 字段或 runtime payload；`ERROR` 诊断长期保留。
- `POST /api/v1/studio-applications/{id}/initialization/retry` 仅接受 `ERROR` Application 和 `idempotency_key`。DAG ID 由 Application ID 与 key 稳定派生；同 key 返回同轮结果，不同 key 在已有初始化运行时返回 `ERR_APPSTUDIO_APPLICATION_INVALID_STATE`。新 DAG 创建成功后切换当前 DAG 引用和 `CREATING`；失败时仅在当前引用仍等于候选 DAG时条件回滚 `ERROR`。
- 初始化终态投影必须校验 `task.owner_id == application.initialization_dag_task_group_id`。旧 DAG 迟到事件只保留在 Task Center 历史，不得更新 Application 或当前初始化聚合。崩溃重试必须复用同一 Project、Hook、commit、Agent、Session、Binding、Message 和 Invocation。
- StudioApplication 内部保存当前 `coding_agent_id/coding_session_id/coding_agent_generation`；应用级状态、消息、Invocation 查询/事件/取消、挂起、恢复和替换均通过 Agent 内部 owner-scoped 接口代理，响应不得返回 Workspace。
- `ListStudioAgentMessages` 只能代理 Agent `ListMessages` 并限定当前 Application/generation/session，固定按 `(created_at DESC, id DESC)` 分页。AppStudio 不保存第二份 Message；Invocation 响应必须携带稳定 `user_message_id/assistant_message_id` 供发送、历史和 SSE 归并。
- `StreamStudioAgentInvocationEvents` 只能代理 Agent 持久化的 12 类统一事件。SSE `id/event/data` 分别映射十进制 `sequence_no`、统一事件名和类型化 envelope；`Last-Event-ID` 只接受非负十进制并只重放更大序号。唯一终态事件 flush 后关闭，已终态 Invocation 补完重放后关闭，heartbeat 不占序号。
- 替换成功后原子递增 generation 并切换新 Agent/Session；新 generation 原子创建默认平台 MCP Binding，旧 Agent 历史保留。已有当前 generation 执行一次幂等回填；用户删除后同 generation 不重建。替换失败继续使用旧引用，不得形成半切换 generation。
- Coding Invocation 创建时固定 Application、Workspace、base Revision、base CommitSHA、Blueprint version 和 prompt kind；同一 Workspace 同时只允许一个源码写事务。Worker 在 Invocation 终态前校验默认分支从 base 到 HEAD 恰好一个普通 fast-forward commit，并按 Invocation 幂等生成一个既有 ChangeSet 和下一条 Revision。无 commit、多 commit、分叉、force 语义、base 不匹配或并发写冲突时 Invocation 失败且不推进 Revision；push 后崩溃重试必须继续同步同一 commit。
- 应用级 Invocation 投影按 `agent_invocation_id` 聚合全部已应用 ChangeSet，`resulting_source_revision` 取最大 `target_revision`，`resulting_change_set_id` 取该 Revision 对应的最后一个 ChangeSet。恢复继续调用既有 source restore API，以当前 Revision/CommitSHA 为 base 创建新的 Git commit、Restore ChangeSet/Revision；Session、Message、Invocation、原 ChangeSet 和历史 Revision 全部保留。
- 公共源码、Revision、ChangeSet、Snapshot 和 Preview API 只以 `studio_application_id` 寻址；公共 DTO、权限、错误、通知和 SSE 不得返回或要求 `workspace_id`。
- 所有 API 源码写入必须带 `base_revision` 和幂等键；AppStudio 在内部解析唯一默认 Workspace、Revision CommitSHA 和 GitLab branch HEAD，通过带 base SHA 与稳定 ChangeSet 标记的 Git commit 应用。远端 commit 成功而数据库提交失败时重试必须识别并复用原 commit；冲突不得自动覆盖、部分应用或隐式合并。
- 文件读取、列表、搜索、Restore、Snapshot 和正文 digest 均按目标 Revision 的 `commit_sha` 通过 `SourceProvider` 获取。Source Snapshot 是引用固定 Revision/CommitSHA 的不可变 Build 输入；Build 不得读取当前 Workspace。Production Release 固定 Artifact ID 和 digest，不得挂载 Workspace、Revision 或 Snapshot。
- Build、Preview、Release/升级/回滚的实际运行均通过 Task Center -> Task Worker -> Infra Adapter -> Infrastructure。
- GitLab Push/Pipeline Hook 使用 Project 专属 token digest 验证。Push 只按本地 Project/CommitSHA 提交固定领域 DAG；Snapshot 必须等待并绑定 canonical Revision。Pipeline 成功后从受限 artifact 流完成既有 StudioBuild Bundle lifecycle，再由 `appstudio.preview.ensure` 使用同一 Revision SourceArchive 创建 Preview。Production 不进入该 DAG。
- Preview 创建/刷新与停止分别使用 `appstudio.preview.ensure/stop`，Build 使用 `appstudio.build.execute`，部署/升级/回滚与停止分别使用 `appstudio.production.reconcile/stop`；arguments、结果、能力和策略必须符合 Task Center `function-registry.yaml` 固定版本，AppStudio 不提交 Infra DTO。
- AppStudio 只保存 Task ID、InfraRuntime ID、Endpoint 摘要、Artifact ID/digest 和脱敏诊断；不保存 TaskAttempt、容器 ID、Host Port、Provider response 或 storage_ref。
- StudioBuild 的 `owner_user_id` 是 Bundle Artifact owner 的 canonical 来源。`appstudio.build.execute` Task Worker 创建 Artifact 时必须携带受信服务身份和原任务 `authorization_ref`；Bundle 固定声明 `producer_type=studio_build`、`producer_id=StudioBuild.id` 和 `producer_idempotency_key=studio-build:<studio_build_id>:bundle`。自动 TaskAttempt 重试复用同一 key；新逻辑构建创建新 StudioBuild ID。
- `RuntimeConfig` 使用 PUT 整体替换并以 `resource_version` 乐观控制，只保存 `secret://`/`integration://` 引用和校验状态。

## 4. 跨域协作

| 目标 | 允许调用 | 禁止行为 |
| --- | --- | --- |
| agent | 调用内部 `CreateCodingAgentForStudio`、owner-scoped `ListMessages`/Invocation 事件重放和 Agent/Session/Invocation 操作；实现 `WorkspaceGateway` 的 Runtime workspace access 与 Invocation base context | 签发旧正文工具授权、让前端调用内部创建语义、读取 Agent 私表、移除公共 Platform kind guard、建立第二套交互记录 |
| gitlab | 通过消费方 `SourceProvider` 使用默认 Server、稳定 GitLabProject ID、Repository 和 Runtime token 能力 | 读取 GitLab 私表、保存远端 numeric ID/PAT/credential URL、建立跨 Domain 外键 |
| task-center | 创建初始化及 Build/Preview/Production DAG/任务，按当前 DAG 读取阶段安全投影并消费可靠状态 | 写 Task/Attempt/重试/超时终态，向公共初始化 DTO透传原始任务 payload |
| infrastructure | 通过 Task Center 间接使用 Revision/Snapshot 的 CommitSHA archive access、Runtime Git access `SECRET_REF` 和 Artifact 引用 | 直接操作 Docker、宿主机路径或 Provider API，向环境变量/inspect 暴露 token |
| asset-library | 受控创建/读取 Bundle Artifact 和批量摘要；通过 `POST /api/v1/studio-builds/batch-summaries` 读取 owner 与一跳 producer 投影 | 保存 Blob、storage_uri、写 Artifact 私表，或由 Asset Library 读取 AppStudio 私表 |
| notification-center/sse | 发布可靠 AppStudio 状态事件 | 写通知收件箱或以 UserEvent 替代事实 |

## 5. 一致性与安全

- StudioApplication 与 application-platform.Application 身份、版本、运行对象和私有数据完全分离。
- ChangeSet、Revision、Snapshot、Version、Build、Release 和 RuntimeInstance 的历史不可被后续可变资源覆盖。
- `StudioSourceRepository.gitlab_project_id` 只保存 GitLabProject 本地稳定 ID，不建立跨 Domain 外键；`StudioWorkspaceRevision.commit_sha` 固定后不可修改。管理员绕过平台修改默认分支视为外部冲突，不自动接受或回填 Revision。
- Build 成功必须同时满足 Task 终态、Asset Library Artifact 内容完成和 digest 一致；AtomicTask SUCCESS 不能单独推断 Artifact ready。
- `POST /api/v1/studio-builds/batch-summaries` 每批接收 1..200 个 `{id}`，响应 `total/items` 与请求数量和顺序一致；每项返回请求 ID 与 nullable `studio_build`，投影字段严格限制为 `id/owner_user_id/name/status`。不得返回 Task 参数、`authorization_ref`、诊断、日志、Artifact ID/digest、源码、Revision 或 Snapshot 信息。
- Artifact 创建时，AppStudio 对受信服务身份携带的原任务 `authorization_ref` 按委托用户执行 `appstudio.build.manage`；Artifact 列表/详情时按当前调用者执行同一校验。仅有服务身份不得绕过用户权限，不存在或不可见统一返回 null。
- `authorized_editor` 和 `system_admin` 可以按 AppStudio 授权查看 Build，但不因此获得 Asset Library Artifact 权限；Artifact 仍由 Asset Library 严格按 owner 过滤。
- 新生产 Runtime 只有健康后才能切换入口；部署失败、健康失败或回滚失败不得破坏旧健康实例。
- 回滚必须创建新的 StudioRelease 和候选 StudioRuntimeInstance，并引用目标历史 Release 的不可变内容；不得修改或重新激活旧 Release。
- API/事件列表使用 `total/items`、统一分页和最多一跳摘要；文件正文按大小上限返回，禁止把源码大对象放进列表。
- `web-react@v1` 使用结构化 YAML 和嵌入式只读资产加载，包含 React/TypeScript/Vite/pnpm lockfile、基础页面、`.gitignore`、四类 prompt 和只 include `omnimam/appstudio-ci:/web-app.yml@main` 的 `.gitlab-ci.yml`；不创建 Service、公共 API 或数据库表。
- Coding Agent 高频 Invocation 事件不写 AppStudio Outbox、不进入通用 `/api/v1/events/stream`；AppStudio 只执行鉴权、当前 generation/session 范围校验和 DTO 投影。
- Coding Agent Runtime 详情、历史、日志和健康由 Agent Service 提供。AppStudio 只执行应用所有权、当前 Agent/generation 范围校验和 DTO 投影；历史允许覆盖该 Application 已授权的旧 generation。日志额外要求 `appstudio.agent.runtime.logs.read`，其他诊断使用 `appstudio.agent.read`。
- AppStudio 不得直接调用 Infrastructure 诊断 API、读取 Agent/Infrastructure 私表或保存第二份 Runtime/Invocation 投影；Runtime Endpoint、Infra Runtime ID、容器/Provider 信息、宿主路径和私网地址不得进入公共 DTO。
- `studio_workspaces`、Workspace Revision、ChangeSet、Snapshot 与 Preview 中的 Workspace 字段继续作为后端 canonical 事实，不因公共 API 内化而删除或改名。

## 6. S1 追溯

主要规则：`R-STUDIO-001..027`。主要来源章节：应用分离（2）、源码/Workspace（3、5、7）、初始化诊断与恢复（6）、Preview（9）、Build（10）、Release/RuntimeInstance（11-12）、权限/Secret（17-18）、Agent 面板与接口（19-20）、事件（21）、错误与范围（22-25）。
