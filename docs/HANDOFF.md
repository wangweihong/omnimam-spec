# OmniMAM Spec Handoff

## 当前项目目标

发布 ComfyUI WorkflowTestRun 输入覆盖与输出候选选择契约，使临时预览只采集用户所选输出节点。

## 本次完成

1. 扩展 `BR-AIAPP-167..168` 和 `AC-AIAPP-048-01/04/05`，明确输入参数与输出候选的校验、快照和历史回填语义。
2. 试运行输出候选沿用应用模板的 `node_id + output_index` 身份，至少选择一项。
3. `collect_preview` 将输出选择按 `node_id` 归并，只收集所选节点的图片/文本轻量描述。
4. 保持临时预览边界，不登记 Artifact/Asset，不保存媒体正文。
5. Application Platform OpenAPI 升级为 1.3.0，并增加输出选择请求与详情快照 DTO。
6. 设计态试运行表增加 `output_snapshot_json`；权限、事件和错误码编号不变。
7. 规格变更提交为 `3e166a5`，`spec-v1.7.5` release 记录与标签已创建。
8. 保留用户原有 `AGENTS.md` 修改，不纳入本任务提交。

## 文件变化

- `00_product/domains/application-platform/product-spec.md`
- `01_contracts/domains/application-platform/openapi.yaml`
- `01_contracts/domains/application-platform/schema.sql`
- `01_contracts/domains/application-platform/errors.yaml`
- `01_contracts/domains/application-platform/module-contract.md`
- `02_architecture/domains/application-platform.md`
- `CHANGELOG.md`
- `RELEASE.md`
- `docs/HANDOFF.md`

## 关键设计决策

- 输出选择与应用模板输出映射复用相同稳定身份，但试运行只按 node_id 过滤 ComfyUI history，不产生标准应用制品。
- 输出选择必须持久化，因为 collect_preview 在异步 DAG 的第三步执行，不能依赖前端临时状态。
- 同节点选择多个输出端口时只收集一次该节点的 history 结果。
- 旧试运行记录允许输出快照为空；新创建请求必须至少选择一个当前可解析输出候选。

## API、Schema 与配置变化

- `ComfyUIWorkflowTestRunCreateRequest` 新增必填 `outputs`。
- 新增 `ComfyUIWorkflowTestOutputSelection`。
- `ComfyUIWorkflowTestRunDetail` 新增可空 `output_snapshot`。
- `aiapp_comfyui_workflow_test_runs` 新增 `output_snapshot_json TEXT NOT NULL DEFAULT '[]'`。
- 无新 endpoint、权限、事件、错误码编号或运行时配置。

## 待办与风险

- Server 需要更新 SSOT pin，增加运行态列、请求校验、幂等比较、输出快照持久化和 collect_preview 过滤。
- Web 需要更新 SSOT pin 和生成客户端，在试运行画布中分别选择输入覆盖与输出候选，并支持历史回填。
- `master` 与 `spec-v1.7.5` 标签尚未推送到远端；Server/Web 本地实施可先 pin 当前 release commit。

## 推荐下一任务

在 Server/Web pin `spec-v1.7.5` 并实施输出选择快照与筛选。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
