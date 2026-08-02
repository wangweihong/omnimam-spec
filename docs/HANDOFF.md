# OmniMAM Spec Handoff

## 当前目标与状态

目标：提交已补全的 Identity S1/S2，整合远端 `spec-v1.12.1`，发布 `spec-v1.12.2` 并推送 `master`。

状态：进行中。Identity 规格提交已 rebase 到远端 `master=23d1313`，发布前校验通过；`spec-v1.12.2` Release 元数据已写入，正在创建 release commit 和 annotated tag。

## 本次完成

- 已补全 Identity S1：版本化当前主体授权投影、注册审批/拒绝/重新申请、Service Account 直接角色与凭据生命周期、跨域用户删除依赖检查，以及页面状态、动作和恢复语义。
- 已同步 Identity OpenAPI、设计态 Schema、错误、权限、事件、模块合同、Domain Context、领域架构、Global Context、Context Map 和 CHANGELOG。
- 已新增 `BR-IAM-023..030`、`US-IAM-015..020`；Identity OpenAPI 当前为 `0.2.0-draft`。
- 已完成结构化与语义校验：57 个 operation、307 个本地 `$ref`、19 张设计态表、52 个 Identity 错误、13 个权限、8 个事件；全仓 354 个错误 code/value 无重复。
- 已创建并 rebase Identity 规格提交 `a56f84d60f14fe6251dcac9c1e1d2b2faa432bd5`。
- 已 fetch 远端 `spec-v1.12.1`；远端 Workflow Canvas/Task Center 修改未触及 Identity 正式文件。
- 已保留远端 `spec-v1.12.1` 的 Changelog 内容，并合入本次 Identity Unreleased 内容。
- 已恢复用户已有的两个 `skills/archive/` 删除；它们继续保持未暂存，不进入本次提交。
- 已在 `RELEASE.md` 新增 `spec-v1.12.2`，Release 内容 commit 指向 `a56f84d60f14fe6251dcac9c1e1d2b2faa432bd5`。
- 用户已有 `skills/archive/` 两个删除已临时 stash；未跟踪的 `archive/`、`docs/identity_fix.md`、`设计图/` 未处理。

## 当前进行中

- 提交 `spec-v1.12.2` Release 元数据并创建 annotated tag。
- 更新最终 handoff，推送 `master` 和标签并核对远端引用。

## 文件变化

- Identity S1：`00_product/domains/identity/product-spec.md`。
- Identity S2：`01_contracts/domains/identity/openapi.yaml`、`schema.sql`、`errors.yaml`、`permissions.yaml`、`events.yaml`、`module-contract.md`。
- 架构与 Context：`02_architecture/domains/identity.md`、`domains/identity/context.md`、`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`。
- 维护与发布：`CHANGELOG.md`、`docs/HANDOFF.md`；`RELEASE.md` 尚待新增 `spec-v1.12.2`。
- 未新增正式 migration、实现代码、运行时配置、依赖或 CI/CD 文件。

## 关键设计决定

- 登录、Refresh 与独立接口返回同一版本化授权投影；角色只用于展示解释，后端继续按当前权限码实时鉴权。
- ADMIN_APPROVAL 在批准前不分配角色、不创建会话或 Token；审批历史不可变，拒绝后允许同一身份重新申请。
- Service Account 只通过直接角色授权；owner 不可用时凭据交换 fail closed；Secret 只返回一次。
- 用户删除使用 Identity 聚合的完整、短期跨域依赖检查；资源转移和来源事实仍由目标 domain 拥有。
- `spec-v1.12.2` 只发布 Identity 本次 S1/S2 及直接维护文件，不覆盖 `spec-v1.12.1` 的 Workflow Canvas/Task Center Release。

## API、Schema、依赖与配置变化

- Identity OpenAPI 包含 57 个 operation；新增注册审批、初始密码重置、用户/服务账号直接角色、删除依赖检查、共享目录、Service Account Token/凭据历史与撤销合同。
- Identity 设计态 Schema 包含 19 张表，新增注册申请、服务账号角色和用户删除检查表。
- 未新增依赖或运行时配置。

## 验证结果与剩余检查

- rebase 前 Identity YAML、OpenAPI、本地 `$ref`、权限、错误、追溯、分页、批量请求、SQL 表闭合及 `git diff --check` 均通过。
- rebase 后已重新通过 YAML、OpenAPI、S1 追溯、全局错误码、分页、批量请求、SQL 表闭合、内容路径和 `git diff --check` 校验。
- 当前环境没有 `mmdc`，Mermaid 未执行渲染器语法验证。

## 待办事项

- 创建 release commit 与 annotated tag `spec-v1.12.2`。
- 推送 `master` 和 `spec-v1.12.2` 标签并核对远端引用。

## 已知问题与风险

- 各资源 domain 仍需在正式实现前登记用户删除依赖检查和 Service Account owner 批量投影；未登记或不可用时必须 fail closed。
- 用户已有归档删除和未跟踪资料不属于本次 Release，不得纳入提交。

## 推荐下一步

暂存 `RELEASE.md`、`CHANGELOG.md` 和 `docs/HANDOFF.md`，创建 `spec-v1.12.2` release commit 与 annotated tag。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
