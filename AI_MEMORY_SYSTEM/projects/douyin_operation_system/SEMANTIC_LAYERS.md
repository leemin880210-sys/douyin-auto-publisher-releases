# SEMANTIC_LAYERS（语义分层协议）

## 一、系统语义分层

### 1️⃣ MASTER_CONTROL
→ 负责【执行权限】

只回答：
- 能不能做

不回答：
- 当前阶段
- 未来规划

---

### 2️⃣ PROJECT_FRAMEWORK
→ 负责【系统设计】

只回答：
- 系统有哪些模块
- 模块怎么组成

不回答：
- 当前执行状态

---

### 3️⃣ STATE.json
→ 负责【当前真实状态】

只回答：
- 现在在做什么
- 当前阶段是什么

不回答：
- 长期规划
- 模块结构

---

### 4️⃣ TASKS.json
→ 负责【下一步动作】

只回答：
- 下一步做什么

不回答：
- 当前状态
- 系统结构

---

## 二、禁止混合语义

禁止：

- STATE写架构
- FRAMEWORK写状态
- MASTER_CONTROL写阶段
- TASKS写系统结构

---

## 三、冲突解决规则

优先级：

1. MASTER_CONTROL（执行权）
2. STATE（当前状态）
3. TASKS（下一步）
4. FRAMEWORK（系统结构）

---

## 四、新AI必须遵守

AI必须判断：

👉 当前文件属于哪个语义层
👉 不能混用不同语义
---

## 五、系统宪法优先

`SYSTEM_CONSTITUTION.md` 是最高约束文件。语义分层必须服从系统宪法：

1. `MASTER_CONTROL.md` 负责执行权。
2. `STATE.json` 负责当前状态。
3. `TASKS.json` 负责下一步。
4. `PROJECT_FRAMEWORK.md` 负责系统结构。
5. `MODULE_ROUTES.md` 负责如何路由。
