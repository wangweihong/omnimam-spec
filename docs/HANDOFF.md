# OmniMAM Spec Handoff

## 当前目标与状态

目标：提交补全后的 Identity S1/S2，整合远端 `spec-v1.12.1`，发布 `spec-v1.12.2` 并推送远端。

状态：完成。Identity 规格提交、Release 记录、release commit 和 annotated tag 已创建；`master` 与 `spec-v1.12.2` 已通过 SSH 推送远端并核对。

## 本次完成

- 补全 Identity S1：版本化当前主体授权投影、注册审批/拒绝/重新申请、Service Account 直接角色与凭据生命周期、跨域用户删除依赖检查，以及页面状态、动作和恢复语义。
- 同步 Identity OpenAPI、设计态 Schema、错误、权限、事件、模块合同、Domain Context、领域架构、Global Context、Context Map 和 CHANGELOG。
- 新增 `BR-IAM-023..030`、`US-IAM-015..020`；Identity OpenAPI 升级为 `0.2.0-draft`。
- fetch 并整合远端 `spec-v1.12.1`；保留 Workflow Canvas/Task Center 的 Release、Changelog 和 handoff 事实。
- 创建 Identity 规格提交 `a56f84d60f14fe6251dcac9c1e1d2b2faa432bd5`（`spec: complete identity authorization and lifecycle contracts`）。
- 在 `RELEASE.md` 登记 `spec-v1.12.2`，Release 内容 commit 指向 `a56f84d60f14fe6251dcac9c1e1d2b2faa432bd5`。
- 创建 release commit `f2f74f4fd3fec443d50dba3996515fea939666ee`（`release: publish spec-v1.12.2`）。
- 创建 annotated tag `spec-v1.12.2`；远端 tag object 为 `56002dd61dd414dd73b18a9037f090af706a7fc8`，peel 到 release commit `f2f74f4fd3fec443d50dba3996515fea939666ee`。
- 已 atomic push `master` 和 `spec-v1.12.2`；首次推送后远端 `master` 为 `f2f74f4fd3fec443d50dba3996515fea939666ee`。
- 用户已有 `skills/archive/s1-origin-2.md`、`skills/archive/s1-origin.md` 删除及未跟踪的 `archive/`、`docs/identity_fix.md`、`设计图/` 均未纳入本次提交。

## 当前进行中

无。

## 文件变化

- S1：`00_product/domains/identity/product-spec.md`。
- S2：`01_contracts/domains/identity/openapi.yaml`、`schema.sql`、`errors.yaml`、`permissions.yaml`、`events.yaml`、`module-contract.md`。
- 架构与 Context：`02_architecture/domains/identity.md`、`domains/identity/context.md`、`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`。
- 维护与发布：`CHANGELOG.md`、`RELEASE.md`、`docs/HANDOFF.md`。
- 未新增正式 migration、实现代码、运行时配置、依赖或 CI/CD 文件。

## 关键设计决定

- 登录、Refresh 和独立授权查询返回同一版本化授权投影；角色只用于展示解释，后端继续按当前权限码实时鉴权，角色与完整权限不写入 JWT。
- `ADMIN_APPROVAL` 在批准前不分配角色、不创建会话或 Token；审批、拒绝和重新申请历史不可变。
- Service Account 只通过直接角色授权；owner 不可用时凭据交换 fail closed；初始密码和 Secret 只返回一次。
- 用户删除必须使用完整、未过期并在提交前重验的跨域依赖检查；资源转移和来源事实仍由目标 domain 拥有。
- `SystemAuthConfig` 与 `AuditLog` 继续归 `platform-management`，Identity 不维护重复事实或管理 API。

## API、Schema、依赖与配置变化

- Identity OpenAPI 当前包含 57 个 operation，新增注册审批、初始密码重置、用户/服务账号直接角色、删除依赖检查、共享目录、Service Account Token/凭据历史与撤销合同。
- Identity 设计态 Schema 当前包含 19 张表，新增注册申请、服务账号角色和用户删除检查表。
- Identity 当前包含 52 个错误、13 个权限和 8 个可靠事件。
- 未新增依赖或运行时配置。

## 验证结果

- Identity OpenAPI、errors、permissions、events 均通过 `yq` 解析。
- 57 个 operationId 唯一且路径均使用 `/api/v1`；307 个本地 `$ref` 可解析；所有 operation 均有授权声明和 S1 追溯。
- 11 个列表 operation 均包含 `page_num/page_size`；请求合同未发现直接字符串或 ID 数组。
- 全仓 15 个错误文件共识别 354 个 code/value，未发现全局重复；Identity 错误均落在登记区间。
- 19 个 `CREATE TABLE` 与闭合数量一致；Release 登记路径存在；`git diff --check` 通过。
- 远端 `spec-v1.12.2` annotated tag 已核对并 peel 到 release commit。

## 待办事项

- 在依赖本 Spec 的实现仓库中将 SSOT/submodule 版本同步到 `spec-v1.12.2`。
- 各资源 domain 在正式实现用户删除与 Service Account owner 投影前，需登记对应受控批量提供方合同；未登记或不可用时保持 fail closed。

## 已知问题与风险

- 当前环境没有 `mmdc`，Mermaid 已完成图文和围栏检查，但未执行渲染器语法验证。
- 本任务只修改和发布规格，没有运行后端构建或实现测试。
- 工作区仍有用户自己的归档删除和未跟踪资料，后续任务不得误提交或恢复。

## 推荐下一步

在实现仓库中将 SSOT/submodule 固定到 `spec-v1.12.2`，同步版本记录，并按 Identity implementation gate 开始实现或验收。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
