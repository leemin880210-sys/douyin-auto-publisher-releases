# CHAT_LOGS

本文件用于按时间追加记录用户、AI、Codex 对话。AI_MEMORY_SYSTEM v2.0 启用后，不允许删除、覆盖、折叠或隐藏历史聊天。

## [2026-06-28]

用户：
```text
# AI_MEMORY_SYSTEM 容器升级规则（v2.0 - 精简版）

核心目标：AI_MEMORY_SYSTEM 是外部记忆容器，负责存储所有项目、保存项目聊天记录、保存源码历史版本、保证项目可恢复；不参与业务逻辑，仅做存储。

每个项目必须具备：CHAT_LOGS.md、CODE_EVOLUTION.md、CODE_SNAPSHOTS/、BOOT.md、STATE.json、TASKS.json、CORE.md、LOGS.md。

CHAT_LOGS.md 必须记录所有用户 + AI + Codex 对话，按时间追加，不允许丢失、覆盖或折叠隐藏历史。

CODE_SNAPSHOTS/ 必须包含 v1_latest、v2_previous、v3_previous_previous；每次修改必须滚动更新，保存完整代码，不是 diff。

Codex 每次进入项目必须读取 CHAT_LOGS.md、STATE.json、CODE_SNAPSHOTS/v1_latest，执行任务后更新 CHAT_LOGS.md、LOGS.md、STATE.json、CODE_EVOLUTION.md、CODE_SNAPSHOTS/。

强制约束：不允许删除历史聊天，不允许删除代码版本，不允许跨项目访问数据，不允许覆盖旧版本，所有历史必须保留。
```

AI：
```text
收到。我会将 v2.0 规则落成实际结构：补齐 CHAT_LOGS.md 与 CODE_SNAPSHOTS 三版本快照，并把 AI_MEMORY_SYSTEM 明确为外部记忆容器。
```

Codex：
```text
已读取当前仓库结构、registry 和项目文件；准备创建 CHAT_LOGS.md、CODE_SNAPSHOTS/v1_latest、CODE_SNAPSHOTS/v2_previous、CODE_SNAPSHOTS/v3_previous_previous，并同步 README、registry、BOOT、STATE、TASKS、CORE、LOGS、CODE_EVOLUTION。
```
