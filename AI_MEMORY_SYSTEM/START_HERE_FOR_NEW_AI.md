# START HERE FOR NEW AI

本文件是任何新的 GPT / Codex / AI 账号进入本仓库后的第一入口。

## 1. 这是什么

`AI_MEMORY_SYSTEM` 是外部记忆容器，不是普通代码仓库。

它的作用是保存项目记忆、聊天记录、状态、任务、日志、源码历史快照和恢复路径。新 AI 不应把它当作业务代码目录直接执行，也不应跳过记忆文件直接修改代码。

## 2. 当前唯一活跃项目

当前唯一活跃项目是：

```text
AI_MEMORY_SYSTEM/projects/douyin_operation_system/
```

旧的 `project_brain` 与 `douyin_account_ops` 已经合并进该统一项目。registry 当前只应把 `douyin_operation_system` 作为活跃项目入口。

## 3. 新 AI 必须读取的顺序

任何新的 GPT / Codex / AI 进入后，必须先读取认知统一入口：

0. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/COGNITIVE_ENTRY.md`

随后按认知入口固定顺序读取：

1. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/STATE.json`
2. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/TASKS.json`
3. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/MASTER_CONTROL.md`
4. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/PROJECT_FRAMEWORK.md`
5. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/MODULE_ROUTES.md`
6. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/UNIFIED_MEMORY_BRAIN.md`

继续读取一致性和宪法文件：

7. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/SYSTEM_CONSTITUTION.md`
8. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/STATE_CONSISTENCY_LOCK.md`
9. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/SEMANTIC_LAYERS.md`
10. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/STATE_CONSOLIDATION_RULES.md`
11. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/ENTRY_PROTOCOL.md`

最后继续读取恢复辅助文件：

12. `AI_MEMORY_SYSTEM/README.md`
13. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/CHAT_LOGS.md`
14. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v1_latest/`
15. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/BOOT.md`
16. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/CORE.md`
17. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/LOGS.md`
18. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_EVOLUTION.md`

`COGNITIVE_ENTRY.md` 是第一认知入口。  
`STATE.json` 是运行状态唯一来源。  
`TASKS.json` 是任务唯一来源。  
`MASTER_CONTROL.md` 只回答能不能做。  
`PROJECT_FRAMEWORK.md` 只回答系统结构。  
`MODULE_ROUTES.md` 只回答如何路由。

## 4. 新 AI 接手判断规则

新 AI 读取完成后，必须先回答：

1. 当前允许执行什么（只能来自 MASTER_CONTROL）？
2. 当前状态是什么（只能来自 STATE.json）？
3. 下一步动作是什么（只能来自 TASKS.json）？
4. 系统结构是什么（只能来自 PROJECT_FRAMEWORK）？
5. 请求应如何路由（只能来自 MODULE_ROUTES）？
6. 当前禁止事项是什么？
7. 当前文件属于哪个语义层？

如果不能回答以上问题，不允许执行任何修改。

## 5. 如果涉及账号采集模块

如果任务涉及抖音账号采集、采集包、评论、OCR、抽帧、ZIP 输出、`douyin_auto_tool.ps1` 或 `account_ops`，还必须继续读取：

1. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/modules/account_ops/BOOT.md`
2. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/modules/account_ops/STATE.json`
3. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/modules/account_ops/TASKS.json`
4. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/modules/account_ops/CORE.md`
5. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/modules/account_ops/LOGS.md`
6. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/modules/account_ops/CODE_EVOLUTION.md`

## 6. 读取后必须先输出

新 AI 读取完上述文件后，必须先向用户输出：

- 当前项目目标
- 当前阶段
- 当前任务
- 当前模块边界
- 当前源码路径
- 下一步建议

在输出这些恢复信息前，不要直接执行修改。

## 7. 当前禁止事项

除非用户明确授权，否则禁止：

- 不要直接修改代码。
- 不要启动 `shop_account_analysis` 做真实账号深度分析。
- 不要启动 `merchant_brain_factory` 创建真实商家大脑。
- 不要启动 `data_analysis`。
- 不要启动 `content_pipeline`。
- 不要启动 `data_review`。
- 不要做账号诊断、运营方案、脚本生成、自动发布或商家建档。
- 不要绕过当前 `modules/account_ops` 的边界。
- 不要修改 `AI_MEMORY_SYSTEM/00_GLOBAL_MEMORY`。
- 不要把旧项目目录重新当成活跃项目。
- 不要把采集包 ZIP 提交到 `AI_MEMORY_SYSTEM`。

## 8. GitHub 无法读取时

如果新 AI 无法读取 GitHub 链接，应要求用户粘贴以下文件内容：

1. `AI_MEMORY_SYSTEM/README.md`
2. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/SYSTEM_CONSTITUTION.md`
3. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/MASTER_CONTROL.md`
4. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/STATE.json`
5. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/UNIFIED_MEMORY_BRAIN.md`
6. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/TASKS.json`
7. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/PROJECT_FRAMEWORK.md`
8. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/MODULE_ROUTES.md`
9. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/ENTRY_PROTOCOL.md`
10. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/STATE_CONSISTENCY_LOCK.md`
11. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/SEMANTIC_LAYERS.md`
12. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/STATE_CONSOLIDATION_RULES.md`
13. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/modules/account_ops/STATE.json`
14. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/modules/account_ops/TASKS.json`
15. `AI_MEMORY_SYSTEM/projects/douyin_operation_system/modules/account_ops/CORE.md`

## 9. 当前源码恢复路径

当前 GitHub 可恢复源码路径是：

```text
AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v1_latest/douyin_auto_tool.ps1
```

本地路径只作为历史执行路径，不作为新 AI 的恢复依据。
