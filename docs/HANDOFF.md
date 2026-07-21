# OmniMAM Spec Handoff

## 当前项目目标

为公开资源响应建立统一的关联资源可读投影规则，并按领域逐步消除前端按 UUID 追加详情请求；Task Center、ApplicationRun、Canvas、AI Chat 与 Asset Library 关系契约已发布。

## 本次完成

- `spec-v1.6.0` 已发布全局 `BR-GLOBAL-001..005`、S2 强制评审规则及 Task Center 一跳摘要契约。
- Application Platform 新增 `BR-AIAPP-185`，OpenAPI 升级到 1.2.0。
- ApplicationRun 创建与详情新增 Application、ApplicationVersion、ApplicationTemplateVersion、ProviderCapability、EngineInstance 和 AtomicTask 一跳摘要。
- 明确 ApplicationRun 的 Artifact 引用是可直接展示和导航的内嵌只读投影，客户端不得按 `artifact_id` 逐项补查。
- 同步 application-platform module contract、架构和 CHANGELOG。
- 内容提交 `47948e29dd208a6f4c73a22a15636114da5f15aa` 已登记为 `spec-v1.6.1` 正式实现依据。
- Workflow Canvas 新增 `BR-WORKFLOW-016`，CanvasVersion、CanvasRun、重跑来源、DAGTaskGroup 与 CanvasNodeRun AtomicTask 增加一跳摘要。
- 明确 Canvas/版本/重跑来源使用快照或同域批量读取，Task Center 关系使用受控批量投影。
- Canvas 内容提交 `73f37510a92d6b697773188a85a449a2cb06183e` 已登记为 `spec-v1.6.2` 正式实现依据。
- AI Chat 新增 `BR-AICHAT-25`，Topic、Assistant 与助手级 QuickPhrase 增加 Assistant/ProviderModel 一跳摘要。
- Message 历史快照、同 Topic 父消息、Generation 对应消息和翻译来源均明确为当前响应上下文可解析，不递归展开。
- 修复 AI Chat OpenAPI 原有的根级 bearer 安全声明和 18 个 operation summary 缺失，使 Redocly 从 36 error 降为 0 error。
- AI Chat 内容提交 `5fb52fbc91c4d8611d99e48894617a24a8450972` 已登记为 `spec-v1.6.3` 正式实现依据。
- Asset Library 新增 `BR-USER-ASSET-80`，覆盖 UserAsset 当前版本、Artifact 来源/任务/运行/登记结果、Collection 父级/固定版本和 AssetRelation 两端素材摘要。
- 明确 Artifact 尝试、节点运行和节点定义 ID 在已返回的父任务/运行上下文解析，不递归展开；同域关系按 owner 批量读取，跨域关系使用事实源受控批量投影。
- Asset Library 内容提交 `6b4a112` 已登记为 `spec-v1.6.4` 正式实现依据。

## 文件变化

- `00_product/domains/application-platform/product-spec.md`
- `01_contracts/domains/application-platform/openapi.yaml`
- `01_contracts/domains/application-platform/module-contract.md`
- `02_architecture/domains/application-platform.md`
- `00_product/domains/workflow-canvas/product-spec.md`
- `01_contracts/domains/workflow-canvas/openapi.yaml`
- `01_contracts/domains/workflow-canvas/module-contract.md`
- `02_architecture/domains/workflow-canvas.md`
- `00_product/domains/ai-chatting/product-spec.md`
- `01_contracts/domains/ai-chatting/openapi.yaml`
- `01_contracts/domains/ai-chatting/module-contract.md`
- `02_architecture/domains/ai-chatting.md`
- `00_product/domains/asset-library/product-spec.md`
- `01_contracts/domains/asset-library/openapi.yaml`
- `01_contracts/domains/asset-library/module-contract.md`
- `02_architecture/domains/asset-library.md`
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
- Workflow Canvas OpenAPI 由 `spec-v1.0.0` 升级到 `spec-v1.1.0`，同样只增加向后兼容的只读响应字段。
- AI Chat OpenAPI 由 0.1.0 升级到 0.2.0；新增摘要字段并补齐已有鉴权/operation 元数据。
- Asset Library OpenAPI 由 `0.3.0-draft` 升级到 `0.4.0`，只增加向后兼容的只读响应投影和审计 ID 描述。
- `RELEASE.md` 已登记 `spec-v1.6.3`；release tag 指向包含发布记录的最终提交。
- `RELEASE.md` 已登记 `spec-v1.6.2`；release tag 指向包含发布记录的最终提交。

## 验证结果

- Application Platform YAML 可解析，新增 schema 名称唯一。
- Redocly 校验 0 error；73 个告警均为既有 license、tag、4XX、oneOf 和未使用组件告警。
- `git diff --check` 通过。
- Workflow Canvas Redocly 校验 0 error；15 个告警均为既有 license 与 4XX 告警。
- AI Chat Redocly 校验 0 error；25 个告警均为既有 license、tag 与 4XX 告警。
- Asset Library Redocly 校验 0 error；46 个告警均为既有 license 与 4XX 告警。

## 待办与风险

- 发布 `spec-v1.6.1` 后，Server/Web 必须更新 submodule pin 和 `SSOT_VERSION` 才能正式实现。
- Server 需要补齐 ApplicationRun 公共响应 DTO；当前持久化 `ApplicationArtifact` 的 JSON 形状与 `ApplicationArtifactRef` 契约不一致。
- Web 需要移除 ApplicationRun 详情对 Artifact 的 `useQueries` 扇出，并用摘要展示/导航。
- Canvas Server 需要新增同域批量查询和 Task Center 批量摘要能力；Web 当前没有已发布 CanvasRun 详情视图，只需保持客户端契约可生成。
- AI Chat Server 需要增加 model-management 受控批量摘要和同域 Assistant 批量查询；Web 可直接消费 Topic/Assistant/QuickPhrase 摘要并保留现有选择器数据流。
- Server/Web 需要更新到 `spec-v1.6.4`，实现 Asset Library 同域批量摘要、跨域受控 Artifact producer 投影并更新生成客户端。
- model-management 仍需继续按全局规则审查裸资源 ID；ProviderModel 已返回 `provider_name`，SystemLLMConfig 已内嵌 `model`，应优先补明确豁免说明而非重复展开。

## 推荐下一任务

更新 Server/Web pin，实现 `spec-v1.6.4` Asset Library 摘要，完成全量测试后再收敛 model-management 的豁免说明。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
