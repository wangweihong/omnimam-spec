skills/spec-workflow/SKILL.md
# OmniMAM Spec Workflow Skill

本文档是 `omnimam-spec` 仓库的 Spec 工作流入口。

完整规则已拆分为：

```text
skills/spec-workflow/S0.md
skills/spec-workflow/S1.md
skills/spec-workflow/S2.md
``` 
## 1. 必读顺序

修改本仓库前，按任务类型读取对应规则：

涉及原型、S0 沉淀、原型来源：
  读取 skills/spec-workflow/S0.md

涉及产品语义、用户故事、业务规则、验收标准：
  读取 skills/spec-workflow/S1.md

涉及 OpenAPI、SQL schema、错误码、权限码、事件、模块契约：
  读取 skills/spec-workflow/S2.md

如果任务跨阶段，必须同时读取相关文件。

示例：
```
从原型沉淀产品文档：
  读取 S0.md + S1.md

根据产品文档生成契约：
  读取 S1.md + S2.md

修正接口字段导致产品语义变化：
  读取 S1.md + S2.md
```

## 2. 阶段定位
S0 是探索，不是事实源。
S1 是产品语义事实源。
S2 是实现契约事实源。

S0 用于快速验证想法、交互、页面布局和功能可行性。

S1 回答：
```
做什么
为什么做
用户如何使用
怎么做才算完成
```
S2 回答：
```
API 如何定义
数据结构如何定义
错误码如何定义
权限码如何定义
事件如何定义
模块边界如何定义
```

## 3. 目录结构
```
omnimam-spec/
├── AGENTS.md
├── CHANGELOG.md
├── RELEASE.md
├── skills/
│   └── spec-workflow/
│       ├── SKILL.md
│       ├── S0.md
│       ├── S1.md
│       └── S2.md
├── 00_product/
│   ├── glossary.md
│   ├── global-business-rules.md
│   ├── global-feature-matrix.md
│   └── domains/
│       └── <domain_id>/
│           └── product-spec.md
├── 01_contracts/
|   └── error-code-index.md
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

## 4. 核心优先级
产品语义以 S1 为准。
实现契约以 S2 为准。
架构参考不替代 S1/S2。

冲突时：
```
S0 vs S1：
  以 S1 为准；若 S0 有已确认但未沉淀内容，补入 S1。

S1 文字 vs Mermaid 图：
  以文字为准；但图文是同一事实集合，冲突必须修正。

S1 vs S2：
  必须修正 S1 或 S2，修正后重新 release。

S2 vs 实现：
  实现错则改实现；S2 遗漏则补 S2；若影响产品语义，必须同步更新 S1。
```

## 5. Release 规则
Release 由用户人工确认，记录在`RELEASE.md`
未 release 的 S1/S2 可以用于：
```
草稿讨论
原型探索
实现评估
```
但不得作为：
```
正式实现依据
合并依据
验收依据
发布依据
```
已 release 的 S1/S2 才能作为正式依据。

每次 release 必须记录：
```
版本号
对应 commit
涉及 domain
包含的 S1 文件
包含的 S2 文件
用户确认状态
是否允许作为正式实现依据
```
推荐格式：
```
## spec-v0.1.0

- commit: abc123456789
- status: released
- confirmed_by: user
- allowed_as_formal_implementation_basis: true
- domains:
  - ai-chatting
- S1:
  - 00_product/domains/ai-chatting/product-spec.md
- S2:
  - 01_contracts/domains/ai-chatting/openapi.yaml
  - 01_contracts/domains/ai-chatting/schema.sql
  - 01_contracts/domains/ai-chatting/errors.yaml
  - 01_contracts/domains/ai-chatting/permissions.yaml
  - 01_contracts/domains/ai-chatting/events.yaml
  - 01_contracts/domains/ai-chatting/module-contract.md
```
CHANGELOG.md 记录所有变更，包括未发布草稿。
RELEASE.md 只记录用户确认后的正式版本。

## 6. 命名与编号

domain_id 用于目录名，使用小写短横线：
```
ai-chatting
asset-library
model-management
workflow-canvas
```
domain_code 用于编号，使用大写无分隔符：
```
AICHAT
ASSET
MODEL
WORKFLOW
```
编号格式：
```
BR-<DOMAIN_CODE>-<三位数字>
US-<DOMAIN_CODE>-<三位数字>
AC-<DOMAIN_CODE>-<US三位数字>-<两位序号>
```
示例：
```
BR-AICHAT-001
US-AICHAT-001
AC-AICHAT-001-01
```
编号一旦 release，应保持稳定。
废弃语义应标记 deprecated，不得复用旧编号表达新语义。

7. 禁止事项

全仓禁止：
```
存放正式实现代码
维护实际数据库 migration
把 S0 原型当正式事实源
只写 S2 不写 S1
在 S1/S2 冲突时 release
```
S1 禁止：
```
过度规定数据库实现细节
过度规定 API DTO 细节
过度规定前端组件细节
过度规定后端 service 函数
```
S2 禁止：
```
凭空新增 S1 未定义的核心业务能力
与 S1 用户故事长期不一致
将临时实现反向写为契约
```
## 8. 最终规则
S0 是探索。
S1 是产品语义。
S2 是实现契约。

S1 要聚合，方便评审。
S2 要结构化，方便生成和校验。

冲突必须修正，不能长期并存。