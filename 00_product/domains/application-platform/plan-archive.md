# AI 应用平台计划存档

## 文档信息

- 最后更新：2026-07-10
- domain_id：application-platform
- 当前事实源：`00_product/domains/application-platform/product-spec.md` v0.5.0-draft

## 1. 当前第一阶段范围

以下能力已进入第一阶段事实源，不再作为归档能力：

```text
ProviderAdapter / ProviderOperation 只读目录
ComfyUI 与 SaaS 工作流模板
统一能力图、输入端口和输出端口
InputMapping / OutputMapping
direct SaaS Operation 创建应用
AppEngine 基础管理、健康和并发能力
匹配引擎查询、用户指定和自动路由
应用真实测试
AppRun 与 TaskRun 异步运行协作
标准化输出与结果引用
Seedance 2.0 视频生成
GPT Image 2 图像生成和编辑
```

## 2. 后续计划能力

### 2.1 应用发布与公共市场

```text
应用审核、申请上架、撤回和下架
公共应用与应用市场
发布版本和发布快照
标签治理、质量等级和审核日志
```

### 2.2 外部通知

```text
Webhook 配置、签名和投递记录
Webhook 重试和失败状态
任务或结果完成通知
```

### 2.3 引擎基础设施供给

```text
EngineClass
EngineClaim
EngineProvision
云主机创建或发现
Worker 绑定和自动拉起
GPU 资源、配额和预算确认
```

### 2.4 高级调度与治理

```text
跨区域和成本感知路由
余额、QPS、日配额和费用估算
复杂故障转移和批量容量预留
公共共享引擎池
```

### 2.5 Credential Management / Secret Vault

后续阶段评估建立独立 `credential-management` 领域，负责：

```text
API Key、密码、Bearer Token 和 AK/SK 托管
密钥加密存储和仅写不回显
密钥引用、授权范围和租户隔离
轮换、失效、审计和泄漏响应
Provider 账户余额与凭证可用性
```

当前阶段继续沿用 AppEngine 明文认证配置和回显契约。该行为是已知且已接受的安全风险，不代表后续密钥模块的目标设计。

## 3. 重新进入事实源的条件

归档能力进入 S1/S2 前必须明确阶段目标，补充产品规则、用户故事和验收标准，再推导 API、schema、错误、权限、事件和模块边界；未经用户确认不得记录为 release。
