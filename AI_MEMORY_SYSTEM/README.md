> 新 GPT / Codex / AI 请先读取 START_HERE_FOR_NEW_AI.md。

# AI_MEMORY_SYSTEM

AI_MEMORY_SYSTEM v2.0 是外部记忆容器，只负责保存项目记忆、聊天记录、源码历史版本和恢复信息。

它不参与具体业务逻辑执行；业务逻辑只存在于各项目自己的记忆文件、模块文件和实际源码中。

## 容器职责

1. 存储所有项目。
2. 保存项目聊天记录。
3. 保存源码历史版本。
4. 保证项目可恢复。

## 当前活跃项目

```text
douyin_operation_system -> AI_MEMORY_SYSTEM/projects/douyin_operation_system
status: active
type: douyin_operation_system
```

`project_brain` 与 `douyin_account_ops` 已合并为 `douyin_operation_system`。历史源目录仍保留在 `projects/` 下作为历史材料，但 registry 只注册 `douyin_operation_system`。

## 每个项目必须具备结构

```text
AI_MEMORY_SYSTEM/projects/{project}/
├── CHAT_LOGS.md
├── CODE_EVOLUTION.md
├── CODE_SNAPSHOTS/
│   ├── v1_latest/
│   ├── v2_previous/
│   └── v3_previous_previous/
├── BOOT.md
├── STATE.json
├── TASKS.json
├── CORE.md
└── LOGS.md
```

## CHAT_LOGS 规则

`CHAT_LOGS.md` 用于记录用户、AI、Codex 的对话事实。

要求：

- 按时间追加。
- 不允许丢失或覆盖。
- 不允许折叠隐藏历史。

格式：

```text
## [时间]

用户：
...

AI：
...

Codex：
...
```

## CODE_SNAPSHOTS 规则

`CODE_SNAPSHOTS/` 保存最近 3 次完整源码快照，不保存 diff。

```text
CODE_SNAPSHOTS/
├── v1_latest/              # 最新代码
├── v2_previous/            # 上一版代码
└── v3_previous_previous/   # 上上版代码
```

规则：

- 每次修改必须滚动更新。
- `v1_latest` = 最新代码。
- `v2_previous` = 上一版本。
- `v3_previous_previous` = 上上版本。
- 必须保存完整代码文件，不只保存差异。

## Codex 执行规则

每次进入项目必须：

1. 读取 `CHAT_LOGS.md`。
2. 读取 `STATE.json`。
3. 读取 `CODE_SNAPSHOTS/v1_latest`。
4. 执行用户授权任务。
5. 更新：
   - `CHAT_LOGS.md`
   - `LOGS.md`
   - `STATE.json`
   - `CODE_EVOLUTION.md`
   - `CODE_SNAPSHOTS/`

## 强制约束

- 不允许删除历史聊天。
- 不允许删除代码版本。
- 不允许跨项目访问数据。
- 不允许覆盖旧版本。
- 所有历史必须保留。
- 不允许把 registry 当作 memory 使用。
- 不允许把 global memory 写入项目业务内容。

## 系统目标

AI_MEMORY_SYSTEM v2.0 必须保证：

- 聊天永久可追溯。
- 代码具备最近 3 版本回滚能力。
- 项目完全可恢复。
- 多项目完全隔离。

## 兼容说明

`00_GLOBAL_MEMORY`、`01_PROJECT_REGISTRY`、`02_PROJECT_FACTORY` 等既有系统层文件保留为历史结构和容器辅助文件；v2.0 的当前核心定位是外部记忆容器，不直接承载业务逻辑。

## 状态收敛提示

README 只作为外部大脑入口说明，不作为状态源。

- 当前状态以 `AI_MEMORY_SYSTEM/projects/douyin_operation_system/STATE.json` 为准。
- 当前任务以 `AI_MEMORY_SYSTEM/projects/douyin_operation_system/TASKS.json` 为准。
- 已发生事实以 `AI_MEMORY_SYSTEM/projects/douyin_operation_system/LOGS.md` 为准。
- 状态冲突时按 `STATE_CONSOLIDATION_RULES.md` 处理。
