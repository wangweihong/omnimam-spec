# OmniMAM Spec Handoff

## 当前项目目标

发布 ApplicationRun 持久化列表与 AtomicTask 终态投影契约，作为 Server/Web 修复应用运行数据不可见问题的正式依据。

## 本次完成

1. `BR-AIAPP-194` 与 `AC-AIAPP-043-06..07` 明确应用详情运行历史、权限、排序和终态投影语义。
2. 新增 `GET /api/v1/applications/{application_id}/runs`，分页返回包含 AtomicTask 摘要和 Artifact 引用的 ApplicationRun。
3. 明确终态必须在 AtomicTask 持久化后按递增 resource version 单调投影，重复或乱序通知不得回退或重复创建 Artifact 引用。
4. 同步模块契约、领域架构、Changelog 和 release 记录；Application Platform OpenAPI 升级为 1.7.0。

## 文件变化

- `00_product/domains/application-platform/product-spec.md`
- `01_contracts/domains/application-platform/openapi.yaml`
- `01_contracts/domains/application-platform/module-contract.md`
- `02_architecture/domains/application-platform.md`
- `CHANGELOG.md`
- `RELEASE.md`
- `docs/HANDOFF.md`

## 关键设计决策

- 运行历史属于 Application Platform，不允许 Web 从 Task Center 扇出或拼装。
- 列表复用完整 ApplicationRun 投影，任务摘要和 Artifact 引用由服务端批量组合。
- AtomicTask 是执行状态事实源；ApplicationRun 只接受更高 task resource version 的投影。
- Artifact 引用使用稳定输出身份幂等创建，投影重试不能改变 AtomicTask 终态。

## API、Schema 与配置变化

- Application Platform OpenAPI 1.7.0。
- 新增 `GET /api/v1/applications/{application_id}/runs`，支持分页以及 `created_at|updated_at` 排序。
- 数据库 schema、权限码、错误码和配置不变。

## 待办与风险

- omnimam-server 更新 SSOT pin，实现列表 API 与终态完成通知/回调，并覆盖乱序、重放、权限和分页测试。
- omnimam-web 更新 SSOT pin，应用详情加载并分页展示运行历史。
- 对真实 ComfyUI 运行验证 SUCCESS、输出和图片 Artifact 在刷新后仍可见。

## 推荐下一任务

在 omnimam-server pin `spec-v1.7.13`，先补失败测试，再实现 ApplicationRun 列表和 AtomicTask 持久化后的终态投影。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
