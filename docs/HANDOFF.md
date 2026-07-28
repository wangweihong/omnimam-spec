# OmniMAM Spec Handoff

## 当前项目目标

以 `spec-v1.7.14` 消除 Canvas ApplicationVersion 到 ApplicationRun、AtomicTask 与 Artifact 输出之间的运行边界歧义。

## 本次完成

1. 规范内部 functionRef 为 `application-platform.run`。
2. 明确 Canvas 只创建 DAG 内唯一 AtomicTask，Worker 在 Conductor 解析最终输入后幂等创建并绑定 ApplicationRun。
3. 明确目录、发布和运行通过 Application Platform 受控接口复核可见性、开关、schema 与 Engine/runtime。
4. 扩展 `application_version_published` 与 ApplicationRun Artifact 引用消费契约，闭合 NodeDefinition 登记和 Canvas 输出投影。

## 文件变化

- `00_product/domains/application-platform/product-spec.md`
- `00_product/domains/workflow-canvas/product-spec.md`
- `00_product/domains/sse/product-spec.md`
- `01_contracts/domains/application-platform/events.yaml`
- `01_contracts/domains/application-platform/module-contract.md`
- `01_contracts/domains/workflow-canvas/module-contract.md`
- `01_contracts/domains/task-center/module-contract.md`
- `02_architecture/domains/application-platform.md`
- `02_architecture/domains/workflow-canvas.md`
- `CHANGELOG.md`
- `RELEASE.md`
- `docs/HANDOFF.md`

## 关键设计决策

- Canvas ApplicationRun 的稳定来源键是 owner + `canvas_run_id + execution_key`。
- Application Platform 绑定既有 DAG AtomicTask，不调用任务创建接口。
- 发布事件负责目录登记，事件投影不替代实时可用性校验。
- Canvas 输出按 AtomicTask、output key、sequence 与 Artifact resource version 单调投影。

## API、Schema 与配置变化

- 公共 OpenAPI、SQL schema、错误码、权限码和配置不变。
- Application Platform 事件 payload 与跨域内部模块契约扩展。

## 待办与风险

- omnimam-server pin `spec-v1.7.14` 并实现完整运行、事件和输出投影链路。
- omnimam-web pin 同一版本；如公共 API 不变则无需 UI 代码变化。
- 使用真实 Conductor/Worker/Provider 验证重试、重启和上游连线输入。

## 推荐下一任务

在 omnimam-server 实现失败测试、既有 AtomicTask 绑定、发布消费者、Artifact 输出投影和恢复测试。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
