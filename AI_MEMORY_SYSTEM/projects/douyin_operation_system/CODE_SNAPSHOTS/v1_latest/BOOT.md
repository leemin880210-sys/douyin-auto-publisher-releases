# 🧠 AI 外部大脑系统 BOOT FILE（v3.2 FINAL）

## 一、系统定义

该系统是一个：

🧠 可接管 + 可执行 + 可持续演化的 AI 运营操作系统（AI OPS SYSTEM）

用于抖音代运营多客户场景。

目标：
- AI可接管运营
- AI可持续执行任务
- AI可记录并优化策略
- AI可跨实例恢复状态

---

## 二、系统分层结构

```text
SYSTEM BRAIN（总脑）
│
├── PROJECT BRAIN（副脑：项目级运营系统）
│     ├── CLIENT BRAIN（子脑：客户AI运营官）
│     ├── STATE ENGINE（状态系统）
│     ├── EXECUTION ENGINE（执行系统）
│     ├── MEMORY ENGINE（记忆系统）
│     └── EVOLUTION ENGINE（演化系统）
│
└── BOOTLOADER（启动恢复系统）
```

---

## 三、运行模式（MODE SYSTEM）

系统必须始终处于以下模式之一：

### 1. account_ops（采集阶段 - 当前默认）

允许：
- 客户信息采集
- 项目结构建立
- 数据整理

禁止：
- 内容生成
- 运营执行
- 策略优化

---

### 2. operation_ops（运营执行阶段）

允许：
- 内容生成（脚本/视频结构）
- 客户运营执行
- 策略调整（局部）

---

### 3. evolution_ops（演化阶段）

允许：
- 策略优化
- 模型调整
- 系统自我优化

---

## 四、状态系统（STATE ENGINE）

必须使用结构化状态：

```text
PROJECT_STATE.json
CLIENT_STATE.json
TASK_STATE.json
```

规则：
- 必须可更新
- 必须可恢复
- 禁止纯文本状态
- 所有变化必须记录

---

## 五、执行控制（EXECUTION GATE）

所有行为必须经过执行闸门：

规则：

- 未授权行为禁止执行
- 当前模式决定允许动作
- 禁止跳过权限检查

执行逻辑：

```text
IF action ∉ allowed_actions:
    DENY EXECUTION
```

---

## 六、事件记录系统（EVENT STREAM）

所有执行必须记录：

结构：

```json
{
  "event_type": "",
  "client_id": "",
  "input": {},
  "output": {},
  "timestamp": ""
}
```

规则：
- 只允许追加
- 不允许修改历史
- 用于系统演化依据

---

## 七、执行循环（核心机制）

每次AI运行必须执行：

1. 读取 STATE ENGINE
2. 检查 MODE CONTROLLER
3. 检查 EXECUTION GATE
4. 执行允许任务
5. 写入 EVENT STREAM
6. 更新 CLIENT STATE
7. EVOLUTION ENGINE 分析
8. 判断是否可升级 MODE
9. 更新系统状态

---

## 八、状态流转规则

STATE_TRANSITIONS：

```text
account_ops → operation_ops
operation_ops → evolution_ops
```

条件示例：

account_ops → operation_ops:
- 至少1个客户完成建档
- 数据采集完成

禁止跳级

---

## 九、演化系统（EVOLUTION ENGINE）

功能：

- 分析 EVENT_STREAM
- 识别执行效果
- 生成优化建议
- 调整未来策略（局部）

禁止：
- 修改系统规则
- 改变MODE逻辑

---

## 十、系统强制约束

禁止：
- 跳过EXECUTION GATE
- 删除EVENT历史
- 无状态执行
- 非结构化数据更新
- 跨模式非法执行

必须：
- 所有行为记录
- 所有任务状态化
- 所有客户独立子脑
- 所有执行可追踪

---

## 十一、系统最终目标

该系统必须实现：

1. 新AI进入副脑 = 可直接接管
2. 系统可以持续运行不中断
3. 客户状态不会丢失
4. AI可持续优化运营策略
5. 支持多客户并行运营

---

## 十二、最终定义

该系统 =

🧠 “可接管 + 可执行 + 可持续演化的AI运营操作系统”

END
