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
---

## 六、状态一致性锁

`STATE_CONSISTENCY_LOCK.md` 是状态判断的硬约束文件。

- 状态只允许来自 `STATE.json`。
- 不允许从 `CORE.md`、`PROJECT_FRAMEWORK.md`、`MODULE_ROUTES.md` 推断状态。
- 不允许从 `TASKS.json` 推断当前进度。
---

## 七、语义分层协议

`SEMANTIC_LAYERS.md` 定义各文件语义职责：

- `MASTER_CONTROL.md` 负责执行权限。
- `PROJECT_FRAMEWORK.md` 负责系统设计。
- `STATE.json` 负责当前真实状态。
- `TASKS.json` 负责下一步动作。
