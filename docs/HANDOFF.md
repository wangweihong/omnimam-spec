# OmniMAM Spec Handoff

## 当前项目目标

为公开资源响应建立统一的关联资源可读投影规则，并按领域逐步消除前端按 UUID 追加详情请求；Task Center 与 ApplicationRun 契约已发布。

## 本次完成

- `spec-v1.6.0` 已发布全局 `BR-GLOBAL-001..005`、S2 强制评审规则及 Task Center 一跳摘要契约。
- Application Platform 新增 `BR-AIAPP-185`，OpenAPI 升级到 1.2.0。
- ApplicationRun 创建与详情新增 Application、ApplicationVersion、ApplicationTemplateVersion、ProviderCapability、EngineInstance 和 AtomicTask 一跳摘要。
- 明确 ApplicationRun 的 Artifact 引用是可直接展示和导航的内嵌只读投影，客户端不得按 `artifact_id` 逐项补查。
- 同步 application-platform module contract、架构和 CHANGELOG。
- 内容提交 `47948e29dd208a6f4c73a22a15636114da5f15aa` 已登记为 `spec-v1.6.1` 正式实现依据。

## 文件变化

- `00_product/domains/application-platform/product-spec.md`
- `01_contracts/domains/application-platform/openapi.yaml`
- `01_contracts/domains/application-platform/module-contract.md`
- `02_architecture/domains/application-platform.md`
- `CHANGELOG.md`
- `docs/HANDOFF.md`

保留用户原有的 `AGENTS.md` 未提交修改，不纳入 release。

## 关键设计决策

- 原始 ID 仍是稳定引用；摘要最多一跳且不携带凭证、大型正文、任务参数、输出或 provider 原始配置。
- ApplicationRun 优先使用创建时保存的非敏感快照；旧数据缺少快照时才读取当前同域投影。
- AtomicTask 通过 Task Center 受控服务读取，禁止跨领域直接查询私有表。
- 关联缺失或不可见时父运行继续返回，相关摘要为空。
- Artifact 引用本身承担运行详情的输出展示，不再引入每行一个请求。

## API、Schema 与配置变化

- Application Platform OpenAPI 由 1.1.0 升级到 1.2.0，为向后兼容的只读响应字段扩展。
- 新增 `ApplicationTemplateVersionSummary`、`ProviderCapabilityRefSummary`，并复用现有 Application、ApplicationVersion、EngineInstance、AtomicTask 摘要。
- `RELEASE.md` 已登记 `spec-v1.6.1`；release tag 指向包含发布记录的最终提交。
- 未修改 SQL schema、错误码、权限码、事件或运行时配置。

## 验证结果

- Application Platform YAML 可解析，新增 schema 名称唯一。
- Redocly 校验 0 error；73 个告警均为既有 license、tag、4XX、oneOf 和未使用组件告警。
- `git diff --check` 通过。

## 待办与风险

- 发布 `spec-v1.6.1` 后，Server/Web 必须更新 submodule pin 和 `SSOT_VERSION` 才能正式实现。
- Server 需要补齐 ApplicationRun 公共响应 DTO；当前持久化 `ApplicationArtifact` 的 JSON 形状与 `ApplicationArtifactRef` 契约不一致。
- Web 需要移除 ApplicationRun 详情对 Artifact 的 `useQueries` 扇出，并用摘要展示/导航。
- workflow-canvas、ai-chatting、asset-library、model-management 仍需继续按全局规则审查裸资源 ID。

## 推荐下一任务

更新 Server/Web 到 `spec-v1.6.1`，实现 ApplicationRun 摘要、Artifact 引用投影与前端详情展示，然后继续 workflow-canvas 关联摘要切片。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
