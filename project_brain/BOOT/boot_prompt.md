# 项目接入规则

本文件是当前项目的唯一入口。任何 AI（Codex / GPT）进入项目时，必须先读取本文件，再继续读取其他模块。

---

## 强制执行顺序（不可跳过）

任何 AI 进入项目必须严格按顺序执行：

1. `CORE/memory.md`
2. `STATE/state.json`
3. `TASKS/next_actions.json`
4. `LOGS/change_log.md`

---

## 固定执行流程

所有执行必须按以下顺序：

1. Step 1：读取 `BOOT/boot_prompt.md`
2. Step 2：读取 `STATE/state.json`
3. Step 3：读取 `TASKS/next_actions.json`
4. Step 4：执行任务
5. Step 5：更新 `STATE/state.json`
6. Step 6：写入 `LOGS/change_log.md`
7. Step 7：结束

---

## 接入后必须输出

- 当前项目在做什么
- 当前状态是什么
- 当前下一步任务是什么
- 是否存在风险

---

## 强制行为规则

- 不允许跳过 `STATE/state.json` 读取
- 不允许直接执行 `TASKS/next_actions.json` 中的任务
- 不允许在未更新 `STATE/state.json` 前结束任务
- 不允许忽略 `LOGS/change_log.md` 记录
- 不允许直接修改代码不更新 `STATE/state.json`
- 不允许在 `TASKS/next_actions.json` 中记录状态
- 不允许在 `LOGS/change_log.md` 中写计划
- 不允许乱序执行步骤

---

## 状态与任务边界

- `STATE/state.json` 是唯一当前状态来源
- 所有进度必须写入 `STATE/state.json`
- `TASKS/next_actions.json` 只能写待做任务
- `LOGS/change_log.md` 只能记录已发生事实

---

## 核心原则

1. 每个项目完全独立
2. 不共享任何记忆
3. 所有状态必须写入 STATE
4. 所有任务必须写入 TASKS
5. 所有变更必须写入 LOGS
