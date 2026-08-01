# AppStudio Module Contract

产品语义以 `00_product/domains/appstudio/product-spec.md` 为准。本合同覆盖第一阶段内置 Source Service、TypeScript Light BFF、编辑态 Preview、Build Bundle、preview/production Release 与 StudioDeploymentProvider；外部 Git Provider、复杂自动合并和其他技术栈未开放。

## 1. 模块边界

| 模块 | 拥有 | 不拥有 | S1 引用 |
| --- | --- | --- | --- |
| application | StudioApplication、技术/运行 Profile、逻辑 Repository 与默认 Workspace 引用 | application-platform.Application、Agent 会话 | BR-APPSTUDIO-001、BR-APPSTUDIO-002；US-APPSTUDIO-001 |
| source-service | StudioSourceRepository、Workspace、文件索引、Revision、ChangeSet、Snapshot 与受控存储引用 | AgentInvocation、Build 执行状态、Artifact 内容 | BR-APPSTUDIO-002、BR-APPSTUDIO-003、BR-APPSTUDIO-004、BR-APPSTUDIO-005；US-APPSTUDIO-002、US-APPSTUDIO-003、US-APPSTUDIO-004 |
| source-version | 不可变 StudioSourceSnapshot 与 StudioApplicationVersion | 可变 Workspace 内容、Build Artifact | BR-APPSTUDIO-005、BR-APPSTUDIO-006；US-APPSTUDIO-004 |
| build | StudioBuild 业务投影、诊断摘要、Task/Artifact 稳定引用和 digest 快照 | TaskAttempt/重试、Artifact 内容与存储 | BR-APPSTUDIO-007、BR-APPSTUDIO-008、BR-APPSTUDIO-013；US-APPSTUDIO-005 |
| preview | StudioPreviewRuntime、当前 Workspace Revision 的快速检查与权限裁剪诊断 | 正式 Snapshot、Artifact、Release | BR-APPSTUDIO-003、BR-APPSTUDIO-009；US-APPSTUDIO-006 |
| runtime-config | 公开配置、Secret/Integration 引用和资源 Profile | Secret 值、Identity Credential、Provider 私有配置 | BR-APPSTUDIO-010、BR-APPSTUDIO-011；US-APPSTUDIO-009 |
| release | StudioRelease、Artifact digest 固定、环境、回滚谱系、访问入口切换 | Build 执行、Artifact 内容、底层部署实例 | BR-APPSTUDIO-008、BR-APPSTUDIO-009、BR-APPSTUDIO-010、BR-APPSTUDIO-011、BR-APPSTUDIO-012；US-APPSTUDIO-007、US-APPSTUDIO-008、US-APPSTUDIO-009 |
| deployment-provider | 受控 Artifact 获取、运行配置注入、底层实例生命周期和健康检查 | Release 业务状态、AgentRuntime、Secret 业务事实 | BR-APPSTUDIO-009、BR-APPSTUDIO-010、BR-APPSTUDIO-011、BR-APPSTUDIO-012；US-APPSTUDIO-007、US-APPSTUDIO-008 |
| runtime-instance | StudioRuntimeInstance 业务状态、健康状态与权限裁剪入口摘要 | Provider 原始资源、路由基础设施私有配置 | BR-APPSTUDIO-009、BR-APPSTUDIO-011、BR-APPSTUDIO-012；US-APPSTUDIO-007、US-APPSTUDIO-008 |
| event-outbox | AppStudio 可靠事件写入、重试和重放 | Notification 收件箱、UserEvent 历史 | BR-APPSTUDIO-014；US-APPSTUDIO-001、US-APPSTUDIO-003、US-APPSTUDIO-004、US-APPSTUDIO-005、US-APPSTUDIO-006、US-APPSTUDIO-007、US-APPSTUDIO-008 |

## 2. 数据归属

| 数据 | 所有者 | AppStudio 保存方式 |
| --- | --- | --- |
| StudioApplication、Repository、Workspace、Revision、ChangeSet、Snapshot、Version | appstudio | 完整业务事实；存储定位只在 Source Service 私有边界 |
| StudioBuild、RuntimeConfig、Release、StudioRuntimeInstance | appstudio | 完整业务事实与外部稳定引用 |
| Agent、Session、Invocation、Message、Memory、AgentRuntime | agent | 只保存 ChangeSet actor 稳定 ID 与权限裁剪摘要 |
| AtomicTask、TaskAttempt、TaskGroup、Schedule | task-center | 只保存任务稳定 ID 与 Build/Release 业务投影 |
| Artifact、Blob、Asset、Representation | asset-library | 只保存 `artifact_id`、不可变 digest 与非敏感历史快照 |
| Notification、UserEvent | notification-center、sse | 不保存；只发布可靠源事件 |
| Secret、Integration 授权、JWT/RBAC | identity/受控集成边界 | 只保存引用与校验状态，绝不保存解析后的 Secret |

## 3. StudioApplication 初始化

创建事务必须保证 StudioApplication、StudioSourceRepository、默认 StudioWorkspace 和初始 Revision 形成一致聚合：

```text
validate template and profiles
→ create StudioApplication(CREATING)
→ create built_in SourceRepository
→ materialize controlled template to Workspace Storage
→ write appstudio.json application_id
→ create Revision 1 and file index
→ bind default Workspace/Repository
→ mark StudioApplication and Workspace READY
```

- `template_id` 是生成应用平台模板，不得解析成 application-platform.ApplicationTemplate。
- 初始化失败保留可诊断 ERROR 聚合或在幂等边界内补偿，不得返回缺少 Workspace/Revision 的 READY 应用。
- API 永不返回 Repository/Workspace `storage_ref`、宿主路径或 Source Service Provider 私有配置。
- 应用归档只停止新的编辑/构建/发布入口，不删除历史 Snapshot、Build、Artifact 引用、Release 或 Runtime 历史。

相关引用：BR-APPSTUDIO-001、BR-APPSTUDIO-002、BR-APPSTUDIO-013；US-APPSTUDIO-001。

## 4. Workspace Tool 授权

Coding Agent 调用带 `X-Workspace-Tool-Authorization` 的接口时，AppStudio 必须验证以下声明：

```text
principal_id
agent_id
agent_session_id
agent_invocation_id
studio_workspace_id
allowed_actions
expires_at
authorization_id
```

- 同时通过 Agent 受控接口确认 Agent `kind=coding`、`workspace_type=studio` 且固定 `workspace_id` 匹配。
- 授权只覆盖 list/read/search/apply_change_set/preview_check/diagnostics 中明确动作，不得隐式允许 Snapshot、Build、Release、RuntimeConfig 或部署。
- Invocation 终态、Agent 停用、Workspace 归档、Principal 失权或授权过期后必须拒绝；重新签发不得扩大动作范围。
- Header 值不得进入日志、事件、ChangeSet、错误详情或审计 payload。审计只记录 `authorization_id` 和动作摘要。
- 普通用户请求不使用该 Header，按 Identity/RBAC 和应用协作权限校验。

相关引用：BR-APPSTUDIO-003、BR-APPSTUDIO-013；US-APPSTUDIO-002、US-APPSTUDIO-003、US-APPSTUDIO-006。

## 5. 文件读取与查询预算

- 文件路径必须是 Workspace 根目录内的规范化相对路径，拒绝绝对路径、`..`、符号链接逃逸和受保护文件越权读取。
- `studio_source_files` 只保存索引、digest、大小与保护标记；文件正文由 Source Service 从受控存储读取。
- 列表和搜索在单个 Workspace/Revision 内分页，禁止为每个文件调用跨域服务。
- 文件内容响应有大小上限；超过上限返回 `truncated=true` 或要求更窄读取，不把大型源码塞入资源列表。
- Workspace Tool 不得返回 `storage_ref`、仓库 Provider 配置、生产 Secret、运行时凭证或未授权集成内容。

相关引用：BR-APPSTUDIO-002、BR-APPSTUDIO-003；US-APPSTUDIO-002。

## 6. ChangeSet 与 Revision

ChangeSet 应用顺序固定为：

```text
authorization and fixed Workspace
→ idempotency lookup
→ Workspace state and base_revision
→ normalize paths and operations
→ protected file / dependency / dangerous code / size validation
→ atomically materialize all changes
→ calculate source tree digest
→ create target Revision
→ update file index and Workspace.current_revision
→ persist applied ChangeSet and outbox event
```

- 相同 `workspace_id + idempotency_key` 必须返回同一 ChangeSet。成功重试不得再次递增 Revision。
- 任一校验或写入失败不得部分修改文件、创建 target Revision、刷新 Preview 或发布 revision 事件。
- `base_revision != current_revision` 返回 `ERR_APPSTUDIO_WORKSPACE_REVISION_CONFLICT`，携带当前 Revision 摘要，不自动覆盖或合并。
- 冲突/拒绝/失败 ChangeSet 的 `target_revision` 必须为 null；失败摘要不得包含完整源码、Secret 或内部路径。
- 历史恢复以当前 Revision 为 `base_revision`，以选定历史 Revision 为 `source_revision`，创建新的 Revision；不删除中间历史。
- Agent/Session/Invocation ID 是跨域审计引用，不建 FK。Agent 删除不改变既有 ChangeSet/Revision。

相关引用：BR-APPSTUDIO-003、BR-APPSTUDIO-004、BR-APPSTUDIO-013、BR-APPSTUDIO-014；US-APPSTUDIO-003。

## 7. Snapshot 与 Version

- Snapshot 创建只接受 Workspace 当前可发布 Revision；在短时写锁内物化内容、校验 `appstudio.json`、计算 `content_digest`/`manifest_digest` 后解除锁。
- 只有 `status=ready` 且 digest、私有存储引用齐全的 Snapshot 才能被 Version 或 Build 引用。
- Snapshot 创建失败必须释放写锁并保持 Workspace 可编辑；失败对象不能被 Build 使用。
- `content_digest` 在同一 StudioApplication 内幂等复用相同内容 Snapshot，但不得修改其创建来源和历史。
- StudioApplicationVersion 固定 `source_snapshot_id`，创建后不得换绑；版本号在应用内唯一。
- API 和事件不返回 Snapshot `storage_ref`，Build Service 通过一次性受控读取能力获取内容。

相关引用：BR-APPSTUDIO-005、BR-APPSTUDIO-006；US-APPSTUDIO-004、US-APPSTUDIO-005。

## 8. Build 与 Task Center

Build 创建顺序固定为：

```text
validate application/snapshot/version
→ persist StudioBuild(pending) with request idempotency
→ create TaskGroup/AtomicTask through Task Center
→ bind stable task IDs
→ Build workers read immutable Snapshot
→ Build Service validates/compiles/packages
→ Asset Library creates idempotent studio_application_bundle Artifact
→ persist artifact_id/digest snapshot
→ mark StudioBuild succeeded
```

- AppStudio 不保存或更新 TaskAttempt、重试、取消、超时或进度状态机；只消费 Task Center 可靠事件并以查询对账单调更新 Build 投影。
- 取消叠加 Task Center 权限并转发取消请求。只有 Task Center 终态后 Build 才能投影为 `cancelled`。
- Build 只能读取 Snapshot，禁止读取当前 Workspace。相同 Snapshot 可创建多个逻辑 Build。
- Bundle producer key 固定为 `studio-build:<studio_build_id>:bundle`。同一逻辑 Build 的 TaskAttempt 重试必须复用该 key。
- 只有 Asset Library 确认 Artifact 类型为 `studio_application_bundle`、内容完成且 digest 与 Build 快照一致时，Build 才能 `succeeded`。
- 失败 Build 保留 Task 与权限裁剪诊断，但不得产生可发布 Artifact 引用或修改既有 Release。

相关引用：BR-APPSTUDIO-005、BR-APPSTUDIO-007、BR-APPSTUDIO-008、BR-APPSTUDIO-013、BR-APPSTUDIO-014；US-APPSTUDIO-005。

## 9. Artifact 边界

- Artifact、Blob、内容、存储、处理、保留和登记归 asset-library；AppStudio 不建 Artifact FK，不访问私表。
- AppStudio 只保存 `artifact_id`、`artifact_digest`、size/created_at 历史快照。API 通过 Asset Library 受控批量摘要返回当前状态。
- 不返回 `storage_uri`、Blob path、StorageBackend、永久/任意下载 URL 或签名 Query。
- Build Worker 或 Deployment Provider 不得成为 Bundle Owner；Owner 必须是发起 Build 的用户或等价受信主体。
- Artifact 交付失败时 Build 不得伪造 succeeded，也不得通过 AppStudio 私有存储记录绕过 Asset Library。

相关引用：BR-APPSTUDIO-008、BR-APPSTUDIO-013；US-APPSTUDIO-005、US-APPSTUDIO-007。

## 10. Preview 边界

- StudioPreviewRuntime 固定一个当前 Workspace Revision，只用于增量编译、快速 BFF 启动和诊断。
- Preview 不创建 Source Snapshot、Build Artifact、StudioApplicationVersion 或 StudioRelease，也不执行完整正式安全检查。
- Coding Agent 触发 Preview Check 必须持有当前 Invocation 的 Tool 授权；响应仅返回权限裁剪诊断和受控入口。
- Preview endpoint 通过访问代理或短期受控入口暴露；API 不返回 `endpoint_ref`、process ID、端口映射或私网地址。
- Preview 失败不回滚已成功 ChangeSet，不改写 Workspace Revision，也不影响现有正式 Release。

相关引用：BR-APPSTUDIO-003、BR-APPSTUDIO-009；US-APPSTUDIO-006。

## 11. RuntimeConfig 与 Secret

- PUT 整体替换指定 Version/Environment 的公开配置与引用集合，使用 `resource_version` 乐观控制。
- `secret_references` 只允许受控 `secret://` 引用；`integration_references` 只允许受控 `integration://` 引用。
- AppStudio 可以校验引用存在性、环境和主体范围，但不读取或保存 Secret 值。API 只返回引用与 valid/invalid/unavailable 状态。
- StudioDeploymentProvider 在固定 Release 部署边界内解析引用并短期注入，不得回写解析值或暴露给 Agent、Build、Preview、日志和事件。
- RuntimeConfig 未通过校验时不得创建 Release。部署时失效必须 fail closed，现有健康 Release 保持不变。

相关引用：BR-APPSTUDIO-010、BR-APPSTUDIO-011；US-APPSTUDIO-009。

## 12. Release、健康切换与回滚

Release 创建必须固定：

```text
studio_application_version_id
studio_build_id
runtime_config_id
artifact_id
artifact_digest
environment
deployment_provider_id
```

- 只接受 `StudioBuild.status=succeeded` 且 Artifact/digest 校验通过的 Build。
- preview 与 production Release 使用同一正式 Artifact/部署链路，但保持独立当前入口；编辑态 Preview Runtime 不可转成 Release。
- AppStudio 先创建 Release 和部署 Task，再由 Deployment Worker 调用 Provider。Provider 不直接写 Release 表。
- 新 RuntimeInstance 只有 `status=READY && health_status=healthy` 后才能原子切换访问入口并将 Release 标记 ready。
- 部署或健康失败保留失败 Release/RuntimeInstance 和诊断引用；不得切换或停止当前健康入口。
- 回滚以历史 Release 的固定 Artifact ID/digest 为源，创建新的 Release；不修改 Workspace、Snapshot、Build 或原 Release 历史。
- 回滚失败保持当前线上 Release 不变。成功后旧 Release 可标记 superseded，但不能删除。

相关引用：BR-APPSTUDIO-008、BR-APPSTUDIO-009、BR-APPSTUDIO-010、BR-APPSTUDIO-011、BR-APPSTUDIO-012；US-APPSTUDIO-007、US-APPSTUDIO-008、US-APPSTUDIO-009。

## 13. StudioDeploymentProvider

- Provider 输入只包含 Release/Runtime 稳定 ID、受控 Artifact 读取授权、固定 digest、RuntimeConfig 引用、资源 Profile、网络/路由策略和幂等键。
- Provider 负责获取/校验 Bundle、读取 manifest、解析受控引用、创建/停止一个轻量 BFF 运行单元、健康检查和返回受控入口。
- Provider 不下载源码、不安装依赖、不编译、不执行数据库 migration、不调用 Agent。
- `provider_runtime_id`、原始 endpoint、平台 Credential 和基础设施配置只在 provider/runtime 私有边界保存，不出现在 API/事件。
- AgentRuntimeProvider 与 StudioDeploymentProvider 不能共享业务状态、表或 Runtime ID；基础设施适配复用也必须保持两个领域合同隔离。

相关引用：BR-APPSTUDIO-009、BR-APPSTUDIO-010、BR-APPSTUDIO-011、BR-APPSTUDIO-012、BR-APPSTUDIO-013；US-APPSTUDIO-007、US-APPSTUDIO-008。

## 14. 权限、摘要与查询预算

- 不存在与不可见统一返回相应 `*_NOT_VISIBLE` 和 HTTP 200，避免泄露应用、源码、Build、Release 或 Artifact 存在性。
- 列表在 AppStudio 域内通过 JOIN 批量组装 Workspace/Version/Release 摘要；跨域 Agent/Task/Artifact 摘要必须调用目标域批量能力，禁止 N+1。
- 所有响应保留稳定 `*_id`；一跳摘要目标不可见、删除或不可用时为 null，不递归展开下一层。
- 历史 Build/Release 优先使用不可变 digest 和非敏感快照，不以当前可变 Artifact/配置覆盖历史事实。
- 管理员权限不隐含源码、Secret、生产入口或 Agent 会话读取权；每个资源和动作仍须显式授权。

相关引用：BR-APPSTUDIO-003、BR-APPSTUDIO-008、BR-APPSTUDIO-010、BR-APPSTUDIO-013；US-APPSTUDIO-001、US-APPSTUDIO-002、US-APPSTUDIO-003、US-APPSTUDIO-004、US-APPSTUDIO-005、US-APPSTUDIO-006、US-APPSTUDIO-007、US-APPSTUDIO-008、US-APPSTUDIO-009。

## 15. 事件边界

- AppStudio 聚合更新与 `appstudio_outbox` 在同一事务提交。事件幂等键使用 `aggregate_id:resource_version` 或 Snapshot/Revision 的稳定版本键。
- 事件只携带稳定 ID、状态、资源版本、digest、权限裁剪入口摘要和必要失败分类；禁止源码、patch、文件内容、storage_ref、Secret、provider_runtime_id 和私有 endpoint。
- Agent 消费 Workspace/Preview 事件时按 Revision/资源版本幂等，不得据此复制 AppStudio 状态机。
- Notification Center 自行决定通知主题、聚合、已读和渠道；AppStudio 不维护通知收件箱。
- Task Center/Asset Library 源事件驱动 Build/Release 投影时，AppStudio 只接受更高版本并可通过受控查询对账，不从 AtomicTask SUCCESS 单独推断 Artifact ready。

相关引用：BR-APPSTUDIO-007、BR-APPSTUDIO-008、BR-APPSTUDIO-011、BR-APPSTUDIO-013、BR-APPSTUDIO-014；US-APPSTUDIO-001、US-APPSTUDIO-003、US-APPSTUDIO-004、US-APPSTUDIO-005、US-APPSTUDIO-006、US-APPSTUDIO-007、US-APPSTUDIO-008。

## 16. 跨域调用规则

| 目标领域 | 允许调用 | 禁止行为 |
| --- | --- | --- |
| agent | 校验固定 Coding Agent/Invocation、获取 actor 批量摘要、发布 Workspace/Preview 结果 | 读取 Agent 私表、创建第二套 Session/Invocation |
| task-center | 创建/查询/取消 Build/Deployment TaskGroup/AtomicTask、消费可靠状态事件 | 写 Task/Attempt/重试/Lease 状态 |
| asset-library | 创建/读取受控 Bundle Artifact、校验 digest、批量摘要 | 保存 Blob/storage_uri、直接写 Artifact 私表 |
| identity/integration | JWT/RBAC、引用校验、部署时受控 Secret 解析、安全审计 | 保存/返回 Secret、缓存永久授权 |
| notification-center | 消费可靠 AppStudio 事件 | 写通知、已读、偏好或聚合 |
| sse | 投影已持久化 AppStudio 变化提示 | 用 UserEvent 替代完整 REST 事实 |

跨域写动作必须携带 `request_id`、`correlation_id`、当前 Principal 和稳定幂等键。依赖失败不得通过直接写目标域表、复制状态机或绕过受控内容边界补偿。

## 17. 保留与删除策略

- StudioApplication 和 StudioWorkspace 首期只归档，不提供物理删除 API；归档不得级联删除 Repository、Revision、ChangeSet、Snapshot、Version、Build、Release 或 RuntimeInstance 历史。
- `studio_source_files.deleted=true` 是当前 Workspace 文件索引的 tombstone；源码恢复通过新 Revision 重建索引，不删除旧 Revision 内容。
- WorkspaceRevision、已应用/失败 ChangeSet、ready Snapshot、ApplicationVersion、Build、Release 和 RuntimeInstance 是审计或发布谱系事实，首期不可物理删除。
- 失败 Snapshot 可以在审计保留期后由 Source Service 清理私有存储内容，但保留失败元数据；ready Snapshot 被 Version/Build 引用时必须保留。
- PreviewRuntime 过期后可清理底层进程和私有 endpoint，业务记录进入 expired/stopped 并保留权限裁剪诊断。
- RuntimeConfig 通过 PUT 产生新 `resource_version`，不保留解析后的 Secret；历史 Release 固定其 `runtime_config_id`，被 Release 引用的配置不能物理删除。
- `appstudio_outbox` 成功投递并超过平台审计保留期后可物理清理；清理 outbox 不得删除或重放部署副作用。

相关引用：BR-APPSTUDIO-002、BR-APPSTUDIO-004、BR-APPSTUDIO-005、BR-APPSTUDIO-006、BR-APPSTUDIO-007、BR-APPSTUDIO-011、BR-APPSTUDIO-012、BR-APPSTUDIO-014；US-APPSTUDIO-001、US-APPSTUDIO-003、US-APPSTUDIO-004、US-APPSTUDIO-005、US-APPSTUDIO-006、US-APPSTUDIO-007、US-APPSTUDIO-008。
