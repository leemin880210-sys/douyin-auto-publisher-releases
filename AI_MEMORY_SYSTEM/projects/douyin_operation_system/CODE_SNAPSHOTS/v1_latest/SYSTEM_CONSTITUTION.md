# SYSTEM_CONSTITUTION（系统宪法）

## 一、最高原则

本系统是一个“抖音代运营 AI 操作系统”。

所有 AI 必须优先理解：

👉 系统是“流程系统”，不是单一工具

---

## 二、唯一真实状态源

系统状态只能来自：

👉 STATE.json

任何其他文件：

- CORE.md
- FRAMEWORK
- TASKS
- MASTER_CONTROL

都不得作为“状态依据”

---

## 三、系统分层（不可混用）

### 1️⃣ MASTER_CONTROL
→ 只控制“能不能做”

### 2️⃣ STATE.json
→ 只描述“现在在做什么”

### 3️⃣ TASKS.json
→ 只描述“下一步做什么”

### 4️⃣ PROJECT_FRAMEWORK
→ 只描述“系统结构”

### 5️⃣ MODULE_ROUTES
→ 只描述“如何路由”

---

## 四、禁止混合语义（关键）

禁止：

- STATE写未来
- TASKS写状态
- FRAMEWORK写执行
- CONTROL写业务结构

---

## 五、版本分裂处理规则

如果不同文件出现冲突：

### 优先级：

1. MASTER_CONTROL（执行权）
2. STATE.json（当前状态）
3. TASKS.json（下一步）
4. LOGS.md（事实）
5. FRAMEWORK（结构）

---

## 六、AI进入系统必须遵守

任何 AI 必须：

1. 先读取 MASTER_CONTROL
2. 再读取 STATE
3. 再读取 TASKS
4. 再读取 FRAMEWORK
5. 再读取 ROUTES

---

## 七、禁止行为（强约束）

任何 AI 禁止：

- 跨模块执行
- 跳过采集直接分析
- 跳过分析直接建商家
- 自动生成运营方案
- 自动生成内容策略
- 修改状态来源文件

---

## 八、当前系统执行原则

当前唯一执行模块：

👉 account_ops

其他模块全部为规划状态

---

## 九、系统稳定性原则

系统允许扩展模块，但：

👉 不允许改变执行顺序
👉 不允许跳阶段
👉 不允许合并状态源
