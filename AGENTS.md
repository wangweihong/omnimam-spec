# OmniMAM Spec Agent Rules

本仓库是 OmniMAM 的规格仓库，负责维护 S0、S1、S2 相关制品。

详细规则不写在顶层 `AGENTS.md` 中，避免顶层规则过长。


## 必读 Skill

任何修改本仓库内容前，必须读取：

```text
skills/spec-workflow/SKILL.md
```

该 Skill 定义：

```text
S0 原型沉淀规则
S1 产品语义事实源规则
S2 实现契约事实源规则
目录结构
编号规范
Mermaid 可视化规则
Release 规则
冲突处理规则
禁止事项
```

## 仓库边界

本仓库只维护：

```text
00_product/       # S1 产品语义事实源
01_contracts/     # S2 实现契约事实源
02_architecture/  # 架构参考
CHANGELOG.md
RELEASE.md
```

本仓库禁止维护：

```text
正式前端实现代码
正式后端实现代码
实际数据库 migration
运行时配置
CI/CD 实现细节
```

## 输出语言

除代码、路径、字段名、协议名、枚举值、API 路径、SQL、YAML、Mermaid 等技术内容外，说明性文本默认使用中文。

## 修改原则

修改任何 domain 时，必须优先定位：

```text
00_product/domains/<domain_id>/product-spec.md
01_contracts/domains/<domain_id>/
02_architecture/domains/<domain_id>.md
```

涉及产品语义时，先改 S1。

涉及接口、schema、错误码、权限码、事件或模块边界时，改 S2。

如果 S2 变更会影响产品语义，必须同步更新 S1。

## 最终规则

```text
顶层 AGENTS.md 只做路由和边界声明。
完整 SSOT / Spec 工作流规则见 skills/spec-workflow/SKILL.md。
```
