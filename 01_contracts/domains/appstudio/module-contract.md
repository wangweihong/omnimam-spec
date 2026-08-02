# AppStudio Module Contract

产品语义以 `00_product/domains/appstudio/product-spec.md` 为准。本合同只覆盖当前 S1 草稿；旧版 S2 不属于输入。`StudioApplication`、`StudioSourceRepository`、`StudioWorkspace`、`StudioWorkspaceRevision`、`StudioChangeSet`、`StudioSourceSnapshot`、`StudioApplicationVersion`、`StudioBuild`、`RuntimeConfig`、`StudioRelease`、`StudioRuntimeInstance` 是唯一 canonical 对象；旧 Project/StudioApp/Deployment 名称不再构成产品事实或兼容别名。

## 1. 追溯状态

当前 AppStudio S1 使用 `US-APPSTUDIO-001`、`BR-APPSTUDIO-001`、`AC-APPSTUDIO-001-01..12` 及 `R-STUDIO-*` 规则。OpenAPI、Schema、错误、权限和事件必须同时遵守 canonical 源码谱系、Artifact 成功门禁和健康切换/回滚语义。

## 2. 模块边界

| 模块 | 拥有 | 不拥有 |
| --- | --- | --- |
| application | StudioApplication 初始化、元数据、归档和默认 Workspace 引用 | AI 能力 Application、Agent Session、运行时容器 |
| source | Repository、Workspace、文件索引、Revision、ChangeSet、Snapshot、Version | Agent 会话、源码存储 Provider 私有配置、生产 Runtime |
| preview | 基于当前 Workspace Revision 的 StudioPreviewRuntime 和诊断摘要 | 正式 Snapshot、Build Artifact、Release |
| build | StudioBuild 业务投影、Build Gate、Task/Artifact 稳定引用 | TaskAttempt/重试状态、Artifact 内容、源码当前目录 |
| release-runtime | RuntimeConfig 引用、StudioRelease、StudioRuntimeInstance、健康切换和回滚 | Docker/Provider 私有状态、Secret 明文、Artifact 内容 |
| access | 应用/Workspace/版本/发布权限和 Coding Agent Tool 授权 | Identity 用户、Agent 业务生命周期 |
| event-outbox | AppStudio 可靠事件、重试和重放 | Notification 收件箱、SSE 历史事实 |

## 3. 输入与输出

- 所有源码写入必须带 `base_revision` 和幂等键；冲突不得自动覆盖、部分应用或隐式合并。
- Source Snapshot 是不可变 Build 输入；Build 不得读取当前 Workspace。Production Release 固定 Artifact ID 和 digest，不得挂载 Workspace、Revision 或 Snapshot。
- Build、Preview、Release/升级/回滚的实际运行均通过 Task Center -> Task Worker -> Infra Adapter -> Infrastructure。
- Preview 创建/刷新与停止分别使用 `appstudio.preview.ensure/stop`，Build 使用 `appstudio.build.execute`，部署/升级/回滚与停止分别使用 `appstudio.production.reconcile/stop`；arguments、结果、能力和策略必须符合 Task Center `function-registry.yaml` 固定版本，AppStudio 不提交 Infra DTO。
- AppStudio 只保存 Task ID、InfraRuntime ID、Endpoint 摘要、Artifact ID/digest 和脱敏诊断；不保存 TaskAttempt、容器 ID、Host Port、Provider response 或 storage_ref。
- `RuntimeConfig` 使用 PUT 整体替换并以 `resource_version` 乐观控制，只保存 `secret://`/`integration://` 引用和校验状态。

## 4. 跨域协作

| 目标 | 允许调用 | 禁止行为 |
| --- | --- | --- |
| agent | 校验固定 Coding Agent/Invocation，签发受控 Workspace Tool 授权 | 读取 Agent 私表、建立第二套交互记录、绕过 Agent 授权 |
| task-center | 创建/查询/取消 Build/Preview/Production functionRef 任务，消费可靠状态 | 写 Task/Attempt/重试/超时终态 |
| infrastructure | 通过 Task Center 间接使用 Revision/Snapshot/Artifact 受控 `source_ref` | 直接操作 Docker、宿主机路径或 Provider API |
| asset-library | 受控创建/读取 Bundle Artifact 和批量摘要 | 保存 Blob、storage_uri 或写 Artifact 私表 |
| notification-center/sse | 发布可靠 AppStudio 状态事件 | 写通知收件箱或以 UserEvent 替代事实 |

## 5. 一致性与安全

- StudioApplication 与 application-platform.Application 身份、版本、运行对象和私有数据完全分离。
- ChangeSet、Revision、Snapshot、Version、Build、Release 和 RuntimeInstance 的历史不可被后续可变资源覆盖。
- Build 成功必须同时满足 Task 终态、Asset Library Artifact 内容完成和 digest 一致；AtomicTask SUCCESS 不能单独推断 Artifact ready。
- 新生产 Runtime 只有健康后才能切换入口；部署失败、健康失败或回滚失败不得破坏旧健康实例。
- 回滚必须创建新的 StudioRelease 和候选 StudioRuntimeInstance，并引用目标历史 Release 的不可变内容；不得修改或重新激活旧 Release。
- API/事件列表使用 `total/items`、统一分页和最多一跳摘要；文件正文按大小上限返回，禁止把源码大对象放进列表。

## 6. S1 追溯

主要规则：`R-STUDIO-001..024`。主要来源章节：应用分离（2）、源码/Workspace（3、5、7）、Preview（9）、Build（10）、Release/RuntimeInstance（11-12）、权限/Secret（17-18）、事件（21）、错误与范围（22-25）。
