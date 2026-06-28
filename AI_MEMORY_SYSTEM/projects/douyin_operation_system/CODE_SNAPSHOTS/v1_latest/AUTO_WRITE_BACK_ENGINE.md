# AUTO_WRITE_BACK_ENGINE.md

# AUTO WRITE-BACK ENGINE v1.0（自动写回引擎）

## 一、系统目标

将所有 AI 对话输出自动转换为外脑状态更新，实现：

- 聊天 = 自动更新外脑系统
- 对话 = 系统状态演化
- 输出 = 结构化写入

## 二、核心原则

### 1. 所有 AI 输出必须结构化处理

AI 输出不能仅作为文本存在，必须解析为：

- `CLIENT_STATE.json` 更新
- `TASK_QUEUE.json` 更新
- `EVENT_STREAM.json` 记录

### 2. 写回必须自动执行

每次 AI 回答后必须自动执行：

```text
AUTO_WRITE_BACK_PROCESS
```

## 三、写回引擎执行流程

每次 AI 输出后执行：

### STEP 1：解析输出内容

识别 3 类信息：

1. 客户信息（client data）
2. 行动任务（next actions）
3. 决策/结果（insight / event）

### STEP 2：分类写入

## 1. 写入 CLIENT_STATE.json（状态更新）

触发条件：

- 提到客户信息
- 提到当前进展
- 提到运营状态

写入格式：

```json
{
  "client_id": "A001",
  "update_time": "now",
  "state": "updated_from_chat",
  "content": "AI对话中提取的最新状态"
}
```

如果对话中没有真实客户信息，不允许伪造 `client_id`。

## 2. 写入 TASK_QUEUE.json（任务生成）

触发条件：

- 出现“下一步 / 应该做 / 需要做”

写入格式：

```json
{
  "task_id": "auto_generated",
  "client_id": "A001",
  "action": "derived_from_chat",
  "status": "pending"
}
```

如果是系统维护类任务，必须标记为 `system_runtime_task`，不得伪造成客户业务任务。

## 3. 写入 EVENT_STREAM.json（行为记录）

所有 AI 输出必须记录：

```json
{
  "event_type": "chat_to_state",
  "input": "user_message",
  "output": "ai_response",
  "result": "state_updated"
}
```

## 四、强制写回规则

### 规则1：必须写回

任何 AI 输出 = 必须写入至少一个系统模块。

### 规则2：禁止只输出不更新

```text
IF AI_output AND no_state_update:
    INVALID STATE
    FORCE WRITEBACK
```

### 规则3：写回优先级

1. `CLIENT_STATE.json`
2. `TASK_QUEUE.json`
3. `EVENT_STREAM.json`

无真实客户信息时，跳过客户状态实体写入，但必须写明跳过原因，并写入 `EVENT_STREAM.json`。

## 五、自动触发机制

每次 AI 回复结束后自动执行：

```text
AUTO_WRITE_BACK_ENGINE()
```

## 六、系统运行结果定义

如果写回成功：

- 客户状态更新，或记录无客户信息无法更新的原因
- 任务队列增加或更新
- 事件记录生成

## 七、系统最终效果

启用本引擎后：

- 聊天 = 自动运营系统更新
- AI = 自动更新外脑的运营官
- 所有对话 = 系统进化数据源

## 八、禁止行为

- 不允许 AI 只回答不写回
- 不允许输出不进入系统
- 不允许无状态回复
- 不允许伪造客户信息
- 不允许把系统维护任务伪造成客户业务任务

## END
