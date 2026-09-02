# Workflow Canvas 模块契约

## 1. 职责

Workflow Canvas 拥有 Canvas 草稿、不可变 CanvasVersion、Node/Edge/Flow、TargetBinding、运行范围、ExecutionPlan、CanvasRun/FlowRun/NodeRun 与 Task/输出绑定投影。

它不拥有 ApplicationVersion、ProviderAccount/Resource、ProviderExecutionGrant、AtomicTask 状态机或 Artifact 生命周期。

相关 S1：`US-WORKFLOW-001..011`、`BR-WORKFLOW-001..052`。

## 2. NodeDefinition 与 LLM

- NodeDefinition 只允许 passive、compile_time、atomic、expanded 受控绑定。
- ApplicationNode 固定已发布 ApplicationVersion，编译为唯一 `application-platform.run` functionRef。
- `system.llm.text-generation@1.0.0` 通过 `application_version_published` 注册为普通 ApplicationNode，renderer=`application.llm`。
- 禁止新增 ModelNode、模型专用 functionRef、任意 Provider HTTP 或脚本执行类型。

## 3. TargetBinding

ApplicationNode 配置使用：

```text
FIXED: provider_account_id + provider_resource_id?
DEFAULT: 不携带账号 ID
REQUEST: 不携带账号 ID，运行请求补全
```

发布必须通过 Application Platform 消费方接口验证 binding 被固定 ApplicationVersion policy 允许。

- PRIVATE Canvas 只允许固定创建者自己的 USER 账号或有权使用的 PLATFORM 账号。
- PROJECT Canvas 禁止固定 USER 账号；允许固定有权使用的 PLATFORM 账号。
- DEFAULT/REQUEST 不得把当前用户账号写入 CanvasVersion。
- CanvasVersion 冻结 policy 快照和 binding，不冻结账号健康、凭证、Grant、配置或资源当前事实。

## 4. CanvasRun 目标选择

`node_target_selections` 是对象数组，每项包含 `node_id`、`provider_account_id` 和按 policy 要求的 `provider_resource_id`。

运行预检必须：

1. 根据 scope 确定进入本次运行的节点；
2. 只接受其中 `target_binding.source=REQUEST` 的 ApplicationNode；
3. 拒绝重复 node_id、范围外节点、非 REQUEST 节点和多余字段；
4. 拒绝任何缺少选择的 REQUEST 节点；
5. 通过 Application Platform/Gateway 重新校验 owner、project、namespace、account scope、ProviderType、ResourceKind、能力与健康；
6. 在 DAGTaskGroup 创建前固定选择快照与请求摘要。

目标不可用时不跨 USER/PLATFORM 回退。

## 5. 编译与 Task Center

Canvas 发布先确定性编译完整 DAG template，再注册内容寻址的不可变 workflow definition。运行时按 scope、输入、TargetSelection 与复用策略裁剪为唯一 ExecutionPlan。

Task arguments 只允许非敏感 TargetSelection ID、ApplicationVersion、CanvasRun/NodeRun/execution_key 和输入映射；禁止 endpoint、credential、Header、Provider 私有配置、Grant 或 Grant 解析结果。

Conductor 解析最终输入后调用 Application Platform `EnsureCanvasApplicationRun`。Application Platform 使用已存在 AtomicTask 创建幂等 ApplicationRun 并向 Gateway 请求 Grant；Canvas 不接触 Grant。

## 6. 执行指纹与复用

ApplicationNode execution fingerprint 必须包含：

```text
target_selection_source
account_scope
provider_account_id
provider_account_config_version
provider_resource_id / provider_resource_revision
provider_capability_revision
```

账号、资源或修订变化使旧输出失去复用资格。凭证与 Grant 不进入指纹；需要敏感变化语义时只使用 Gateway 的非敏感版本号。

REUSED NodeRun 不创建伪造 AtomicTask，必须继续校验 project/namespace/权限、来源终态、输出完整性和 Artifact/结构化值可用性。

## 7. 输出

- ApplicationRun `output_values` 的文本/JSON 结果可直接绑定 Canvas string/json 端口。
- 媒体结果使用 Asset Library ArtifactReference。
- CanvasNodeRun 成功必须满足全部必需结构化输出已持久化且必需 Artifact 达到端口要求。
- `application_run_projection_changed` 驱动结构化值；`application_run_artifact_ref_changed` 驱动媒体引用，两者不能互相推断。

## 8. 数据所有权

CanvasVersion 保存 `target_policy_snapshots_json`；CanvasRun 保存 `node_target_selections_json`；CanvasNodeRun 保存非敏感 Provider 目标快照与执行指纹字段。所有 Provider ID 都是跨域稳定引用，不建立 Gateway 私表外键。

Canvas、CanvasVersion、CanvasRun 和 NodeRun 响应使用创建时非敏感快照与有界一跳摘要，列表禁止跨服务 N+1。

## 9. 权限

草稿保存、发布和运行都校验 project、namespace、created_by、visibility 与引用资源权限。拥有 Provider ID 不代表可固定或可执行；Gateway 是 Provider 可见性与资格事实源。

## 10. 事件

Canvas 事件使用 outbox 至少一次投递并按 aggregate_version 单调投影。事件可以携带目标选择数量/摘要与非敏感修订，不得携带 endpoint、credential、Header、Provider 私有配置、Grant 或解析结果。

## 11. 非职责

- Application、ApplicationVersion、ProviderAccount、ProviderResource 或 Model Preference 当前事实。
- Provider 协议、认证、提交、轮询、取消、下载和结果解析。
- AtomicTask/Attempt/DAGTaskGroup 状态机或 Artifact/Asset 生命周期。
- ModelNode 或旧 Engine 兼容执行路径。
