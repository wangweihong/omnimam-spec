# OmniMAM Spec Handoff

## 当前项目目标

发布 `spec-v1.7.2`，补齐任务中心 DAG 运行工作台依赖的 S1/S2，并提供 Asset Library Artifact 有界批量摘要协作。

## 本次完成

1. 新增 `US-TASK-023`、`BR-TASK-133..141`，定义 DAG 可观测详情、动态节点聚合、事件、时间线、executor 裁剪、Artifact 摘要和日志筛选/下载。
2. Task Center OpenAPI 升级到 1.3.0；DAG operation 从不存在的 `task.dag.operate` 统一为 `task.group.operate`。
3. 新增 `DAGTaskGroupDetail`、`DAGNodeExecutionSummary`、触发摘要、事件/时间线 DTO、`node_key` 子任务过滤，以及 Attempt 日志 cursor、方向、筛选和下载接口。
4. Task Center schema 增加 DAG 时间/触发快照、`dag_node_key`、executor 快照和运行时投影查询索引；未新增执行历史表。
5. 新增 `US-USER-ASSET-47`、`BR-USER-ASSET-81`；Asset Library OpenAPI 升级到 0.5.0，并增加最多 200 项的 Artifact 批量摘要接口。
6. 更新两个领域的权限、事件追溯、模块契约、架构参考和 CHANGELOG。

## 文件变化

- 修改 Task Center S1、OpenAPI、schema、permissions、events、module contract 和领域架构。
- 修改 Asset Library S1、OpenAPI、permissions、module contract 和领域架构。
- 修改 `CHANGELOG.md`、`RELEASE.md` 和本文件。
- 用户原有 `AGENTS.md` 修改保持不变，不纳入本次提交或 release。

## 关键设计决策

- DAG 用户事件和时间线从既有 `runtime_projection_events`、AtomicTask 和 TaskAttempt 投影规范化生成，不建立第二套事件事实表，也不透传运行时 payload。
- 动态节点按 `dag_node_key` 聚合，实际 fan-out AtomicTask 仍可独立分页定位。
- executor 只保存稳定类型与显示名，且仅 `task.operation.admin` 可见。
- Artifact 摘要由 Asset Library 事实源按 owner 批量裁剪；不可见、已删除或不存在统一返回空摘要，Task Center 保留原 ID。
- Attempt 日志在线查询和下载共用授权、过滤、脱敏、排序与 retention 语义。

## API、Schema 与配置变化

- 新增 `GET /api/v1/dag-task-groups/{dag_task_group_id}/events`。
- 新增 `GET /api/v1/dag-task-groups/{dag_task_group_id}/timeline`。
- 新增 `GET /api/v1/atomic-tasks/{atomic_task_id}/attempts/{task_attempt_id}/logs/download`。
- 新增 `POST /api/v1/artifacts/batch-summaries`。
- DAG 详情响应改为 `DAGTaskGroupDetail`，子任务查询增加 `node_key`。
- `dag_task_groups` 增加执行时间与触发快照；`atomic_tasks` 增加 `dag_node_key`；`task_attempts` 增加 executor 快照。
- 无新错误码、无新领域源事件、无运行时配置。

## 验证结果

- 5 个相关 YAML 文件解析通过。
- Task Center 与 Asset Library OpenAPI 本地 `$ref`、operationId、权限引用和 S1 引用检查通过。
- 全仓 196 个错误码 code/value 唯一性检查通过。
- `task.dag.operate` 已从 S2 清除，`git diff --check` 通过。

## 待办与风险

- Server/Web 尚未 pin `spec-v1.7.2` 或实现本次契约。
- 实现迁移需为已有 DAG 回填 trigger 信息，并新增 schema migration；本仓库只维护设计态 schema。
- 事件/时间线完整性取决于运行时历史和投影保留，缺失必须返回 `complete=false`。
- OpenAPI 未运行专用外部 validator；已完成 YAML、引用、权限、operationId 和追溯自检。

## 推荐下一任务

在 `omnimam-server` 更新 spec submodule 与 `SSOT_VERSION` 到 `spec-v1.7.2`，实现 Task Center/Asset Library 契约和 migration，再由 Web 接入 DAG 运行工作台。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
