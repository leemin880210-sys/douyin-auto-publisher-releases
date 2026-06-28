# MASTER_CONTROL（系统总控制器）

## 一、系统唯一目标

本系统的目标是：

> 抖音代运营 AI 系统（采集 → 分析 → 商家大脑 → 内容 → 复盘）

但当前执行阶段必须受限。

---

## 二、当前执行权限（非常重要）

当前执行权限只允许：

### ✔ account_ops（账号采集模块）

其他模块全部禁止执行。

---

## 三、模块执行顺序（不可跳过）

1. account_ops（采集）
2. shop_account_analysis（分析）
3. merchant_brain_factory（建档）
4. merchants（商家大脑）
5. content_pipeline（内容生成）
6. data_review（复盘）

---

## 四、强制执行规则

- AI 不得跳过阶段
- AI 不得跨模块执行
- AI 不得直接进入 merchant_brain
- AI 不得自动做运营方案
- AI 不得自动生成内容策略

---

## 五、当前唯一合法动作

👉 读取采集包 / 生成采集包 / 检查采集包

除此之外全部禁止

---

## 六、进入系统必须优先读取

1. STATE.json
2. ENTRY_PROTOCOL.md
3. STATE_CONSOLIDATION_RULES.md
4. MASTER_CONTROL.md（本文件）
5. PROJECT_FRAMEWORK.md
6. MODULE_ROUTES.md
7. TASKS.json

## 七、系统启动协议

进入本系统必须先读取 `STATE.json` 和 `ENTRY_PROTOCOL.md`。启动协议要求：

1. `STATE.json` 是阶段和状态的唯一事实源。
2. 按固定顺序读取 `STATE_CONSOLIDATION_RULES.md`、`MASTER_CONTROL.md`、`PROJECT_FRAMEWORK.md`、`MODULE_ROUTES.md`、`TASKS.json`。
3. 输出当前系统目标、当前运行模块、当前阶段、下一步任务、是否允许跨模块、当前禁止模块。
4. 没有用户明确指令前，只允许读取，不允许执行。

## 八、状态边界

`MASTER_CONTROL.md` 只用于约束执行权限，不用于描述状态。状态字段全部以 `STATE.json` 为准。
