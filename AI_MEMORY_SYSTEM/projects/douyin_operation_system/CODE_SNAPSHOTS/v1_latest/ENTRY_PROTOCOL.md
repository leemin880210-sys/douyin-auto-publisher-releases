# ENTRY_PROTOCOL（系统启动协议）

任何 AI / Codex / GPT 进入本系统必须执行：

## Step 1：状态源优先

任何 AI 必须先读取：

1. STATE.json

`STATE.json` 是当前阶段和当前状态的唯一事实源。

---

## Step 2：读取顺序固定

读取 `STATE.json` 后，继续按以下顺序读取：

1. STATE_CONSOLIDATION_RULES.md
2. MASTER_CONTROL.md
3. PROJECT_FRAMEWORK.md
4. MODULE_ROUTES.md
5. TASKS.json

---

## Step 3：必须输出 6 项信息

- 当前系统目标
- 当前运行模块
- 当前阶段
- 下一步任务
- 是否允许跨模块
- 当前禁止模块

---

## Step 4：禁止行为

- 禁止直接执行 shop_account_analysis
- 禁止直接创建 merchant_brain
- 禁止跳过 account_ops
- 禁止跨模块执行

---

## Step 5：必须等待用户指令

在没有用户明确指令前：

👉 只允许读取，不允许执行

---

## Step 6：状态收敛规则

- 当前阶段以 `STATE.json` 为准。
- 当前任务以 `TASKS.json` 为准。
- 已发生事实以 `LOGS.md` 为准。
- `MASTER_CONTROL.md` 只约束执行权限，不描述当前状态。
- `PROJECT_FRAMEWORK.md`、`MODULE_ROUTES.md`、`CORE.md`、`README.md` 不作为状态源。
