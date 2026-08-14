# GitLab Domain Module Contract

## 1. 模块边界

| 模块 | 拥有事实 | 提供能力 | 不负责 |
| --- | --- | --- | --- |
| `server` | GitLabServer、credential、连接状态、AppStudio 默认标记 | 服务端派生 API URL、固定 Group ensure、Server CRUD、Test、默认 Server 解析和 Client Factory 输入 | GitLab 进程生命周期、Secret Provider |
| `project` | GitLabProject 本地投影、`CREATING -> READY/ERROR` reservation 和 AppStudio Hook 元数据 | 远端 Project/Hook 幂等创建、读取、删除及投影维护 | AppStudio Revision/ChangeSet、Webhook 业务编排 |
| `repository` | GitLab Repository 与 Project Access Token 协议适配 | tree/file/archive、HEAD、compare/commit、token create/revoke | AppStudio 业务事务、Runtime 生命周期 |
| `client` | GitLab HTTP 协议适配 | version/user/namespace/project/repository/token/pipeline API | 业务权限、数据库事务、Task 状态 |
| `pipeline-worker` | 一次 GitLab Pipeline Attempt 的外部调用 | create/get/cancel、external_job_id 恢复和小型结果 | AtomicTask 状态机、业务数据库直写、Infra/Docker |

## 2. API Server 协作

- Controller 负责请求绑定、BasicQueryParam、管理员权限和统一响应。
- Service 负责 Server/Project 业务规则、数据库事务、远端补偿和错误映射。
- Store 接口由 GitLab Service 消费；PostgreSQL adapter 实现查询、乐观版本和关联删除保护。
- Credential 只在服务端内存和 HTTP header 中短暂出现，不进入 JSON、日志、Task 参数、Task 输出或事件。
- Create/Update 请求不得接收 API URL 或 Namespace Path。Service 从规范化 External URL 的同一路径派生 `/api/v4`，依次调用 version/user，并通过 Client 幂等解析或创建 private 顶级 Group `omnimam-appstudio`。全部成功后才写入连接；创建直接写 `READY`，更新失败保留原连接。
- GitLab Client Factory 从 GitLabServer 构造带超时的 client；业务 service 不直接拼装 HTTP 请求。
- `is_appstudio_default=true` 只允许 READY Server；更新默认值必须在一个数据库事务中清除旧默认。API URL、Namespace Path 或 credential 变化以及 Test 失败必须清除当前标记，partial unique index 保证全局最多一个默认 Server。
- 默认 Server 解析找不到唯一 READY 且 `is_appstudio_default=true` 的 Server 时返回 `ERR_GITLAB_APPSTUDIO_DEFAULT_SERVER_UNAVAILABLE`；不得任意选择其他 READY Server。

## 3. GitLab Client 接口

客户端至少提供：

- `GetVersion`、`GetCurrentUser`、`ResolveNamespace`、`CreateNamespace`；
- `CreateProject`、`GetProject`、`DeleteProject`、`CreateProjectHook`、`GetProjectHook`、`DeleteProjectHook`；
- `ListRepositoryTree`、`GetRepositoryFile`、`GetRepositoryArchive`、`GetBranchHead`、`CompareCommits`、`CreateCommit`；
- `CreateProjectAccessToken`、`RevokeProjectAccessToken`；
- `CreatePipeline`、`GetPipeline`、`RetryPipeline`、`CancelPipeline`、`ListPipelineJobs`、`DownloadPipelineArtifact`。

管理调用使用 `PRIVATE-TOKEN`；Runtime Git clone/push 只使用限时 Project Access Token。所有调用必须限制响应体或 archive 流大小，解析 GitLab `{message}` 错误并保留上下文取消。连接 Test 的单次外部操作和整体检测必须有明确 deadline。任何 token、credential 或带凭据 clone URL 都必须在日志和错误中脱敏。

AppStudio 消费方定义 `SourceProvider`，GitLab domain 提供 `GitLabSourceProvider` adapter。该 adapter 只接受本地 GitLabProject ID 和结构化参数，提供确定性 Project 幂等初始化、按 commit SHA 的 file/tree/archive、带 base SHA 与稳定幂等标记的 commit、默认分支 HEAD/compare，以及 Runtime workspace access 创建/撤销。adapter 必须保留默认 Server 不可用、连接、远端 Project 和 projection 的结构化 GitLab 业务错误链，不得统一映射为 `ERR_APPSTUDIO_SOURCE_CHANGE_REJECTED`。远端 numeric ID、PAT 和 credential URL 不得跨越该接口。

AppStudio 初始化的顺序是：AppStudio 先持久化 `CREATING` Application/Repository/Workspace reservation；GitLab adapter 再以同一稳定本地 Project ID 和确定性 path 持久化 `CREATING` GitLabProject projection；只有 reservation 存在后才调用远端 Project API。远端成功时补全 numeric ID/URL 并切换 Project 为 `READY`；远端或补偿失败保留脱敏 `ERROR` reservation。重复调用必须复用 reservation、远端 Project 和 Starter commit。

AppStudio Project Hook URL 只能来自服务端部署配置。adapter 生成或接收当前调用内存中的随机 token，创建 Push/Pipeline Hook 后只把 Hook ID 和 `sha256:<hex>` digest 写入 Project 投影；明文不得被 Store、日志、错误或 Task 接收。Pipeline artifact 下载使用本地 Project ID、Pipeline ID 和固定 job/artifact 名定位并流式限制大小，不接受调用方 URL。

## 4. Task Center 协作

`gitlab.pipeline.run` 是非 Infra-backed 外部 AtomicTask。Task Center 负责创建 AtomicTask、TaskAttempt、重试、取消、超时、callback 调度和终态投影；GitLab Worker 只执行当前 Attempt。

输入：`gitlab_project_id`、`ref`、可选 `variables`。Worker 通过 GitLab Store 读取 Project/Server，再通过 Client Factory 调用 GitLab。输入不得携带 API URL、credential、远端 numeric project ID、任意 HTTP 地址或 Worker 配置。

首次 Attempt 创建远端 Pipeline 后保存 `external_job_id`；非终态返回 `IN_PROGRESS` 和 5 秒 callback。恢复和自动重试优先读取同一 external job。取消调用 `CancelPipeline`，失败/成功/取消只返回小型脱敏输出。

## 5. 跨域与安全

- AppStudio 只保存本地 GitLabProject ID，通过消费方 `SourceProvider` 使用内部能力；双方不共享表、不建立跨 Domain 外键，也不向 AppStudio 公共 API 增加 GitLab 字段。
- AppStudio 初始化仅解析唯一 READY 默认 Server，使用稳定 Application/Repository/Workspace/Project ID 和确定性 path。缺失默认 Server 返回专用结构化错误；远端 Project 或 Starter commit 已成功时，同一创建或恢复幂等链必须返回原 Project/commit，不得重复创建。
- Runtime workspace access 只允许目标 Project、固定 Runtime/generation、`write_repository` 和有限有效期。明文 token 只返回给受信 Infrastructure resolver 的内存链路；停止、替换或到期时幂等撤销，撤销失败依靠到期兜底。
- Identity 只提供 ADMIN/SUPER_ADMIN 权限校验；GitLab 不读取 Identity 私表。
- GitLab 不调用 Infrastructure，不操作 Docker Socket，不写其他领域数据库。
- 第一阶段不写 GitLab 领域事件；Task Center 事件仍由 Task Center 负责。

## 6. S1 追溯

主要规则：`BR-GITLAB-001..020`；用户故事：`US-GITLAB-001..003`；验收：`AC-GITLAB-001-*`、`AC-GITLAB-002-*`、`AC-GITLAB-003-*`。
