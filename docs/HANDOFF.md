# OmniMAM Spec Handoff

## Current goal and status

- Goal: 发布 spec-v1.25.4，修复 TCP Endpoint 跨域冲突，供 server 完成 Model Deployment v2。
- Status: 规格修复完成；待创建 annotated tag、Release 元数据并推送。

## Work completed in this session

- 两域 S1/S2 对齐 HTTP/HTTPS/TCP、Endpoint 完整请求、HTTP/TCP 探活组合、READY 门禁与运行快照恢复。
- PROFILE 继续使用固定 Profile 声明；模型部署使用受信 resolver 的固定 Spec Revision。
- 修改两域 product-spec.md、openapi.yaml、module-contract.md、context.md；修改 Infrastructure schema.sql、CHANGELOG.md 和本文件。无新增权限、错误码、事件或运行时实现。

## Verification

- 两域 OpenAPI YAML 解析与本地引用检查通过；协议枚举、请求字段和 SQL 协议约束一致；git diff --check 通过。

## Outstanding tasks and exact next step

- 提交规格并创建 spec-v1.25.4 annotated tag，提交 RELEASE.md 的准确 commit 和用户确认记录，推送分支与 tag，核对远端解引用结果。
- server 必须从远端获取已发布 tag，更新 ssot/ 与 SSOT_VERSION 后才实施。
- 风险：server 的完整生命周期、配置物化、旧数据清理及 make compose 验收尚未完成。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
