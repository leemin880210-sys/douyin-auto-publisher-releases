# STATE_CONSOLIDATION_RULES（状态收敛规则）

## 一、唯一状态源

系统只允许以下文件描述状态：

1. STATE.json（唯一状态源）
2. TASKS.json（唯一任务源）
3. LOGS.md（事实记录）

---

## 二、禁止行为

- 不允许 CORE.md 写状态
- 不允许 FRAMEWORK 写状态
- 不允许 MODULE_ROUTES 写状态
- 不允许 README 写状态

---

## 三、状态冲突处理规则

如果不同文件冲突：

优先级：

STATE.json > TASKS.json > LOGS.md > 其他文件

---

## 四、当前阶段判定规则

当前阶段以 STATE.json 为准。

MASTER_CONTROL 只用于约束执行权限，不用于描述状态。

---

## 五、新 AI 必须遵守

任何 AI 必须先读取：

STATE.json

作为唯一事实源。
