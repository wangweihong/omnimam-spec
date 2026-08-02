# Infrastructure Module Contract

产品语义以 `00_product/domains/infrastructure/product-spec.md` 为准。本合同只覆盖当前 S1 第一阶段单机 Docker 范围；Kubernetes、Edge、Local Process、多节点调度、自动扩缩容和跨 Provider 兼容不属于当前 S2。

## 1. 追溯状态

当前 Infrastructure S1 只有 `R-INFRA-*` 强制规则和章节语义，没有标准 `US-*`/`BR-*` 编号。契约中的 `user_stories` 保持为空，规则引用使用真实 `R-INFRA-*` 和 `source_sections`。补齐标准编号是 Release 前置任务。

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
- `source_ref` 只能是来源领域签发的受控引用；不得把它解释为宿主机路径。Production 只允许固定 Artifact digest，携带 Workspace/Revision/Snapshot 的请求必须拒绝。

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
- Secret 只接受 SecretRef，由 Infra 在运行阶段解析并注入；普通 API、事件、日志和输出不得包含凭证、Provider 原始响应、容器 ID、Host Port、宿主路径或私网地址。
- Runtime 事件必须带稳定 Runtime ID、ownerDomain/ownerReference、资源版本和脱敏失败分类；来源领域通过 Task Center/受控 API 对账自己的业务投影。
- RuntimeOutput 只保存受控 Artifact 引用或小型状态，不保存媒体正文；Artifact 内容、处理和生命周期归 asset-library。

## 6. S1 追溯

主要规则：`R-INFRA-001..018`、`R-INFRA-020`；主要来源章节：运行模型（6）、Profile（7）、对象（8）、请求/Provider（9-10）、资源（11）、挂载（12）、配置（13）、网络/健康/日志（14-16）、状态与恢复（17-23）、第一阶段部署（29）。
