# AppStudio Module Contract

产品语义以 `00_product/domains/appstudio/product-spec.md` 为准。本合同只覆盖当前 S1 草稿；旧版 S2 不属于输入。`StudioApplication`、`StudioSourceRepository`、`StudioWorkspace`、`StudioWorkspaceRevision`、`StudioChangeSet`、`StudioSourceSnapshot`、`StudioApplicationVersion`、`StudioBuild`、`RuntimeConfig`、`StudioRelease`、`StudioRuntimeInstance` 是唯一 canonical 对象；旧 Project/StudioApp/Deployment 名称不再构成产品事实或兼容别名。

## 1. 追溯状态

当前 AppStudio S1 使用 `US-APPSTUDIO-001`、`BR-APPSTUDIO-001`、`AC-APPSTUDIO-001-01..17` 及 `R-STUDIO-*` 规则。OpenAPI、Schema、错误、权限和事件必须同时遵守 Workspace 后端内化、Coding Agent generation、消息/事件 facade、canonical 源码谱系、Artifact 成功门禁和健康切换/回滚语义。

## 2. 模块边界

| 模块 | 拥有 | 不拥有 |
| --- | --- | --- |
| application | StudioApplication 初始化、元数据、归档和内部默认 Workspace 引用 | AI 能力 Application、Agent Session、运行时容器、公共 Workspace 资源 |
| source | 内部 Repository、Workspace、文件索引、Revision、ChangeSet、Snapshot、Version及应用级源码投影 | Agent 会话、源码存储 Provider 私有配置、生产 Runtime、Workspace 页面或选择器 |
| preview | 基于当前 Workspace Revision 的 StudioPreviewRuntime 和诊断摘要 | 正式 Snapshot、Build Artifact、Release |
| build | StudioBuild 业务投影、canonical owner、Build Gate、Task/Artifact 稳定引用和受控 producer 批量摘要 | TaskAttempt/重试状态、Artifact 内容、源码当前目录 |
| release-runtime | RuntimeConfig 引用、StudioRelease、StudioRuntimeInstance、健康切换和回滚 | Docker/Provider 私有状态、Secret 明文、Artifact 内容 |
| access | 应用/源码/版本/发布权限和 Coding Agent Tool 授权 | Identity 用户、Agent 业务生命周期 |
| event-outbox | AppStudio 可靠事件、重试和重放 | Notification 收件箱、SSE 历史事实 |

## 3. 输入与输出

- 公共 `CreateStudioApplication` 接收初始需求、附件、显式 Coding 模型选择、可选 Agent Profile 和创建幂等键，但不接受 Workspace 输入。AppStudio 必须在初始化事务中创建 Application、唯一默认 Repository/StudioWorkspace revision 0，并通过 Agent 内部 `CreateCodingAgentForStudio` 创建固定绑定的 Coding Agent、默认 Session、WorkspaceBinding、选定的 ACTIVE primary ModelBinding 和默认平台 MCP Binding。
- 初始化事务失败时不得产生可用项目；同一 owner/创建幂等键重试不得重复初始化对象。初始化成功后 Application 保持 `READY`，再持久化首条 Message 和 CODING Invocation。首次 Task 提交失败只把该 Invocation 投影为 `FAILED/ERR_AGENT_INVOCATION_TASK_UNAVAILABLE`；相同创建幂等键复用同一 Message/Invocation 重试提交，不删除项目或重复创建 Agent、Session、Binding。
- StudioApplication 内部保存当前 `coding_agent_id/coding_session_id/coding_agent_generation`；应用级状态、消息、Invocation 查询/事件/取消、挂起、恢复和替换均通过 Agent 内部 owner-scoped 接口代理，响应不得返回 Workspace。
- `ListStudioAgentMessages` 只能代理 Agent `ListMessages` 并限定当前 Application/generation/session，固定按 `(created_at DESC, id DESC)` 分页。AppStudio 不保存第二份 Message；Invocation 响应必须携带稳定 `user_message_id/assistant_message_id` 供发送、历史和 SSE 归并。
- `StreamStudioAgentInvocationEvents` 只能代理 Agent 持久化的 12 类统一事件。SSE `id/event/data` 分别映射十进制 `sequence_no`、统一事件名和类型化 envelope；`Last-Event-ID` 只接受非负十进制并只重放更大序号。唯一终态事件 flush 后关闭，已终态 Invocation 补完重放后关闭，heartbeat 不占序号。
- 替换成功后原子递增 generation 并切换新 Agent/Session；新 generation 原子创建默认平台 MCP Binding，旧 Agent 历史保留。已有当前 generation 执行一次幂等回填；用户删除后同 generation 不重建。替换失败继续使用旧引用，不得形成半切换 generation。
- 应用级 Invocation 投影按 `agent_invocation_id` 聚合全部已应用 ChangeSet，`resulting_source_revision` 取最大 `target_revision`，`resulting_change_set_id` 取该 Revision 对应的最后一个 ChangeSet。恢复继续调用既有 source restore API，以当前 Revision 为 base 创建新的 Restore ChangeSet/Revision；Session、Message、Invocation、原 ChangeSet 和历史 Revision 全部保留。
- 公共源码、Revision、ChangeSet、Snapshot 和 Preview API 只以 `studio_application_id` 寻址；公共 DTO、权限、错误、通知和 SSE 不得返回或要求 `workspace_id`。
- 所有源码写入必须带 `base_revision` 和幂等键；AppStudio 在内部解析唯一默认 Workspace，冲突不得自动覆盖、部分应用或隐式合并。
- Source Snapshot 是不可变 Build 输入；Build 不得读取当前 Workspace。Production Release 固定 Artifact ID 和 digest，不得挂载 Workspace、Revision 或 Snapshot。
- Build、Preview、Release/升级/回滚的实际运行均通过 Task Center -> Task Worker -> Infra Adapter -> Infrastructure。
- Preview 创建/刷新与停止分别使用 `appstudio.preview.ensure/stop`，Build 使用 `appstudio.build.execute`，部署/升级/回滚与停止分别使用 `appstudio.production.reconcile/stop`；arguments、结果、能力和策略必须符合 Task Center `function-registry.yaml` 固定版本，AppStudio 不提交 Infra DTO。
- AppStudio 只保存 Task ID、InfraRuntime ID、Endpoint 摘要、Artifact ID/digest 和脱敏诊断；不保存 TaskAttempt、容器 ID、Host Port、Provider response 或 storage_ref。
- StudioBuild 的 `owner_user_id` 是 Bundle Artifact owner 的 canonical 来源。`appstudio.build.execute` Task Worker 创建 Artifact 时必须携带受信服务身份和原任务 `authorization_ref`；Bundle 固定声明 `producer_type=studio_build`、`producer_id=StudioBuild.id` 和 `producer_idempotency_key=studio-build:<studio_build_id>:bundle`。自动 TaskAttempt 重试复用同一 key；新逻辑构建创建新 StudioBuild ID。
- `RuntimeConfig` 使用 PUT 整体替换并以 `resource_version` 乐观控制，只保存 `secret://`/`integration://` 引用和校验状态。

## 4. 跨域协作

| 目标 | 允许调用 | 禁止行为 |
| --- | --- | --- |
| agent | 调用内部 `CreateCodingAgentForStudio`、owner-scoped `ListMessages`/Invocation 事件重放和 Agent/Session/Invocation 操作，签发受控 Workspace Tool 授权 | 让前端调用内部创建语义、读取 Agent 私表、移除公共 Platform kind guard、建立第二套交互记录 |
| task-center | 创建/查询/取消 Build/Preview/Production functionRef 任务，消费可靠状态 | 写 Task/Attempt/重试/超时终态 |
| infrastructure | 通过 Task Center 间接使用 Revision/Snapshot/Artifact 受控 `source_ref` | 直接操作 Docker、宿主机路径或 Provider API |
| asset-library | 受控创建/读取 Bundle Artifact 和批量摘要；通过 `POST /api/v1/studio-builds/batch-summaries` 读取 owner 与一跳 producer 投影 | 保存 Blob、storage_uri、写 Artifact 私表，或由 Asset Library 读取 AppStudio 私表 |
| notification-center/sse | 发布可靠 AppStudio 状态事件 | 写通知收件箱或以 UserEvent 替代事实 |

## 5. 一致性与安全

- StudioApplication 与 application-platform.Application 身份、版本、运行对象和私有数据完全分离。
- ChangeSet、Revision、Snapshot、Version、Build、Release 和 RuntimeInstance 的历史不可被后续可变资源覆盖。
- Build 成功必须同时满足 Task 终态、Asset Library Artifact 内容完成和 digest 一致；AtomicTask SUCCESS 不能单独推断 Artifact ready。
- `POST /api/v1/studio-builds/batch-summaries` 每批接收 1..200 个 `{id}`，响应 `total/items` 与请求数量和顺序一致；每项返回请求 ID 与 nullable `studio_build`，投影字段严格限制为 `id/owner_user_id/name/status`。不得返回 Task 参数、`authorization_ref`、诊断、日志、Artifact ID/digest、源码、Revision 或 Snapshot 信息。
- Artifact 创建时，AppStudio 对受信服务身份携带的原任务 `authorization_ref` 按委托用户执行 `appstudio.build.manage`；Artifact 列表/详情时按当前调用者执行同一校验。仅有服务身份不得绕过用户权限，不存在或不可见统一返回 null。
- `authorized_editor` 和 `system_admin` 可以按 AppStudio 授权查看 Build，但不因此获得 Asset Library Artifact 权限；Artifact 仍由 Asset Library 严格按 owner 过滤。
- 新生产 Runtime 只有健康后才能切换入口；部署失败、健康失败或回滚失败不得破坏旧健康实例。
- 回滚必须创建新的 StudioRelease 和候选 StudioRuntimeInstance，并引用目标历史 Release 的不可变内容；不得修改或重新激活旧 Release。
- API/事件列表使用 `total/items`、统一分页和最多一跳摘要；文件正文按大小上限返回，禁止把源码大对象放进列表。
- Coding Agent 高频 Invocation 事件不写 AppStudio Outbox、不进入通用 `/api/v1/events/stream`；AppStudio 只执行鉴权、当前 generation/session 范围校验和 DTO 投影。
- `studio_workspaces`、Workspace Revision、ChangeSet、Snapshot 与 Preview 中的 Workspace 字段继续作为后端 canonical 事实，不因公共 API 内化而删除或改名。

## 6. S1 追溯

主要规则：`R-STUDIO-001..025`。主要来源章节：应用分离（2）、源码/Workspace（3、5、7）、Preview（9）、Build（10）、Release/RuntimeInstance（11-12）、权限/Secret（17-18）、事件（21）、错误与范围（22-25）。
