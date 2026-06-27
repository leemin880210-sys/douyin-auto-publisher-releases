# Project Factory v2: create_project

本文件定义 AI_MEMORY_SYSTEM 的自动项目生成流程。

目标：输入一句话，自动解析项目名、项目类型和描述，然后生成完整项目结构。

## INPUT

```json
{
  "project_name": "string",
  "project_type": "string",
  "description": "optional string"
}
```

也允许一句话输入，例如：

```text
创建一个 test project 用来做 data analysis
```

一句话输入必须先经过 `router.md` 解析为结构化 INPUT。

## PROCESS

### 1. 根据 project_type 选择模板

模板映射：

- `default` → `AI_MEMORY_SYSTEM/02_PROJECT_FACTORY/project_templates/default/`
- `data_analysis` → `AI_MEMORY_SYSTEM/02_PROJECT_FACTORY/project_templates/data_analysis/`
- `automation` → `AI_MEMORY_SYSTEM/02_PROJECT_FACTORY/project_templates/automation/`
- `ai_agent` → `AI_MEMORY_SYSTEM/02_PROJECT_FACTORY/project_templates/ai_agent/`

如果 `project_type` 未命中，必须使用 `default`。

### 2. 创建项目目录

创建：

```text
AI_MEMORY_SYSTEM/projects/{project_name}/
```

禁止覆盖已有同名项目。

### 3. 复制模板文件

从模板目录复制以下文件到新项目目录：

- `BOOT.md`
- `STATE.json`
- `TASKS.json`
- `CORE.md`
- `LOGS.md`

### 4. 初始化 STATE.json

新项目 `STATE.json` 必须写入：

```json
{
  "project_name": "{project_name}",
  "current_stage": "initialized",
  "current_task": "setup",
  "progress": "0%",
  "blockers": "",
  "last_update": "2026-06-27"
}
```

### 5. 写入 CORE.md

`CORE.md` 必须写入：

- project_name
- project_type
- description
- 项目边界
- 不跨项目读取数据
- 不共享 STATE

### 6. 写入 PROJECT_REGISTRY/index.json

必须自动追加：

```json
{
  "id": "{project_name}",
  "path": "projects/{project_name}",
  "status": "active"
}
```

### 7. 标记 active

新项目必须在注册中心标记：

```json
"status": "active"
```

## OUTPUT

成功后必须存在：

```text
AI_MEMORY_SYSTEM/projects/{project_name}/
├── BOOT.md
├── STATE.json
├── TASKS.json
├── CORE.md
└── LOGS.md
```

并且 `AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/index.json` 已包含新项目记录。

## 自动生成函数逻辑

```text
function create_project(project_name, project_type, description = ""):
    resolved_type = route(project_type, description)
    template_path = project_templates[resolved_type]
    target_path = AI_MEMORY_SYSTEM/projects/{project_name}

    assert project_name is not empty
    assert target_path does not already exist

    create target_path
    copy BOOT.md, STATE.json, TASKS.json, CORE.md, LOGS.md from template_path
    render STATE.json with project_name, setup, 0%, 2026-06-27
    render CORE.md with project_name, resolved_type, description
    append { id, path, status } to PROJECT_REGISTRY/index.json
    mark status active
    return target_path
```

## 成功标准

- 输入一句话可以通过 router 转换为 project_name、project_type、description。
- 新项目拥有完整五件套。
- 新项目 STATE 已初始化。
- 新项目已注册为 active。
- 未修改未授权项目。
