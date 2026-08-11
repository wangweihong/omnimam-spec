# GitLab Context

## 1. 领域职责

`gitlab` 管理 GitLab API 连接、远端 Project 的本地投影、Repository HTTP 适配和通用 Pipeline 外部任务语义。它是独立领域，不属于 AppStudio，也不拥有 StudioApplication、源码 Revision、ChangeSet、Build 或 Release。

## 2. 核心对象

- `GitLabServer`：API URL、External URL、固定 Namespace、PAT 和最近连接状态。
- `GitLabProject`：GitLab 远端 Project 的本地稳定投影。
- Repository adapter：按 Project 调用 tree/file/commit/archive/branch 和 Project Access Token API；不拥有 AppStudio Revision。
- `gitlab.pipeline.run`：通过 Task Center/Task Worker 执行并用 external_job_id 恢复的外部 AtomicTask。

## 3. 核心规则

- credential 只写不读，不进入响应、日志、事件或任务输入输出。
- 只有 READY Server 可以创建 private Project；namespace 由 Server 固定。
- 有关联 Project 时禁止删除 Server；Project 远端 404 可清理本地投影。
- Pipeline 回调和自动重试查询同一 external_job_id，不重复提交。
- 管理 API 只授予 ADMIN 和 SUPER_ADMIN。

## 4. 领域边界

GitLab 拥有连接、远端 Project 映射、默认 AppStudio Server 选择和 GitLab HTTP Client 语义。Task Center 拥有 AtomicTask、TaskAttempt、重试、取消和终态。Identity 提供管理员权限。AppStudio 第二阶段只通过稳定 Project ID 和受控模块接口使用 Repository，不共享表或 PAT。

## 5. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/gitlab/product-spec.md` | S1 | GitLab Server、Project 和 Pipeline 产品语义 |
| `01_contracts/domains/gitlab/openapi.yaml` | S2 | 管理 API 与 DTO |
| `01_contracts/domains/gitlab/schema.sql` | S2 | 设计态 Server/Project Schema |
| `01_contracts/domains/gitlab/errors.yaml` | S2 | 业务错误 |
| `01_contracts/domains/gitlab/permissions.yaml` | S2 | 管理权限 |
| `01_contracts/domains/gitlab/events.yaml` | S2 | 第一阶段无领域事件 |
| `01_contracts/domains/gitlab/module-contract.md` | S2 | GitLab Client、Store 与 Task Worker 协作边界 |

涉及 AtomicTask、external_job_id、IN_PROGRESS、回调、重试和取消时继续读取 `domains/task-center/context.md` 及其直接相关正式片段。

## 6. 当前状态

本领域随 `spec-v1.22.0` 首次建立并发布；AppStudio Repository binding 和 Runtime access 由 `spec-v1.23.0` 发布。Webhook、自动构建、自动 Preview 和发布仍不在本阶段。
