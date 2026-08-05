# OmniMAM Spec Handoff

## 当前目标与状态

- 当前目标：补齐 AgentRuntimeAdapter 调用 Hermes 的受控 Endpoint 解析，以及 Docker Job 实际输出字节到 Asset Library Artifact 的可信交付链路。
- 状态：发布中。规格内容提交 `64435e32db213bf4483d057039036375ee545183` 已创建；`spec-v1.17.2` Release 元数据已写入且定向复验通过，待提交和创建 annotated tag。
- 目标 Release：`spec-v1.17.2`；`RELEASE.md` 必须继续指向上述规格内容提交，而不是后续 Release 元数据提交。

## 本次已完成

- 已读取 `skills/spec-workflow/SKILL.md`、`S1.md`、`S2.md` 和任务指定的仓库规则。
- 已确认工作树仅有原有未跟踪内容：`archive/`、`docs/identity_fix.md`、`设计图/`；这些内容不在本任务范围内。
- 已锁定跨域决策：AgentRuntimeAdapter 仅可直接调用 Infrastructure 的只读 Endpoint resolve；Runtime 生命周期写操作仍由 Task Center 编排。
- 已锁定输出决策：Docker Provider 收集实际字节并生成 `infra-output://` 可信引用，Task Worker 流式读取后通过 Asset Library 既有上传流程完成 Artifact。
- 已更新 Infrastructure S1：补充 RuntimeProfile 命名 Endpoint/输出声明、Docker 内部端口发布、READY 门禁、实际字节收集、staging、受控内容读取与 Artifact 回链，并将 `R-INFRA-002` 收敛为生命周期写操作规则。
- 已更新 Agent S1：补充 AgentRuntimeAdapter 在完整业务绑定校验后的只读 Endpoint resolve 与 Hermes/OpenCode 同步调用链，新增地址不持久化规则。
- 已完成 Infrastructure OpenAPI、设计态 Schema、错误、权限、事件和模块合同，新增 Endpoint resolve、RuntimeOutput 内容读取与 Artifact 回链合同。
- 已完成 Agent、Task Center、Asset Library 跨域模块合同与 Task Center Function Registry；`appstudio.build.execute@1.1` 为 ACTIVE，`1.0` 为 RETAINED 且历史 digest 未改写。
- 已复算 Function Registry digest：生命周期 `status` 在摘要输入中规范化为 `ACTIVE`，使 RETAINED 历史合同仍可按原摘要验证；`appstudio.build.execute@1.1` digest 为 `sha256:8e2738acd06cdebbd7569be888aacb1b95d06ab154326dbbb969d0efea09e82e`。
- 已同步 Infrastructure 架构参考，明确生命周期写链路、AgentRuntimeAdapter 只读解析例外、命名端口 READY 门禁和 RuntimeOutput 到 Artifact 的流式交付链路。
- 已同步 Infrastructure、Agent、Task Center、Asset Library Domain Context、`GLOBAL_CONTEXT.md` 与 `CHANGELOG.md`；`CONTEXT_MAP.md` 无导航变化，未修改；`RELEASE.md` 未修改。
- 最终人工审阅已统一 Endpoint/Runtime 可解析状态为 Endpoint `READY`、Runtime `RUNNING` 且健康，并修正 Agent 合同字段名和排版。
- 已收敛设计态 SQL：仅 Endpoint `READY` 时强制存在私有发布地址；RuntimeOutput 在 Artifact 回链后允许清除 staging 引用，且 `artifact_id` 与 `artifact_attached_at` 必须成对出现。
- 已在 Infrastructure OpenAPI 明确 Endpoint resolve、内容读取和 Artifact 回链的稳定错误码映射；OpenAPI 与 Function Registry schema 均结构化拒绝绝对输出路径和 `..` 路径段。
- 已创建规格内容提交 `64435e32db213bf4483d057039036375ee545183`，提交信息为 `spec: close Hermes endpoint and runtime output contracts`。
- 已将 Agent/Infrastructure S1、Infrastructure S2、四域 Context、`GLOBAL_CONTEXT.md` 与 `CHANGELOG.md` 切换为 `spec-v1.17.2` 已发布状态，并在 `RELEASE.md` 新增用户确认记录。

## 当前进行中

- 提交 Release 元数据并创建 `spec-v1.17.2` annotated tag。

## 文件变化

- 已修改：`docs/HANDOFF.md`、Agent/Infrastructure S1、Infrastructure 六类 S2、Agent/Task Center/Asset Library 模块合同、Task Center function registry 及其 schema。
- 已修改：Infrastructure 架构、Infrastructure/Agent/Task Center/Asset Library Context、`GLOBAL_CONTEXT.md`、`CHANGELOG.md`。
- 发布阶段已修改：`RELEASE.md`、相关 S1/S2 发布状态、Context、`GLOBAL_CONTEXT.md`、`CHANGELOG.md` 和本文件。
- 明确不修改：正式实现代码、数据库 migration、运行时配置、无关领域和原有未跟踪内容。

## 关键决定

- Endpoint 普通摘要继续隐藏真实地址；新增受工作负载身份和 owner 约束的短时只读解析响应。
- Docker Service 只发布 RuntimeProfile Revision 声明的命名端口，并绑定平台内部接口。
- RuntimeOutput 只有在受控输出根内读取实际普通文件、计算大小与 SHA-256、复制至 Infra staging 后才可进入 `COLLECTED`。
- `infra-output://<output_id>` 是非 bearer 受控引用，不是文件路径、Docker Volume 地址或任意外部 URL。
- `appstudio.build.execute` 新增 `1.1` ACTIVE，保留 `1.0` RETAINED，不改写历史 digest。

## API、Schema、依赖或配置变化

- 已新增 `POST /api/v1/infra/endpoints/{endpoint_id}/resolve`。
- 已新增 `GET /api/v1/infra/runtime-outputs/{output_id}/content` 和幂等 `POST /api/v1/infra/runtime-outputs/{output_id}/attach-artifact`。
- 已扩展 `infra_runtime_endpoints`、`CreateRuntimeRequest`、`RuntimeOutput` 和 `infra_runtime_output_changed`。
- 不新增运行时依赖或配置实现。

## 验证与风险

- 6 个受影响 YAML 文件解析通过；Infrastructure OpenAPI 的 79 个本地 `$ref`、18 个唯一 `operationId` 和 18 个权限引用通过。
- Endpoint 普通摘要敏感字段、resolve 状态/错误映射、RuntimeOutput 字段和输出路径约束检查通过。
- Infrastructure 17 个错误码 code/value 唯一且落在登记区间；新增 `240804..240807` 与 RuntimeOutput 事件保密检查通过。
- Function Registry 通过 Draft 2020-12 schema；7 个 functionRef 各有且仅有一个 ACTIVE，8 个合同 digest 全部复算一致。
- 47 个直接相关 S1 引用存在；Agent/Task 公共 OpenAPI 和事件未出现 `base_url`、Host Port、私网地址或 `infra-output://`。
- SQL 的 8 个设计态表、括号/终止结构、Endpoint READY 门禁、RuntimeOutput digest/content_ref/staging/attach 门禁通过定向静态检查。
- Release 阶段复验通过：6 个 YAML、Function Registry Draft 2020-12 schema、79 个 Infrastructure OpenAPI 本地 `$ref`、18 个唯一 `operationId`、18 个权限引用、17 个错误码、7 个 functionRef 的 ACTIVE 唯一性和 8 个合同 digest。
- Release 阶段复验通过：57 个直接 S1 引用、Endpoint/RuntimeOutput 地址保密、8 个设计态表及 Endpoint READY、RuntimeOutput digest/content_ref/staging/attach 门禁。
- `git diff --check` 通过；`RELEASE.md` 精确指向规格内容提交 `64435e32db213bf4483d057039036375ee545183`；`CONTEXT_MAP.md` 无 diff。
- 环境没有 `psql`、`pglast`、`sqlglot` 或 `sqlparse`，因此未执行 PostgreSQL parser 级验证；本仓库任务范围也不包含 Docker Provider 实现或数据库 migration。
- 按约束未运行全仓测试，也未读取或修改无关模块和原有未跟踪内容。

## 未完成事项

- 本轮规格实施无未完成项。
- 用户已明确确认发布；待完成 Release 元数据提交和 `spec-v1.17.2` tag。

## 推荐下一步

- 提交 Release 元数据，然后在该提交上创建 annotated tag `spec-v1.17.2`。

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
