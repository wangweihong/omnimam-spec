# OmniMAM Spec Handoff

## 当前发布任务（spec-v1.15.1，2026-08-04）

- 当前目标：提交 AppStudio 脚手架模板字段清理，并发布一个小版本。
- 状态：已完成；规格提交 `7d290e8`，发布提交 `2d15f36`，`spec-v1.15.1` 标签已创建并推送。
- 已完成：`template_id`、`technology_stack` 已从 AppStudio OpenAPI 创建请求和设计态 Schema 移除；已更新 CHANGELOG；已通过定向 YAML 解析与 `git diff --check`。
- 当前进行中：无。
- 文件变化：`01_contracts/domains/appstudio/openapi.yaml`、`01_contracts/domains/appstudio/schema.sql`、`CHANGELOG.md`、`docs/HANDOFF.md` 已包含在规格提交；`RELEASE.md` 和发布交接已包含在发布提交 `2d15f36`。
- 关键决定：本次只发布 AppStudio S2 清理，不新增模板实体、模板发现 API 或替代字段；S1 不变。
- 验证：`yq` 解析 AppStudio OpenAPI 通过；目标文件无 `template_id`、`technology_stack`、`technology_profile`、`runtime_profile`；`git diff --check` 通过；无可运行的 AppStudio 实现测试。
- 风险：用户已有未跟踪的 `archive/`、`docs/identity_fix.md`、`设计图/` 不纳入本次提交；历史 Release 元数据错位不在本次范围。
- 下一步：实现侧按 `spec-v1.15.1` 重新生成 AppStudio 客户端，移除旧模板选择器和禁用保护假设。

## 当前清理任务（移除 AppStudio 脚手架模板残留，2026-08-04）

- 当前目标：根据用户确认“并没有脚手架模板的任何设计”，从 AppStudio 当前 S2 清理 `template_id` 及其同一旧设计残留。
- 状态：已完成；已重新读取 `skills/spec-workflow/SKILL.md`、`skills/spec-workflow/S2.md` 和现有交接，确认 S1 当前创建语义没有模板对象或模板输入。
- 已完成：从 AppStudio OpenAPI 创建请求和设计态 Schema 首表移除 `template_id`、`technology_stack`；未新增模板实体、发现 API 或替代字段。
- 当前进行中：无。
- 文件变化：`01_contracts/domains/appstudio/openapi.yaml`、`01_contracts/domains/appstudio/schema.sql`、`CHANGELOG.md`、`docs/HANDOFF.md`；保留用户已有未跟踪文件不动。
- 关键决策：不新增 `StudioTemplate` 或发现 API；按当前 S1 直接删除无事实依据的模板字段及其旧技术栈字段，避免继续暗示脚手架能力。
- 验证：AppStudio OpenAPI 使用 `yq` 解析通过；目标域已无 `template_id`、`technology_stack`、`technology_profile`、`runtime_profile` 残留；`git diff --check` 通过；未运行全仓测试。
- 风险：AppStudio S1/S2 的发布门禁和历史 tag 元数据仍有既有错位，本次不扩大范围处理。
- 下一步：客户端或实现侧按新的 AppStudio 创建合同重新生成 DTO/客户端；本仓库不包含对应实现 package 或测试。

## 当前分析任务（AppStudio template_id，2026-08-04）

- 当前目标：分析 AppStudio 为什么同时出现 `template_id` 与“应用模板 ID”，并核对用户给出的历史提交与当前 SSOT/客户端不一致。
- 状态：已完成分析；已读取 `GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、`domains/appstudio/context.md` 与工作流规则，确认任务事实归属为 `appstudio`。
- 已完成：核对当前 S1 第 5.1/6 节、S2 OpenAPI 创建 Schema、Schema 首表、模块合同，以及 `28ceccb`、`6da35fb`、`f1471d5`、`2f71a83`、`81cdf96` 的历史；确认旧版 `template_id` 的明确语义、重写后的 name-only 创建合同和当前残留字段。
- 结论：`template_id` 最初是 AppStudio 初始化用的“平台受控生成应用模板 ID”，特意声明不同于 `application-platform.ApplicationTemplate`；`f1471d5` 重写后 S1 已不再定义模板选择，OpenAPI 和 Schema 的残留字段现已清理。模板发现接口从未在旧合同中定义，旧前端无法合法获得必填模板 ID。
- 当前进行中：无。
- 文件变化：仅更新本交接文件；未修改产品或契约事实源。
- 关键决策：分析以当前 AppStudio S1/S2 和可验证 Git 历史为准；Web `appstudio-client.ts`、按钮逻辑和测试不在本仓库，用户提供的 Web 提交链路作为外部事实单独标注，不反向提升为 SSOT。
- 验证：完成定向文本、Git 历史和 OpenAPI/Schema 结构核对；未运行测试（当前工作区没有 AppStudio 实现 package 或直接相关测试）。
- 风险：`RELEASE.md` 当前记录的 `spec-v1.12.0` commit 为 `2f71a83`，但 annotated tag `spec-v1.12.0` 实际指向 `6da35fb`；发布记录与 tag 仍存在元数据错位。AppStudio S1/S2 当前 Context 标记为未 Release 草稿，不能据此作为正式实现依据。
- 下一步：实现侧重新生成 AppStudio 客户端并移除旧的模板选择器/禁用保护假设；若未来重新引入模板能力，必须先新增独立 S1 决策和完整 S2 合同。

## 当前发布任务（spec-v1.15.0）

- 当前目标：完成权限审计中的高置信修复，提交、登记 `spec-v1.15.0`、创建 annotated tag 并推送 `master` 与 tag。
- 状态：已完成。规格提交为 `0d5954609215da7bce01fe82b351e7d57e8018da`，发布提交为 `1445e30d800c7ae4598bed42811c787bf7d39fbd`；annotated tag `spec-v1.15.0` 与 `master` 已推送到 `origin`。
- 发布范围：AI Chat、Application Platform、Asset Library、Task Center、Workflow Canvas、Model Management、Notification Center、SSE、Agent、AppStudio、MCP、Model Gateway 的权限契约及必要 S1/Context；不包含用户未跟踪文件。
- 已完成：补齐 Model Management/Notification/SSE 默认角色与 Model Management 16 个 OpenAPI 权限标注；统一 `REGULAR_USER -> USER`；新增 Application Platform 显式 `manage_all/global` 权限并同步 S1/OpenAPI/Context。
- 验证结果：目标 YAML 均可解析；OpenAPI 直接和条件权限引用均能解析到定义；Model Management 16 个 operation 均有 `x-permission`；目标角色编码合法；`git diff --check` 通过。
- 当前进行中：无。
- 下一步：实现仓库按 `spec-v1.15.0` 的权限码、默认角色、owner 边界和条件权限实施鉴权；优先补 Agent Runtime 日志 API，并单独评估聚合权限拆分。

## 本次权限审计复核（2026-08-03）

- 当前目标：排查仍缺少管理员/超级管理员权限或权限契约不完整的模块。
- 状态：审计完成；本次只读取权限契约、OpenAPI 标注、Identity 角色事实和相关 Context，未修改业务权限。
- 明确缺口：`model-management` 4 个用户权限没有 `default_roles`，其 OpenAPI 16 个 operation 均缺少 `x-permission`；`notification-center` 4 个用户收件箱/偏好权限及 `notification.admin.receive` 没有默认角色；`sse` 2 个用户流权限没有默认角色。
- 跨 owner 缺口：`application-platform` 明确允许管理员代管任意用户工作流和管理 global Application，但只复用普通用户的 `aiapp.comfyui_workflow.read/manage`、`aiapp.application.manage`；这与 Identity `BR-IAM-009/013` 要求“不得硬编码角色、跨 owner 必须显式 manage_all 权限”不一致。`agent`、`appstudio` 的 `system_admin` 跨 owner 语义也需要明确为仅受权范围，或补独立 `manage_all` 权限。
- 角色不一致：`agent`、`appstudio`、`mcp`、`modelgateway` 使用未在 Identity 内置角色中定义的 `REGULAR_USER`；`infrastructure` 使用未在 Identity 角色事实中登记的 `SERVICE_TASK_CENTER`，需确认其是否为 ServiceAccount 角色映射而非普通角色。
- 接口引用结论：`agent.runtime.logs.read` 有 S1 `GetAgentRuntimeLogs` 依据，但 Agent OpenAPI 缺少对应 operation；`task.operation.admin` 已用于 TaskAttempt `executor` 字段级裁剪和模块合同，不是遗漏接口。Identity 的认证/换证 operation 不需要普通业务权限，其他未直接引用项均为内部服务或接收者规则。
- 权限粒度风险：`task.atomic.operate`、`task.group.operate`、`task.schedule.manage` 将读、创建、取消、重试、日志或系统计划管理合并，限制了自定义最小权限角色；`aiapp.application.manage` 混合 owner 管理与 global 管理；`asset.delete` 混合软删除、恢复和不可逆清理。当前内置角色可工作，但后续自定义角色难以最小授权。
- 已确认正常：15 个全局领域均存在权限文件；`asset-library`、`ai-chatting`、`workflow-canvas` 的 owner 权限边界清晰；`platform-management`、`modelgateway` 的管理员专用动作有独立权限；MCP 非直接权限通过 `x-delegated-permissions` 引用；内部服务权限未授给普通用户。
- 下一步：若用户要求修复，优先补 `model-management`、`notification-center`、`sse`，随后拆出 Application Platform `manage_all/global` 权限并统一 `REGULAR_USER`；最后补 Agent Runtime 日志 API和评估高风险聚合权限拆分。

## 上一任务检查点（素材库权限，2026-08-03）

- 当前目标：补充 `asset-library` 素材库的管理员/超级管理员默认权限，同时保持素材 owner 隔离和服务主体权限边界。
- 状态：完成；权限补充为未发布草稿，未修改 `RELEASE.md`。
- 已完成：14 个用户级素材权限默认授予 `USER`、`ADMIN`、`SUPER_ADMIN`；StorageBackend/Blob 检查继续仅限 `ADMIN`、`SUPER_ADMIN`；Artifact 创建和 Representation 写入继续无默认角色，保留受信服务/Worker 边界。
- 关键决定：管理员和超级管理员可以使用自己的素材、上传、Collection、标签、引用、Artifact 和 Representation 读取能力，但不获得跨用户素材访问或平台管理员共享素材语义。
- 文件变化：`01_contracts/domains/asset-library/permissions.yaml`、`CHANGELOG.md`、`docs/HANDOFF.md`。
- 验证结果：Asset 权限 YAML/OpenAPI 可解析；53 个 operation 的 `x-permission` 引用全部已登记；默认角色仅为 `USER`、`ADMIN`、`SUPER_ADMIN`；所有权限 BR/US 追溯有效；服务权限/存储权限边界符合预期；`git diff --check` 通过。
- 下一步：等待用户确认是否与前一轮权限补充一起登记新的 `RELEASE.md` 版本；发布前不得作为正式实现依据。
- 风险：BR-USER-ASSET-03、BR-USER-ASSET-33 禁止跨用户管理员共享素材；实现侧不得根据角色名称增加隐式绕过。

## 上一任务目标与状态

- 目标：补充管理员/超级管理员在 `workflow-canvas`、`application-platform`、`ai-chatting`、`task-center` 的缺失权限，并保持 Identity 角色语义与各域权限契约一致。
- 状态：完成；本次变更仍是未发布草稿，未修改 `RELEASE.md`。

## 上一任务完成

- 画布：为 9 个面向用户/管理员的权限补充 `default_roles`；NodeDefinition 管理仅授予 `ADMIN`、`SUPER_ADMIN`。
- 应用平台：8 个权限统一使用 Identity 已定义的 `USER`、`ADMIN`、`SUPER_ADMIN`，移除无效的 `REGULAR_USER`。
- 任务中心：为 AtomicTask、TaskGroup、Schedule 和运维诊断权限补充管理员/超级管理员默认授权；内部 runtime/projection 权限仍仅服务主体可用。
- AI Chat：新增 10 个 `ai_chat.*` 权限，覆盖工作区、话题、消息、生成、助手、快捷短语和翻译；18 个 OpenAPI operation 全部增加 `x-permission`。
- AI Chat S1 与模块契约：将独立权限和默认角色写入产品语义，并明确权限不扩大 owner、scope、Topic 归属或可见性；本轮不新增跨用户代管权限。
- 文档：更新 `CHANGELOG.md` 与本交接文件。

## 文件变化

- `00_product/domains/ai-chatting/product-spec.md`
- `01_contracts/domains/ai-chatting/{permissions.yaml,openapi.yaml,module-contract.md}`
- `01_contracts/domains/application-platform/permissions.yaml`
- `01_contracts/domains/task-center/permissions.yaml`
- `01_contracts/domains/workflow-canvas/permissions.yaml`
- `domains/ai-chatting/context.md`
- `CHANGELOG.md`
- `docs/HANDOFF.md`

## 关键设计决定

- 默认角色只使用 `USER`、`ADMIN`、`SUPER_ADMIN`，与 Identity S1/S2 的内置角色一致。
- 管理员权限只控制已登记操作入口；各业务域仍必须执行 owner、project、namespace、visibility、状态、版本和资源引用校验。
- AI Chat 的资源继续按当前主体个人数据隔离；跨用户代管若未来需要，必须新增显式管理权限和对应 S1 语义。
- 未新增 API 路径、Schema、错误码、事件、依赖或运行时配置；未修改正式实现代码和 migration。

## 验证结果

- `yq` 解析四个目标权限 YAML 和 AI Chat OpenAPI：通过。
- 目标默认角色校验：仅 `USER`、`ADMIN`、`SUPER_ADMIN`。
- AI Chat 权限引用校验：18 个 operation 均有 `x-permission`，且引用的 10 个权限键均已登记。
- AI Chat S1 追溯校验：10 个权限的 `related_rules`、`related_user_stories` 均存在。
- 旧 `REGULAR_USER` 和废弃 `ai_chat.read/write/manage` 在目标文件中已清理。
- `git diff --check`：通过。
- 未运行全仓库测试；本次无目标实现 package 测试可运行。

## 未完成事项与风险

- 本次权限补充尚未进入 `RELEASE.md`，在用户确认发布前不得作为正式实现依据。
- 实现侧需要按权限码实时鉴权，不得根据角色名称增加隐式绕过。
- 工作区存在用户自己的未跟踪 `archive/`、`docs/identity_fix.md`、`设计图/`，本次未修改。

## 推荐下一步

由用户确认是否修复本次审计发现的 `model-management`、`notification-center`、`sse` 和角色编码缺口；修复后再更新 `RELEASE.md`，登记所有相关 S1/S2 文件并发布。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
