# 抖音代运营采集工具 CODE_EVOLUTION

本文件用于记录 `douyin_account_ops` 项目的采集代码演进。

## 文件用途

- 记录采集代码层面的关键变化。
- 说明每次代码变化为什么发生。
- 保存行为前后差异，便于 GPT/Codex 后续判断是否回归。
- 保存验证方式和验证结果。
- 保存最近3次完整代码版本快照，防止多轮修改后丢失上下文。

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

## Code Snapshot History

### v1（最新版本）

```text
完整修改后的代码
```

### v2（上一版本）

```text
修改前最近一次完整代码；如果不存在，则写：无历史版本
```

### v3（上上版本）

```text
再之前的一次完整代码；如果不存在，则写：无历史版本
```
```

## 最近3次完整代码版本快照规则

每一个代码修改记录必须维护：

### v1（最新版本）

完整修改后的代码。

### v2（上一版本）

修改前最近一次完整代码。

### v3（上上版本）

再之前的一次完整代码。

如果历史版本不足3次，缺失版本必须明确写为“无历史版本”。

## 快照轮转规则

当发生新的代码修改时：

1. 新代码写入 v1。
2. 修改前的 v1 下移为 v2。
3. 修改前的 v2 下移为 v3。
4. 修改前的 v3 超出最近3次范围，不再保留在当前记录的快照区。
5. 历史记录本身不得覆盖或删除。

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

## 2026-06-28 采集输出字段与状态小优化

### 变更原因

4 个 5 条样本包已经通过基础检查，但样本包和正式包缺少明确的包类型字段；部分评论状态在公开评论数大于 0 但正式评论 items 为空时容易误标为 `ok_with_reply_filtered`；位置证据仍可能被账号名兜底；图文或静态卡片的时长不可用场景需要更明确表达；`detail_title` 不应参与 summary 主标题判断。

### 影响文件

- `douyin_auto_tool.ps1`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/STATE.json`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/TASKS.json`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/CORE.md`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/LOGS.md`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/CODE_EVOLUTION.md`

### 代码变化

- 新增脚本级运行模式状态：`RunMode`、`SampleSize`、`FormalAcceptance`。
- 新增 `SetRunMode`，根据原始请求数量和测试模式判断样本包或正式包。
- 每条作品输出新增 `run_mode`、`sample_size`、`formal_acceptance`。
- `account_summary.md` 和 `works.xlsx` 新增同名字段。
- 评论状态逻辑新增 `visible_count_but_items_empty`、`partial_no_valid_comments_extracted`。
- 当 `public_comment_count > 0` 且 `comments.items=0` 时，作品状态不再按成功处理。
- 新增 `DetectCurrentMediaType`，用于识别 `video` 或 `static_or_image_card`。
- 抽帧结果新增 `duration_status` 和 `media_type`。
- `duration_seconds` 不可用但帧和裁剪正常时输出 `duration_status=unavailable_but_frames_ok`。
- 主页资料解析移除 `has_location_evidence` 使用账号名兜底的逻辑。
- `summary.md` 去掉正文区的详情页标题，改为在 Debug 区记录 `detail_title`。
- `SelfTest` 新增样本/正式 `run_mode` 判定断言，以及失败记录 `duration_status`、`media_type`、`formal_acceptance` 字段断言。

### 行为变化

- 手动指定 5 条采集或 `--test-mode` 生成样本检查包字段。
- 默认 30 条正式采集生成正式包字段；账号实际作品数小于等于 30 时仍按正式包验收。
- 有公开评论数但没有有效评论 items 时，GPT 可以明确识别为评论采集不完整。
- 位置证据更严格，不再用账号名假装地址证据。
- 图文或静态卡片不会因为没有视频时长而直接被误判为内容失败。
- summary 主标题只使用 `canonical_title`，降低详情页错位污染风险。

### 验证结果

- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\douyin_auto_tool.ps1 -SelfTest` 通过。
- `STATE.json` 通过 `ConvertFrom-Json` 校验。
- `TASKS.json` 通过 `ConvertFrom-Json` 校验。

### 风险与边界

- 本次未重新实际采集 5 条样本包或 30 条正式包，只完成脚本自检。
- 本次只优化采集输出字段和状态规则。
- 未扩展账号诊断、运营方案、脚本生成、自动发布或商家建档。
- 未绕过验证码、未破解登录、未抓取无权限内容。
