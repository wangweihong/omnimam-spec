# OmniMAM Spec Handoff

## 当前目标和状态

- 目标：补齐 Model Deployment 创建 Spec Revision 的幂等契约并发布 `spec-v1.25.5`。状态：规格 commit `9ef27f528f37fae02bec998c1375e5cdae61cdcd` 与本地 annotated tag 已创建并核对；`RELEASE.md` 记录已写入但尚未提交，远端推送尚待完成。
- 当前分支 `codex/spec-v1.25.5` 从干净的 `4e338cc28398b3fccc08e2fb7f364b278db5fbf3` 建立。已有正式 tag `spec-v1.25.4` 指向 `7ae868e68080254422749527085ee93c0a2c2b72`；server 仍固定 v1.25.4，本任务不修改 server。

## 本次已完成

- `00_product/domains/model-deployment/product-spec.md`：明确创建 Revision 的键只在该操作内有效，可与 Apply/Start 的键复用；同键同请求返回首次 Revision，同键异请求冲突，不同键可共享最终配置相同的 Revision。新增 `BR-MODELDEP-021` 和 `AC-MODELDEP-002-05/06`，旧键无法追溯、向前生效；保留已发布 `BR-MODELDEP-004` 原义。
- `01_contracts/domains/model-deployment/schema.sql`：新增不可变非资源关联表 `model_deployment_revision_requests`，组合主键 `(model_deployment_id,idempotency_key)`，保存 `request_digest`、目标 `spec_digest` 和 `created_at`；用复合外键指向同部署 Revision 的现有唯一 `(model_deployment_id,spec_digest)`，并建立关联索引。用户已确认非资源表免通用资源元数据。
- `01_contracts/domains/model-deployment/{module-contract.md,openapi.yaml,errors.yaml}`：将请求摘要固定为提交的 `{spec,resource_version}` 经 RFC 8785 规范化并计算 SHA-256，排除键且先于 Profile 解析；明确同键重放在当前资源版本检查前返回，复用现有 `ERR_MODELDEP_IDEMPOTENCY_CONFLICT`，更新 S1 追溯。新键相同最终配置继续先去重并写键映射；新配置仍须资源版本匹配。无新增公开 API、响应字段或错误码。
- 同步 `domains/model-deployment/context.md`、`CHANGELOG.md` 和本文件。未改实际 migration、后端代码、依赖、其他领域或 `RELEASE.md`。
- 用户已确认按该草稿发布 `spec-v1.25.5`，CHANGELOG 条目已从 Unreleased 提升为正式版本标题；提交前仍须做最终 diff 检查。
- 目标 S1/S2、Context 与 CHANGELOG 已独立提交为 `9ef27f528f37fae02bec998c1375e5cdae61cdcd`；本地 `spec-v1.25.5^{}` 指向该 commit，tag 类型为 annotated。交接与 RELEASE 记录将在后续提交，不写入 tag commit。
- 已在 `RELEASE.md` 草拟正式版本记录：用户确认、目标 S1/S2 文件、tag commit、空表向前生效与 server pin 门禁。下一步先校验并提交该记录与本文件，再推送 tag 和分支。

## 关键决定与兼容性

- 请求键在同一 Deployment 的“创建 Revision”操作内唯一；不同动作可以复用同一字符串。多个键可映射同一 Revision，因此关联表以目标 `spec_digest` 引用 Revision，而不向不可变 Revision 行加入单一键列。
- 关联表升级时为空，不推断或清理旧 Revision。精确冲突保证从升级后首次记录该键起生效；旧请求的原键无法从现有数据还原。
- Revision 与新键映射应在同一业务事务提交；同键同摘要先读取映射，不重解析可漂移 Profile 或检查当前资源版本。此次仅定义 SSOT，server pin 与实现待后续任务。

## 验证与剩余检查

- 目标 OpenAPI YAML 解析通过，135 个本地 `$ref` 均可解析；新增规则、验收项、错误码和 operation 追溯检查通过；`git diff --check` 通过。
- 隔离 PostgreSQL 16 验证了同部署不同键共享 Revision、跨部署同键、同键唯一约束、错误目标 Revision 的复合外键、非法请求摘要 CHECK、Deployment 删除级联；新增索引创建检查通过。测试容器已自动移除。
- `spec-v1.25.5` tag 在提交前再次核对为 origin 尚不存在；用户最终确认已收到。下一步在 `RELEASE.md` 记录 tag commit、用户确认、涉及文件和正式实现门禁，再推送记录提交及 tag。

## 待办与已知风险

- 发布完成前不得把草稿当作 server 正式实现依据；发布后 server 仍需独立更新 submodule pin、migration 与实现。
- 旧请求键不可恢复的限制必须保留在 release 门禁。server 的新关系表 migration、CreateRevision 实现和 submodule pin 均不在本次范围。

## 精确下一步

校验 `RELEASE.md` 与 tag/规格文件一致，提交该记录及本文件；先推送 tag、后推送分支。核对远端 tag 解引用和记录 commit 后刷新交接、提交并再次推送分支。不要改 server。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
