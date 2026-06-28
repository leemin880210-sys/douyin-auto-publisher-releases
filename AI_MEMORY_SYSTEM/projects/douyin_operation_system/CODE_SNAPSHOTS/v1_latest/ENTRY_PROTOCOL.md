# ENTRY_PROTOCOL（系统启动协议）

任何 AI / Codex / GPT 进入本系统必须执行：

## Step 1：状态源优先

先读取：

1. STATE.json
2. STATE_CONSISTENCY_LOCK.md
3. SEMANTIC_LAYERS.md

`STATE.json` 是唯一真实状态源。  
`STATE_CONSISTENCY_LOCK.md` 是状态一致性锁。  
`SEMANTIC_LAYERS.md` 是语义分层协议，禁止混用不同文件职责。

---

## Step 2：固定读取顺序

继续按以下顺序读取：

1. ENTRY_PROTOCOL.md
2. STATE_CONSOLIDATION_RULES.md
3. MASTER_CONTROL.md
4. PROJECT_FRAMEWORK.md
5. MODULE_ROUTES.md
6. TASKS.json

---

## Step 3：必须输出 6 项信息

- 当前状态是什么（只能来自 STATE.json）
- 当前允许执行什么（只能来自 MASTER_CONTROL）
- 下一步动作是什么（只能来自 TASKS.json）
- 系统模块是什么（只能来自 PROJECT_FRAMEWORK）
- 是否允许跨模块
- 当前禁止模块是什么

---

## Step 4：禁止行为

- 禁止直接执行 shop_account_analysis
- 禁止直接创建 merchant_brain
- 禁止跳过 account_ops
- 禁止跨模块执行
- 禁止从 CORE.md / PROJECT_FRAMEWORK.md / MODULE_ROUTES.md / TASKS.json 推断状态
- 禁止混用 MASTER_CONTROL、PROJECT_FRAMEWORK、STATE.json、TASKS.json 的语义层

---

## Step 5：必须等待用户指令

在没有用户明确指令前：

👉 只允许读取，不允许执行
