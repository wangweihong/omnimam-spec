# GitLab Domain 产品规格

## 1. 定位与目标

`gitlab` 是 OmniMAM 管理 GitLab 连接、远端项目投影和通用 Pipeline 执行的独立领域。第一阶段只面向平台管理员提供连接与项目管理，并通过 Task Center 执行可恢复的 GitLab Pipeline AtomicTask。

本领域不属于 AppStudio。AppStudio 的 StudioApplication、源码 Repository、Revision、Build、Preview 和 Release 事实保持不变；后续阶段如需关联，只能通过稳定的 GitLabProject ID 和受控模块接口协作。

## 2. 核心对象

### 2.1 GitLabServer

GitLabServer 表示一个由 OmniMAM 管理的 GitLab API 连接，包含：

- 管理员可识别的名称和描述；
- OmniMAM Server 实际调用的 API URL；
- 供用户跳转和展示 clone 地址的 External URL；
- 新建项目固定归属的 Namespace Path；
- 仅服务端持有的 Personal Access Token；
- 最近一次连接检测状态、时间和脱敏错误。

连接状态为 `UNKNOWN`、`READY` 或 `ERROR`。新建连接为 `UNKNOWN`；API URL、Namespace Path 或 credential 改变时必须重置为 `UNKNOWN`。External URL 或纯展示元数据变化不改变已验证连接状态。

Credential 是敏感值。创建和更新请求可以提交 credential，但任何列表、详情、测试响应、错误、日志、事件或任务输入输出都不得返回该值。

### 2.2 GitLabProject

GitLabProject 是 GitLab 远端 Project 的本地受控投影，保存：

- 所属 GitLabServer ID；
- GitLab numeric project ID；
- name、path、path_with_namespace；
- Web URL、HTTP/SSH clone URL；
- GitLab 返回的 default branch。

本地 ID 是 OmniMAM 的稳定身份。其他领域如后续需要引用，只能保存本地 GitLabProject ID，不得直接以 GitLab numeric ID、URL 或 PAT 建立跨域关系。

### 2.3 GitLab Pipeline AtomicTask

`gitlab.pipeline.run` 是 Task Center 注册的非 Infra-backed 外部 AtomicTask。输入只包含 GitLabProject ID、ref 和可选 variables；Worker 必须从 GitLabProject 和 GitLabServer 解析远端 ID、API URL 与 credential。

Pipeline ID 保存为 TaskAttempt 的 `external_job_id`。Worker 首次调用创建 Pipeline，后续延迟回调、自动重试和进程恢复必须查询同一 Pipeline，不得重复提交。运行中的 Pipeline 使用 `IN_PROGRESS` 和延迟回调，不长期占用 Worker。

## 3. 角色与访问边界

- `ADMIN` 和 `SUPER_ADMIN` 可以查询、创建、修改、测试和删除 GitLabServer，并管理 GitLabProject。
- `USER` 第一阶段没有 GitLab 管理入口，也不能直接创建 `gitlab.pipeline.run`。
- 所有 API 都必须经过 Identity 权限校验；不得仅依赖前端隐藏入口。
- 删除仍有关联 GitLabProject 的 GitLabServer 必须失败，禁止级联删除远端项目或本地投影。

## 4. 连接管理规则

1. 创建 GitLabServer 不隐式执行连接检测。
2. Test 动作依次验证 GitLab `/version` 和当前用户 `/user`，并确认 Namespace Path 可解析且当前 PAT 可以访问该 Namespace。
3. 检测成功写入 `READY`、检查时间并清空错误；检测失败写入 `ERROR`、检查时间和脱敏错误。
4. Test 动作本身完成时返回更新后的 GitLabServer，即使结果为 `ERROR`；只有持久化或不可恢复内部故障返回业务错误。
5. Credential 更新请求省略 credential 时必须保留原值；不得使用响应中的掩码值反向覆盖真实 credential。

## 5. Project 管理规则

1. 只有状态为 `READY` 的 GitLabServer 可以创建远端 Project。
2. Namespace 必须由 GitLabServer 的 Namespace Path 解析，客户端不能在创建请求中覆盖 namespace ID 或 path。
3. 新项目固定为 private；name/path 来自受校验请求，其他投影字段使用 GitLab 实际响应。
4. 远端创建成功但本地投影写入失败时，服务必须尽力删除刚创建的远端 Project；补偿失败需记录脱敏诊断并返回稳定业务错误。
5. 删除 GitLabProject 时先删除远端 Project；远端返回 404 视为已达到目标状态，随后删除本地投影。
6. 其他远端失败不得删除本地投影，便于管理员重试和排查。
7. 第一阶段不提供 GitLabProject 更新 API。

## 6. Pipeline 执行规则

1. 首次 Attempt 没有 `external_job_id` 时创建 Pipeline，并保存返回的 Pipeline ID。
2. `created`、`waiting_for_resource`、`preparing`、`pending`、`running` 等非终态返回 `IN_PROGRESS`，默认 5 秒后回调。
3. `success` 映射 AtomicTask 成功；`failed` 映射失败；`canceled` 或任务取消映射取消。
4. Task Center 取消进行中的任务时，Worker 必须尽力调用 GitLab Cancel Pipeline，再按 Task Center 取消语义终态化。
5. 自动重试必须优先使用 `external_job_id` 恢复；手动重试创建新的 AtomicTask，并允许创建新的 Pipeline。
6. Task 输出只保存 GitLabProject ID、Pipeline ID、状态和 Web URL 等小型字段，不保存 PAT、API URL、variables 明文回显、Jobs 原始响应或日志正文。

## 7. 业务规则

- `BR-GITLAB-001`：GitLab 是独立领域，拥有 Server、Project 投影和 GitLab Client 语义，不属于 AppStudio。
- `BR-GITLAB-002`：GitLabServer credential 只允许写入和服务端使用，任何读取面不得返回。
- `BR-GITLAB-003`：连接变更必须重置状态，Test 必须持久化 READY 或 ERROR 结果。
- `BR-GITLAB-004`：只有 READY Server 可以创建 Project，且 namespace 固定来自 Server。
- `BR-GITLAB-005`：GitLabProject 使用本地 ID 作为跨域稳定引用，远端 numeric ID 只在本领域使用。
- `BR-GITLAB-006`：有关联 Project 的 Server 不得删除。
- `BR-GITLAB-007`：Project 远端创建成功、本地写入失败时必须执行尽力补偿。
- `BR-GITLAB-008`：删除 Project 时远端 404 等价于已删除，其他远端错误保留本地投影。
- `BR-GITLAB-009`：`gitlab.pipeline.run` 不得接收 URL、credential 或远端 project ID。
- `BR-GITLAB-010`：Pipeline 必须通过 external_job_id、IN_PROGRESS 和延迟回调恢复，不长期占用 Worker。
- `BR-GITLAB-011`：自动 Attempt 重试不得重复创建 Pipeline，手动重试创建新 AtomicTask。
- `BR-GITLAB-012`：GitLab 管理 API 第一阶段仅对 ADMIN 和 SUPER_ADMIN 开放。

## 8. 用户故事与验收

### US-GITLAB-001 管理 GitLab 连接和项目

作为平台管理员，我可以安全地配置并检测 GitLab 连接，在固定 Namespace 中创建或删除远端 Project，并查看不含 credential 的本地投影。

验收标准：

- `AC-GITLAB-001-01`：创建连接后 credential 不出现在任何响应中，状态为 UNKNOWN。
- `AC-GITLAB-001-02`：有效 PAT 和 Namespace 检测后状态为 READY；失败时为 ERROR 且错误已脱敏。
- `AC-GITLAB-001-03`：READY Server 可以创建 private Project，并保存 GitLab 实际返回的投影。
- `AC-GITLAB-001-04`：有关联 Project 时 Server 删除失败；Project 删除成功或远端 404 后可删除 Server。
- `AC-GITLAB-001-05`：USER 无法访问 GitLab 管理 API。

### US-GITLAB-002 运行可恢复 Pipeline

作为受权的系统流程，我可以用内部 GitLabProject ID 创建 Pipeline AtomicTask，并在 Worker 或 API 重启后继续观察同一远端 Pipeline。

验收标准：

- `AC-GITLAB-002-01`：首次执行创建 Pipeline 并保存 external_job_id，后续回调不重复创建。
- `AC-GITLAB-002-02`：Pipeline 成功、失败和取消分别映射为正确的 AtomicTask 终态。
- `AC-GITLAB-002-03`：取消任务会尽力取消远端 Pipeline，输出不包含 credential、API URL 或原始响应。

## 9. 第一阶段非目标

- 不修改 AppStudio、Coding Agent、Studio Source、Build、Preview 或 Release。
- 不建立 StudioApplication 与 GitLabProject 的外键或 API 字段。
- 不处理 Git push、Webhook、Blueprint、自动预览或自动发布。
- 不管理 GitLab Server 进程的 start/stop/restart。
- 不提供 GitLab Project PATCH、Repository 文件 API 或 Pipeline 日志 API。
- 不引入第二套 Secret Provider、Vault 或 GitLab OAuth。
