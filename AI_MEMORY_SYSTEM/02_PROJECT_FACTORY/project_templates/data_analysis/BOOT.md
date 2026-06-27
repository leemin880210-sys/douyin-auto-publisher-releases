# BOOT

本文件是 data_analysis 项目实例入口。

## 执行顺序

BOOT → STATE → TASKS → CORE → LOGS

## 执行规则

1. 读取 `STATE.json` 确认当前分析阶段。
2. 读取 `TASKS.json` 确认下一步分析任务。
3. 读取 `CORE.md` 确认数据来源、边界和输出要求。
4. 读取 `LOGS.md` 确认已完成事实。
5. 只处理用户授权的数据和文件。

## 隔离规则

- 不跨项目读取数据。
- 不共享 STATE。
- 不处理未授权数据。
