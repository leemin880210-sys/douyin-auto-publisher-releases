# COGNITIVE_ENTRY（认知统一入口）

本文件是整个外部大脑系统的唯一认知入口。

新 AI 必须先读取本文件，才能理解整个系统。

---

## 1. 本系统是什么

这是一个：

抖音代运营 AI 操作系统。

它不是采集工具，不是脚本，不是单模块系统。

---

## 2. 当前唯一运行模块

当前唯一运行模块是：

account_ops。

当前处于：

账号采集阶段。

允许范围：

- 读取采集包。
- 生成采集包。
- 检查采集包。

禁止范围：

- 不允许跨模块执行。
- 不允许提前进入账号分析。
- 不允许提前进入商家建档。
- 不允许提前进入内容生成。
- 不允许提前进入复盘。

---

## 3. 文件语义边界

`COGNITIVE_ENTRY.md` 是唯一认知入口。

`STATE.json` 是唯一状态来源，但不是认知入口。

`PROJECT_FRAMEWORK.md` 只负责结构说明，不代表当前执行状态，也不是认知入口。

`TASKS.json` 只负责下一步动作，不描述系统结构，也不是认知入口。

`MASTER_CONTROL.md` 只负责执行权限，不定义系统认知。

`MODULE_ROUTES.md` 只负责请求路由，不定义当前状态。

---

## 4. 本文件解决什么问题

本文件用于解决：

1. 版本分裂：多文件不同视角导致新 AI 理解不一致。
2. STATE 语义污染：避免把未来规划、结构说明或任务描述写入状态源。
3. 入口混乱：避免新 AI 从不同文件开始理解系统。

---

## 5. 新 AI 必须如何进入系统

新 AI 必须按以下顺序进入：

1. 读取 `COGNITIVE_ENTRY.md`。
2. 读取 `STATE.json`，确认当前真实状态。
3. 读取 `PROJECT_FRAMEWORK.md`，理解系统结构。
4. 读取 `MODULE_ROUTES.md`，理解请求路由。
5. 读取 `TASKS.json`，确认下一步动作。
6. 读取 `MASTER_CONTROL.md`，确认执行权限。

如果未完成以上读取，不允许执行任何修改。

---

## 6. 单入口认知原则

任何 AI 必须把本文件作为第一认知入口。

任何 AI 不得把以下文件作为认知入口：

- `STATE.json`
- `PROJECT_FRAMEWORK.md`
- `TASKS.json`
- `MASTER_CONTROL.md`
- `MODULE_ROUTES.md`
- `CORE.md`

这些文件只能在本文件之后，按各自语义职责被读取。

---

## 7. 当前禁止行为

任何 AI 禁止：

- 跨模块执行。
- 跳过采集直接分析。
- 自动创建商家系统。
- 自动生成运营方案。
- 自动生成内容策略。
- 修改采集工具代码。
- 新增业务模块。
- 扩展业务流程。

---

## 8. 终极规则

如果一个新 AI 只读这一份文件，也必须能理解：

- 这是抖音代运营 AI 系统。
- 当前唯一运行模块是 `account_ops`。
- 当前阶段是账号采集阶段。
- 当前不能分析、建档、生成内容或复盘。
- `STATE.json` 是唯一状态来源，但不是认知入口。
- `PROJECT_FRAMEWORK.md`、`TASKS.json`、`MASTER_CONTROL.md` 都不得替代本文件。
---

## MACHINE_CHECK

COGNITIVE_ENTRY_ENFORCED: true
STATE_JSON_NOT_COGNITIVE_ENTRY: true
VERSION_SPLIT_FIX: true
STATE_SEMANTIC_POLLUTION_FIX: true
---

## 版本演化理解

新 AI 必须理解：

本系统是“持续演化系统”，不是静态系统。

外部大脑 3.0 新增：

- `CHANGE_LOG.md`：记录每次系统变更、修改原因和影响范围。
- `DECISION_LOG.md`：记录关键设计决策、替代方案和最终原因。
- `MEMORY_CONTINUITY.md`：记录系统连续性、模块关系、关键决策摘要和演进路径。

新 AI 在接手系统时，必须读取：

1. `CHANGE_LOG.md`
2. `DECISION_LOG.md`

只有知道“改过什么”和“为什么这样设计”，才能避免重复判断和版本分裂。
