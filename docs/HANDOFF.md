# OmniMAM Spec Handoff

## 当前发布任务（spec-v1.15.0）

- 当前目标：完成权限审计中的高置信修复，提交、登记 `spec-v1.15.0`、创建 annotated tag 并推送 `master` 与 tag。
- 状态：规格提交 `0d5954609215da7bce01fe82b351e7d57e8018da` 已完成，目标校验通过，`RELEASE.md` 已登记；正在创建发布提交、tag 并推送。
- 发布范围：AI Chat、Application Platform、Asset Library、Task Center、Workflow Canvas、Model Management、Notification Center、SSE、Agent、AppStudio、MCP、Model Gateway 的权限契约及必要 S1/Context；不包含用户未跟踪文件。
- 已完成：补齐 Model Management/Notification/SSE 默认角色与 Model Management 16 个 OpenAPI 权限标注；统一 `REGULAR_USER -> USER`；新增 Application Platform 显式 `manage_all/global` 权限并同步 S1/OpenAPI/Context。
- 验证结果：目标 YAML 均可解析；OpenAPI 直接和条件权限引用均能解析到定义；Model Management 16 个 operation 均有 `x-permission`；目标角色编码合法；`git diff --check` 通过。
- 当前进行中：创建 `spec-v1.15.0` 发布提交与 annotated tag，并推送 `master` 与 tag。
- 下一步：核对远端分支和 tag 指向，确认发布完成。

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
