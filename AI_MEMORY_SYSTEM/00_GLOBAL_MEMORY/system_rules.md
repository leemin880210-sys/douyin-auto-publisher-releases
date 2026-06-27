# 全局系统规则

本文件定义 AI_MEMORY_SYSTEM 的通用执行方式。

## 全局读取顺序

任何 AI 接入全局记忆系统时，必须按顺序执行：

1. 读取 `00_GLOBAL_MEMORY/identity.md`，确认全局身份与边界。
2. 读取 `00_GLOBAL_MEMORY/system_rules.md`，确认系统级规则。
3. 读取 `00_GLOBAL_MEMORY/execution_principles.md`，确认通用执行原则。
4. 读取 `01_PROJECT_REGISTRY/index.json` 和 `01_PROJECT_REGISTRY/active_projects.md`，确认项目列表。
5. 只进入用户明确授权的项目目录。
6. 在项目目录内按该项目 `BOOT.md` 的规则执行。

## 全局禁止事项

- 不允许跨项目读取数据。
- 不允许共享 STATE。
- 所有项目必须隔离。
- 不允许把全局层当作项目状态存储。
- 不允许在注册中心写入具体执行步骤。
- 不允许在项目未授权时读取项目文件。
- 不允许将一个项目的 STATE、TASKS、CORE 或 LOGS 复制到另一个项目。
- 不允许修改未授权项目。

## 项目选择规则

- 如果用户明确指定项目，AI 只能进入该项目。
- 如果用户未指定项目，AI 只能读取注册中心并询问用户要进入哪个项目。
- 如果项目不存在，AI 不得擅自创建业务内容；只能在用户授权后创建项目实例。

## 文件职责规则

- GLOBAL MEMORY 只存通用规则和原则。
- PROJECT REGISTRY 只存项目索引、路径和状态摘要。
- PROJECTS 下每个项目独立保存 BOOT、STATE、TASKS、CORE、LOGS。
