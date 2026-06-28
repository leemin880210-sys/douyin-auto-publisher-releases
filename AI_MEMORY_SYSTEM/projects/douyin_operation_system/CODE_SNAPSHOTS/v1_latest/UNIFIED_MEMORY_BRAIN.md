# UNIFIED_MEMORY_BRAIN（统一记忆入口）

本文件受 `COGNITIVE_ENTRY.md` 约束。`COGNITIVE_ENTRY.md` 是第一认知入口，本文件是统一记忆汇总层。

本文件是 `douyin_operation_system` 的统一认知入口汇总层，用于让新的 GPT / Codex / AI 在读取外部大脑后快速接管上下文。

本文件不是唯一状态源，不替代 `STATE.json`。新 AI 必须先读取 `STATE.json`，再读取本文件恢复完整上下文。

## 当前项目目标

本项目是抖音代运营 AI 系统，目标是形成完整流程：

```text
采集 → 分析 → 商家大脑 → 内容 → 复盘
```

系统本质不是单一采集工具，而是可跨 AI 接管的代运营流程系统。

## 当前阶段

当前阶段来自 `STATE.json`：

```text
account_ops 账号采集模块多账号样本验证阶段
```

当前只围绕 `account_ops` 做采集包相关工作。

## 已完成能力

`account_ops` 已具备以下能力基础：

- 生成本地采集包 ZIP。
- 输出评论相关数据。
- 输出关键帧 / OCR 相关材料。
- 生成结构化输出与采集包目录。
- 使用 `output_zip/` 保存 ZIP。
- 使用 `output/packages/{package_base_name}/` 保存解压后的采集包目录。
- 5 条 / 10 条样本包已多账号通过。

采集包是本地业务数据，不默认提交到 `AI_MEMORY_SYSTEM`。

## 系统结构

外部大脑当前核心结构：

- `MASTER_CONTROL.md`：执行权限，只回答能不能做。
- `STATE.json`：唯一真实状态源，只回答现在在做什么。
- `TASKS.json`：下一步动作，只回答下一步做什么。
- `PROJECT_FRAMEWORK.md`：系统结构，只回答系统有哪些模块、模块怎么组成。
- `MODULE_ROUTES.md`：模块路由，只回答用户请求应该进入哪个模块。

如果不同文件发生冲突，先按 `SYSTEM_CONSTITUTION.md` 和 `STATE_CONSISTENCY_LOCK.md` 判断语义层，不允许把状态分散到多个文件。

## 当前运行限制

当前只允许：

- 读取采集包。
- 生成采集包。
- 检查采集包。

当前禁止：

- 启动 `shop_account_analysis` 做真实账号深度分析。
- 创建真实商家大脑。
- 启动 `content_pipeline` 内容生成。
- 启动 `data_review` 数据复盘。
- 自动生成运营方案。
- 自动生成内容策略。
- 自动发布。
- 跨模块执行。

## 下一步模块

下一步设计模块是：

```text
shop_account_analysis
```

但该模块尚未授权启动。只有用户明确授权并提供采集包后，才允许进入真实账号分析。

## 新 AI 接手规则

新 AI 必须：

1. 先读取 `STATE.json`，确认真实状态。
2. 再读取 `UNIFIED_MEMORY_BRAIN.md`，恢复完整认知。
3. 再根据 `MASTER_CONTROL.md` 判断能不能做。
4. 再根据 `TASKS.json` 判断下一步动作。
5. 不从 `CORE.md`、`PROJECT_FRAMEWORK.md`、`MODULE_ROUTES.md` 或 `TASKS.json` 推断状态。
6. 不跳过 `account_ops`。
7. 不把规划模块当成已启动模块。

## 统一记忆原则

本文件让新 AI 不再从 0 理解系统，而是通过一个入口恢复：

- 当前项目目标。
- 当前阶段。
- 当前限制。
- 已完成能力。
- 下一步模块。
- 文件语义分层。
- 接手边界。

如需判断真实状态，以 `STATE.json` 为准。  
如需判断执行权限，以 `MASTER_CONTROL.md` 为准。  
如需判断下一步动作，以 `TASKS.json` 为准。
