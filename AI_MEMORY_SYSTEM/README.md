# AI_MEMORY_SYSTEM

AI_MEMORY_SYSTEM 是一个面向多项目协作的 AI 记忆系统，用于让 AI 在不同项目之间保持可恢复、可交接、可隔离的工作方式。

它不是单项目记忆文件夹，而是一个多项目 AI OS：全局规则、项目注册中心、项目实例和项目工厂各自分层，避免状态混用和跨项目污染。

## 目录结构

```text
AI_MEMORY_SYSTEM/
├── 00_GLOBAL_MEMORY/
│   ├── identity.md
│   ├── system_rules.md
│   └── execution_principles.md
├── 01_PROJECT_REGISTRY/
│   ├── index.json
│   └── active_projects.md
├── 02_PROJECT_FACTORY/
│   ├── create_project.md
│   ├── router.md
│   ├── schema.json
│   ├── registry_hooks.md
│   └── project_templates/
└── projects/
    └── project_brain/
        ├── BOOT.md
        ├── STATE.json
        ├── TASKS.json
        ├── CORE.md
        ├── LOGS.md
        └── PROJECT_INDEX.md
```

## 核心分层

### 00_GLOBAL_MEMORY

保存全局 AI 行为规则和执行原则。

- `identity.md`：定义 AI_MEMORY_SYSTEM 是多项目系统。
- `system_rules.md`：定义禁止跨项目读取、禁止共享 STATE、项目隔离等规则。
- `execution_principles.md`：定义项目接入顺序：BOOT → STATE → TASKS → CORE。

### 01_PROJECT_REGISTRY

保存项目索引，不保存项目记忆。

- `index.json`：登记所有项目路径、状态和类型。
- `active_projects.md`：列出当前活跃项目。

### 02_PROJECT_FACTORY

Project Factory v2，用于根据一句话生成项目实例。

- `router.md`：根据关键词判断项目类型。
- `schema.json`：定义输入、模板和输出结构。
- `create_project.md`：定义创建项目的执行流程。
- `project_templates/`：保存 `default`、`data_analysis`、`automation`、`ai_agent` 四类模板。

### projects

保存每个独立项目实例。每个项目必须拥有自己的：

- `BOOT.md`
- `STATE.json`
- `TASKS.json`
- `CORE.md`
- `LOGS.md`
- `PROJECT_INDEX.md`（推荐）

## 当前项目

当前已注册项目：

```text
project_brain -> AI_MEMORY_SYSTEM/projects/project_brain
status: active
type: memory_system
```

`project_brain` 是从原单项目记忆系统迁移后的项目实例，现在只作为 `projects/` 下的独立项目存在。

## AI 接入流程

AI 进入系统时应按以下顺序：

1. 读取 `00_GLOBAL_MEMORY/identity.md`。
2. 读取 `00_GLOBAL_MEMORY/system_rules.md`。
3. 读取 `00_GLOBAL_MEMORY/execution_principles.md`。
4. 读取 `01_PROJECT_REGISTRY/index.json`。
5. 只进入用户明确授权的项目目录。
6. 在项目内按 `BOOT.md` → `STATE.json` → `TASKS.json` → `CORE.md` 的顺序执行。
7. 任务结束时回写项目自己的 `STATE.json` 和 `LOGS.md`，任务变化时同步 `TASKS.json`。

## 新建项目流程

使用 Project Factory v2 时，一句话会被转换为：

```json
{
  "project_name": "example_project",
  "project_type": "default",
  "description": "用户的一句话需求"
}
```

支持类型：

- `default`
- `data_analysis`
- `automation`
- `ai_agent`

新项目会生成到：

```text
AI_MEMORY_SYSTEM/projects/{project_name}/
```

并注册到：

```text
AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/index.json
```

## 强制约束

- 不允许跨项目读取数据。
- 不允许共享 STATE。
- 不允许把 registry 当作 memory 使用。
- 不允许把 global memory 写入项目业务内容。
- 不允许修改未授权项目。
- 不允许删除项目历史日志。

## 当前状态

AI_MEMORY_SYSTEM 当前可作为多项目 AI OS 使用。

- 全局规则层：已存在。
- 项目注册中心：已存在。
- project_brain 项目实例：已存在且 active。
- Project Factory v2：已存在，可按模板生成新项目。
