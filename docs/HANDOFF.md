# OmniMAM Spec Handoff

## 当前项目目标

为公开资源响应建立统一的一跳关联资源可读投影规则，并在 Task Center、Application Platform、Workflow Canvas、AI Chat、Asset Library 和 Model Management 中消除无说明的裸资源 ID 与客户端逐 ID 补查。

## 本次完成

- `spec-v1.6.0` 发布 `BR-GLOBAL-001..005`、S2 强制“摘要或明确豁免”评审规则和 Task Center 摘要契约。
- `spec-v1.6.1` 发布 ApplicationRun Application/Version/TemplateVersion/ProviderCapability/EngineInstance/AtomicTask 摘要，并禁止 Artifact 每行补查。
- `spec-v1.6.2` 发布 Workflow Canvas Canvas/Version/Run/retry/DAGTaskGroup/AtomicTask 摘要。
- `spec-v1.6.3` 发布 AI Chat Topic/Assistant/QuickPhrase 的 Assistant/ProviderModel 摘要，并明确消息快照和当前 Topic 上下文豁免。
- `spec-v1.6.4` 发布 `BR-USER-ASSET-80`：UserAsset 当前版本、Artifact 来源/任务/运行/登记结果、Collection 父级/固定版本和 AssetRelation 两端素材摘要。
- `spec-v1.6.5` 发布 `BR-USER-MODEL-32`：ProviderModel `provider_name` 必返，DefaultModelConfig 和 HealthCheckResult 关联 ID 使用内嵌模型或当前动作上下文解释。
- AI Chat 与 Model Management 补齐根级 bearer security 和 operation summary；所有本轮相关 OpenAPI 均通过 Redocly 结构校验。
- Server/Web 已更新到 `spec-v1.6.5` 并完成对应实现与生成客户端适配。

## 文件变化

- 全局规则与工作流：`00_product/global-business-rules.md`, `skills/spec-workflow/S2.md`。
- 六个领域的 S1 product spec、S2 OpenAPI/module contract 和架构文档。
- `CHANGELOG.md`, `RELEASE.md`, `docs/HANDOFF.md`。

保留用户原有的 `AGENTS.md` 未提交修改，不纳入任何 release。

## 关键设计决策

- 原始 ID 始终保留为稳定引用；摘要最多一跳，不递归展开。
- 摘要只包含页面识别、状态展示和导航所需字段，不包含凭证、大型正文、任务输入输出、Provider 原始响应或内部运行时配置。
- 关联缺失、删除或不可见时父资源继续返回，摘要为空，不泄露目标存在性。
- 历史运行和不可变版本优先使用创建时保存的非敏感快照。
- 同域列表使用 JOIN 或固定批次；跨领域只允许事实源受控投影、快照或模块协作接口，禁止穿透私有表。
- 仅在当前响应/endpoint 上下文已经能解释引用时允许只返回 ID，且必须在 schema 或 module contract 中写明原因。

## API、Schema 与配置变化

- 只增加向后兼容的只读响应字段和字段说明；未修改 SQL schema、错误码、权限码、事件或运行时配置。
- Application Platform OpenAPI 升级到 `1.2.0`，Workflow Canvas 升级到 `1.1.0`，AI Chat 升级到 `0.2.0`，Asset Library 升级到 `0.4.0`，Model Management 升级到 `0.2.0`。
- 正式实现基线为 release tag `spec-v1.6.5`；`RELEASE.md` 记录对应内容提交。

## 验证结果

- Application Platform、Workflow Canvas、AI Chat、Asset Library 和 Model Management OpenAPI YAML 均可解析，本轮新增 `$ref` 可解析。
- Redocly 结果：相关 OpenAPI 均为 0 error；剩余告警为既有 license、4XX、tag、oneOf 或未使用组件告警。
- `git diff --check` 通过。

## 待办与风险

- 后续新增任何 `*_id`、`source_id`、`target_id`、`owner_id` 或多态引用时，release review 必须继续执行“摘要或明确豁免”检查。
- 新领域应复用已有 summary schema 语义，避免同一资源出现字段含义冲突的多个摘要。
- 实现侧仍需在真实 PostgreSQL 和部署环境验证查询预算；这不改变已发布契约。

## 推荐下一任务

在下一次新增或修改资源响应时，把 `skills/spec-workflow/S2.md` 的关联资源检查作为 release gate，并优先补充查询预算与越权回归测试。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
