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

本项目是面向微小商家的抖音代运营、账号采集、内容生成与 AI 工作流系统。业务范围包括：

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

## 执行方式规则

```text
人工触发 + AI生成 + 结构化输出模式
```

本项目默认不是自动执行系统。模块执行许可，以 `STATE.json` 和 `MASTER_CONTROL.md` 为准。

## 阶段状态读取规则

`CORE.md` 不描述当前状态。

- 阶段判断以 `STATE.json` 为准。
- 任务判断以 `TASKS.json` 为准。
- 事实记录以 `LOGS.md` 为准.
- 执行权限以 `MASTER_CONTROL.md` 为准。
- 模块路由以 `MODULE_ROUTES.md` 为准。

## 通用限制

- 未实现自动上传/同步机制。
- 不做不影响使用的微优化。
## 禁止做什么

- 不绕过登录。
- 不破解验证码。
- 不抓取无权限内容。
- 不采集或外传本机 cookie。
- 不把未授权数据伪造成已授权数据。
- 不承诺投流、广告投放、涨粉或成交结果。
- 不修改与授权任务无关的业务代码。
- 不删除历史聊天。
- 不删除历史日志。
- 不删除代码版本。
- 不覆盖已有输出文件。
- 不混用不同商家的作品编号。
- 不修改 `AI_MEMORY_SYSTEM/00_GLOBAL_MEMORY`。
- 不把旧 `project_brain` 或 `douyin_account_ops` 作为独立注册项目继续运行。

## 采集包存储边界

1. 采集包 ZIP 默认保存在本地，不提交到 `AI_MEMORY_SYSTEM`。
2. `output_zip/` 保存 ZIP 包。
3. `output/packages/{package_base_name}/` 保存解压后的采集包目录。
4. `AI_MEMORY_SYSTEM` 不保存每个采集包本体。
5. `AI_MEMORY_SYSTEM` 只保存：
   - 采集包命名规则。
   - 输出路径规则。
   - `package_metadata` 字段要求。
   - 采集包检查标准。
   - 分析模块如何读取用户上传的 ZIP。
6. 如果需要 GPT 分析某个店铺，用户需要上传对应 ZIP 包，或者让 Codex 在本地读取该 ZIP 路径。
7. 如果需要长期追踪采集包，只记录 `package_metadata` 或 `package_index`，不保存大文件。
8. 不要把商家隐私数据、评论截图、视频关键帧批量提交到 GitHub 外部大脑。

## 外部大脑恢复原则

1. 外部大脑的首要目标是防止换 AI 后从 0 开始。
2. 新 AI 必须先读取 MASTER_CONTROL，再恢复项目总框架、阶段信息和模块路由。
3. `MASTER_CONTROL.md` 是系统总控制器。
4. `PROJECT_FRAMEWORK.md` 是系统总框架。
5. `MODULE_ROUTES.md` 是模块入口判断规则。
6. `STATE.json` 是当前状态。
7. `TASKS.json` 是下一步任务。
8. `LOGS.md` 是已发生事实。
9. `CHAT_LOGS.md` 是用户与 AI/Codex 的关键对话记录。
10. `CODE_EVOLUTION.md` 只记录采集工具代码演进。
11. 采集包 ZIP 是本地业务数据，不进入外部大脑。

## MASTER_CONTROL 优先原则

1. `ENTRY_PROTOCOL.md` 是系统启动协议。
2. `MASTER_CONTROL.md` 是当前项目最高优先级控制器。
3. 新 AI 必须先读取 `STATE.json`，再按 `ENTRY_PROTOCOL.md` 的固定顺序读取控制链路。
3. 当前唯一允许执行模块是 `account_ops`。
4. 当前唯一合法动作是读取采集包 / 生成采集包 / 检查采集包。
5. 未经用户后续明确授权，不得启动账号深度分析、商家建档、商家大脑、内容生成、自动发布或数据复盘。
6. 如果其他文件与 `MASTER_CONTROL.md` 冲突，以 `MASTER_CONTROL.md` 的执行权限限制为准。

## ENTRY_PROTOCOL 启动原则

1. `ENTRY_PROTOCOL.md` 是系统启动协议。
2. 任何 AI / Codex / GPT 进入本系统必须先读取 `ENTRY_PROTOCOL.md`。
3. 固定读取顺序是 `MASTER_CONTROL.md` → `PROJECT_FRAMEWORK.md` → `MODULE_ROUTES.md` → `STATE.json` → `TASKS.json`。
4. 读取后必须输出启动恢复六项信息。
5. 没有用户明确指令前，只允许读取，不允许执行。
6. 禁止直接执行 `shop_account_analysis`、创建 `merchant_brain`、跳过 `account_ops` 或跨模块执行。

## STATE_CONSOLIDATION_RULES 状态收敛原则

1. `STATE.json` 是唯一状态源。
2. `TASKS.json` 是唯一任务源。
3. `LOGS.md` 是事实记录源。
4. `CORE.md`、`PROJECT_FRAMEWORK.md`、`MODULE_ROUTES.md`、`README.md` 不描述当前状态。
5. 如果不同文件冲突，优先级为：`STATE.json` > `TASKS.json` > `LOGS.md` > 其他文件。
6. `MASTER_CONTROL.md` 只用于约束执行权限，不用于描述状态。
