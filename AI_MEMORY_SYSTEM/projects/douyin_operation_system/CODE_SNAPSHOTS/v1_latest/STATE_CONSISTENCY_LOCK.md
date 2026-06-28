# STATE_CONSISTENCY_LOCK（状态一致性锁）

## 一、唯一状态来源

系统状态只允许来自：

- STATE.json（唯一真实状态源）

---

## 二、禁止行为

任何 AI 不得：

- 从 CORE.md 推断状态
- 从 FRAMEWORK 推断状态
- 从 ROUTES 推断状态
- 从 TASKS 推断当前进度

---

## 三、冲突处理规则

优先级：

STATE.json > TASKS.json > LOGS.md > 其他文件

---

## 四、当前阶段判定规则

当前阶段必须以 STATE.json 为准。

MASTER_CONTROL 只负责“执行权限”，不负责状态判断。

---

## 五、AI 行为约束

新 AI 必须先回答：

- 当前状态是什么（只能来自 STATE.json）
- 当前允许执行什么模块
- 当前禁止模块是什么
