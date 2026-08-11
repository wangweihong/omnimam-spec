# GitLab Domain Module Contract

## 1. 模块边界

| 模块 | 拥有事实 | 提供能力 | 不负责 |
| --- | --- | --- | --- |
| `server` | GitLabServer、credential、连接状态 | Server CRUD、Test、Client Factory 输入 | GitLab 进程生命周期、Secret Provider |
| `project` | GitLabProject 本地投影 | 远端 Project 创建/读取/删除和投影维护 | AppStudio 源码、Webhook、文件推送 |
| `client` | GitLab HTTP 协议适配 | version/user/namespace/project/pipeline API | 业务权限、数据库事务、Task 状态 |
| `pipeline-worker` | 一次 GitLab Pipeline Attempt 的外部调用 | create/get/cancel、external_job_id 恢复和小型结果 | AtomicTask 状态机、业务数据库直写、Infra/Docker |

## 2. API Server 协作

- Controller 负责请求绑定、BasicQueryParam、管理员权限和统一响应。
- Service 负责 Server/Project 业务规则、数据库事务、远端补偿和错误映射。
- Store 接口由 GitLab Service 消费；PostgreSQL adapter 实现查询、乐观版本和关联删除保护。
- Credential 只在服务端内存和 HTTP header 中短暂出现，不进入 JSON、日志、Task 参数、Task 输出或事件。
- GitLab Client Factory 从 GitLabServer 构造带超时的 client；业务 service 不直接拼装 HTTP 请求。

## 3. GitLab Client 接口

客户端至少提供：

- `GetVersion`、`GetCurrentUser`、`ResolveNamespace`；
- `CreateProject`、`GetProject`、`DeleteProject`；
- `CreatePipeline`、`GetPipeline`、`RetryPipeline`、`CancelPipeline`、`ListPipelineJobs`。

所有请求必须使用 `PRIVATE-TOKEN`，限制响应体大小，解析 GitLab `{message}` 错误并保留上下文取消。连接 Test 的单次外部操作和整体检测必须有明确 deadline。

## 4. Task Center 协作

`gitlab.pipeline.run` 是非 Infra-backed 外部 AtomicTask。Task Center 负责创建 AtomicTask、TaskAttempt、重试、取消、超时、callback 调度和终态投影；GitLab Worker 只执行当前 Attempt。

输入：`gitlab_project_id`、`ref`、可选 `variables`。Worker 通过 GitLab Store 读取 Project/Server，再通过 Client Factory 调用 GitLab。输入不得携带 API URL、credential、远端 numeric project ID、任意 HTTP 地址或 Worker 配置。

首次 Attempt 创建远端 Pipeline 后保存 `external_job_id`；非终态返回 `IN_PROGRESS` 和 5 秒 callback。恢复和自动重试优先读取同一 external job。取消调用 `CancelPipeline`，失败/成功/取消只返回小型脱敏输出。

## 5. 跨域与安全

- AppStudio 第一阶段不依赖 GitLab domain，不共享表、不增加外键、不增加 API 字段。
- Identity 只提供 ADMIN/SUPER_ADMIN 权限校验；GitLab 不读取 Identity 私表。
- GitLab 不调用 Infrastructure，不操作 Docker Socket，不写其他领域数据库。
- 第一阶段不写 GitLab 领域事件；Task Center 事件仍由 Task Center 负责。

## 6. S1 追溯

主要规则：`BR-GITLAB-001..012`；用户故事：`US-GITLAB-001..002`；验收：`AC-GITLAB-001-*`、`AC-GITLAB-002-*`。
