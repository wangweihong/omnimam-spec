# OmniMAM Spec Workflow Skill

本文档定义 `omnimam-spec` 仓库中 **S0（探索）**、**S1（产品语义）**、**S2（实现契约）** 的制品、产出与边界。

---

# 1. 定位与核心原则

## 1.1 阶段定位

**S0 是探索。**
用于快速验证想法、交互、页面布局和功能可行性。S0 不是事实源，但可作为 S1 的输入。

**S1 是产品语义事实源。**
回答“做什么、为什么做、用户如何使用、怎么做才算完成”。S1 面向人类评审，要求聚合、易读、上下文完整。

**S2 是实现契约事实源。**
将 S1 转化为结构化、可校验的接口、数据、错误码、权限码、事件和模块契约。S2 面向开发与工具。

**Release 是正式承诺。**
S1/S2 经用户确认后 release，作为正式实现、合并、验收和发布依据。

未 release 的 S1/S2 可以作为草稿讨论、原型探索和实现评估参考，但不得作为正式实现、合并、验收或发布依据。

---

## 1.2 优先级链

```text
产品语义以 S1 为准。
实现契约以 S2 为准。
S1 与 S2 冲突时，必须先修正 spec，再 release。
实现与 S2 冲突时，优先修正实现；若 S2 遗漏，则补充 S2。
若 S2 变更影响产品语义，必须同步修正 S1。
```

---

# 2. 目录结构

```text
omnimam-spec/
├── AGENTS.md
├── CHANGELOG.md
├── RELEASE.md
├── skills/
│   └── spec-workflow/
│       └── SKILL.md
├── 00_product/
│   ├── glossary.md
│   ├── global-business-rules.md
│   ├── global-feature-matrix.md
│   └── domains/
│       └── <domain_id>/
│           └── product-spec.md
├── 01_contracts/
│   └── domains/
│       └── <domain_id>/
│           ├── openapi.yaml
│           ├── schema.sql
│           ├── errors.yaml
│           ├── permissions.yaml
│           ├── events.yaml
│           └── module-contract.md
└── 02_architecture/
    ├── global-architecture.md
    └── domains/
        └── <domain_id>.md
```

---

# 3. S0 原型阶段

## 3.1 允许产出

```text
可运行原型
页面 mock
交互 demo
流程草图
原型截图
原型说明
用户反馈
```

## 3.2 禁止产出

```text
正式 API
正式 SQL schema
正式错误码
正式权限码
用于生产环境的实现代码
```

## 3.3 沉淀规则

用户确认后的 S0 原型必须沉淀到：

```text
00_product/domains/<domain_id>/product-spec.md
```

并在 `product-spec.md` 的“原型来源”章节显式保留：

```text
原型路径
原型目标
确认状态
沉淀范围
未沉淀内容
```

S0 与 S1 不一致时，以 S1 为准。
若 S0 中存在已确认但未沉淀的能力，必须补充到 S1。

---

# 4. S1 产品语义事实源

## 4.1 定位

S1 负责描述完整产品语义，包括：

```text
功能是什么
为什么需要
用户如何使用
核心业务对象是什么
业务规则是什么
有哪些用户故事
不同端支持哪些能力
不同端如何呈现
哪些能力本阶段不做
如何验收
```

S1 不负责规定：

```text
API 路径细节
SQL 表结构细节
错误码编码细节
权限码编码细节
前端组件细节
后端 service 函数细节
ORM 结构
HTTP DTO 名称
```

---

## 4.2 聚合原则

每个 domain 仅维护一个核心产品文档：

```text
00_product/domains/<domain_id>/product-spec.md
```

`product-spec.md` 聚合该领域的产品知识，避免评审时跳转漏读。
若内容较多，可以拆分为章节，但原则上仍保持在同一个文件内。

---

## 4.3 product-spec.md 模板

```markdown
# <Domain> 产品规格

## 文档信息

- 版本：v1.x:
- 最后更新：YYYY-MM-DD
- 作者：
- domain_id：
- domain_code：

## 0. 原型来源

若源于 S0，说明原型路径、原型目标、确认状态、沉淀范围和未沉淀内容。

## 1. 功能概述

说明目标、用户价值、适用范围和非目标范围。

## 2. 核心数据模型

说明实体及逻辑字段。

本节仅描述 S1 领域模型，表达产品语义和逻辑字段，不等同于 OpenAPI DTO、SQL schema 或 ORM。

## 3. 业务规则

使用稳定编号 `BR-<DOMAIN_CODE>-<三位数字>`。

业务规则覆盖状态、权限、可见性、校验、默认值、归档、异步、多端差异等。

## 4. 用户故事

使用稳定编号 `US-<DOMAIN_CODE>-<三位数字>`。

用户故事描述用户目标、操作路径、涉及角色、端能力、主要状态、异常情况和相关业务规则。

## 5. 功能适配矩阵

以 `00_product/global-feature-matrix.md` 中的端列表为基准，使用 ✅ / ❌ / ⚠️ / 🚧 标记支持度。

## 6. 各端呈现策略

说明布局、交互、状态、屏蔽能力及端限制。

不写具体组件名、CSS class、状态管理库或平台实现类。

## 7. 验收标准

使用稳定编号 `AC-<DOMAIN_CODE>-<US三位数字>-<两位序号>`。

验收标准覆盖前置条件、用户操作、预期结果、适用端和异常覆盖。

## 8. 非目标范围

明确本阶段不实现的能力。

## 9. 待确认问题

记录仍需确认的问题。
```

---

## 4.4 核心数据模型规则

S1 核心数据模型只描述领域语义。

允许描述：

```text
实体名
逻辑字段名
逻辑类型，如 string(100)、money、boolean、date-time
是否必填
业务含义
字段约束
实体关系
```

禁止描述：

```text
数据库 column 名
数据库索引
数据库外键细节
ORM 结构
HTTP DTO 名称
前端 TypeScript 具体类型
```

---

## 4.5 编号与命名规范

`domain_id` 用于目录名，使用小写短横线：

```text
ai-chat
asset-library
model-management
workflow-canvas
```

`domain_code` 用于编号，使用大写无分隔符：

```text
AICHAT
ASSET
MODEL
WORKFLOW
```

编号格式：

```text
BR-<DOMAIN_CODE>-<三位数字>
US-<DOMAIN_CODE>-<三位数字>
AC-<DOMAIN_CODE>-<US三位数字>-<两位序号>
```

示例：

```text
BR-AICHAT-001
US-AICHAT-001
AC-AICHAT-001-01
AC-AICHAT-001-02
```

编号一旦 release，应保持稳定。
语义废弃时应标记 deprecated，不应复用旧编号表达新语义。

---

## 4.6 术语规则

跨领域复用的核心业务术语必须收归：

```text
00_product/glossary.md
```

仅在单一 domain 内使用的术语，可以在对应 `product-spec.md` 中首次定义。

S1 文档中首次出现重要术语时，应链接到 `glossary.md` 或在当前文档中明确声明定义。

---

## 4.7 Mermaid 可视化规则

S1 用户故事和业务规则可以使用 Mermaid 图辅助理解复杂流程、状态变化、角色权限和交互时序。

Mermaid 图必须绑定明确的用户故事 ID 或业务规则 ID。

每个图前必须声明：

```markdown
> ⚠️ 本图是对对应 US/BR 的可视化补充；若与文字冲突，以文字为准，但二者应视为同一事实，冲突必须修正。
```

适用场景：

| 场景       | 推荐图类型             |
| -------- | ----------------- |
| 多步骤操作流   | `stateDiagram-v2` |
| 角色权限与可见性 | `graph TD`        |
| 消息流与交互时序 | `sequenceDiagram` |
| 业务规则分支   | `graph TD`        |
| 后台任务生命周期 | `stateDiagram-v2` |

Mermaid 图要求：

```text
不能单独存在，必须有对应文字说明
不能引入文字中不存在的新规则
不能引入文字中不存在的新状态
不能引入文字中不存在的新角色
不能引入文字中不存在的新接口
术语必须来自当前 S1 文档或 glossary.md
复杂图应拆成多个小图
```

---

## 4.8 功能矩阵与端列表

端类型由以下文件统一定义：

```text
00_product/global-feature-matrix.md
```

领域级 `product-spec.md` 只能引用全局端类型，不得自行创造端标识。

推荐支持度标记：

```text
✅ 支持
❌ 不支持
⚠️ 部分支持
🚧 后续支持
```

功能适配矩阵是实现范围约束。
标记为不支持的端，不应被扩展为完整能力。

---

# 5. S2 实现契约事实源

## 5.1 定位

S2 是 S1 的结构化表达，用于指导实现和自动化校验。

S2 不能凭空创造 S1 中未定义的核心业务能力。

S2 负责定义：

```text
API
请求响应结构
设计态 SQL schema
错误码
权限码
事件契约
模块契约
```

---

## 5.2 文件位置

```text
01_contracts/domains/<domain_id>/
├── openapi.yaml
├── schema.sql
├── errors.yaml
├── permissions.yaml
├── events.yaml
└── module-contract.md
```

---

## 5.3 S1 追溯性要求

所有 S2 契约必须能追溯到 S1 元素。

OpenAPI operation、错误码、权限码、事件必须显式引用相关 US/BR。

`schema.sql` 至少在表级标注来源；关键字段可补充字段级注释。

推荐引用字段：

```yaml
x-s1-refs:
  user_stories:
    - US-AICHAT-001
  business_rules:
    - BR-AICHAT-002
```

或使用等效字段：

```yaml
related_user_stories:
  - US-AICHAT-001
related_rules:
  - BR-AICHAT-002
```

要求：

```text
引用编号必须真实存在
引用编号必须属于当前或明确依赖的 domain
不得引用不存在、废弃或语义无关的编号
```

---

## 5.4 openapi.yaml 规则

`openapi.yaml` 覆盖所有需要服务支持的 S1 用户故事。

必须定义：

```text
接口路径
HTTP 方法
请求参数
请求体
响应结构
错误响应
状态码
鉴权要求
分页规则
排序规则
过滤规则
x-s1-refs
```

禁止：

```text
先实现后反推 OpenAPI
OpenAPI 与 S1 用户故事长期不一致
OpenAPI 中出现 S1 未定义的核心业务能力
```

---

## 5.5 schema.sql 规则

`schema.sql` 是设计态表结构，不是实际 migration。

必须定义：

```text
表
字段
字段类型
主键
唯一约束
外键关系
索引建议
默认值
软删除策略
时间字段
JSON 字段约束
状态字段取值
S1 来源注释
```

建议用 SQL 注释标注来源：

```sql
-- s1_refs: US-AICHAT-001, BR-AICHAT-002
CREATE TABLE ai_assistants (
  id UUID PRIMARY KEY
);
```

---

## 5.6 errors.yaml 规则

错误码必须来自 S1 的业务规则或异常场景。

推荐结构：

```yaml
ERROR_CODE:
  message:
  http_status:
  module:
  meaning:
  frontend_behavior:
  retryable:
  related_rules:
    - BR-XXX-001
  related_user_stories:
    - US-XXX-001
```

要求：

```text
唯一
稳定
语义清晰
HTTP 状态码明确
前端展示行为明确
必须关联 S1
```

---

## 5.7 permissions.yaml 规则

权限码必须来自 S1 的角色、可见性和操作规则。

推荐结构：

```yaml
PERMISSION_CODE:
  module:
  resource:
  action:
  description:
  frontend_usage:
  backend_enforcement:
  related_rules:
    - BR-XXX-001
  related_user_stories:
    - US-XXX-001
```

要求：

```text
唯一
稳定
前后端共用
前端可用于展示控制
后端必须用于真实校验
必须关联 S1
```

---

## 5.8 events.yaml 规则

事件定义必须来自 S1 的异步流程、任务状态、通知规则或跨模块协作需求。

推荐结构：

```yaml
event_name:
  producer:
  consumers:
    - consumer_name
  trigger_condition:
  payload:
  idempotency_key:
  retry_policy:
  failure_policy:
  related_rules:
    - BR-XXX-001
  related_user_stories:
    - US-XXX-001
```

要求：

```text
事件名唯一
payload 明确
生产者明确
消费者明确
触发时机明确
幂等规则明确
失败处理明确
必须关联 S1
```

---

## 5.9 module-contract.md 规则

`module-contract.md` 用于定义模块职责和边界。

应包含：

```text
模块职责
模块不负责什么
输入
输出
依赖模块
被依赖模块
跨模块调用规则
数据归属
权限边界
事件边界
相关 S1 引用
```

模块契约用于防止模块边界混乱和跨模块穿透。

---

# 6. 架构参考

架构参考文件：

```text
02_architecture/global-architecture.md
02_architecture/domains/<domain_id>.md
```

用于说明：

```text
全局模块关系
领域模块关系
核心时序
运行时边界
外部 provider 边界
跨模块依赖
```

架构参考不替代 S1/S2。

冲突处理：

```text
产品语义以 S1 为准。
实现契约以 S2 为准。
架构参考需同步修正。
```

---

# 7. Release 规则

Release 由用户人工确认，记录在：

```text
RELEASE.md
```

每次 release 必须注明：

```text
版本号
对应 commit
涉及的 domain 列表
该 domain 下所有 S1 文件
该 domain 下所有 S2 文件
用户确认状态
是否允许作为正式实现依据
```

示例：

```markdown
# RELEASE

## spec-v0.1.0

- commit: abc123456789
- status: released
- confirmed_by: user
- allowed_as_formal_implementation_basis: true
- domains:
  - ai-chat
- S1:
  - 00_product/domains/ai-chat/product-spec.md
- S2:
  - 01_contracts/domains/ai-chat/openapi.yaml
  - 01_contracts/domains/ai-chat/schema.sql
  - 01_contracts/domains/ai-chat/errors.yaml
  - 01_contracts/domains/ai-chat/permissions.yaml
  - 01_contracts/domains/ai-chat/events.yaml
  - 01_contracts/domains/ai-chat/module-contract.md
```

`CHANGELOG.md` 记录所有变更历史，包括未发布草稿。
`RELEASE.md` 只记录用户确认后的正式版本。
二者应保持对应关系。

---

# 8. 冲突处理

## 8.1 冲突记录

发现冲突者必须记录：

```text
冲突位置
相关文件
相关编号
冲突描述
建议修正方向
```

冲突可通过以下方式追踪：

```text
Issue
PR 评论
变更说明
product-spec.md 待确认问题
CHANGELOG.md 草稿记录
```

## 8.2 冲突优先级

```text
S0 vs S1：
以 S1 为准；若 S0 有已确认但未沉淀内容，补入 S1。

S1 文字 vs Mermaid 图：
以文字为准，但二者是同一事实集合，冲突必须修正。

S1 vs S2：
必须修正 S1 或 S2，修正后重新 release。

S2 vs 实现：
实现错则改实现；S2 遗漏则补 S2；若变动影响产品语义，须同步更新 S1。
```

---

# 9. 禁止事项

## 9.1 全仓禁止

```text
存放正式实现代码
维护实际数据库 migration
把 S0 原型当正式事实源
只写 S2 不写 S1
在 S1/S2 冲突时 release
```

## 9.2 S1 禁止

```text
过度规定数据库实现细节
过度规定 API DTO 细节
过度规定前端组件细节
过度规定后端 service 函数
```

## 9.3 S2 禁止

```text
凭空新增 S1 未定义的核心业务能力
与 S1 用户故事长期不一致
将临时实现反向写为契约
```

---

# 10. 最终规则

```text
S0 是探索，不是事实源。
S1 是产品语义事实源。
S2 是实现契约事实源。

S1 要聚合，方便评审。
S2 要结构化，方便生成和校验。

未 release 的 S1/S2 可用于讨论、探索和评估。
已 release 的 S1/S2 才能作为正式实现、合并、验收和发布依据。

产品语义以 S1 为准。
实现契约以 S2 为准。
冲突必须修正，不能长期并存。
```
