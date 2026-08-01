# AppStudio 源码管理、构建与运行设计

> 文档版本：v1.1-draft
>
> 文档状态：未 Release，不得作为正式实现依据。
>
> `StudioApplication` 表示 Agent 辅助开发的 Web/BFF 应用，独立于 `application-platform.Application` 所表示的 AI 能力应用。两者不共享身份、版本、运行对象或私有数据。

## 1. 核心结论

AppStudio 对生成应用代码拥有完整管理权。

```text
Agent 模块
    负责 AgentSession、AgentInvocation，并通过受控 Tool 读取和修改代码

AppStudio
    负责持有 StudioApplication、源码、工作区、变更记录、版本、构建、发布和生成应用运行事实

Task Center / Build Service
    负责将源码快照构建成不可变运行制品

Asset Library
    负责 Build Artifact 的身份、受控内容和生命周期

StudioDeploymentProvider
    负责将运行制品部署到具体环境并启动 StudioRuntimeInstance
```

完整链路：

```text
应用模板
    ↓
可编辑 Workspace
    ↓
Agent ChangeSet
    ↓
Workspace Revision
    ↓
不可变 Source Snapshot
    ↓
Build
    ↓
Build Artifact
    ↓
Release
    ↓
StudioRuntimeInstance
```

必须区分三个阶段：

```text
编辑态：Workspace

构建态：Source Snapshot + StudioBuild

运行态：Artifact 引用 + StudioRelease + StudioRuntimeInstance
```

生产运行环境绝不直接使用可编辑 Workspace。

---

# 2. 源码管理总体架构

```text
┌─────────────────────────────────────────────┐
│              AppStudio Service              │
│                                             │
│ StudioApplication                           │
│ StudioWorkspace                             │
│ Source Revision                             │
│ Source Snapshot                             │
│ StudioApplicationVersion                    │
│ StudioBuild                                 │
│ StudioRelease                               │
│ StudioRuntimeInstance                       │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│              Source Service                 │
│                                             │
│ 创建源码仓库                                │
│ 创建工作区                                  │
│ 读取文件                                    │
│ 应用 ChangeSet                              │
│ 创建 Revision                               │
│ 创建不可变 Snapshot                         │
│ 恢复历史 Revision                           │
└───────────────┬─────────────────────────────┘
                │
        ┌───────┴────────┐
        ▼                ▼
┌───────────────┐  ┌─────────────────────────┐
│ Workspace     │  │ Snapshot Storage        │
│ Storage       │  │                         │
│               │  │ 不可变源码快照           │
│ 活跃编辑目录   │  │ 内容哈希                 │
│ 快速读写       │  │ 长期保存                 │
└───────┬───────┘  └────────────┬────────────┘
        │                       │
        │ Agent 修改            │ Build 读取
        ▼                       ▼
┌────────────────┐    ┌────────────────────────┐
│ Agent Service  │    │ Build Service          │
└────────────────┘    └────────────────────────┘
```

AppStudio 与其他领域只通过稳定 ID、不可变快照、受控 Tool、Task Center 资源和 Asset Library Artifact 能力协作，不读取其他领域私有表，也不复制 Agent 会话、任务状态机或 Artifact 内容事实。

---

# 3. 一个 StudioApplication 如何管理源码

## 3.1 一个 StudioApplication 对应一个逻辑源码仓库

每个 `StudioApplication` 创建时，都创建一个逻辑源码仓库：

```text
StudioApplication
    └── StudioSourceRepository
```

数据结构：

```text
StudioSourceRepository
- id
- studio_application_id
- default_workspace_id
- provider
- storage_uri
- current_revision
- status
- created_at
- updated_at
```

第一阶段：

```text
provider = built_in
```

源码由 AppStudio 内置 Source Service 管理。

后续可以增加：

```text
git
remote_git
enterprise_git
external_repository
```

AppStudio 领域模型不依赖具体源码存储方式。

---

## 3.2 源码不保存到数据库字段

源码不能以大段文本方式直接保存在业务数据库中。

业务数据库只保存：

* 文件索引；
* Workspace ID；
* Revision；
* Snapshot ID；
* 内容哈希；
* 存储地址；
* 变更摘要。

实际文件保存在：

```text
Workspace Storage
Snapshot Storage
```

两类存储用途不同。

### Workspace Storage

用于当前编辑。

特点：

* 可读写；
* 低延迟；
* 支持 Agent 频繁修改；
* 支持快速预览；
* 可以被临时运行环境挂载；
* 不作为长期版本事实。

### Snapshot Storage

用于版本、构建和审计。

特点：

* 不可修改；
* 按内容哈希标识；
* 长期保存；
* 构建只能从 Snapshot 读取；
* Release 可以追溯到具体 Snapshot。

---

# 4. 源码目录结构

第一阶段所有生成应用使用统一结构：

```text
application/
├── appstudio.json
├── package.json
├── lockfile
├── tsconfig.json
│
├── src/
│   ├── web/
│   │   ├── main.tsx
│   │   ├── app.tsx
│   │   ├── pages/
│   │   ├── components/
│   │   ├── hooks/
│   │   └── styles/
│   │
│   ├── bff/
│   │   ├── main.ts
│   │   ├── routes/
│   │   ├── middleware/
│   │   ├── services/
│   │   └── runtime/
│   │
│   └── shared/
│       ├── contracts/
│       ├── schemas/
│       ├── types/
│       └── constants/
│
├── public/
├── tests/
└── appstudio/
    ├── blueprint.json
    ├── integrations.json
    └── permissions.json
```

其中：

```text
src/web
    Web 前端代码

src/bff
    轻量 BFF 代码

src/shared
    前后端共享类型和 Schema

appstudio/
    AppStudio 管理配置
```

Agent 可以修改业务代码，但不能随意修改平台控制文件。

---

# 5. appstudio.json

每个应用必须包含：

```json
{
  "schema_version": "appstudio/v1",
  "application_id": "studio_app_123",
  "runtime_profile": "web_light_bff",
  "technology_profile": "typescript_light_bff",
  "entrypoints": {
    "web": "src/web/main.tsx",
    "bff": "src/bff/main.ts"
  },
  "build": {
    "web_output": "dist/web",
    "bff_output": "dist/bff"
  },
  "health_check": {
    "path": "/healthz"
  }
}
```

该文件由 AppStudio 管理。

Agent 默认只读，只有专门工具允许修改受控字段。

---

# 6. Workspace 管理

## 6.1 StudioWorkspace

每个正在编辑的 StudioApplication 分支持有一个 StudioWorkspace；正式 StudioApplicationVersion 只引用不可变 Source Snapshot，不直接引用可变 Workspace。

```text
StudioWorkspace
- id
- studio_application_id
- source_repository_id
- base_snapshot_id
- current_revision
- preview_runtime_id
- status
- created_at
- updated_at
```

状态：

```text
initializing
ready
modifying
previewing
conflicted
locked
archived
```

AppStudio 是 StudioWorkspace 状态、Revision、存储与生命周期的唯一事实源。一个 StudioWorkspace 可以被多个固定绑定的 Coding Agent 使用，但任何写入都必须经过 ChangeSet 和 `base_revision` 校验。

---

## 6.2 Workspace 初始化

创建 StudioApplication 时：

```text
创建 StudioApplication
    ↓
创建 StudioSourceRepository
    ↓
选择平台应用模板
    ↓
将模板复制到 Workspace Storage
    ↓
写入 application_id
    ↓
生成初始 Revision 1
    ↓
启动 Preview Runtime
```

初始模板已经包含：

* Web 入口；
* BFF 入口；
* 健康检查；
* Platform Runtime SDK；
* Task Center SDK；
* SSE 基础实现；
* 错误处理；
* 日志；
* 基础测试。

Agent 不需要从空目录开始生成整个项目。

创建 Coding Agent 时必须由 AppStudio 提供一个已存在且有权访问的 StudioWorkspace。Agent 生命周期内不得切换 Workspace；删除、停用或挂起 Agent 不得改变 StudioWorkspace 状态。

---

# 7. Agent 如何修改代码

Agent 不直接挂载 AppStudio 数据目录。

Agent 只能通过 Workspace Tool API 操作代码：

```text
list_files
read_file
search_files
create_file
apply_patch
delete_file
read_application_manifest
read_blueprint
update_blueprint
run_preview_check
get_build_diagnostics
```

调用关系：

```text
用户提出修改要求
    ↓
AppStudio 选择固定绑定该 StudioWorkspace 的 Coding Agent
    ↓
Agent Service 创建或复用 AgentSession
    ↓
创建 AgentInvocation 和 AtomicTask
    ↓
AppStudio 为当前 AgentInvocation 签发 Workspace Tool 授权
    ↓
Agent 通过 Workspace API 读取代码
    ↓
Agent 生成 ChangeSet
    ↓
AppStudio 校验 ChangeSet
    ↓
Source Service 应用 ChangeSet
    ↓
生成新的 Workspace Revision
```

---

## 7.1 ChangeSet

Agent 每次修改必须形成 ChangeSet：

```text
StudioChangeSet
- id
- workspace_id
- agent_id
- agent_session_id
- agent_invocation_id
- base_revision
- target_revision
- files_added
- files_modified
- files_deleted
- summary
- status
- created_at
```

Agent 返回：

```json
{
  "base_revision": 12,
  "changes": [
    {
      "operation": "modify",
      "path": "src/web/pages/home.tsx",
      "patch": "..."
    },
    {
      "operation": "create",
      "path": "src/bff/routes/gallery.ts",
      "content": "..."
    }
  ]
}
```

AppStudio 应用前必须检查：

* Agent 的 `workspace_type=studio` 且 `workspace_id` 与目标 StudioWorkspace 一致；
* 当前用户、AgentSession 和 AgentInvocation 仍有权操作该 StudioWorkspace；
* `base_revision` 是否仍是当前 Revision；
* 文件是否属于允许修改范围；
* 是否修改依赖白名单；
* 是否修改受保护文件；
* 是否包含危险代码；
* 是否超过单次变更大小限制。

任何校验失败都必须返回明确分类，且不得写入部分文件、创建目标 Revision 或改变 Preview Runtime。成功应用后，同一个 `agent_invocation_id + base_revision` 的重复提交必须返回同一结果，不能重复递增 Revision。

---

## 7.2 Revision

每次成功应用 ChangeSet 后，Workspace Revision 递增：

```text
Revision 12
    ↓ Agent ChangeSet
Revision 13
```

Revision 用于：

* 快速撤销；
* 变更对比；
* 预览刷新；
* 冲突检测；
* Agent 并发控制。

Revision 是编辑态版本，不等于发布版本。

---

# 8. 源码快照

用户点击“构建”时，AppStudio 不直接构建当前目录，而是先创建不可变源码快照。

```text
当前 Workspace Revision 18
    ↓
锁定短时间写入
    ↓
生成 Source Snapshot
    ↓
计算内容哈希
    ↓
解除 Workspace 锁定
```

数据结构：

```text
StudioSourceSnapshot
- id
- studio_application_id
- workspace_id
- workspace_revision
- content_digest
- storage_uri
- manifest_digest
- created_by
- created_at
```

例如：

```text
snapshot_id:
source_snapshot_123

workspace_revision:
18

content_digest:
sha256:abc123...
```

后续所有构建都只读取 `source_snapshot_123`。

即使 Workspace 已经继续修改，也不会影响正在进行的构建。

---

# 9. StudioApplicationVersion 和源码快照关系

创建正式 StudioApplicationVersion 时：

```text
StudioApplicationVersion
- id
- studio_application_id
- version
- source_snapshot_id
- blueprint_revision_id
- runtime_profile
- status
- created_at
```

关系：

```text
StudioApplicationVersion 5
    ↓
Source Snapshot 123
    ↓
Workspace Revision 18
```

一个源码快照可以重复构建多次：

```text
Source Snapshot 123
├── Build 1：基础设施失败
├── Build 2：成功
└── Build 3：重新构建
```

但 StudioApplicationVersion 引用的源码内容始终不变。

---

# 10. 构建架构

```text
AppStudio Service
    ↓ 创建 StudioBuild
Task Center
    ↓ 创建并调度 Build TaskGroup / AtomicTask
Build Worker
    ↓ 获取 Source Snapshot
Build Service
    ↓ 校验、编译、打包
Asset Library
    ↓ 创建并保存 studio_application_bundle Artifact
AppStudio
    ↓ 更新 StudioBuild
```

---

## 10.1 StudioBuild

```text
StudioBuild
- id
- studio_application_id
- studio_application_version_id
- source_snapshot_id
- task_group_id
- build_profile
- status
- artifact_id
- artifact_digest
- diagnostics
- started_at
- completed_at
```

状态：

```text
pending
validating
building
packaging
succeeded
failed
cancelled
```

StudioBuild 是 AppStudio 的业务投影，TaskGroup 和其中的 AtomicTask 才是执行状态、进度、TaskAttempt、重试、取消和超时事实源。AppStudio 按 Task Center 的可靠状态事件和查询结果单调更新 Build 投影，不得覆盖任务历史或从 Build 状态反向改写 AtomicTask。

`artifact_id` 指向 asset-library 的 Artifact；`artifact_digest` 是 Build 成功时保存的不可变校验快照。AppStudio 不保存 Artifact 内容、存储位置、处理状态机或登记状态。

---

## 10.2 Build Service 职责

Build Service 负责：

* 准备隔离构建目录；
* 下载源码快照；
* 校验项目结构；
* 校验技术栈；
* 校验依赖；
* 安装锁定依赖；
* 执行类型检查；
* 执行测试；
* 执行安全检查；
* 构建 Web；
* 构建 BFF；
* 生成运行 Manifest；
* 打包运行制品；
* 通过 asset-library 受控能力交付并创建 Build Artifact。

Build Service 不负责：

* 应用需求理解；
* 修改源码；
* Agent 修复；
* 正式部署；
* 运行实例管理。

---

# 11. 构建流程

```text
Source Snapshot
    ↓
1. MATERIALIZE_SOURCE
    ↓
2. VALIDATE_MANIFEST
    ↓
3. VALIDATE_TECHNOLOGY
    ↓
4. VALIDATE_DEPENDENCIES
    ↓
5. INSTALL_DEPENDENCIES
    ↓
6. TYPE_CHECK
    ↓
7. UNIT_TEST
    ↓
8. SECURITY_CHECK
    ↓
9. BUILD_WEB
    ↓
10. BUILD_BFF
    ↓
11. GENERATE_RUNTIME_MANIFEST
    ↓
12. PACKAGE_ARTIFACT
    ↓
13. REGISTER_ARTIFACT
```

这些步骤由 Task Center 组成 TaskGroup。

AppStudio 不自己维护步骤重试和状态机。

任何构建步骤失败时，Task Center 保留失败 AtomicTask 与 Attempt，StudioBuild 投影为 failed 并保存权限裁剪的诊断摘要。失败构建不得产生可发布的 Artifact 引用；Artifact 内容交付失败时，即使编译已经完成，StudioBuild 仍不能进入 succeeded。

---

# 12. Web 构建

Web 源码：

```text
src/web/
```

构建后：

```text
dist/web/
├── index.html
├── assets/
└── application-config.json
```

Web 构建必须：

* 使用锁定依赖；
* 禁止构建时任意联网；
* 禁止动态下载脚本；
* 禁止读取平台密钥；
* 禁止嵌入服务端 Secret；
* 将 API 地址统一设置为相对路径 `/api`。

前端只能调用：

```text
/api/*
```

不能直接持有平台内部访问凭证。

---

# 13. BFF 构建

BFF 源码：

```text
src/bff/
```

第一阶段建议使用 TypeScript 轻量 BFF。

构建结果为：

```text
dist/bff/
├── server.js
└── server.manifest.json
```

或者直接输出单文件：

```text
dist/bff/server.js
```

BFF 运行时依赖尽量打包到单一制品中，减少：

* 启动时安装依赖；
* 运行环境差异；
* 冷启动时间；
* 部署文件数量。

BFF 构建完成后，运行环境不再执行：

```text
npm install
npm build
```

运行环境只负责启动已经构建好的 BFF 制品。

---

# 14. Build Artifact

最终构建产物不是源码压缩包，而是可直接运行的应用制品。

```text
studio-app-bundle/
├── manifest.json
├── web/
│   ├── index.html
│   └── assets/
│
├── bff/
│   └── server.js
│
└── metadata/
    ├── source.json
    ├── build.json
    └── integrations.json
```

`manifest.json`：

```json
{
  "schema_version": "appstudio.bundle/v1",
  "application_id": "studio_app_123",
  "version_id": "version_5",
  "build_id": "build_789",
  "runtime_profile": "web_light_bff",
  "entrypoint": "bff/server.js",
  "web_root": "web",
  "api_prefix": "/api",
  "health_check": "/healthz"
}
```

Build Artifact 使用内容哈希：

```text
sha256:def456...
```

正式发布必须固定到具体 Artifact Digest，不能使用 `latest`。

---

# 15. Build Artifact 存储

构建产物由 asset-library 作为 Artifact 保存。Artifact 的身份、受控内容、处理、保留、登记和存储位置均归 asset-library；AppStudio 只保存以下引用和历史快照：

```text
StudioBuild Artifact Reference
- artifact_id
- artifact_type = studio_application_bundle
- artifact_digest
- artifact_size_snapshot
- artifact_created_at_snapshot
```

类型：

```text
studio_application_bundle
```

AppStudio 或 StudioDeploymentProvider 读取 Artifact 时必须经过 asset-library 的受控内容能力，不能持久化 `storage_uri`、任意下载地址或其他存储后端私有字段。

Build Bundle 使用稳定 producer key，例如 `studio-build:<studio_build_id>:bundle`。同一个 AtomicTask 的自动 TaskAttempt 重试必须复用该 key，并由 asset-library 幂等返回同一 Artifact；不得为同一次逻辑 Build 制造重复 Bundle。Artifact owner 必须是发起 StudioBuild 的当前用户或等价受信主体，不能归属 Build Worker、Provider 或系统管理员。

后续如果部署 Provider 需要容器镜像，可以通过 Task Center 调度受控 Packaging Worker，将 Bundle 转换为新的受控制品或部署缓存；不得静默改写原 Artifact 内容或 digest。

AppStudio 不要求所有部署方式必须使用镜像。

---

# 16. 预览运行

预览运行和正式运行使用不同链路。

## 16.1 编辑态快速预览

编辑态预览直接基于 Workspace Revision：

```text
Agent 修改 Workspace
    ↓
快速依赖检查
    ↓
增量编译 Web
    ↓
增量编译 BFF
    ↓
刷新 Preview Runtime
```

特点：

* 不创建正式 Source Snapshot；
* 不创建正式 Build Artifact；
* 不执行完整安全检查；
* 不形成可发布版本；
* 只用于用户快速查看修改效果。

---

## 16.2 Preview Runtime

```text
StudioPreviewRuntime
- id
- studio_application_id
- workspace_id
- workspace_revision
- status
- endpoint
- process_id
- last_active_at
```

状态：

```text
starting
running
refreshing
failed
stopped
expired
```

Preview Runtime 负责：

* 创建隔离预览目录；
* 加载当前 Workspace；
* 启动 Web 编译服务；
* 启动轻量 BFF；
* 暴露预览端口；
* 收集日志；
* 修改后自动刷新；
* 超时后释放。

预览地址第一阶段可以直接使用：

```text
http://preview-host:{port}
```

后续再由域名服务提供：

```text
https://{preview-id}.preview.example.com
```

---

# 17. 正式运行架构

正式运行不读取源码，只读取 Build Artifact。

```text
Build Artifact
    ↓
StudioDeploymentProvider
    ↓
StudioRuntimeInstance
```

`StudioDeploymentProvider` 是 AppStudio 使用的系统注册组件，负责校验并获取 Artifact、准备受控运行配置、创建或停止底层运行单元、执行健康检查和返回访问入口。它不拥有 StudioRelease 业务状态，也不等同于 Agent 的 AgentRuntimeProvider。

```text
StudioRuntimeInstance
- id
- studio_application_id
- studio_release_id
- artifact_id
- artifact_digest
- deployment_provider
- provider_runtime_id
- status
- health_status
- endpoint_summary
- ready_at
- stopped_at
- created_at
- updated_at
```

AppStudio 是 StudioRuntimeInstance 业务状态和访问入口的事实源；Provider 原始资源标识只作为受控引用，不向用户暴露基础设施私有配置。

运行单元：

```text
┌──────────────────────────────────────┐
│ Generated Application Runtime        │
│                                      │
│ Lightweight BFF Process              │
│ ├── /api/*                           │
│ ├── /healthz                         │
│ ├── Platform SDK                     │
│ └── SSE Proxy                        │
│                                      │
│ Web Static Files                     │
│ ├── /assets/*                        │
│ └── /* → index.html                  │
└──────────────────────────────────────┘
```

一个轻量 BFF 进程同时负责：

* 提供 API；
* 提供健康检查；
* 提供 Web 静态文件；
* 返回 SPA 入口；
* 转发 Task Center 事件。

因此，一个 StudioApplication Release 只需要一个运行单元。

---

# 18. 应用启动流程

StudioDeploymentProvider 启动应用时：

```text
获取 Build Artifact
    ↓
校验 Artifact Digest
    ↓
解压或挂载运行制品
    ↓
读取 manifest.json
    ↓
加载运行配置
    ↓
解析 Secret Reference
    ↓
启动 Lightweight BFF
    ↓
BFF 加载 Web 静态目录
    ↓
执行 /healthz
    ↓
标记 StudioRuntimeInstance Ready
```

运行环境不需要：

* 下载源码；
* 安装依赖；
* 执行编译；
* 执行数据库迁移；
* 调用 Agent。

---

# 19. 运行配置管理

源码中不能保存环境密钥。

运行配置由 AppStudio 管理，StudioDeploymentProvider 只在部署时消费固定版本和环境对应的受控配置：

```text
StudioRuntimeConfig
- studio_application_id
- studio_application_version_id
- environment
- public_config
- secret_references
- integration_references
- resource_profile
```

示例：

```json
{
  "environment": "production",
  "public_config": {
    "application_name": "创意作品站"
  },
  "secret_references": [
    "secret://appstudio/app-123/platform-token"
  ],
  "integration_references": [
    "integration://studio-integration-456"
  ]
}
```

StudioDeploymentProvider 负责在授权边界内解析引用并注入具体运行环境，不得将解析后的 Secret 回写到 AppStudio 业务事实。

Agent 看不到真实生产密钥。

---

# 20. StudioRelease

```text
StudioRelease
- id
- studio_application_id
- studio_application_version_id
- studio_build_id
- artifact_id
- artifact_digest
- environment
- deployment_provider
- studio_runtime_instance_id
- hostname
- status
- released_at
```

关系：

```text
StudioRelease
    → StudioBuild
        → Source Snapshot
            → Workspace Revision
```

因此线上任何一个 Release 都能追溯到：

* 哪个源码 Revision；
* 哪个源码快照；
* 哪次构建；
* 哪个构建产物；
* 哪个运行实例。

---

# 21. 发布流程

```text
用户确认发布
    ↓
AppStudio 检查 Build 成功
    ↓
创建 StudioRelease
    ↓
创建部署 AtomicTask 或 TaskGroup
    ↓
Task Center 调度 Deployment Worker
    ↓
Deployment Worker 调用 StudioDeploymentProvider
    ↓
Provider 创建 StudioRuntimeInstance
    ↓
加载 Build Artifact
    ↓
启动应用
    ↓
执行健康检查
    ↓
绑定访问地址
    ↓
更新 StudioRelease
    ↓
写出可靠 StudioRelease 成功事件
```

StudioRelease 状态由 AppStudio 按 Task Center 与 Provider 结果单调更新。Notification Center 可以消费可靠事件形成通知，但 AppStudio 不维护通知收件箱、已读状态或聚合规则。

---

# 22. 回滚流程

回滚不重新修改源码，也不要求重新调用 Agent。

```text
用户选择历史 Release
    ↓
读取历史 Artifact Digest
    ↓
创建新的回滚 Release
    ↓
StudioDeploymentProvider 部署历史 Artifact
    ↓
健康检查
    ↓
切换访问入口
    ↓
停止异常 StudioRuntimeInstance
```

回滚对象是：

```text
Build Artifact
```

而不是：

```text
Workspace Revision
```

这样回滚速度更快，也能确保运行内容完全一致。

---

# 23. 应用修改后的完整链路

```text
用户提出修改
    ↓
Agent 修改 Workspace Revision 18
    ↓
AppStudio 应用 ChangeSet
    ↓
生成 Workspace Revision 19
    ↓
Preview Runtime 刷新
    ↓
用户确认效果
    ↓
创建 Source Snapshot
    ↓
创建 StudioApplicationVersion 6
    ↓
Task Center 正式构建
    ↓
生成 Build Artifact
    ↓
部署 Preview Release
    ↓
用户确认上线
    ↓
部署 Production Release
```

---

# 24. 并发与冲突控制

同一个 StudioWorkspace 可以同时绑定多个 Coding Agent，每个 Agent 通过自己的 AgentSession 和 AgentInvocation 读取最新事实并提交 ChangeSet。

每个 ChangeSet 必须包含：

```text
base_revision
```

例如：

```text
Agent A 基于 Revision 18 修改
Agent B 也基于 Revision 18 修改
```

Agent A 先提交：

```text
Revision 18 → Revision 19
```

Agent B 再提交时：

```text
base_revision = 18
current_revision = 19
```

AppStudio 返回：

```text
WORKSPACE_REVISION_CONFLICT
```

Agent B 必须重新读取最新代码并生成新 ChangeSet。

第一阶段不做复杂自动合并。

Revision 冲突不是 Agent、Session 或 Invocation 的永久错误。冲突 ChangeSet 保留失败摘要但不产生 `target_revision`，Agent 可以在新的 Invocation 中基于最新 Revision 重试。

---

# 25. 源码恢复

用户可以将 Workspace 恢复到历史 Revision：

```text
当前 Revision 25
    ↓
选择 Revision 20
    ↓
Source Service 创建新的 Revision 26
    ↓
Revision 26 内容等同于 Revision 20
```

不直接删除 Revision 21～25。

这样保留完整修改历史。

---

# 26. 产品动作

## 26.1 获取工作区

用户和受权 Coding Agent 可以读取 StudioWorkspace 基础信息、状态、当前 Revision 和权限裁剪的 StudioApplication 摘要。响应不得包含 `storage_uri` 或存储实现细节。

## 26.2 读取文件

受权 Coding Agent 可以通过 Workspace Tool 列出、读取和搜索允许范围内的文件。每次调用必须绑定当前 AgentInvocation 和短期授权。

## 26.3 应用 ChangeSet

受权 Coding Agent 可以提交带 `base_revision` 的 StudioChangeSet。AppStudio 原子校验并应用全部变更；任何一项失败时不得部分写入。

## 26.4 创建源码快照

用户可以从指定的当前 Workspace Revision 创建不可变 StudioSourceSnapshot。Revision 不存在、不是当前可发布内容或 Workspace 处于禁止快照状态时创建失败。

## 26.5 创建构建

用户可以从 StudioSourceSnapshot 创建 StudioBuild。AppStudio 创建 TaskGroup/AtomicTask 引用，构建只能读取 Snapshot，不得读取当前 Workspace。

## 26.6 创建预览 Release

用户可以从成功 StudioBuild 的固定 Artifact 创建 preview StudioRelease。该 Preview Release 使用正式 Artifact 和部署链路，与编辑态 StudioPreviewRuntime 不同。

## 26.7 创建正式 Release

用户确认后可以从成功 StudioBuild 的固定 Artifact 创建 production StudioRelease。创建前必须校验 Build、Artifact ID、digest、运行配置和发布权限。

精确 HTTP 路径、方法、DTO、错误码、权限码和事件 payload 属于后续 S2，不在本 S1 固定。

---

# 27. 最终对象关系

```text
StudioApplication
├── StudioSourceRepository
│   └── StudioWorkspace
│       ├── Workspace Revision
│       ├── StudioChangeSet
│       └── StudioSourceSnapshot
│
├── StudioApplicationVersion
│   └── StudioSourceSnapshot
│
├── StudioBuild
│   ├── StudioSourceSnapshot
│   ├── TaskGroup / AtomicTask Reference
│   └── Artifact Reference
│
└── StudioRelease
    ├── StudioBuild
    ├── Artifact ID + Digest Snapshot
    └── StudioRuntimeInstance

External References
├── AgentSession / AgentInvocation
├── TaskGroup / AtomicTask
└── Asset Library Artifact
```

---

# 28. 最终端到端链路

```text
创建 StudioApplication
    ↓
初始化源码 Workspace
    ↓
Agent 通过 Workspace API 修改代码
    ↓
AppStudio 保存 ChangeSet 和 Revision
    ↓
Preview Runtime 快速编译并展示
    ↓
用户确认当前 Revision
    ↓
AppStudio 创建不可变 Source Snapshot
    ↓
创建 StudioApplicationVersion
    ↓
Task Center 调度 Build Service
    ↓
构建 Web 与 Lightweight BFF
    ↓
通过 Asset Library 创建不可变 Build Artifact
    ↓
AppStudio 创建 Release
    ↓
Task Center 调用 StudioDeploymentProvider
    ↓
StudioDeploymentProvider 创建 StudioRuntimeInstance
    ↓
绑定访问地址
    ↓
StudioApplication 正式运行
```

最终需要坚持五个事实：

```text
Workspace 是编辑事实

Source Snapshot 是源码版本事实

Artifact 是可运行制品的受控内容事实，归 asset-library

StudioRelease 是线上运行事实

StudioRuntimeInstance 是当前部署实例事实
```

Agent 只能修改 Workspace。

正式构建只能读取 Source Snapshot。

生产运行只能读取 Build Artifact。

线上版本只能通过 StudioRelease 切换。

---

# 29. 关键失败与恢复结果

* **Workspace 授权失败**：不返回文件内容或存在性差异，不创建 ChangeSet，不自动切换到其他 Workspace。
* **受保护文件或危险变更**：整组 ChangeSet 拒绝，Revision 不递增，Preview Runtime 不刷新。
* **Revision 冲突**：返回当前 Revision 摘要，要求 Agent 重新读取并提交新 ChangeSet，不自动合并或覆盖。
* **Snapshot 失败**：Workspace 保持可编辑，短时写锁必须释放，不创建可被 Build 引用的部分 Snapshot。
* **Build 失败**：保留 Task Center 执行历史和诊断摘要，不产生可发布 Artifact 引用，不修改已存在 Release。
* **Artifact 交付或处理失败**：Build 不能进入 succeeded；AppStudio 不通过自建存储记录绕过 asset-library。
* **Release 部署失败**：StudioRelease 进入失败结果并保留 Build/Artifact 快照；现有健康 Release 和访问入口不切换。
* **健康检查失败**：新 StudioRuntimeInstance 不进入 ready；根据部署策略停止失败实例并保留可诊断引用。
* **回滚失败**：当前线上 Release 保持不变；失败的回滚 Release 保留独立历史，不能覆盖旧 Release 状态。
* **Secret 解析失败**：部署失败且不启动应用；错误和日志只能返回脱敏引用与分类。

---

# 30. 最终职责边界

## AppStudio

拥有 StudioApplication、StudioSourceRepository、StudioWorkspace、Revision、StudioChangeSet、StudioSourceSnapshot、StudioApplicationVersion、StudioBuild、StudioRuntimeConfig、StudioPreviewRuntime、StudioRelease 和 StudioRuntimeInstance。

## Agent

拥有 Agent、AgentSession、AgentInvocation、消息、记忆和 AgentRuntime。Coding Agent 固定引用一个 StudioWorkspace，并通过 AppStudio Tool 提交 ChangeSet；Agent 删除或挂起不影响 AppStudio 事实。

## Task Center

拥有 AtomicTask、TaskAttempt、TaskGroup、调度、重试、取消、超时和执行状态。AppStudio 只保存稳定任务引用与业务投影。

## Asset Library

拥有 Artifact 身份、内容、处理、存储、保留和登记。AppStudio 只保存 `artifact_id` 和不可变 digest 等历史快照。

## Notification Center

消费 AppStudio 的可靠领域事件并维护通知、已读、偏好和聚合。AppStudio 不维护通知收件箱事实。

---

# 31. S2 追溯锚点

本节只为后续实现契约提供稳定引用，不改变前述产品语义。规则与用户故事的完整含义仍以前文章节为准。

## 31.1 业务规则

| 编号 | 规则 | 主要来源章节 |
| --- | --- | --- |
| BR-APPSTUDIO-001 | StudioApplication 是生成式 Web/BFF 应用身份，与 application-platform.Application 完全分离。 | 1、30 |
| BR-APPSTUDIO-002 | AppStudio 拥有逻辑源码仓库、StudioWorkspace、Revision 和源码索引；源码内容位于受控 Workspace/Snapshot Storage，不存入业务大字段。 | 2、3、6、30 |
| BR-APPSTUDIO-003 | Coding Agent 只能通过绑定当前 Invocation 的短期 Workspace Tool 授权读取文件、搜索源码和请求诊断，不能直接挂载存储。 | 6.2、7、26.1、26.2、29 |
| BR-APPSTUDIO-004 | StudioChangeSet 必须携带 `base_revision` 并原子应用；冲突、危险变更或受保护文件失败不得部分写入或递增 Revision，重复提交必须幂等。 | 7.1、7.2、24、29 |
| BR-APPSTUDIO-005 | StudioSourceSnapshot 固定一个 Workspace Revision 与内容 digest，创建成功后不可修改，正式 Build 只能读取 Snapshot。 | 8、9、26.4、28 |
| BR-APPSTUDIO-006 | StudioApplicationVersion 固定引用 Source Snapshot；Workspace 后续变化不得改写历史版本。 | 9、23、27 |
| BR-APPSTUDIO-007 | StudioBuild 是 AppStudio 业务投影；Task Center 拥有 TaskGroup/AtomicTask 状态、重试、取消、超时和 Attempt 历史。 | 10、11、26.5、30 |
| BR-APPSTUDIO-008 | Build Artifact 内容和生命周期归 asset-library；AppStudio 只保存稳定 `artifact_id`、digest 与非敏感历史快照，同一逻辑 Build 使用稳定 producer key。 | 14、15、29、30 |
| BR-APPSTUDIO-009 | 编辑态 Preview Runtime 与正式 preview/production Release 分离；正式运行只读取固定 digest 的 Build Artifact。 | 16、17、18、26.6、26.7 |
| BR-APPSTUDIO-010 | StudioRuntimeConfig 只保存公开配置和 Secret/Integration 引用；真实 Secret 仅在部署边界解析，不得返回给 Agent 或写回业务事实。 | 19、29 |
| BR-APPSTUDIO-011 | Release 只有在 Build、Artifact digest、运行配置与权限校验通过后才能创建；新实例健康前不得切换现有健康访问入口。 | 18、20、21、26.6、26.7、29 |
| BR-APPSTUDIO-012 | 回滚必须创建新的 StudioRelease 并部署历史 Build Artifact；不得修改源码 Revision 或覆盖原 Release 历史。 | 22、29 |
| BR-APPSTUDIO-013 | Agent、Task Center、Asset Library 与 Notification Center 的事实只能通过稳定 ID、受控接口、快照或可靠事件协作，禁止跨域私表与状态复制。 | 2、10、15、21、27、30 |
| BR-APPSTUDIO-014 | AppStudio 资源状态和发布结果持久化后必须发布可靠事件；事件不得包含源码、Secret、存储地址或 Provider 私有配置。 | 21、29、30 |

## 31.2 用户故事

| 编号 | 用户故事 | 主要来源章节 |
| --- | --- | --- |
| US-APPSTUDIO-001 | 用户可以创建、查询和更新 StudioApplication，并获得初始化的源码仓库与 Workspace。 | 1、3、6.2、28 |
| US-APPSTUDIO-002 | 用户或受权 Coding Agent 可以查询 Workspace、列出/读取/搜索允许范围内的文件和查看当前 Revision。 | 6、7、26.1、26.2 |
| US-APPSTUDIO-003 | 受权 Coding Agent 可以提交带 `base_revision` 的 ChangeSet，并获得新 Revision 或明确冲突/校验结果。 | 7.1、7.2、24、26.3 |
| US-APPSTUDIO-004 | 用户可以从当前 Revision 创建不可变 Source Snapshot 和固定该 Snapshot 的 StudioApplicationVersion。 | 8、9、26.4 |
| US-APPSTUDIO-005 | 用户可以从 Source Snapshot 创建 StudioBuild，并查看状态、任务引用、Artifact 摘要和权限裁剪的诊断。 | 10、11、15、26.5 |
| US-APPSTUDIO-006 | 用户可以请求并查看基于当前 Workspace Revision 的编辑态预览检查与 Preview Runtime。 | 16、26.2 |
| US-APPSTUDIO-007 | 用户可以从成功 Build 创建 preview 或 production Release，并查看 Release 与 Runtime 状态和访问入口。 | 17、20、21、26.6、26.7 |
| US-APPSTUDIO-008 | 用户可以选择历史 Release 创建新的回滚 Release，健康切换失败时保持当前线上版本不变。 | 22、29 |
| US-APPSTUDIO-009 | 用户可以按应用版本和环境管理运行配置引用，但不能读取解析后的生产 Secret。 | 19、26.7 |
