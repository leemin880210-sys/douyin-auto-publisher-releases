# 抖音代运营采集工具 CODE_EVOLUTION

本文件用于记录 `douyin_account_ops` 项目的采集代码演进。

## 文件用途

- 记录采集代码层面的关键变化。
- 说明每次代码变化为什么发生。
- 保存行为前后差异，便于 GPT/Codex 后续判断是否回归。
- 保存验证方式和验证结果。

## 记录边界

- 只记录代码实现变化。
- 不记录当前项目状态；当前状态只写入 `STATE.json`。
- 不记录待办计划；待办任务只写入 `TASKS.json`。
- 不替代事实日志；文件新增、同步、测试事实仍写入 `LOGS.md`。
- 不记录账号诊断、运营方案、脚本生成、自动发布、商家建档内容。

## 标准记录格式

每次采集代码变化按以下格式记录：

```text
## YYYY-MM-DD 变更标题

### 变更原因

### 影响文件

### 代码变化

### 行为变化

### 验证结果

### 风险与边界
```

## 2026-06-27 账号采集模块稳定性优化

### 变更原因

正式 30 条公开采集包中出现内容层采集失败样本，主要集中在：

- 图文或短作品播放过快，页面自动跳到下一条作品。
- `frame_status` 和 `video_crop_status` 在部分作品上失败。
- 采集过程中可能误操作隐藏视频或已跳转作品。
- 评论解析 fallback 可能把纯数字、抢首评、UI 文本写入正式评论。
- 未配置 ASR 时 transcript 输出容易被误解为已完成语音转写。

### 影响文件

- `douyin_auto_tool.ps1`

### 代码变化

- 主画面识别优先使用当前可见最大 `video`。
- 当 `video` 不可用时，裁剪逻辑 fallback 到主图 `img`、`canvas` 或包含主画面的容器。
- seek 逻辑只操作当前可见最大视频，避免误操作隐藏 video。
- 增加作品锁定逻辑：如果作品自动跳转，重新打开原作品链接并等待目标 `card_modal_id/opened_modal_id` 恢复。
- 抽帧重试逻辑改为核心帧缺失也触发重试。
- 重试前清理旧帧，重新打开原作品，重新等待媒体加载。
- 每条作品 `meta.json` 增加 `frame_errors` 和 `video_crop_errors`。
- 未配置 ASR 时，失败或异常路径中的 `transcript.txt` 写入 `speech_transcription_status: not_configured` 和空 transcript。
- 评论入库前过滤纯数字、抢首评、UI 文本、解析错位的纯数字作者名。

### 行为变化

- 图文作品和短作品不应因为自动跳转污染当前作品。
- 第 2 条、第 16 条这类 frame/crop 失败样本应通过等待、重试、重新打开原 `card_modal_id` 降低失败率。
- `frame_status=ok` 和 `video_crop_status=ok` 应表示核心帧与 contact sheet 均可用。
- 正式 `comments.items` 不写入纯数字、抢首评或明显 UI 噪声。
- 未配置 ASR 时不伪装语音转写完成。

### 验证结果

- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\douyin_auto_tool.ps1 -SelfTest` 通过。
- 测试模式 2 条采集结果为 `public_success=2`、`partial=0`、`failed=0`。
- 正式模式 30 条采集结果为 `public_success=29`、`partial=1`、`failed=0`。
- 正式模式 30 条 `visual_order` 为 1-30 连续。
- 正式模式 30 条 `content_mapping_status` 全部为 `ok`。
- 正式模式 30 条 `frame_status` 全部为 `ok`。
- 正式模式 30 条 `video_crop_status` 全部为 `ok`。
- 正式模式 30 条 `comments.json` 未检测到纯数字、抢首评或 UI 文本进入正式 `items`。
- 正式模式 30 条 `transcript.txt` 均保持 `speech_transcription_status: not_configured`。

### 风险与边界

- 本次只修改账号采集模块稳定性。
- 未扩展账号诊断、运营方案、脚本生成、自动发布或商家建档。
- 未绕过验证码、未破解登录、未抓取无权限内容。
- 当前仍有 1 条作品因 `ocr_status=failed` 进入 `partial`；frame/video_crop 已恢复为 ok。

## 2026-06-27 指定采集数量修复

### 变更原因

批量采集 4 个账号、每个账号指定 `-MaxWorks 5` 时，脚本进入正式模式后仍按默认正式规则自动改成最近 30 条。

该行为与临时指定采集数量冲突，会导致：

- 用户要求 5 条时实际采集 30 条。
- 批量多账号采集耗时明显增加。
- 采集包数量不符合用户当次任务要求。

### 影响文件

- `douyin_auto_tool.ps1`

### 代码变化

- 调整 `CollectLinks` 中正式模式采集数量计算逻辑。
- 当 `$Limit -lt 30` 时，正式模式尊重指定数量，并与主页作品总数取较小值。
- 当 `$Limit >= 30` 时，继续执行正式默认规则：账号作品数大于 30 时采最近 30 条，账号作品数小于等于 30 时采全部。

### 行为变化

- `-MaxWorks 5` 会在正式模式下采集最近 5 条。
- 正式默认规则仍保持 `test_mode=false`、默认 `max_works=30`。
- 账号作品数少于指定数量时，只采实际可见作品数量。

### 验证结果

- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\douyin_auto_tool.ps1 -SelfTest` 通过。
- 批量采集 4 个账号，每个账号均按 `-MaxWorks 5` 采集。
- 4 个输出包的 `works.json` 均为 5 条。
- 4 个输出包的 `visual_order` 均为连续 1-5。
- 4 个输出包的 `frame_status` 均为 `ok=5`。
- 4 个输出包的 `video_crop_status` 均为 `ok=5`。
- 4 个输出包均生成标准 `douyin_analysis_package.zip`。

### 风险与边界

- 本次只修复指定采集数量在正式模式下不生效的问题。
- 未修改评论、OCR、抽帧、摘要、授权指标采集逻辑。
- 未扩展账号诊断、运营方案、脚本生成、自动发布或商家建档。
