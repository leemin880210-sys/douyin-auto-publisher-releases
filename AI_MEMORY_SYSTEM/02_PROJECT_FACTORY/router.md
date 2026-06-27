# Project Factory v2 Router

本文件定义一句话输入到项目类型的路由规则。

## 输入

- `sentence`：用户的一句话需求。
- `project_name`：可由用户提供；未提供时由 AI 根据 sentence 生成 snake_case 名称。
- `description`：可选，默认使用 sentence 原文。

## 路由规则

按优先级匹配关键词：

1. 包含 `data` 或 `analysis`：`data_analysis`
2. 包含 `bot` 或 `automation`：`automation`
3. 包含 `ai` 或 `agent`：`ai_agent`
4. 未命中：`default`

## 输出

```json
{
  "project_name": "{project_name}",
  "project_type": "{resolved_type}",
  "description": "{description}"
}
```

## 示例

输入：`创建一个 test project 用来分析销售 data`

输出：

```json
{
  "project_name": "test_project",
  "project_type": "data_analysis",
  "description": "创建一个 test project 用来分析销售 data"
}
```
