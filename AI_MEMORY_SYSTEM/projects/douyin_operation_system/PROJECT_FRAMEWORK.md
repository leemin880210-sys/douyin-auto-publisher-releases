# 抖音代运营系统总框架

## 语义层职责

`PROJECT_FRAMEWORK.md` 只负责【系统设计】。

只回答：

- 系统有哪些模块
- 模块怎么组成
- 模块之间的设计顺序

不回答：

- 当前执行状态
- 当前阶段
- 当前进度

## 系统目标

抖音代运营 AI 系统：采集 → 分析 → 商家大脑 → 内容 → 复盘。

## 设计模块

### 1. account_ops：账号采集模块

- 输入：抖音主页链接。
- 输出：本地采集包 ZIP。
- 职责：采集公开账号数据、生成采集包、检查采集包。

### 2. shop_account_analysis：店铺账号深度分析模块

- 输入：`account_ops` 生成的采集包 ZIP。
- 输出：账号问题、主页问题、作品问题、评论需求、接手方向。
- 职责：只做账号诊断，不创建长期商家大脑，不生成发布内容。

### 3. merchant_brain_factory：商家独立大脑创建模块

- 输入：账号诊断报告 + 商家基础资料。
- 输出：一个独立商家大脑。
- 目标：每个商家一个独立电子运营官。

### 4. merchants：商家独立大脑目录

- 每个商家独立一个目录。
- 每个商家拥有自己的 `PROFILE`、`STATE`、`STRATEGY`、`MATERIALS`、`PUBLISH_LOGS`、`DATA_REVIEW`。
- 不同商家之间记忆隔离。

### 5. content_pipeline：内容生产模块

- 输入：商家大脑 + 商家提供素材。
- 输出：混剪方向、标题、发布文案、脚本草案。

### 6. data_review：发布复盘模块

- 输入：已发布作品数据、评论、咨询反馈。
- 输出：复盘结论、调整方向、下一轮内容建议。

## 设计顺序

1. `account_ops`
2. `shop_account_analysis`
3. `merchant_brain_factory`
4. `merchants`
5. `content_pipeline`
6. `data_review`

## 采集包与外部大脑关系

采集包是业务数据，默认保存在本地 `output_zip/` 和 `output/packages/{package_base_name}/`，不默认提交到 `AI_MEMORY_SYSTEM`。

`AI_MEMORY_SYSTEM` 只保存规则、状态、任务、日志、源码快照、模板和恢复路径。
