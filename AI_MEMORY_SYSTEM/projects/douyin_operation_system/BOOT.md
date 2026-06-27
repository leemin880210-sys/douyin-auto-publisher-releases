# douyin_operation_system BOOT

project_id: `douyin_operation_system`

本项目是由 `project_brain` 与 `douyin_account_ops` 合并后的统一抖音代运营业务项目。

- `project_brain` 已迁移为本项目根部的 core system。
- `douyin_account_ops` 已迁移为 `modules/account_ops/` 模块。
- `modules/data_analysis/` 与 `modules/content_pipeline/` 为统一业务项目内的预留模块目录。

## 强制读取顺序

任何 AI 进入本项目必须按顺序读取：

1. `BOOT.md`
2. `STATE.json`
3. `TASKS.json`
4. `CORE.md`
5. `LOGS.md`

涉及账号采集模块时，必须继续读取：

1. `modules/account_ops/BOOT.md`
2. `modules/account_ops/STATE.json`
3. `modules/account_ops/TASKS.json`
4. `modules/account_ops/CORE.md`
5. `modules/account_ops/LOGS.md`
6. `modules/account_ops/CODE_EVOLUTION.md`

## 项目边界

- 本项目是 registry 中唯一活跃业务项目。
- 本项目不承担全局记忆职责。
- 本项目不修改 `AI_MEMORY_SYSTEM/00_GLOBAL_MEMORY`。
- 本项目内部模块不得写入其他项目状态。
- root `STATE.json` 只记录统一业务项目状态。
- 模块状态保留在各自模块目录内，不覆盖 root 状态。

## 执行规则

- root `STATE.json` 是统一项目当前状态源。
- root `TASKS.json` 只记录统一项目待执行任务和模块路由任务。
- root `CORE.md` 记录长期业务边界、输出规则和模块职责。
- root `LOGS.md` 只记录已发生事实。
- 任务结束前必须回写 root `STATE.json` 和 `LOGS.md`。
- 涉及 `account_ops` 代码或规则时，必须同步 `modules/account_ops/CODE_EVOLUTION.md` 与 `modules/account_ops/LOGS.md`。

## 强制回写顺序

1. 更新 root `STATE.json`。
2. 写入 root `LOGS.md`。
3. 如任务变化，同步 root `TASKS.json`。
4. 如修改模块规则或代码，同步对应模块日志与代码演进记录。

## 禁止行为

- 不允许把 registry 当 memory 使用。
- 不允许把 global memory 写入项目层。
- 不允许跨项目读取未授权项目数据。
- 不允许共享不同项目的 STATE。
- 不允许删除历史 LOGS。
- 不允许覆盖既有输出文件。
- 不允许修改抖音采集代码，除非用户明确要求。
