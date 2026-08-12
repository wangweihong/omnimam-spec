# OmniMAM Spec Handoff

## 当前目标与状态

- 目标：定义并发布 AppStudio 初始化诊断与显式恢复契约 `spec-v1.23.3`。
- 状态：进行中；AppStudio/GitLab/Task Center 最小范围 S1/S2 已修订，正在执行定向一致性校验并准备 release commit/tag。

## 本次已完成

- 已确认远端尚无 `spec-v1.23.3` tag，当前正式基线为 `spec-v1.23.2` commit `9e1bf2291dd1925e982a5dd728e05a27c334f8d9`。
- 已加载 Spec S1/S2 工作流及 AppStudio、GitLab、Task Center 直接相关 Context。
- 已锁定四阶段初始化、安全诊断、原 reservation 幂等重试、新旧 DAG fence 和无 schema 变更边界。
- 已新增初始化 GET/retry OpenAPI、四阶段安全 DTO、GitLab 默认 Server 专用错误、结构化错误保留、条件回滚与 owner fence 契约。
- 已同步 AppStudio/GitLab S1 验收、三个 module contract、三个 Domain Context、Global Context 与 Changelog；未修改 schema、权限或事件。

## 当前进行中

- 执行定向 YAML/OpenAPI/引用/错误码校验；随后提交内容并写入 `RELEASE.md`。

## 文件变化

- Modified: AppStudio/GitLab product spec，AppStudio OpenAPI，GitLab errors，AppStudio/GitLab/Task Center module contract，三个 Domain Context，`GLOBAL_CONTEXT.md`、`CHANGELOG.md`、`docs/HANDOFF.md`。
- Planned: `RELEASE.md`。

## 关键决定

- 显式重试，不增加后台扫描器；重试复用原 reservation。
- 初始化查询只公开四阶段安全投影，不暴露 Workspace、凭据、内部参数或原始 runtime payload。
- 新 DAG ID 由 Application ID 与 retry `idempotency_key` 稳定派生；旧 DAG 终态通过 owner fence 禁止覆盖当前轮次。
- 不新增数据库表或字段。

## API、Schema、依赖或配置变化

- Added: initialization GET/retry API 与 `ERR_GITLAB_APPSTUDIO_DEFAULT_SERVER_UNAVAILABLE`；无 Schema、权限码或事件变化。

## 验证与风险

- Remaining: 定向 YAML/OpenAPI/引用/错误码/release/tag 校验。
- 风险：错误诊断必须严格脱敏；重试状态冲突与旧 DAG fence 必须在 S1/S2 一致定义。

## 未完成事项

- 完成目标 S1/S2 修订与定向验证，提交、记录 release、创建并推送 `spec-v1.23.3` tag；随后更新 Server gitlink。

## 推荐下一步

运行 AppStudio OpenAPI YAML/Redocly、GitLab errors YAML、追溯引用和 `git diff --check` 定向校验；通过后创建内容 commit。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
