# douyin_operation_system BOOT

project_id: `douyin_operation_system`

本项目是由 `project_brain` 与 `douyin_account_ops` 合并后的统一抖音代运营业务项目。

AI_MEMORY_SYSTEM v2.0 下，本目录作为外部记忆容器中的项目实例，只保存项目恢复所需的聊天、状态、任务、核心规则、日志和最近 3 次完整源码快照。

## v2.0 强制读取顺序

任何 AI / Codex 进入本项目必须先读取 `STATE.json`，再读取 `STATE_CONSISTENCY_LOCK.md` 和 `ENTRY_PROTOCOL.md`。

状态一致性锁要求：系统状态只允许来自 `STATE.json`，不得从 `CORE.md`、`PROJECT_FRAMEWORK.md`、`MODULE_ROUTES.md` 或 `TASKS.json` 推断状态。

固定读取顺序：

1. `STATE.json`
2. `STATE_CONSISTENCY_LOCK.md`
3. `ENTRY_PROTOCOL.md`
4. `STATE_CONSOLIDATION_RULES.md`
5. `MASTER_CONTROL.md`
6. `PROJECT_FRAMEWORK.md`
7. `MODULE_ROUTES.md`
8. `TASKS.json`

完成固定读取顺序并输出 6 项恢复信息后，再继续读取：

9. `CHAT_LOGS.md`
10. `CODE_SNAPSHOTS/v1_latest/`
11. `BOOT.md`
12. `CORE.md`
13. `LOGS.md`
14. `CODE_EVOLUTION.md`

`ENTRY_PROTOCOL.md` 是系统启动协议，要求没有用户明确指令前只允许读取，不允许执行。  
`STATE_CONSISTENCY_LOCK.md` 定义唯一状态来源和状态判断禁止项。  
`STATE_CONSOLIDATION_RULES.md` 定义状态收敛和冲突优先级。  
`MASTER_CONTROL.md` 是系统总控制器，只约束执行权限。  
`PROJECT_FRAMEWORK.md` 用于理解系统总框架，不描述状态。  
`MODULE_ROUTES.md` 用于判断用户请求应该进入哪个模块，不描述状态。  
如果用户请求不明确，AI 必须先询问，不得自行跨模块执行。

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
- `modules/shop_account_analysis/` 是下一阶段店铺账号深度分析模块。
- `modules/merchant_brain_factory/` 是后续商家独立大脑创建模块。
- `modules/data_analysis/`、`modules/content_pipeline/`、`modules/data_review/` 为预留或后续模块，未授权不得启动。

## 项目边界

- 本项目是 registry 中唯一活跃业务项目。
- AI_MEMORY_SYSTEM 只作为外部记忆容器，不直接参与业务逻辑。
- 本项目不修改 `AI_MEMORY_SYSTEM/00_GLOBAL_MEMORY`。
- 本项目内部模块不得写入其他项目状态。
- root `STATE.json` 只记录统一业务项目状态。
- 模块状态保留在各自模块目录内，不覆盖 root 状态。
- 采集包 ZIP 默认保存在本地，不提交到 `AI_MEMORY_SYSTEM`。

## 执行规则

- `CHAT_LOGS.md` 记录用户、AI、Codex 对话，必须按时间追加。
- root `STATE.json` 是统一项目当前状态源。
- `STATE.json` 是阶段和状态的唯一事实源。
- `ENTRY_PROTOCOL.md` 是系统启动协议。
- `STATE_CONSOLIDATION_RULES.md` 是状态收敛规则。
- `MASTER_CONTROL.md` 是执行权限控制源。
- `PROJECT_FRAMEWORK.md` 是系统总框架源。
- `MODULE_ROUTES.md` 是模块入口判断源。
- `CODE_SNAPSHOTS/v1_latest/` 是当前最新完整代码快照。
- root `TASKS.json` 只记录统一项目待执行任务和模块路由任务。
- root `CORE.md` 记录长期业务边界、输出规则和模块职责。
- root `LOGS.md` 只记录已发生事实。
- 任务结束前必须回写 root `CHAT_LOGS.md`、`STATE.json` 和 `LOGS.md`。
- 涉及采集工具代码变化时，必须同步 `CODE_EVOLUTION.md` 和 `CODE_SNAPSHOTS/`。

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
5. 如修改代码或核心文件，同步 `CODE_SNAPSHOTS/`。
6. 只有采集工具代码变化时，才同步 `CODE_EVOLUTION.md`。
7. 如修改模块规则或代码，同步对应模块日志与必要记录。

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
- 不允许未授权启动账号深度分析、商家建档、内容生产、自动发布或数据复盘。
