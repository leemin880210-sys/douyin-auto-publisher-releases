# Registry Hooks v2

本文件定义 Project Factory v2 写入 PROJECT_REGISTRY 的规则。

## 目标文件

新项目必须写入：

```text
AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/index.json
```

## 必须追加的记录

每个新项目必须自动追加：

```json
{
  "id": "{project_name}",
  "path": "projects/{project_name}",
  "status": "active"
}
```

## 强制规则

- 新项目必须写入 PROJECT_REGISTRY/index.json。
- 必须记录 `path` + `status`。
- 必须标记 `active`。
- `path` 使用相对项目路径：`projects/{project_name}`。
- 不允许把项目 STATE、TASKS、CORE 或 LOGS 写入注册中心。
- 注册中心只保存项目索引、路径、状态和类型摘要。

## active_projects.md 同步

新项目创建后，必须同步追加到：

```text
AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/active_projects.md
```

推荐格式：

```text
- {project_name}: projects/{project_name} (active)
```

## 隔离约束

- 注册新项目不等于授权读取其他项目。
- registry 不得成为 memory。
- registry 不得保存执行日志。
- registry 不得保存跨项目共享状态。
