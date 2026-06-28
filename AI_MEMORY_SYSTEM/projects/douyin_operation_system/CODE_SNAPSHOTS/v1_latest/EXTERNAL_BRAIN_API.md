# EXTERNAL_BRAIN_API.md

# 外脑（B）API 服务合约 v1.0

## 一、定位

外脑（B）是抖音代运营 AI 操作系统的决策执行 API 服务层。

它负责：

- 读取子脑状态。
- 读取任务队列。
- 执行被允许的任务。
- 写回状态。
- 记录事件。
- 保证所有执行可追踪、可恢复、可审计。

Web 线上展示与部署属于 Web（A）范围，不在本文件执行范围内。

---

## 二、唯一数据源

所有运行态数据必须来自 Supabase。

禁止：

- 将本地 JSON 文件作为线上运行状态源。
- 绕过 Supabase 直接生成不可追踪状态。
- 只返回 AI 文本但不写回事件。

---

## 三、必须暴露的 API

### 1. 获取子脑状态

```http
GET /api/client/:client_id
```

返回：

```json
{
  "client_state": {},
  "current_task": "",
  "mode": "account_ops"
}
```

### 2. 获取任务队列

```http
GET /api/tasks?client_id=xxx
```

返回该 client 的任务队列。

### 3. 执行任务

```http
POST /api/execute
```

输入：

```json
{
  "client_id": "",
  "task": {}
}
```

规则：

1. 读取 client state。
2. 检查当前 mode。
3. 检查 task.action 是否允许。
4. 允许则执行。
5. 不允许则标记 blocked。
6. 必须写入 EVENT。
7. 必须更新 TASK / STATE。

### 4. 写回状态

```http
POST /api/update_state
```

用于写回 CLIENT_STATE / PROJECT_STATE 等运行状态。

### 5. 事件记录

```http
POST /api/events
```

所有执行、写回、阻塞、失败都必须写 EVENT。

---

## 四、事件记录要求

每次执行必须记录：

```json
{
  "event_type": "task_execution",
  "task_id": "",
  "client_id": "",
  "action": "",
  "input": {},
  "output": {},
  "result": "success | failed | blocked",
  "timestamp": ""
}
```

---

## 五、运行闭环

外脑（B）运行逻辑固定为：

```text
READ -> EXECUTE -> WRITE -> UPDATE -> LOOP
```

含义：

1. READ：读取 Supabase 中的 client state / task queue / mode。
2. EXECUTE：执行当前 mode 允许的 task。
3. WRITE：写入 event stream。
4. UPDATE：更新 state 与 task 状态。
5. LOOP：等待下一次任务或调用。

---

## 六、当前阶段限制

当前 mode 仍为：

```text
account_ops
```

允许：

- 读取采集包。
- 生成采集包。
- 检查采集包。
- 收集客户信息。
- 建立客户档案结构。

禁止：

- 账号分析。
- 商家建档。
- 内容生成。
- 自动发布。
- 运营策略优化。
- 复盘分析。

---

## 七、Web（A）边界

本文件只定义外脑（B）API 合约。

Web 线上部署、页面展示、域名、Vercel 配置、前端调用实现，均由 Web（A）窗口处理。

本外脑窗口不得继续修改 Web 端代码或线上部署。

---

## 八、最终目标

外脑（B）最终形态：

```text
AI 决策执行 API 服务
```

必须满足：

- 所有状态来自 Supabase。
- 所有任务可追踪。
- 所有执行写 EVENT。
- 所有 AI 输出可写回。
- 新 AI 可通过外脑状态无缝接管。