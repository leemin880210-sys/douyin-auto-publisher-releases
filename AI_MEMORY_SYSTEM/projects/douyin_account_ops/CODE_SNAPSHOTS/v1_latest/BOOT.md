# 抖音代运营采集工具 BOOT

project_id: `douyin_account_ops`

本项目是 `AI_MEMORY_SYSTEM` 下的独立项目实例，只保存抖音代运营采集工具的项目记忆、状态、任务和日志。

## 强制读取顺序

任何 AI 进入本项目必须按顺序读取：

1. `BOOT.md`
2. `STATE.json`
3. `TASKS.json`
4. `CORE.md`
5. `LOGS.md`

## 项目隔离

- 不允许把本项目状态写入全局记忆。
- 不允许把本项目状态写入 `project_brain`。
- 不允许读取或修改未授权项目实例。
- 不允许修改 `AI_MEMORY_SYSTEM/00_GLOBAL_MEMORY`。
- 不允许修改抖音采集代码，除非用户明确要求。

## 执行规则

- `STATE.json` 是本项目唯一当前状态源。
- `TASKS.json` 只记录待执行任务和验收标准。
- `CORE.md` 只记录长期规则和已确认采集规范。
- `LOGS.md` 只记录已发生事实。
- 任务结束前必须回写 `STATE.json` 和 `LOGS.md`。
- 如果任务内容变化，必须同步 `TASKS.json`。

## 当前用途

本项目用于维护抖音账号采集包工具的产品规则、采集边界、输出规范、待修问题和 Codex/GPT 协同检查状态。
