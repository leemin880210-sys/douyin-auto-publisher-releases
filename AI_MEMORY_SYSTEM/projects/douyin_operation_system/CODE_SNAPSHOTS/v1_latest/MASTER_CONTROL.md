# MASTER_CONTROL（系统总控制器）

## 一、系统唯一目标

本系统的目标是：

> 抖音代运营 AI 系统（采集 → 分析 → 商家大脑 → 内容 → 复盘）

但当前执行阶段必须受限。

---

## 二、当前运行阶段（非常重要）

当前系统只允许执行：

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

1. MASTER_CONTROL.md（本文件）
2. PROJECT_FRAMEWORK.md
3. MODULE_ROUTES.md
4. STATE.json
5. TASKS.json
