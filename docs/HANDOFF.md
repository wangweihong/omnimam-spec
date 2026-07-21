# OmniMAM Spec Handoff

## 当前项目目标

为公开资源响应建立统一的关联资源可读投影规则，并以 Task Center 为首个正式契约切片，使前端无需按 UUID 逐项追加详情请求。

## 本次完成

- 新增全局产品规则 `BR-GLOBAL-001..005`，定义 ID 保留、一跳摘要、权限裁剪、历史快照、跨域所有权与列表查询预算。
- 在 S2 工作流规则中强制所有响应资源 ID 完成“摘要或明确豁免”审查，避免后续契约再次只返回 UUID。
- Task Center 新增 `BR-TASK-128`，OpenAPI 升级为 1.1.0。
- 新增 `AtomicTaskSummary`、`TaskOwnerSummary`、`TaskScheduleSummary`。
- AtomicTask 增加 `root_task`、`retry_of_task`、`owner`；TaskAttempt 增加 `atomic_task`；TaskGroup/DAGTaskGroup 增加 `retry_of`；ScheduleExecution 增加 `schedule`。
- 更新 Task Center module contract 和架构，明确同域批量查询、缺失引用与权限边界。

## 文件变化

- `00_product/global-business-rules.md`
- `00_product/domains/task-center/product-spec.md`
- `01_contracts/domains/task-center/openapi.yaml`
- `01_contracts/domains/task-center/module-contract.md`
- `02_architecture/domains/task-center.md`
- `skills/spec-workflow/S2.md`
- `CHANGELOG.md`
- `docs/HANDOFF.md`

保留用户原有的 `AGENTS.md` 未提交修改，不纳入本次内容提交。

## 关键设计决策

- 原始 ID 仍是稳定引用；摘要只负责可读展示和导航。
- 摘要最多一跳，不嵌套大型输入输出或其他关联摘要。
- 同域关系使用 JOIN 或按类型批量查询；跨域使用事实源只读投影或不可变快照。
- 关联资源不可见或缺失时父资源继续返回，摘要为空且不泄露额外信息。
- 历史运行优先使用创建时保存的非敏感快照。

## API、Schema 与配置变化

- Task Center OpenAPI 从 1.0.0 升级到 1.1.0，属于向后兼容的只读响应字段扩展。
- 未修改 SQL schema、错误码、权限码、事件或运行时配置。

## 验证结果

- 全部 S2 YAML 可解析。
- Task Center OpenAPI 通过 Redocly 校验，0 error；仅有既有 license 与 4XX 规则警告。
- `git diff --check` 通过。

## 待办与风险

- 需要完成 release 记录并创建 `spec-v1.6.0` tag。
- Server 和 Web 必须更新 submodule pin 后再提交正式实现。
- 其他领域仍需按新规则逐项审查已有裸资源 ID；Task Center 是首个切片，不代表全仓审查已经完成。

## 推荐下一任务

发布 `spec-v1.6.0`，更新 Server/Web 的 SSOT pin，完成 Task Center 后端批量摘要与前端详情展示，然后按 application-platform、workflow-canvas、ai-chatting、asset-library、model-management 顺序继续审查。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
