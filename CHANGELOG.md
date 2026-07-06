# Changelog

## 2026-07-06

- 基于当前 S1 生成 `ai-chatting` 和 `model-management` S2 契约，新增 OpenAPI、设计态 SQL schema、错误码、权限码、事件和模块边界，并登记全局错误码区间。
- 收敛 `ai-chatting` 模型来源语义，明确 AI 聊天只读取 `model-management` 中当前用户自己的模型设置，不维护独立模型配置或模型清单。
- 收敛 S2 HTTP 状态码规则，仅允许 `200`、`404`、`500` 和真实重定向 `3xx`，业务成功或失败统一通过 `code` / `value` 判断。
- 同步将 `application-platform` 与 `task-center` 现有业务错误码契约改为 HTTP `200`，避免继续使用 `400`、`403`、`409` 表达业务错误。
- 收敛 `application-platform` 第一阶段 S1 产品规格，仅保留模板管理、应用管理和参数/字段映射能力。
- 将 `EngineClaim`、`EngineProvision`、Webhook、应用审核上架、公共应用/应用市场、执行、任务、订单、结果回调、引擎和基础设施编排等机制移出第一阶段事实源，并归档至 `00_product/domains/application-platform/plan-archive.md`。
- 同步收敛 `application-platform` S2 契约，更新 OpenAPI、设计态 SQL schema、错误码、权限码、事件、模块边界和错误码索引，避免 S1/S2 冲突。
- 基于 `task-center` S1 生成任务中心 S2 契约草稿，新增 OpenAPI、设计态 SQL schema、错误码、权限码、事件和模块边界文档，并登记全局错误码区间。
- 为 `task-center` S1 用户故事和核心业务规则补充稳定追溯编号，便于 S2 契约引用。

## 2026-07-05

- 调整 `application-platform` S1 产品规格中的角色语义，移除 `业务使用者`、`外部系统`、`应用创建者`、`平台管理员` 等旧角色表达，统一收敛为 `普通用户` 和 `系统管理员`。
- 更新 `application-platform` 功能适配矩阵、用户故事、业务规则、系统呈现策略和待确认问题，避免旧四角色模型继续作为产品事实源。
- 基于收敛后的 `application-platform` S1 生成 S2 契约草稿，新增 OpenAPI、设计态 SQL schema、错误码、权限码、事件和模块边界文档，并登记全局错误码区间。
