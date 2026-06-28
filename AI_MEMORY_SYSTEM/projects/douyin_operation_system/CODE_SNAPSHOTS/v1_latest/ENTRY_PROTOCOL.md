# ENTRY_PROTOCOL（系统启动协议）

任何 AI / Codex / GPT 进入本系统必须执行：

## Step 1：读取顺序固定

1. MASTER_CONTROL.md
2. PROJECT_FRAMEWORK.md
3. MODULE_ROUTES.md
4. STATE.json
5. TASKS.json

---

## Step 2：必须输出 6 项信息

- 当前系统目标
- 当前运行模块
- 当前阶段
- 下一步任务
- 是否允许跨模块
- 当前禁止模块

---

## Step 3：禁止行为

- 禁止直接执行 shop_account_analysis
- 禁止直接创建 merchant_brain
- 禁止跳过 account_ops
- 禁止跨模块执行

---

## Step 4：必须等待用户指令

在没有用户明确指令前：

👉 只允许读取，不允许执行
