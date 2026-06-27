# BOOT

本文件是 automation 项目实例入口。

## 执行顺序

BOOT → STATE → TASKS → CORE → LOGS

## 执行规则

1. 读取 `STATE.json` 确认自动化阶段。
2. 读取 `TASKS.json` 确认下一步自动化任务。
3. 读取 `CORE.md` 确认触发条件、权限和边界。
4. 读取 `LOGS.md` 确认已执行事实。
5. 自动化动作必须可审计、可暂停、可回滚。

## 隔离规则

- 不跨项目读取数据。
- 不共享 STATE。
- 不执行未授权自动化动作。
