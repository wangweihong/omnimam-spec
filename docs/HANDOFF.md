# OmniMAM Spec Handoff

## 当前目标与状态

- 目标：发布 `spec-v1.23.0`，正式定义 AppStudio GitLab 第二阶段跨域契约。
- 状态：内容 commit `7010953df6130caa1f59c8b19dd9feaa5e06d467` 已完成，`spec-v1.23.0` release record 已写入；正在创建 release commit/tag 并推送。
- 基线：`spec-v1.22.0` release commit `edcdbcebf8daecec8eaefd129338e829512b00fe`。

## 本次已完成

- GitLab 已定义为 AppStudio 唯一源码正文 Provider；AppStudio Revision/ChangeSet 保持 canonical，并由 `commit_sha` 关联 Git commit。
- 新增内置 `web-react@v1` Blueprint、固定 prompt 路由和 CI include 约束，不新增 Blueprint Service/API/表。
- GitLabServer 增加唯一 READY AppStudio 默认标记；GitLab repository/token client 能力扩展为内部模块契约。
- Agent Invocation claims 固定 base Revision/CommitSHA、Blueprint 和 prompt kind；删除旧正文工具授权语义。
- Coding Runtime 使用 Runtime-scoped Project Access Token、tmpfs credential helper 和可丢弃 `/workspace` clone；Preview/Build 按固定 commit archive 流式注入。
- Task Worker 在 CODING Invocation 终态前校验恰好一个普通 fast-forward commit，并幂等投影一个 ChangeSet/Revision。
- 已创建内容 commit `7010953df6130caa1f59c8b19dd9feaa5e06d467`，并以用户本次明确实施请求作为 release 确认写入 `RELEASE.md`。

## 当前进行中

- 创建 `spec-v1.23.0` release commit、annotated tag 和 push，并校验远端引用。

## 文件变化

- Modified: `GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、`CHANGELOG.md`。
- Modified: `domains/{appstudio,agent,gitlab,infrastructure,task-center}/context.md`。
- Modified: `00_product/domains/{appstudio,agent,gitlab,infrastructure,task-center}/product-spec.md`。
- Modified: AppStudio schema/module contract、GitLab schema/OpenAPI/module contract、Agent/Infrastructure/Task Center module contracts。

## 关键决定

- AppStudio 只保存 GitLabProject 本地 ID，不保存远端 numeric ID、PAT 或 credential URL，也不建立跨 Domain 外键。
- 公共 AppStudio 创建 API 不增加 Blueprint/GitLab 参数；`STATIC_WEB` 固定 `web-react@v1`。
- Runtime token 明文不得进入环境变量、Task、数据库、日志、错误或 Docker inspect；停止、替换、到期时撤销，失败由到期兜底。
- 同一 Workspace 同时只允许一个源码写事务；无 commit、多 commit、分叉、force 语义或 base 漂移均不推进 Revision。
- 不迁移 `BUILT_IN` 旧数据；部署切换时清理 PostgreSQL 和旧 AppStudio source volume。

## API、Schema、依赖或配置变化

- GitLab 管理 API create/update/response 增加 `is_appstudio_default`。
- `studio_applications` 增加 `blueprint_id/blueprint_version`；`studio_source_repositories` 增加 `gitlab_project_id` 且 provider 固定 `GITLAB`；`studio_workspace_revisions` 增加唯一 `commit_sha`。
- `gitlab_servers` 增加 READY 状态约束的 `is_appstudio_default` 和 partial unique index。
- 不新增错误码、权限码、事件、公开 AppStudio API、数据库表或运行依赖。

## 验证与风险

- `yq` 已成功解析 GitLab OpenAPI；Redocly 验证有效，仅报告仓库 HTTP 200 业务错误策略及 license/tag 描述的 13 个非阻断 warning。
- scoped `git diff --check` 通过；限定正式文件中的 Workspace Tool/`BUILT_IN` 旧术语为零匹配，新增 schema/API/模块契约关键字段定向检查通过。
- 尚需 release commit、tag/push 和远端校验。
- 规范发布后 server 必须先更新 submodule pin 与 `SSOT_VERSION`，再实施行为变更。

## 未完成事项

- 创建 `spec-v1.23.0` release commit/tag 并推送。
- 下游 server 更新 pin 后实施并验证。

## 推荐下一步

提交 `RELEASE.md` 和 handoff，创建 annotated `spec-v1.23.0` tag，并推送当前分支与 tag。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
