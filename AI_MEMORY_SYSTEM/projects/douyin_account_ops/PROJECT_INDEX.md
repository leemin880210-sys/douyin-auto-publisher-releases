# 抖音代运营采集工具 项目索引

project_id: `douyin_account_ops`

name: 抖音代运营采集工具

type: `data_analysis`

status: `active`

path: `AI_MEMORY_SYSTEM/projects/douyin_account_ops`

## 用途

本项目用于保存抖音代运营采集工具的独立项目记忆，包括：

- 抖音账号采集包规则
- 未授权账号内容诊断规则
- 授权后指标补齐边界
- 代运营接手前分析规则
- Codex 中转和 GPT 检查任务

## 文件说明

- `BOOT.md`：项目入口和执行规则。
- `STATE.json`：当前唯一状态源。
- `TASKS.json`：当前待修任务和验收标准。
- `CORE.md`：长期稳定采集规则。
- `LOGS.md`：已发生事实记录。
- `PROJECT_INDEX.md`：项目索引和文件说明。

## 隔离要求

- 本项目不写入全局记忆。
- 本项目不污染 `project_brain`。
- 本项目不读取或修改其他项目实例。
