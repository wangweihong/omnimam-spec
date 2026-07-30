# OmniMAM Spec Handoff

## 当前目标与状态

为 `omnimam-spec` 增加轻量上下文索引层。状态：已完成并通过验证；Context 仅用于摘要与导航，未修改正式 S1/S2 或 Release。

## 本次已完成

- 新增 `GLOBAL_CONTEXT.md`，说明项目目标、Spec 分层、9 个实际领域、核心对象、事实归属、跨域边界和最小读取规则。
- 新增 `CONTEXT_MAP.md`，建立单领域关键词、跨域任务和全局入口到最小文档集合的映射。
- 为 ai-chatting、application-platform、asset-library、identity、model-management、notification-center、sse、task-center、workflow-canvas 创建统一九章节 Domain Context。
- 新增根 `README.md`，声明 AI Context 读取入口和 Context 非 SSOT 规则。
- 更新 `AGENTS.md` 的仓库边界、按需加载顺序和 Context 维护触发条件，保留任务开始前已有的 Completion & Handoff Rules。
- 更新 `CHANGELOG.md`，记录 2026-07-30 未发布的上下文索引改造。

## 当前进行中

- 无。

## 文件变化

- 新增：`GLOBAL_CONTEXT.md`、`CONTEXT_MAP.md`、`README.md`。
- 新增：`domains/ai-chatting/context.md`、`domains/application-platform/context.md`、`domains/asset-library/context.md`、`domains/identity/context.md`、`domains/model-management/context.md`、`domains/notification-center/context.md`、`domains/sse/context.md`、`domains/task-center/context.md`、`domains/workflow-canvas/context.md`。
- 修改：`AGENTS.md`、`CHANGELOG.md`、`docs/HANDOFF.md`。
- 未修改：`00_product/`、`01_contracts/`、`02_architecture/`、`RELEASE.md`。
- 保留用户已有工作区改动：`archive/`、已删除的 `skills/archive/s1-origin.md` 与 `skills/archive/s1-origin-2.md`，以及 `AGENTS.md` 的 Handoff 规则。

## 关键设计决策

- Domain Context 位于根级 `domains/<domain_id>/context.md`，不混入 S1 或 S2 目录。
- 使用实际领域名 `ai-chatting`；`application-engine`、`capability-catalog`、`mcp-server` 因无独立正式目录只在 Context Map 标记为规划中。
- Engine、Adapter、Executor 和 ProviderCapability 当前导航到 application-platform；Artifact 归 asset-library；AtomicTask 归 task-center。
- TaskRun、ExecutionLease、Worker claim、DAGFlowTask 等旧术语只作为过期检索词，并明确让位于 AtomicTask 主线。
- 产品语义以 S1 为准，实现合同以 S2 为准；Context 冲突时让位于正式 Spec，S1/S2 冲突必须修复并重新 release。

## API、Schema、依赖与配置变化

- 无 API、Schema、错误码、权限码、事件、模块合同、依赖、migration 或运行时配置变化。

## 验证结果

- 9 个实际领域与 9 个 Domain Context 集合完全一致；每个文件都包含统一九章节及“不在本领域定义的内容”。
- 汉字数：Global Context 1612、Context Map 1085；Domain Context 为 775～924，全部满足约定范围。
- 已验证 70 个 Context 文件或目录引用真实存在；规划领域没有虚构 Context，identity 没有虚构 S2 路径。
- 新文件尾随空格检查和代码围栏平衡检查通过；`git diff --check` 通过。
- `00_product/`、`01_contracts/`、`02_architecture/`、`RELEASE.md` 的任务 diff 为空。

## 待办、问题与风险

- 本次改造无未完成任务。
- identity 只有 S1，S2 仍待未来从正式产品语义推导。
- SSE、workflow-canvas、asset-library 等正文头部状态可能滞后于后续 Release；索引已要求以 `RELEASE.md` 的具体记录和 implementation gate 为准，本次未重写原 Spec。
- 后续修改核心对象、领域职责、边界、核心规则、状态或事实源路径时，必须同步维护对应 Context。

## 推荐下一步

在下一次实际 Spec 任务中按 `GLOBAL_CONTEXT.md` → `CONTEXT_MAP.md` → 一个 Domain Context → 1～3 个正式 Spec 的顺序验证 Token 收敛效果；若关键词无法定位，再调整 Context Map，而不是扩大默认读取范围。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
