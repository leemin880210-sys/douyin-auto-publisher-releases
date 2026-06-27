# AI项目工厂系统 v1：create_project

本文件定义 AI_MEMORY_SYSTEM 中创建新项目实例的标准流程。

## 输入

创建项目时必须提供：

- `project_name`：项目唯一名称，只能用于创建 `AI_MEMORY_SYSTEM/projects/{project_name}/`。
- `project_type`：项目类型，用于选择模板。v1 默认使用 `templates/default_project/`。

## 输出

执行完成后必须得到：

1. `AI_MEMORY_SYSTEM/projects/{project_name}/` 项目目录。
2. 从对应模板复制得到的 `BOOT.md`、`STATE.json`、`TASKS.json`、`CORE.md`、`LOGS.md`。
3. 已初始化的 `STATE.json`。
4. 已写入项目基础认知的 `CORE.md`。
5. 已注册到 `AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/index.json` 的项目记录。

## 创建流程

1. 校验 `project_name` 不为空，且不能与已有项目重名。
2. 校验 `project_type`，如果没有专用模板，则使用 `templates/default_project/`。
3. 创建目录：`AI_MEMORY_SYSTEM/projects/{project_name}/`。
4. 复制模板文件到新项目目录。
5. 初始化 `STATE.json`：
   - `project_name` 写入输入项目名。
   - `current_stage` 保持 `initialized`。
   - `progress` 保持 `0%`。
   - `last_update` 写入执行日期。
6. 写入 `CORE.md`：记录项目名称、项目类型、项目边界和禁止跨项目读取规则。
7. 按 `registry_hooks.md` 更新 `AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/index.json`。
8. 按需更新 `AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/active_projects.md`。

## 成功标准

- 新项目拥有完整五件套：BOOT、STATE、TASKS、CORE、LOGS。
- 新项目的 STATE 不共享任何其他项目状态。
- 新项目被注册为 active。
- 未修改任何未授权项目。
