# OmniMAM Spec Handoff

## 当前目标与状态

- 目标：发布 `spec-v1.23.4`，修复 Coding Runtime Git access 函数合同遗漏，并规定 Attempt 失败日志输出脱敏后的具体原因。
- 状态：进行中；内容 commit `0da3dd236d687643e0b34a71cc115b51f5de485f` 与 release record 已完成，待创建 release commit/tag/push。

## 本次已完成

- 基于已发布 `spec-v1.23.3` 创建 `codex/spec-v1.23.4`。
- 确认 `agent.runtime.ensure@1.0` 因 `additionalProperties: false` 拒绝已由 Agent Service 生成、Worker 消费的 `runtime_git_access_ref`。
- 将 `1.0` 原 input schema/ref/digest 保持不变并标记为 RETAINED；新增 `1.1` ACTIVE 合同。
- `1.1` 为 Coding Agent 条件必填 `runtime_git_access_ref`，并限制为 `^appstudio-runtime-git-access://`；Platform Agent 不要求该字段。
- `US-TASK-022` 与 Task Center module contract 要求失败日志包含经过统一脱敏、单行化和长度限制的具体摘要，写入仍为 best-effort。
- 更新 `CHANGELOG.md`；未修改 API、Schema、错误码、权限码、事件或 Context。
- 已创建内容 commit `0da3dd236d687643e0b34a71cc115b51f5de485f`，并写入 `spec-v1.23.4` release record。

## 当前进行中

- 创建 release commit、annotated tag 并推送，随后核验远端 tag peeled commit。

## 文件变化

- Modified: `00_product/domains/task-center/product-spec.md`。
- Modified: `01_contracts/domains/task-center/function-registry.yaml`。
- Modified: `01_contracts/domains/task-center/module-contract.md`。
- Modified: `CHANGELOG.md`、`docs/HANDOFF.md`。

## 关键决定

- 已发布合同不可原地改写；`1.0` 保留历史恢复能力，`1.1` 成为新任务唯一 ACTIVE 版本。
- Task 只携带 opaque Runtime Git access reference；clone URL、用户名和 token 不进入 Task、日志或业务投影。
- 失败日志复用既有统一安全管线，不改变任务结果、重试或取消语义。

## 验证与风险

- Passed: Server 正式 registry verifier，8 个 functionRef 各有唯一 ACTIVE 合同。
- Passed: `agent.runtime.ensure@1.0` digest 保持 `sha256:5fff8cdcec364fea4c8d833b6c625b43c4e93c6b65bb46fb170f9d951eb8a4ec`。
- Passed: `agent.runtime.ensure@1.1` digest 复算为 `sha256:48bb42c3793a3a4e3138d4b2108756addca8c751423d445f3264343b0a8d2d47`。
- Passed: YAML/meta-schema、ACTIVE/RETAINED 唯一性和 `git diff --check`。
- Remaining: release commit/tag/push 与远端 tag 指向核验。

## 推荐下一步

提交当前内容，写入 `spec-v1.23.4` release record，再创建并推送 release commit 与 annotated tag。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
