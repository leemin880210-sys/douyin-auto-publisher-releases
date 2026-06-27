# BOOT

本文件是项目实例入口。

## 执行顺序

1. 读取 `BOOT.md`。
2. 读取 `STATE.json`。
3. 读取 `TASKS.json`。
4. 读取 `CORE.md`。
5. 读取 `LOGS.md`。
6. 执行用户授权任务。
7. 回写 `STATE.json` 和 `LOGS.md`，任务变化时同步 `TASKS.json`。

简写顺序：BOOT → STATE → TASKS → CORE → LOGS。

## 隔离规则

- 不跨项目读取数据。
- 不共享 STATE。
- 不修改未授权项目。
