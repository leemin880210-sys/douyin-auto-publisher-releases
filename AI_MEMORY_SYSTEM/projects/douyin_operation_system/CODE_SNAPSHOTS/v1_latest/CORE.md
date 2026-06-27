# douyin_operation_system CORE

本文件是统一抖音代运营业务项目的长期核心认知。

## AI_MEMORY_SYSTEM v2.0 容器定位

AI_MEMORY_SYSTEM 是外部记忆容器，负责保存项目聊天、状态、任务、日志、核心规则和最近 3 次完整源码快照。

AI_MEMORY_SYSTEM 不直接参与业务逻辑执行；业务执行只由用户明确授权的项目、模块或实际源码完成。

## 在 AI_MEMORY_SYSTEM 中的位置

```text
AI_MEMORY_SYSTEM/projects/douyin_operation_system
```

本项目由两个原独立项目合并而来：

- `project_brain` → root core system。
- `douyin_account_ops` → `modules/account_ops/`。

合并后，registry 只注册 `douyin_operation_system` 一个统一业务项目。

## v2.0 必备恢复文件

本项目必须包含：

- `CHAT_LOGS.md`
- `CODE_EVOLUTION.md`
- `CODE_SNAPSHOTS/v1_latest/`
- `CODE_SNAPSHOTS/v2_previous/`
- `CODE_SNAPSHOTS/v3_previous_previous/`
- `BOOT.md`
- `STATE.json`
- `TASKS.json`
- `CORE.md`
- `LOGS.md`

## CHAT_LOGS 规则

- 记录用户、AI、Codex 对话。
- 必须按时间追加。
- 不允许丢失、覆盖、折叠或隐藏历史。

## CODE_SNAPSHOTS 规则

- `v1_latest/` 保存最新完整代码。
- `v2_previous/` 保存上一版完整代码。
- `v3_previous_previous/` 保存上上版完整代码。
- 每次修改必须滚动更新。
- 保存完整代码文件，不只保存 diff。

## 模块职责

### core system（项目根部）

负责统一项目入口、状态、任务、核心规则、日志、聊天记录、源码快照和模块路由。

### modules/account_ops

来源于 `douyin_account_ops`，负责账号采集工具记忆，包括：

- 抖音账号采集包规则
- 未授权账号内容采集边界
- 授权后指标补齐边界
- OCR、评论、抽帧、run_mode、ZIP 输出规则
- 采集代码演进记录

### modules/data_analysis

预留模块，用于后续数据复盘、指标分析和多商家对比。

### modules/content_pipeline

预留模块，用于后续脚本、素材、图片、视频和交付文件流水线。

## 本项目业务范围

本项目是面向微小商家的抖音代运营、账号采集、内容生成与 AI 工作流系统。当前重点包括：

- 抖音账号公开内容采集与分析包生成
- 商家建档
- 素材整理
- 短视频脚本生成
- 视频、图片、zip 输出
- 数据复盘
- GPT 与 Codex 协同执行

## 输出命名规则（v1.0）

规则版本时间：`2026-01-24_1530`

```text
{店铺名称}-{作品数量}-{时间}
```

时间格式：

```text
YYYYMMDD_HHMM
```

示例：

```text
星火奶茶店-001-20260124_1530.mp4
星火奶茶店-002-20260124_1530.txt
```

## ZIP 压缩包规则

所有 zip 文件必须存放在：

```text
/output_zip/
```

zip 命名规则：

```text
{店铺名称}-{作品数量}-{时间}.zip
```

## 防冲突规则

- 不允许同名覆盖。
- 每个作品必须递增编号。
- 同商家必须连续编号。
- 不同商家必须隔离命名。
- 所有输出必须唯一。

## 当前运行模式

```text
人工触发 + AI生成 + 结构化输出模式
```

当前不是自动执行系统。

## 当前限制

- 未实现自动文件夹隔离（每商家独立目录）。
- 未实现自动上传/同步机制。
- `modules/account_ops` 的新字段和输出命名规则仍需继续通过实际 5 条样本包与 30 条正式包复测。

## 禁止做什么

- 不绕过登录。
- 不破解验证码。
- 不抓取无权限内容。
- 不采集或外传本机 cookie。
- 不把未授权数据伪造成已授权数据。
- 不承诺投流、广告投放、涨粉或成交结果。
- 不修改与当前任务无关的业务代码。
- 不删除历史聊天。
- 不删除历史日志。
- 不删除代码版本。
- 不覆盖已有输出文件。
- 不混用不同商家的作品编号。
- 不修改 `AI_MEMORY_SYSTEM/00_GLOBAL_MEMORY`。
- 不把旧 `project_brain` 或 `douyin_account_ops` 作为独立注册项目继续运行。
