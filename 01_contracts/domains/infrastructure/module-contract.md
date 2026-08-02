# Infrastructure Module Contract

产品语义以 `00_product/domains/infrastructure/product-spec.md` 为准。本合同只覆盖当前 S1 第一阶段单机 Docker 范围；Kubernetes、Edge、Local Process、多节点调度、自动扩缩容和跨 Provider 兼容不属于当前 S2。

## 1. 追溯状态

当前 Infrastructure S1 使用 `US-INFRA-001`、`BR-INFRA-001`、`AC-INFRA-001-01..10` 及 `R-INFRA-*` 规则。OpenAPI、Schema、错误、权限和事件必须同时遵守 Docker-only、请求指纹幂等、受控挂载、output descriptor 和 Endpoint 授权语义。

## 2. 模块边界

| 模块 | 拥有 | 不拥有 |
| --- | --- | --- |
| request | RuntimeProfile、请求校验、requestId 幂等边界 | 用户自定义 Profile、业务任务状态 |
| placement | Docker 单机节点、资源匹配、节点状态 | 多节点调度、业务配额、Task 调度 |
| runtime | InfraRuntime、Job/Service 状态、Provider 运行引用和超时 | AgentRuntime、StudioPreviewRuntime、StudioBuild、StudioRelease |
| mount-config | RuntimeMount、ConfigBinding、SecretRef/ModelAccessSpec 注入状态和 Endpoint 摘要 | Secret 明文、宿主路径、业务 Workspace/Artifact 内容 |
| output | RuntimeOutput 和受控 Artifact 引用 | Artifact/Asset 内容、Blob 生命周期 |
| provider-adapter | DockerRuntimeProvider 的 Provider 调用和对账 | 上层业务数据库、任意 Docker API 暴露 |
| audit-observability | 脱敏运行事件、日志和指标 | 用户业务解释、通知收件箱 |

## 3. 调用边界

- 唯一受信调用链为 `Agent/AppStudio -> Task Center -> Task Worker -> Infra Adapter -> Infra Service -> DockerRuntimeProvider`。
- Infra 写 API 必须验证 `requesting_service=task-center`、`owner_domain`、`owner_reference`、`request_id` 和有效 RuntimeProfile。
- 业务域只提交已注册 functionRef 的业务参数和授权引用；Task Worker/Infra Adapter 负责生成受控 Infra 请求。Infra 不解析 Agent、StudioWorkspace、Snapshot 或 Artifact 私表。
- `source_ref` 只能是来源领域签发的受控引用；不得把它解释为宿主机路径。Coding Agent 不允许 StudioWorkspace 文件系统挂载；Production 只允许固定 Artifact digest，携带 Workspace/Revision/Snapshot 的请求必须拒绝。

## 4. 挂载矩阵

| 运行用途 | 允许输入 | 读写策略 |
| --- | --- | --- |
| AgentRuntime | AgentWorkspace 授权引用；Coding Agent 通过 AppStudio 授权 StudioWorkspace | 按业务授权；不得 Docker Socket |
| Preview | 当前 Workspace Revision | 默认只读；不产生正式 Artifact/Release |
| Build | 固定 StudioSourceSnapshot digest | 只读 |
| Production | 固定 Artifact ID/digest | 只读；禁止 Workspace、Revision、Snapshot |

## 5. 运行、恢复与安全

- Job/Service 使用 `ACCEPTED -> VALIDATING -> SCHEDULING -> PREPARING -> RUNNING -> terminal` 状态；Infra 不生成 Agent、Build、Task 或模型业务状态。
- 取消、停止、超时、重试和进程重启必须依据 requestId、已有 `infra_runtime_id` 和 Provider 引用恢复，不得重复创建运行单元。
- `request_fingerprint` 是 Infra 根据规范化创建请求计算并持久化的内部摘要，不由调用方提交；同一 `requesting_service + request_id` 只有摘要一致时才能重放原结果。
- Secret 只接受 SecretRef，由 Infra 在运行阶段解析并注入；普通 API、事件、日志和输出不得包含凭证、Provider 原始响应、容器 ID、Host Port、宿主路径或私网地址。
- Runtime 事件必须带稳定 Runtime ID、ownerDomain/ownerReference、资源版本和脱敏失败分类；来源领域通过 Task Center/受控 API 对账自己的业务投影。
- RuntimeOutput 只保存 output descriptor、小型状态及 Task Worker 登记后回写的可选 Artifact 引用，不保存媒体正文；Infra 不调用 Artifact 登记接口，Artifact 内容、处理和生命周期归 asset-library。
- `requesting_service + request_id` 是创建幂等作用域；请求摘要不同必须冲突，原失败重试必须使用新的 request_id。
- `USER_ACCESSIBLE` Endpoint 必须校验 owner 与当前授权；`PUBLIC` 第一阶段默认禁用，只有 RuntimeProfile 明确允许、来源领域显式请求并通过审计后才能创建。普通响应不返回 Host Port、私网地址或 Provider Endpoint 原文。

## 6. S1 追溯

主要规则：`R-INFRA-001..018`、`R-INFRA-020`；主要来源章节：运行模型（6）、Profile（7）、对象（8）、请求/Provider（9-10）、资源（11）、挂载（12）、配置（13）、网络/健康/日志（14-16）、状态与恢复（17-23）、第一阶段部署（29）。
