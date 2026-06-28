# 抖音代运营系统总框架

## 新 AI 必读说明

任何新的 GPT / Codex / AI 读取本项目时，必须先理解本文件。  
本文件定义的是整个抖音代运营 AI 工作系统的总框架。  
不得只把本项目理解为“采集工具项目”。

本项目不是单一采集工具，而是面向微小商家的抖音代运营 AI 工作系统。

## 状态边界

本文件只描述系统框架和模块顺序，不描述当前状态。  
阶段、任务、进度和阻塞全部以 `STATE.json` 为准。

## 设计执行顺序

1. `account_ops`：采集。
2. `shop_account_analysis`：账号深度分析。
3. `merchant_brain_factory`：商家独立大脑创建。
4. `merchants`：商家独立大脑实例。
5. `content_pipeline`：根据商家素材生成内容方向。
6. `data_review`：根据发布数据复盘调整。

## 系统模块

### 1. account_ops：账号采集模块

- 输入：抖音主页链接。
- 输出：本地采集包 ZIP。
- 边界：只采集，不做账号诊断，不做运营方案。
- 执行许可：以 `MASTER_CONTROL.md` 和 `STATE.json` 为准。

### 2. shop_account_analysis：店铺账号深度分析模块

- 输入：`account_ops` 生成的采集包 ZIP。
- 输出：账号问题、主页问题、作品问题、评论需求、接手方向。
- 边界：只做账号诊断，不创建长期商家大脑，不生成发布内容。
- 执行许可：以 `MASTER_CONTROL.md` 和 `STATE.json` 为准。

### 3. merchant_brain_factory：商家独立大脑创建模块

- 输入：账号诊断报告 + 商家基础资料。
- 输出：一个独立商家大脑。
- 目标：每个商家一个独立电子运营官。
- 执行许可：以 `MASTER_CONTROL.md` 和 `STATE.json` 为准。

### 4. merchants：商家独立大脑目录

- 每个商家独立一个目录。
- 每个商家拥有自己的 `PROFILE`、`STATE`、`STRATEGY`、`MATERIALS`、`PUBLISH_LOGS`、`DATA_REVIEW`。
- 不同商家之间记忆隔离。
- 创建许可：以 `MASTER_CONTROL.md` 和 `STATE.json` 为准。

### 5. content_pipeline：内容生产模块

- 输入：商家大脑 + 商家提供素材。
- 输出：混剪方向、标题、发布文案、脚本草案。
- 执行许可：以 `MASTER_CONTROL.md` 和 `STATE.json` 为准。

### 6. data_review：发布复盘模块

- 输入：已发布作品数据、评论、咨询反馈。
- 输出：复盘结论、调整方向、下一轮内容建议。
- 执行许可：以 `MASTER_CONTROL.md` 和 `STATE.json` 为准。

## 采集包与外部大脑关系

采集包是业务数据，默认保存在本地 `output_zip/` 和 `output/packages/{package_base_name}/`，不默认提交到 `AI_MEMORY_SYSTEM`。

`AI_MEMORY_SYSTEM` 只保存规则、状态、任务、日志、源码快照、模板和恢复路径。

## 后续记录位置

- 项目状态写入 `STATE.json`。
- 下一步任务写入 `TASKS.json`。
- 长期规则写入 `CORE.md`。
- 已发生事实写入 `LOGS.md`。
- 用户与 AI/Codex 对话写入 `CHAT_LOGS.md`。
- 采集工具代码变化才写入 `CODE_EVOLUTION.md`。
- 商家长期资料未来写入 `merchants/{merchant_id}/`，不同商家不得混用记忆。
