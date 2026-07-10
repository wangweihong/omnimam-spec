# Application Platform Module Contract

本契约实现 `product-spec.md` v0.5.0-draft 的第一阶段边界。

## 1. 模块边界

| 模块 | 职责 | 非职责 | S1 引用 |
| --- | --- | --- | --- |
| adapter-catalog | 只读列出系统注册 Adapter/Operation 和版本化端口 schema | 不接受用户代码上传，不保存用户运行实例 | US-AIAPP-001；BR-AIAPP-001..005 |
| template | 解析 ComfyUI/SaaS 工作流，维护能力图、依赖和引用关系 | 不执行真实测试，不承载 direct SaaS 操作 | US-AIAPP-002；BR-AIAPP-006..012 |
| application | 从模板或 direct Operation 创建应用，整体保存输入输出映射与固化参数 | 不实现审核、发布或公共市场 | US-AIAPP-003..005；BR-AIAPP-013..020 |
| app-engine | 管理运行实例、明文认证配置、健康、能力快照和并发槽位 | 不实现平台调用方法或基础设施供给 | US-AIAPP-006、007；BR-AIAPP-021..033 |
| engine-router | 查询匹配引擎，重新校验并原子占用/释放槽位 | 不改变 Application 固定绑定 | US-AIAPP-007；BR-AIAPP-023..033 |
| application-run | 创建测试/正式 AppRun 和 TaskRun，投影 TaskRun 状态与标准输出 | 不维护独立执行状态机 | US-AIAPP-008..011；BR-AIAPP-034..046 |
| access | 校验资源管理权、引擎使用权和运行可见范围 | 管理权不自动授予凭证使用权 | US-AIAPP-012；BR-AIAPP-047..049 |

## 2. ProviderAdapter 执行契约

ProviderAdapter 通过代码注册 Manifest 暴露 `describeOperation`、`validatePayload`、`healthCheck`、`submit`、`poll`、`cancel`、`collectResult`、`normalizeError`。Worker 调用 Adapter，Adapter 使用 AppEngine endpoint 和认证配置访问平台。

异步 Adapter 的 `submit` 返回 external_job_id；重试时 Worker 必须先通过 `poll` 或 `collectResult` 恢复已有外部任务。Adapter 输出必须转换为 ApplicationOutputValue，不能把第三方原始大对象直接写入 TaskRun。

## 3. 一致性要求

- template 来源必须有 template_id，provider_operation 来源不得有 template_id。
- InputMapping 与 fixed_parameters 不得覆盖同一路径；OutputMapping 最多一个主输出。
- 可用引擎查询无匹配项时返回空数组；运行提交必须重新校验并占用槽位。
- 指定引擎不可用时不回退；自动模式无可用引擎按可重试错误处理。
- AppRun 只接受更大的 task_resource_version，TaskRun 是执行状态唯一事实源。
- 运行完成、取消或提交前失败必须释放引擎槽位。
- 大型 image、video、audio、file 输出只保存 asset、storage 或 external 引用。

## 4. 跨域依赖

- 依赖 task-center 创建 TaskRun、Worker/Lease 执行、重试、external_job_id 和版本化状态事件。
- 依赖 asset-library 保存需要素材化的大型输入输出。
- 依赖 identity 提供当前用户、管理员角色和资源权限。
- task-center 不解释 Adapter、Operation、AppEngine 认证或输出映射语义。

## 5. 事件边界

生产 adapter_catalog_changed、app_template_changed、application_changed、application_mapping_changed、app_engine_changed、app_engine_health_changed、application_run_created、application_run_projection_changed。

消费 task_run_status_changed、task_run_progress_updated。消费方必须按 task_run_id 和 resource_version 幂等投影。

## 6. 非目标范围

不包含审核上架、公共市场、Webhook、EngineClass/Claim/Provision、云资源供给、复杂成本路由、独立 Secret Vault 或用户上传 Adapter 代码。
