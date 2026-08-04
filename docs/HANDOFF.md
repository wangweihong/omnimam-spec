# OmniMAM Spec Handoff

## 当前目标与状态

- 当前目标：将 Agent/AppStudio 的 Workspace 内化为后端事实，用户侧不选择、不导航也不传递 Workspace ID。
- 状态：发布收尾中。Agent/AppStudio Workspace 后端内化规格已提交为 `61bcc52b9286cdca807e42b710e4a06670667546`，Release 提交为 `7c4ef77766aecf8b092161a879c905085a4bf7da`，annotated tag `spec-v1.16.0` 已创建；正在提交最终 Handoff 并推送 `master` 与 tag。

## 本次已完成

- 已读取 `skills/spec-workflow/SKILL.md`、`S1.md`、`S2.md`，并按最小上下文核对 Agent/AppStudio S1、S2 和跨域边界。
- 用户已于 2026-08-04 明确请求“提交发布并推送到远端”，确认将本次 Agent/AppStudio Workspace 后端内化规格发布为 `spec-v1.16.0` 并允许作为正式实现依据。
- 已确认 Agent/AppStudio 均为未 Release 草稿，本次直接替换当前公共契约，不保留 Workspace 公共 API 兼容层，不修改 `RELEASE.md`。
- 已确认内部 Workspace、固定 Binding、Revision、ChangeSet、Snapshot 和 Runtime 安全规则继续保留。
- 已修改 Agent S1：用户创建固定为 Platform Agent，后端原子创建 AgentWorkspace；Coding Agent 仅允许 AppStudio 通过内部模块语义创建，页面、公共错误和 SSE 不投影 Workspace。
- 已修改 Agent OpenAPI：创建请求和公共 DTO 删除 Workspace 字段，删除公共 Workspace Binding 路径及 DTO，列表和详情限定为用户管理的 Platform Agent。
- 已完成 Agent S2：公共错误改为初始化语义，删除 `agent.workspace.read`，公共事件移除 Workspace 字段，内部合同新增 `CreateCodingAgentForStudio`，Schema 仅补内部事实边界说明。
- 已更新 Agent Domain Context，明确 Platform/Coding Agent 的创建入口和 Workspace 后端内化边界。
- 已完成 AppStudio S2：公共接口改为 StudioApplication 级 Source/Revision、Snapshot 和 Preview 寻址，删除公开 StudioWorkspace 路径/DTO，权限改为 `appstudio.source.read/write`；内部 Schema、事件和模块协作继续保留 Workspace canonical 引用。
- 已更新 AppStudio Domain Context，明确用户只感知应用、源码和 Revision，Workspace 仅作为后端默认编辑上下文和固定绑定事实。
- 已收口 AppStudio S1：创建、源码访问、Preview、Hotfix、Secret、错误和验收均使用应用级 Source/Revision 语义；Hotfix 不再创建第二个 Workspace。
- 已新增 Agent/AppStudio 领域架构参考，并更新全局架构、Global Context、Context Map 和 Changelog；未修改 `RELEASE.md`。
- 已同步 Infrastructure 架构参考：Preview 使用应用级源码 Revision，Workspace ID 不进入用户或公共 API，内部由 AppStudio 解析受控 `source_ref`。
- 定向校验发现并修复 AppStudio `create_studio_build` 与 `create_studio_release` 漏声明 `studio_application_id` 路径参数；非失败式全路径诊断确认无其他同类遗漏。
- 8 个目标 YAML 均已通过 PyYAML 解析；Agent OpenAPI 的 34 个 operation、133 个本地引用和 34 个权限引用，以及 AppStudio OpenAPI 的 33 个 operation、143 个本地引用和 33 个权限引用均通过一致性检查。
- 定向断言已确认 Agent 公共创建请求、DTO 和 API 不暴露 Workspace；AppStudio 无 `/api/v1/studio-workspaces`、公开 `StudioWorkspace`、`workspace_id/workspace_revision`，且存在应用级 `StudioSourceState`；两个领域的内部 Schema 继续保留 Workspace 事实。
- `git diff --check` 已通过。
- 已创建 Workspace 后端内化规格提交 `61bcc52b9286cdca807e42b710e4a06670667546`；提交仅包含 24 个本任务文件，无关未跟踪内容未暂存。
- 已更新 `RELEASE.md` 并创建 Release 提交 `7c4ef77766aecf8b092161a879c905085a4bf7da`；已在该提交上创建 annotated tag `spec-v1.16.0`。

## 当前进行中

- 正在创建最终 Handoff 提交，随后推送 `master` 与 `spec-v1.16.0` 到 `origin`。

## 文件变化

- 发布阶段新增修改：`RELEASE.md`、`docs/HANDOFF.md`。
- 已修改：`docs/HANDOFF.md`、`00_product/domains/agent/product-spec.md`、`01_contracts/domains/agent/` 下全部 S2 文件、`domains/agent/context.md`。
- 已修改：`00_product/domains/appstudio/product-spec.md`、`01_contracts/domains/appstudio/` 下全部 S2 文件、`domains/appstudio/context.md`。
- 已新增：`02_architecture/domains/agent.md`、`02_architecture/domains/appstudio.md`。
- 已修改：`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、`02_architecture/global-architecture.md`、`02_architecture/domains/infrastructure.md`、`CHANGELOG.md`。
- 不修改：`RELEASE.md`、实际 migration、正式前后端实现代码和无关领域。

## 关键决定

- 用户侧 Agent 页面只创建和管理 Platform Agent；`CreateAgent` 不接收 `kind/workspace_type/workspace_id`。
- Coding Agent 仅由 AppStudio 通过内部 `CreateCodingAgentForStudio` 语义创建，内部输入可以携带稳定 StudioApplication/StudioWorkspace 引用，前端不可调用。
- AppStudio 创建时后端自动创建唯一默认编辑上下文；用户只感知应用、源码和 Revision。
- Workspace 继续是后端 canonical 对象，设计态 Schema 不删除相关表或字段。

## API、Schema、依赖或配置变化

- 已删除 Agent 公共 Workspace Binding 查询和 DTO；`AgentCreateRequest` 不再接收 `kind/workspace_type/workspace_id`，公共 `Agent` DTO 不返回 Workspace 字段。
- AppStudio 已删除 `/api/v1/studio-workspaces/*` 公共路径，改为 `/api/v1/studio-applications/{studio_application_id}/source*` 和应用级 Preview 路径。
- AppStudio 公共 DTO 已将 `workspace_id/workspace_revision` 改为 `studio_application_id/source_revision`；内部设计态 Schema 保留原字段。
- 不新增依赖，不创建 migration。

## 验证与风险

- 已执行：PyYAML 解析 Agent/AppStudio 的 `openapi.yaml`、`errors.yaml`、`permissions.yaml` 和 `events.yaml`，全部成功。
- 已执行：两个 OpenAPI 的 operationId 唯一性、本地 `$ref`、路径参数和权限引用一致性检查，全部通过。
- 已执行：公共 Workspace 暴露断言、`StudioSourceState` 存在断言、内部 Workspace Schema 保留断言和 `git diff --check`，全部通过。
- 按任务约束未运行全仓测试；本次为规格变更，无目标实现 package 测试。
- 风险：本地 Release 记录和 tag 已完成，但远端推送尚未完成；必须确认 `origin/master` 和远端 `spec-v1.16.0` 均更新成功。

## 未完成事项

- 提交最终 Handoff，推送 `master` 和 `spec-v1.16.0` 到 `origin`，并核对远端引用。

## 推荐下一步

- 提交本文件，然后推送 `master` 和 `spec-v1.16.0` 到 `origin`；使用 `git ls-remote` 核对远端分支与 tag。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
