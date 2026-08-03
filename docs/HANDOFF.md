# OmniMAM Spec Handoff

## 当前目标与状态

目标：分析 `platform-management` 领域，补充缺失的 S1/S2 规格并修复内部及跨层不一致。

状态：完成并已发布。Platform Management/Identity 协同规格已登记为 `spec-v1.13.0`，允许作为正式实现依据。

## 本次完成

- Platform S1 升级为 v1.1.0：补齐结构化 PasswordPolicy/LoginFailurePolicy、生命周期范围、SystemAuthConfig 单例与 `resource_version` 乐观并发、配置/AuditLog/Outbox 原子提交和页面冲突恢复。
- 补齐 AuditLog：覆盖 Identity 登录、Token、密码、授权、服务账号和跨 owner 敏感操作；新增 `occurred_at`、来源服务主体校验、来源域复合幂等、内容冲突、detail 大小/嵌套限制和完整查询语义。
- 修正 S1 路由数量、分页示例、最近审计摘要范围和缺失的认证配置页面；移除 Go 结构体与后端目录等过度实现化内容。
- Platform OpenAPI 升级为 `0.2.0-draft`；修正业务错误 `value` 类型和 500 响应，结构化认证配置 DTO，补齐审计过滤、服务主体鉴权、版本冲突和幂等冲突声明。
- 同步 Schema、错误码、权限、事件和模块合同；新增 `ERR_PLATFORM_AUDIT_IDEMPOTENCY_CONFLICT`，overview 区间扩展为 `230600-230799`。
- Identity 可靠事件移除 `platform-audit` 消费者；Identity S1/模块合同明确敏感审计通过受控同步接口确认，失败时回滚、撤销或补偿。
- 新增 `02_architecture/domains/platform-management.md`，同步 Platform Domain Context、Identity 架构参考和 CHANGELOG。
- 用户已于 2026-08-03 明确要求“发布”；`RELEASE.md` 已登记 `spec-v1.13.0`，正式规格基线为 `b942bb8cc405314ec1f87170a3f63d8ed4bc5dad`。
- 已创建发布提交 `56907857c38992c16ae272b20aff957aae366490` 和 annotated tag `spec-v1.13.0`。

## 当前进行中

无。

## 文件变化

- Platform S1/S2：`00_product/domains/platform-management/product-spec.md`、`01_contracts/domains/platform-management/` 全部 6 个文件。
- 跨域同步：`00_product/domains/identity/product-spec.md`、`01_contracts/domains/identity/events.yaml`、`01_contracts/domains/identity/module-contract.md`、`02_architecture/domains/identity.md`。
- 架构与 Context：新增 `02_architecture/domains/platform-management.md`，修改 `domains/platform-management/context.md`。
- 全局维护：`01_contracts/error-code-index.md`、`CHANGELOG.md`、`RELEASE.md`、`docs/HANDOFF.md`。
- 未新增正式 migration、实现代码、运行时配置、依赖或 CI/CD 文件。

## 关键设计决定

- SystemAuthConfig 仅有 `id=default` 单例，使用完整替换和 `resource_version` 防止并发覆盖。
- 配置新版本、`platform.auth_config.update` AuditLog 和配置变更 Outbox 在 Platform 边界内原子提交。
- 配置变更事件只提示版本失效；Identity 必须重新读取完整配置，不能从事件拼装策略。
- 敏感跨域操作必须同步确认 AuditLog；Identity 领域事件不再承担平台审计写入。
- AuditLog 同时保存来源 `occurred_at` 和平台 `created_at`；允许最多 5 分钟未来时钟偏差。
- 审计幂等作用域为 `source_domain + source_module + idempotency_key`，使用规范化内容 SHA-256 区分相同重试和内容冲突。
- PlatformOverview 只展示最近 10 条 `platform.auth_config.update` 摘要，不混入 Identity 高频认证审计或跨 domain 统计。

## API、Schema、依赖与配置变化

- Platform OpenAPI 当前有 7 个 operation，全部使用 `/api/v1`、唯一 operationId、授权声明和 S1 追溯。
- Platform 当前有 10 个错误码、6 个权限码、2 个事件和 3 张设计态表。
- Schema 新增生命周期范围、JSON object、16 KiB detail、审计不可变元数据、来源域复合幂等、内容指纹和查询索引约束。
- `platform.audit.recorded` 第一阶段没有强制消费者；后续消费者必须先在对应 S1/S2 登记。
- 未新增依赖或运行时配置。

## 验证结果

- Platform OpenAPI、errors、permissions、events 和 Identity events 均通过 `yq` 解析。
- 7 个 OpenAPI operationId 唯一；所有本地 `$ref`、S1 引用和 `x-error-codes` 可解析；审计列表通用及业务参数完整。
- 全仓识别 355 个错误码，code/value 无重复；Platform 10 个错误均落在已登记区间并可追溯。
- 72 个错误码区间无重叠；Platform overview 区间已预留 200 个值。
- 6 个 Platform 权限、2 个 Platform 事件和 8 个 Identity 事件的 S1 引用有效。
- 3 张 Platform 设计态表均包含通用资源字段，关键单例、JSON、时间、幂等和指纹约束存在。
- Markdown/Mermaid 围栏平衡，`git diff --check` 通过。
- `RELEASE.md` 中 `spec-v1.13.0` 引用的 14 个 S1/S2、架构和 Context 文件均存在；annotated tag 已校验指向发布提交 `56907857c38992c16ae272b20aff957aae366490`。

## 待办事项

- 正式实现前验证服务主体到 `source_domain/source_module` 的登记、Token 撤销、委托链校验，以及每类敏感操作审计失败后的回滚/撤销/补偿测试。

## 已知问题与风险

- 当前环境没有 `mmdc`，Mermaid 已做围栏和人工语法复核，但未执行渲染器校验。
- 本任务只修改规格，没有运行后端构建、数据库执行或实现测试。
- 工作区仍有用户自己的 `skills/archive/s1-origin-2.md`、`skills/archive/s1-origin.md` 删除及未跟踪的 `archive/`、`docs/identity_fix.md`、`设计图/`；本任务未修改或恢复这些内容。

## 推荐下一步

由实现仓库以 `spec-v1.13.0` 为正式依据，先完成服务主体登记、幂等冲突和敏感操作审计失败补偿测试，再落地 Platform/Identity 协同实现。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
