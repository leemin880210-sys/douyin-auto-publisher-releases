# douyin_operation_system BOOT

project_id: `douyin_operation_system`

本项目是由 `project_brain` 与 `douyin_account_ops` 合并后的统一抖音代运营业务项目。

AI_MEMORY_SYSTEM v2.0 下，本目录作为外部记忆容器中的项目实例，只保存项目恢复所需的聊天、状态、任务、核心规则、日志和最近 3 次完整源码快照。

## v2.0 强制读取顺序

任何 AI / Codex 进入本项目必须按顺序读取：

1. `CHAT_LOGS.md`
2. `STATE.json`
3. `CODE_SNAPSHOTS/v1_latest/`
4. `BOOT.md`
5. `TASKS.json`
6. `CORE.md`
7. `LOGS.md`

涉及账号采集模块时，必须继续读取：

1. `modules/account_ops/BOOT.md`
2. `modules/account_ops/STATE.json`
3. `modules/account_ops/TASKS.json`
4. `modules/account_ops/CORE.md`
5. `modules/account_ops/LOGS.md`
6. `modules/account_ops/CODE_EVOLUTION.md`

## 项目结构来源

- `project_brain` 已迁移为本项目根部的 core system。
- `douyin_account_ops` 已迁移为 `modules/account_ops/` 模块。
- `modules/data_analysis/` 与 `modules/content_pipeline/` 为统一业务项目内的预留模块目录。

## 项目边界

- 本项目是 registry 中唯一活跃业务项目。
- AI_MEMORY_SYSTEM 只作为外部记忆容器，不直接参与业务逻辑。
- 本项目不修改 `AI_MEMORY_SYSTEM/00_GLOBAL_MEMORY`。
- 本项目内部模块不得写入其他项目状态。
- root `STATE.json` 只记录统一业务项目状态。
- 模块状态保留在各自模块目录内，不覆盖 root 状态。

## 执行规则

- `CHAT_LOGS.md` 记录用户、AI、Codex 对话，必须按时间追加。
- root `STATE.json` 是统一项目当前状态源。
- `CODE_SNAPSHOTS/v1_latest/` 是当前最新完整代码快照。
- root `TASKS.json` 只记录统一项目待执行任务和模块路由任务。
- root `CORE.md` 记录长期业务边界、输出规则和模块职责。
- root `LOGS.md` 只记录已发生事实。
- 任务结束前必须回写 root `CHAT_LOGS.md`、`STATE.json` 和 `LOGS.md`。
- 涉及代码或规则变化时，必须同步 `CODE_EVOLUTION.md` 和 `CODE_SNAPSHOTS/`。

## CODE_SNAPSHOTS 滚动规则

每次源码或项目核心文件修改时：

1. 新版本写入 `CODE_SNAPSHOTS/v1_latest/`。
2. 修改前的 `v1_latest/` 下移为 `v2_previous/`。
3. 修改前的 `v2_previous/` 下移为 `v3_previous_previous/`。
4. 不允许删除历史聊天或已有代码版本。

## 强制回写顺序

1. 更新 root `CHAT_LOGS.md`。
2. 更新 root `STATE.json`。
3. 写入 root `LOGS.md`。
4. 如任务变化，同步 root `TASKS.json`。
5. 如修改代码或核心文件，同步 `CODE_EVOLUTION.md` 与 `CODE_SNAPSHOTS/`。
6. 如修改模块规则或代码，同步对应模块日志与代码演进记录。

## 禁止行为

- 不允许把 registry 当 memory 使用。
- 不允许把 global memory 写入项目层。
- 不允许跨项目读取未授权项目数据。
- 不允许共享不同项目的 STATE。
- 不允许删除历史聊天。
- 不允许删除历史 LOGS。
- 不允许删除代码版本。
- 不允许覆盖既有输出文件。
- 不允许修改抖音采集代码，除非用户明确要求。
