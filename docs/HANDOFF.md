# OmniMAM Spec Handoff

## 当前目标与状态

- 目标：发布 `spec-v1.23.1`，修正 AppStudio 初始化必须先持久化 `CREATING` Project reservation 与 GitLabProject schema 不能表达该状态的冲突。
- 状态：进行中。基线是已发布 `spec-v1.23.0` tag `ee0cf7f7732a74d1ca36cc1e73a5541a333ed025`。

## 本次已完成

- GitLab 已定义为 AppStudio 唯一源码正文 Provider；AppStudio Revision/ChangeSet 保持 canonical，并由 `commit_sha` 关联 Git commit。
- 新增内置 `web-react@v1` Blueprint、固定 prompt 路由和 CI include 约束，不新增 Blueprint Service/API/表。
- GitLabServer 增加唯一 READY AppStudio 默认标记；GitLab repository/token client 能力扩展为内部模块契约。
- Agent Invocation claims 固定 base Revision/CommitSHA、Blueprint 和 prompt kind；删除旧正文工具授权语义。
- Coding Runtime 使用 Runtime-scoped Project Access Token、tmpfs credential helper 和可丢弃 `/workspace` clone；Preview/Build 按固定 commit archive 流式注入。
- Task Worker 在 CODING Invocation 终态前校验恰好一个普通 fast-forward commit，并幂等投影一个 ChangeSet/Revision。
- 已创建内容 commit `7010953df6130caa1f59c8b19dd9feaa5e06d467`，并以用户本次明确实施请求作为 release 确认写入 `RELEASE.md`。

## 当前进行中

- 内容 commit `613399f` 已完成并通过定向一致性检查；正在提交 `spec-v1.23.1` release record、创建 annotated tag 并推送。

## 文件变化

- Modified: `GLOBAL_CONTEXT.md`、`CHANGELOG.md`、`docs/HANDOFF.md`。
- Modified: `domains/{appstudio,gitlab}/context.md`。
- Modified: `00_product/domains/{appstudio,gitlab}/product-spec.md`。
- Modified: `01_contracts/domains/gitlab/{schema.sql,module-contract.md}`。

## 关键决定

- AppStudio 只保存 GitLabProject 本地 ID，不保存远端 numeric ID、PAT 或 credential URL，也不建立跨 Domain 外键。
- 公共 AppStudio 创建 API 不增加 Blueprint/GitLab 参数；`STATIC_WEB` 固定 `web-react@v1`。
- Runtime token 明文不得进入环境变量、Task、数据库、日志、错误或 Docker inspect；停止、替换、到期时撤销，失败由到期兜底。
- 同一 Workspace 同时只允许一个源码写事务；无 commit、多 commit、分叉、force 语义或 base 漂移均不推进 Revision。
- 不迁移 `BUILT_IN` 旧数据；部署切换时清理 PostgreSQL 和旧 AppStudio source volume。
- GitLabProject 是唯一允许跨域引用的稳定 Project identity；其 `CREATING` reservation 可在远端创建前没有 numeric ID/URL，只有补全投影后的 `READY` Project 可被 Repository adapter 消费。

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

- 完成 `spec-v1.23.1` release commit、annotated tag 与远端校验。
- 下游 server 更新 pin、实现 reservation-to-READY 状态机并验证。

## 推荐下一步

提交 `RELEASE.md` 和 handoff，创建 annotated `spec-v1.23.1` tag 并推送分支与 tag。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
