# OmniMAM Spec Handoff

## 当前项目目标

发布 ApplicationEngineInstance 同名冲突专用错误契约，避免唯一索引冲突误报为鉴权配置错误。

## 本次完成

1. `BR-AIAPP-140` 明确 ApplicationEngineInstance 名称全局唯一，创建或重命名为已有名称时必须拒绝。
2. 新增 engine 模块错误 `ERR_AIAPP_ENGINE_INSTANCE_NAME_DUPLICATED`，数值 `130429`，HTTP 200，不可重试。
3. 错误码追溯到现有 `BR-AIAPP-140` 与 `US-AIAPP-041`，不复用鉴权、资源版本或其他领域错误。
4. 规格变更提交为 `d0c773a`，`spec-v1.7.10` 已发布并允许作为正式实现依据。

## 文件变化

- `00_product/domains/application-platform/product-spec.md`
- `01_contracts/domains/application-platform/errors.yaml`
- `CHANGELOG.md`
- `RELEASE.md`
- `docs/HANDOFF.md`

## 关键设计决策

- 名称冲突是独立业务失败，不能映射为 `ERR_AIAPP_ENGINE_AUTH_CONFIG_INVALID`。
- 现有 `idx_aiapp_engine_instances_name` 已保证数据库层全局唯一，本次不修改 API 或 schema。

## API、Schema 与配置变化

- 新增 `ERR_AIAPP_ENGINE_INSTANCE_NAME_DUPLICATED`（`130429`）。
- 无 API、schema、权限、事件或运行时配置变化。

## 待办与风险

- omnimam-server 必须 pin `spec-v1.7.10`，生成错误码注册表，并修复 EngineInstance 创建和更新映射。

## 推荐下一任务

在 omnimam-server pin `spec-v1.7.10` 并实现创建、更新同名错误映射。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
