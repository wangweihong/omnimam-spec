# Asset Library Context

## 1. 领域职责

`asset-library` 统一管理执行制品和长期素材，将业务素材身份与物理存储分离。它负责 Artifact 的受控内容、处理与登记，Asset 的版本树和生命周期，Blob 存储抽象，以及 thumbnail、preview、playback 等 Representation 的生成、补全和访问。

## 2. 核心对象

- `Artifact`：应用、画布、AtomicTask 或 StudioBuild 产生、尚未登记为正式素材的执行制品。
- `Asset`、`AssetVersion`：用户长期素材身份及不可变内容版本。
- `AssetRepresentation`：一个版本的 original、thumbnail、preview、playback 或 manifest。
- `Blob`、`StorageBackend`：去重物理内容及其受控存储位置。
- `Collection`、`Label`、`Tag`：素材组织、分类和检索结构。
- `UploadSession`、`LocalScan`：受控上传与本地素材发现过程。

## 3. 核心规则

- Artifact 不等于 Asset；只有 ready Artifact 才能按策略登记为 Asset/AssetVersion。
- Artifact 身份、内容、处理、保留和登记状态都归 asset-library。
- Artifact 处理状态与登记状态独立，登记失败不得改写 AtomicTask 终态。
- StudioBuild Bundle 使用 `producer_type=studio_build`、`producer_id=StudioBuild.id` 和 `studio-build:<studio_build_id>:bundle`；owner 通过 AppStudio 受控投影取 `StudioBuild.owner_user_id`。
- 同一 StudioBuild 的自动 TaskAttempt 重试复用同一 Artifact；新的逻辑 Build 必须创建新的 StudioBuild ID。
- Artifact 始终 owner-only；Build 协作者、管理员角色或仅持有 producer ID 均不继承 Artifact 权限。
- StudioBuild producer 摘要通过 AppStudio 批量投影读取，不存在或不可见时保留 ID 并返回空摘要，禁止读取 AppStudio 私表或逐项 N+1 查询。
- 同一 Artifact 的幂等登记返回同一 Asset/AssetVersion，不重复复制 Blob。
- AssetVersion 不可变；Representation 是派生表现，original 与派生状态分别受控。
- Task Center 只保存小型素材引用，不拥有长期素材或媒体正文。
- workflow-canvas 和 ai-chatting 只按权限引用素材，不拥有素材生命周期。
- 上传、扫描、外部交付和内容读取必须经过受控存储边界，禁止任意 URL 或私网读取。

## 4. 领域边界

本领域拥有 Artifact、Asset、版本、Representation、Blob、上传、扫描、组织和回收站事实。生成任务状态归 task-center；ApplicationRun 输出映射归 application-platform；CanvasNodeRun 和素材节点结构归 workflow-canvas；StudioBuild 及其 owner/摘要事实归 appstudio；通知和实时事件只是本领域可靠事件的投影。

## 5. 上游与下游

上游包括 application-platform、workflow-canvas、ai-chatting、AppStudio `appstudio.build.execute` 和 AtomicTask Worker 交付的受控字节流或可信存储引用。下游包括引用素材的应用与画布、提供 StudioBuild owner/摘要投影的 appstudio、执行派生任务的 task-center，以及消费 Artifact/AssetVersion 事件的 notification-center 和 sse。

## 6. 正式事实源

| 文件 | 层级 | 用途 |
| --- | --- | --- |
| `00_product/domains/asset-library/product-spec.md` | S1 | 素材、制品、存储、处理和生命周期语义 |
| `01_contracts/domains/asset-library/openapi.yaml` | S2 | 素材、上传、Artifact 和组织 API |
| `01_contracts/domains/asset-library/schema.sql` | S2 | 设计态素材与存储结构 |
| `01_contracts/domains/asset-library/events.yaml` | S2 | Artifact、Asset 和派生事件合同 |
| `01_contracts/domains/asset-library/module-contract.md` | S2 | 存储、任务和跨域协作边界 |
| `02_architecture/domains/asset-library.md` | 参考 | 登记、Representation 与补全链路 |

## 7. 常见任务定位

| 任务 | 首先读取 | 继续读取条件 |
| --- | --- | --- |
| 修改素材或版本语义 | S1 product-spec | 涉及接口或存储时读 OpenAPI/Schema |
| 修改 Artifact 登记 | S1 product-spec | 涉及可靠协作时读 events/module-contract |
| 修改 StudioBuild producer/owner/摘要 | S1 product-spec | 必须继续读 appstudio Context；涉及 Attempt 重试或 Function Registry 再读 task-center Context |
| 修改预览或派生补全 | S1 product-spec | 涉及任务编排再读 task-center Context |
| 修改 Canvas 素材节点 | 当前 Context | 再读 workflow-canvas Context |

## 8. 当前状态

素材、上传、Artifact、Representation、组织、回收站和任务协作已有多次正式发布并正在实施；StudioBuild producer 与 AppStudio 摘要投影修订已由 `spec-v1.17.1` 发布。正文元数据可能仍标记 draft，具体可实施范围和门禁以 `RELEASE.md` 为准，不由 Context 提升未发布能力。

## 9. 不在本领域定义的内容

- AtomicTask 状态机、自动重试和 DAG 编排不在本领域定义。
- Application 输入输出语义和 ApplicationRun 状态不在本领域定义。
- Canvas 图结构、节点运行和局部执行不在本领域定义。
- Provider 下载协议、凭证和任意外部地址访问不在本领域定义。
