# BOOT

本文件是 ai_agent 项目实例入口。

## 执行顺序

BOOT → STATE → TASKS → CORE → LOGS

## 执行规则

1. 读取 `STATE.json` 确认 agent 当前阶段。
2. 读取 `TASKS.json` 确认下一步 agent 任务。
3. 读取 `CORE.md` 确认 agent 角色、能力边界和安全约束。
4. 读取 `LOGS.md` 确认已执行事实。
5. agent 行为必须受用户授权和项目边界约束。

## 隔离规则

- 不跨项目读取数据。
- 不共享 STATE。
- 不执行未授权 agent 行为。
