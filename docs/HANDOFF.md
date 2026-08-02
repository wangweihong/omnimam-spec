# OmniMAM Spec Handoff

## 当前目标与状态

目标：将旧 Workflow Canvas compile-time built-ins 合同合入当前 `master`，以 `spec-v1.12.1` 发布并推送远端。

状态：进行中。旧分支已执行 `--no-ff` 合并，Workflow Canvas S1/S2 已进入当前工作树；正在完成冲突收敛、release 元数据、提交和推送。

## 本次完成

- 已读取 `AGENTS.md`、`skills/spec-workflow/SKILL.md`、`S1.md`、`S2.md`、全局 Context Map 及 workflow-canvas/task-center Domain Context。
- 已从 `origin/master` commit `c83b7d70a8fca2fae7d0692b92914b5a661598c7` 创建 `codex/release-workflow-canvas-v1.12.1`。
- 已将 `codex/canvas-compile-time-v1.12` 以 `--no-ff --no-commit` 合入当前分支。
- Workflow Canvas product spec、OpenAPI、schema、module contract 和 Context 已自动合入。
- Task Center S1 保留当前 function registry 的 `BR-TASK-147..153`，Canvas 有限静态 DAG 规则顺延为 `BR-TASK-154`。
- `RELEASE.md` 保留 Agent/AppStudio/Infrastructure/Task Center 的 `spec-v1.12.0` 正式记录；旧 Canvas 记录不再占用该版本号。

## 当前进行中

- 恢复并修正 `spec-v1.12.1` release 元数据，使 release 内容 commit 指向本次合并提交。
- 完成必要一致性检查、提交、创建 annotated tag，并 fast-forward 推送到 `origin/master`。

## 文件变化

- S1：`00_product/domains/workflow-canvas/product-spec.md`、`00_product/domains/task-center/product-spec.md`。
- S2：`01_contracts/domains/workflow-canvas/openapi.yaml`、`schema.sql`、`module-contract.md`，以及 `01_contracts/domains/task-center/module-contract.md`。
- Context：`domains/workflow-canvas/context.md`、`domains/task-center/context.md`。
- 维护与发布：`CHANGELOG.md`、`RELEASE.md`、`docs/HANDOFF.md`。
- 未新增错误码、权限码、事件、数据库表或实现代码。

## 关键设计决定

- `spec-v1.12.0` 继续表示 Agent/AppStudio/Infrastructure/Task Center function registry release。
- Workflow Canvas compile-time built-ins 使用新版本 `spec-v1.12.1`，不覆盖当前四域 release。
- Canvas `loop` 只在编译期展开有限静态 AtomicTask DAG；Task Center 不新增运行时循环、回边或 iteration 状态机。
- 当前 Task Center function registry 合同优先保留，Canvas DAG 规则使用新编号 `BR-TASK-154` 避免编号冲突。

## API、Schema、依赖与配置变化

- Workflow Canvas OpenAPI 引入 `compile_time` execution binding 和五个受控 compiler key。
- Workflow Canvas schema 增加 compiler key 与六个 SYSTEM 内置 NodeDefinition 约束，不新增表。
- 不新增依赖、运行时配置、权限、事件、错误码、migration 或实现代码。

## 验证结果与剩余检查

- 合并前确认远端不存在 `spec-v1.12.1` tag。
- 待运行：冲突标记检查、`git diff --check`、release 内容可达性、目标路径存在性和远端 fast-forward 检查。
- 按用户要求直接合并并推送，不重复执行完整契约测试矩阵。

## 待办

- 完成合并提交。
- 新增指向合并内容提交的 `spec-v1.12.1` release 记录并提交。
- 创建并推送 `spec-v1.12.1` annotated tag，推送当前分支到 `origin/master`。
- 回到 `omnimam-server` 同步 submodule gitlink 与 `SSOT_VERSION`。

## 已知问题与风险

- 远端旧 `spec-v1.12.0` annotated tag 仍指向旧 Canvas release commit，但 `RELEASE.md` 已将该版本分配给当前四域 release；本任务不强制移动或删除该历史 tag。
- 当前没有重新运行完整 OpenAPI/YAML/SQL/追溯校验；发布复用旧 Canvas release 和当前四域 release 已记录的验证结果。

## 推荐下一步

完成冲突标记与 diff 检查，创建合并内容提交，然后用该提交 hash 更新 `RELEASE.md` 的 `spec-v1.12.1` 记录并发布。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
