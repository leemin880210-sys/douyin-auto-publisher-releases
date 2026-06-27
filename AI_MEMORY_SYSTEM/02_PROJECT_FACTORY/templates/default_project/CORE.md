# 项目 CORE

本文件保存项目长期认知。新项目创建后，应写入项目名称、项目类型、业务边界、授权范围和禁止事项。

## 项目基础信息

- project_name:
- project_type:
- owner:
- created_at:

## 项目目标

待初始化。

## 项目边界

- 本项目只读取自身目录内的 BOOT、STATE、TASKS、CORE、LOGS。
- 不跨项目读取数据。
- 不共享 STATE。
- 不修改未授权项目。

## 禁止事项

- 不把 registry 当 memory 使用。
- 不把 global memory 写入项目业务内容。
- 不删除历史日志。
