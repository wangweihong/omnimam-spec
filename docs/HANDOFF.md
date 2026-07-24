# OmniMAM Spec Handoff

## 当前项目目标

发布 ComfyUI 系统内置 ProviderCapability 与 required_immutable 默认绑定契约，同时保持 workflow contract 作为具体 ComfyUI 能力事实源。

## 本次完成

1. ProviderCapability 增加 `kind`、只读 `origin` 和 `binding_policy` 三个正交维度。
2. 新增 `comfyui-workflow-runtime` 内置 engine_binding 清单，不声明虚构 model、operation 或 variant。
3. 定义所有现有及新建 comfyui EngineInstance 必须具有唯一系统绑定；新建实例与绑定原子提交，启动时幂等回填并支持多副本收敛。
4. 系统绑定固定 enabled、空 restrictions、当前内置 revision，不能由管理员创建、更新、禁用或删除。
5. 外部目录不能覆盖内置保留 ID；目录失败只使 registry degraded，内置能力继续可用。
6. EngineCapabilityBinding 响应增加只读 `system_managed`，绑定外键调整为 `ON DELETE CASCADE`。
7. Application Platform OpenAPI 升级为 1.5.0，新增三个稳定业务错误。

## 文件变化

- `00_product/domains/application-platform/product-spec.md`
- `01_contracts/domains/application-platform/openapi.yaml`
- `01_contracts/domains/application-platform/schema.sql`
- `01_contracts/domains/application-platform/errors.yaml`
- `01_contracts/domains/application-platform/module-contract.md`
- `01_contracts/domains/application-platform/provider-capabilities/provider-capability.schema.yaml`
- `01_contracts/domains/application-platform/provider-capabilities/comfyui.yaml`
- `01_contracts/domains/application-platform/provider-capabilities/deepseek.yaml`
- `01_contracts/domains/application-platform/provider-capabilities/seedance.yaml`
- `02_architecture/domains/application-platform.md`
- `CHANGELOG.md`
- `docs/HANDOFF.md`

## 关键设计决策

- `kind` 描述能力用途，`origin` 描述加载来源，`binding_policy` 描述绑定生命周期，三者不能互相替代。
- ComfyUI 固定为 `engine_binding + builtin + required_immutable`；DeepSeek、Seedance 固定为 `catalog + directory + manual`。
- 系统绑定是实例身份与管理投影，不参与 Provider 模板、Variant 或 OperationExecutor 路径。
- ComfyUI API Workflow、workflow contract 和目标实例当前 object_info 继续拥有具体模板与运行能力事实。

## API、Schema 与配置变化

- ProviderCapability 响应新增 `kind`、`origin`、`binding_policy`。
- EngineCapabilityBinding 响应新增只读 `system_managed`。
- 新增 `ERR_AIAPP_PROVIDER_CAPABILITY_ID_RESERVED`、`ERR_AIAPP_SYSTEM_ENGINE_BINDING_IMMUTABLE`、`ERR_AIAPP_REQUIRED_ENGINE_BINDING_FAILED`。
- `aiapp_engine_capability_bindings.engine_instance_id` 外键使用 `ON DELETE CASCADE`。
- 不新增 endpoint、权限码、事件或运行时配置。

## 待办与风险

- 规格尚未提交、记录 release、打 tag 或推送。
- Server 必须在 pin 新 release 后实现 embedded loader、原子创建、启动 reconcile、不可变保护和实际外键 migration。
- Web 如展示绑定操作，需要根据 `system_managed` 隐藏或禁用编辑、禁用和删除动作。

## 推荐下一任务

完成规格校验并发布 `spec-v1.7.8`，随后在 omnimam-server 更新 submodule pin 并实现后端契约。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
