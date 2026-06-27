# Registry Hooks

本文件定义 AI项目工厂系统 v1 写入 PROJECT_REGISTRY 的规则。

## 强制注册规则

- 新项目必须写入 `AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/index.json`。
- 注册记录必须包含 `path` 和 `status`。
- 新项目必须标记为 `active`。
- 不允许把项目 STATE、TASKS、CORE 或 LOGS 写入注册中心。
- 注册中心只保存项目索引、路径、状态和类型摘要。

## index.json 写入格式

新项目必须写入以下结构：

```json
{
  "{project_name}": {
    "path": "AI_MEMORY_SYSTEM/projects/{project_name}",
    "status": "active",
    "type": "{project_type}"
  }
}
```

## active_projects.md 写入格式

`active_projects.md` 必须列出当前活跃项目，至少包含：

```text
- {project_name}: AI_MEMORY_SYSTEM/projects/{project_name} (active)
```

## 隔离约束

- 注册新项目不等于授权读取其他项目。
- registry 不得成为 memory。
- registry 不得保存执行日志。
- registry 不得保存跨项目共享状态。
