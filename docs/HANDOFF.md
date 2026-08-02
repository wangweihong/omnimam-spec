# OmniMAM Spec Handoff

## 当前目标与状态

基于已发布 `spec-v1.11.0` 发布 Canvas `compile_time` 与六个 SYSTEM 内置节点合同。状态：内容提交 `d3541ae` 已完成，Release 元数据正在提交、打 tag 和推送；目标版本为 `spec-v1.12.0`。

## 本次工作完成

- 保留 `spec-v1.11.0` 已发布的 Identity 与 Platform Management S1/S2 及 release 事实。
- 将本地提交 `304a271` 的 Workflow Canvas S1/S2 修改移植到 v1.11.0 基线。
- 创建内容提交 `d3541ae`：`spec: add workflow canvas compile-time built-ins`。
- 合并 `CHANGELOG.md` 与本 handoff 冲突，保留 v1.11.0 既有领域记录并加入 Canvas 变更记录。
- Canvas 新增 `compile_time`、受控 compiler key、六个 SYSTEM 内置节点，以及有限 loop 的 serial/batch/cascade 语义。
- Task Center 继续复用现有 DAGTaskGroup 和 1:N task binding；未新增权限、事件、错误码或运行时循环。

## 当前进行中

- 已更新 `RELEASE.md`，登记 `spec-v1.12.0` 的 S1/S2 文件、用户确认和正式实现门禁。
- 运行 YAML/OpenAPI/SQL/引用/diff 校验，创建 release commit 和 annotated tag，并推送提交与 tag。

## 文件变化

- 修改：`00_product/domains/workflow-canvas/product-spec.md`、`01_contracts/domains/workflow-canvas/{openapi.yaml,schema.sql,module-contract.md}`。
- 修改：`00_product/domains/task-center/product-spec.md`、`01_contracts/domains/task-center/module-contract.md`、对应 Context 文件。
- 修改：`CHANGELOG.md`、`docs/HANDOFF.md`、`RELEASE.md`。

## 关键设计决策

- SYSTEM 定义为 `image`、`prompt`、`loop`、`group`、`promptGroup`、`output`，版本统一为 `1.0.0`。
- `compile_time` 只能使用注册 compiler key；内置节点不创建自身 AtomicTask。
- loop count 只能为 1..99，只展开唯一直接 Application 节点；serial、batch、cascade 均编译为有限无环 DAG，并使用 `all_success`。
- `promptGroup` 隐藏并按 `edge.order` 合并 Prompt；Task Center 不解析 loop 配置、不新增 Group 类型或 iteration 状态机。

## API、Schema、依赖与配置变化

- Workflow Canvas OpenAPI 升级为 1.3.0，execution binding 增加 `compile_time` 和五个受控 compiler key。
- Workflow Canvas 设计态 schema 增加 compiler key 约束和节点类型约束；不新增数据库表。
- 不新增依赖、运行时配置、权限、事件、错误码或二进制。

## 验证结果与剩余检查

- 已确认 Canvas 变更来自本地已提交 `304a271`，并已应用到 v1.11.0 基线。
- 已解决 cherry-pick 文档冲突；当前下一步是更新 release 元数据和执行校验。
- 剩余：OpenAPI/YAML/SQL/引用检查、`git diff --check`、release commit/tag/push，以及 Server 子模块 pin 更新。

## 待办、问题与风险

- `spec-v1.11.0` 已存在，不能覆盖其 tag；Canvas 必须使用新的不可变版本发布。
- Release commit hash 写入 `RELEASE.md` 后才能完成正式 release gate。

## 推荐下一步

更新 `RELEASE.md` 的 `spec-v1.12.0` 记录，运行契约校验，提交并推送 release commit 与 tag。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
