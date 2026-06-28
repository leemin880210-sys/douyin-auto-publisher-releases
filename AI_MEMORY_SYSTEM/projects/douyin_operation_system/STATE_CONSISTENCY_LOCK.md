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

新 AI 必须先按 `SYSTEM_CONSTITUTION.md` 读取 `MASTER_CONTROL.md`、`STATE.json`、`TASKS.json`、`PROJECT_FRAMEWORK.md`、`MODULE_ROUTES.md`。

进行状态判断时只能回答：

- 当前状态是什么（只能来自 STATE.json）

进行权限判断时只能回答：

- 当前允许执行什么模块（只能来自 MASTER_CONTROL）
- 当前禁止模块是什么（只能来自 MASTER_CONTROL）

## 六、语义分层约束

`SEMANTIC_LAYERS.md` 是判断文件职责的协议。任何 AI 必须先判断当前文件属于哪个语义层，不能混用不同语义。
---

## 七、系统宪法优先

`SYSTEM_CONSTITUTION.md` 是最高约束文件。若启动顺序与旧规则冲突，以系统宪法规定的顺序为准。
