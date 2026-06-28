# MEMORY_CONTINUITY.md

本文件用于帮助新 AI 延续上一轮 AI / Codex 的工作，不替代 `STATE.json`，不作为执行权限来源。

## 当前系统最新状态

- 系统名称：`douyin_operation_system`
- 系统版本：外部大脑 3.0 可演化记忆系统
- 当前唯一真实状态源：`STATE.json`
- 当前唯一运行模块：`account_ops`
- 当前允许动作：读取采集包 / 生成采集包 / 检查采集包
- 当前禁止动作：账号分析、商家建档、内容生成、数据复盘、自动发布、跨模块执行
- 采集工具代码：本次未修改

## 当前所有模块关系

```text
account_ops
  -> shop_account_analysis
  -> merchant_brain_factory
  -> merchants
  -> content_pipeline
  -> data_review
```

说明：

- `account_ops` 是当前唯一运行模块。
- `shop_account_analysis` 是后续分析模块，未授权不得启动。
- `merchant_brain_factory` 是后续商家大脑创建模块，未授权不得启动。
- `merchants` 用于未来商家独立大脑，当前只保留模板和规则。
- `content_pipeline` 与 `data_review` 为后续模块，未授权不得启动。

## 当前历史关键决策摘要

- 采用 `COGNITIVE_ENTRY.md` 作为唯一认知入口，避免多入口造成版本分裂。
- 采用 `STATE.json` 作为唯一状态源，避免 STATE 语义污染。
- 采用 `MASTER_CONTROL.md` 管理执行权限，避免新 AI 跨模块执行。
- 采用 `TASKS.json` 只记录下一步动作，避免任务文件承担系统结构职责。
- 采用 `PROJECT_FRAMEWORK.md` 和 `MODULE_ROUTES.md` 描述结构和路由，不描述当前执行状态。
- 采用 `CHANGE_LOG.md` 追踪变更，采用 `DECISION_LOG.md` 解释关键设计决策。

## 当前系统演进路径

```text
单项目大脑
  -> AI_MEMORY_SYSTEM 多项目外部大脑
  -> douyin_operation_system 统一业务项目
  -> COGNITIVE_ENTRY 单入口认知系统
  -> 外部大脑 3.0 可演化记忆系统
```

## 新 AI 接手方式

新 AI 必须先读取：

1. `COGNITIVE_ENTRY.md`
2. `CHANGE_LOG.md`
3. `DECISION_LOG.md`
4. `STATE.json`
5. `TASKS.json`
6. `MASTER_CONTROL.md`
7. `PROJECT_FRAMEWORK.md`
8. `MODULE_ROUTES.md`

然后才能判断是否执行用户任务。
