# 工作流画布领域架构参考

## 1. 事实源状态

当前仓库尚无 `00_product/domains/workflow-canvas/product-spec.md`，S2 目录中的 OpenAPI、错误码、权限码、事件和模块契约为空。

`01_contracts/domains/workflow-canvas/schema.sql` 已明确说明：因缺少 S1 产品事实源，暂不凭空定义业务表。

## 2. 架构定位

本领域只能作为后续画布能力的架构占位，不应作为实现依据。

可能涉及的方向包括：

- 工作流画布定义、节点、边和运行参数。
- 画布输出与 `asset-library` 的输出资产登记。
- 与 `task-center` 的任务运行和状态追踪协作。
- 与 `application-platform` 的模板或应用配置协作。

上述内容均需先补 S1 产品语义，再补 S2 契约。

## 3. 禁止事项

- 不在架构文档中直接定义业务表、API、错误码或权限码。
- 不把现有空 S2 文件解释为“无契约需求”。
- 不绕过 S1 直接从前端原型或实现代码反推正式契约。

## 4. 后续补齐顺序

1. 新增 `00_product/domains/workflow-canvas/product-spec.md`，明确核心业务对象、业务规则、用户故事和验收标准。
2. 基于 S1 生成 `01_contracts/domains/workflow-canvas/` 下的 OpenAPI、schema、错误码、权限码、事件和模块契约。
3. 再更新本架构文档，补充真实模块边界、跨域依赖和运行链路。
