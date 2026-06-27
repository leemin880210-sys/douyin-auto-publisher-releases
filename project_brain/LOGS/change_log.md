# Project Brain 变更记录

## 2026-06-27 创建单项目外部大脑系统

### 修改了什么

- 新增 `project_brain/CORE/memory.md`。
- 新增 `project_brain/STATE/state.json`。
- 新增 `project_brain/TASKS/next_actions.json`。
- 新增 `project_brain/LOGS/change_log.md`。
- 新增 `project_brain/BOOT/boot_prompt.md`。

### 为什么修改

为了建立单项目隔离的外部大脑系统，让任何 AI（Codex / GPT）进入当前项目时，都能快速恢复项目状态、理解当前任务、持续执行并留下可追踪记录。

### 是否影响旧逻辑

否。本次只新增 `project_brain/` 目录，不修改采集工具、业务代码、记忆库验收规则或历史输出。

### 是否通过测试

已通过基础检查：

- 5 个标准文件均已创建。
- `STATE/state.json` 可用 UTF-8 正确解析为 JSON。
- `TASKS/next_actions.json` 可用 UTF-8 正确解析为 JSON。
- 未修改业务代码结构。

## 2026-06-27 上传 project_brain 到 GitHub 供 GPT 检查

### 修改了什么

- 更新 `project_brain/STATE/state.json`，记录当前阶段为外部检查交付阶段。
- 更新 `project_brain/TASKS/next_actions.json`，加入 GitHub 检查链接和 GPT 检查任务。
- 已将 `project_brain/` 上传到 `leemin880210-sys/douyin-auto-publisher-releases` 仓库。

### 为什么修改

用户要求把单项目外部大脑放到 GitHub，便于 GPT 直接通过链接检查，无需人工上传本地压缩包。

### 是否影响旧逻辑

否。本次只更新 project brain 的状态记录和上传交付信息，不修改抖音采集工具、业务代码或既有验收规则。

### 是否通过测试

已通过 GitHub 反向读取验证：`project_brain/TASKS/next_actions.json` 可从仓库正常打开，五个核心文件已推送到 `project_brain/` 路径。

## 2026-06-27 执行稳定性优化

### 已发生事实

- 修改 `project_brain/BOOT/boot_prompt.md`，声明 BOOT 为唯一入口。
- 修改 `project_brain/BOOT/boot_prompt.md`，写入强制执行顺序、固定执行流程和禁止行为。
- 修改 `project_brain/STATE/state.json`，将字段固定为 `project_name`、`current_stage`、`current_task`、`progress`、`blockers`、`last_update`。
- 修改 `project_brain/STATE/state.json`，用 `blockers` 替代旧字段 `blocking_issues`。
- 修改 `project_brain/TASKS/next_actions.json`，删除当前状态、已完成描述和历史交付信息。
- 修改 `project_brain/TASKS/next_actions.json`，保留待做任务、GPT 检查任务和验收标准。
- 修改 `project_brain/LOGS/change_log.md`，记录本次已发生的规则优化事实。

### 影响范围

- 只影响 `project_brain` 内部规则文件。
- 未新增目录结构。
- 未修改抖音采集工具代码。

### 验证结果

- `STATE/state.json` 保持 JSON 格式。
- `TASKS/next_actions.json` 保持 JSON 格式。
