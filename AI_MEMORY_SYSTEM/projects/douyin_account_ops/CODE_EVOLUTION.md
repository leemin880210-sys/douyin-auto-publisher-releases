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

## 2026-06-28 OCR 摘要与转化证据过滤补强

### 变更原因

5 条样本包复测时发现两个内容质量问题：

- 第 1 条作品的 `summary` 曾混入低质量 OCR 文本，例如 `moonfiow/noonfiow/wm F/Se a S` 等乱码。
- 当 OCR 失败时，展示用 fallback 文案“关键帧可上传给 ChatGPT 识别画面文字、价格、地址、活动和团购信息”被误当作 OCR 证据，导致 `conversion_flags.address/group_buy` 误标 true。

### 影响文件

- `douyin_auto_tool.ps1`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/STATE.json`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/TASKS.json`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/CORE.md`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/LOGS.md`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/CODE_EVOLUTION.md`

### 代码变化

- 新增 `GetReliableVisualSummaryText`，过滤低质量 OCR 文本。
- `NewVisualRhythmAnalysis` 在写入画面节奏前先执行可靠 OCR 过滤。
- 单条作品 `summary` 生成逻辑只使用可靠 OCR 或口播转写；没有可靠内容时写“需根据关键帧判断”。
- `FindConversionEvidence` 对 OCR 来源先执行可靠 OCR 过滤。
- `FindConversionEvidence` 排除 `OCR 状态`、`ChatGPT`、`关键帧可上传`、`OCR 引擎不可用` 等 fallback 提示文本。
- `SelfTest` 增加低质量 OCR 摘要过滤、低质量 OCR 团购误判、可靠 OCR 价格识别、OCR fallback 提示不触发转化的断言。

### 行为变化

- 低质量 OCR 不再进入 `summary.md` 的视频画面简述。
- 低质量 OCR 不再进入 `visual_rhythm_analysis`。
- 低质量 OCR 不再触发 `conversion_flags`。
- OCR 失败时的说明性 fallback 文案只用于提示人工查看关键帧，不再作为地址、价格、团购、活动证据。
- 可靠 OCR 中的价格、套餐、营业时间等业务文本仍可用于摘要和转化判断。

### 验证结果

- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\douyin_auto_tool.ps1 -SelfTest` 通过。
- 后续仍需重新执行 5 条样本包，检查 `summary.md` 和 `conversion_flags` 是否不再被 OCR 乱码或 fallback 提示污染。

### 风险与边界

- 本次只优化 OCR 文本使用和转化证据过滤。
- 未修改作品链接采集、关键帧抽取、评论采集、授权指标或账号诊断逻辑。
- 未扩展账号诊断、运营方案、脚本生成、自动发布或商家建档。
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

## 2026-06-28 评论统计字段增强

### 变更原因

GPT 检查评论数量时容易只看 `comments.items`，从而误以为工具没有采集到 `comments.replies` 中的回复 / 楼中楼。

本次目标是在不改变评论采集逻辑、不改变评论分层规则的前提下，增加清晰的评论统计字段，让主评论、回复、总提取数和缺口数可以被直接检查。

### 影响文件

- `douyin_auto_tool.ps1`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/STATE.json`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/TASKS.json`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/CORE.md`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/LOGS.md`
- `AI_MEMORY_SYSTEM/projects/douyin_account_ops/CODE_EVOLUTION.md`

### 代码变化

- 新增 `GetCommentCountStats`。
- 保留 `GetCommentCountMatchStatus` 作为兼容入口，但内部使用新统计函数。
- `AddCommentStats` 新增写入：
  - `main_comment_count`
  - `reply_comment_count`
  - `total_extracted_comment_count`
  - `comment_gap_count`
- 每条作品的 `works.json` / `meta.json` 新增同名评论统计字段。
- `comments.json` 新增同名评论统计字段。
- `works.xlsx` 新增同名列。
- 失败作品和异常作品也输出这些字段，缺少公开评论数时 `comment_count_match_status=unknown`。
- `SelfTest` 增加评论统计字段和新状态枚举断言。

### 行为变化

- `comments.items` 仍然只放正式主评论。
- `comments.replies` 仍然只放回复 / 楼中楼。
- `raw_comments_debug` 仍然只放不确定结构、UI、乱码、DOM 错位内容。
- `web_comment_reply_api` 仍然不进入 `comments.items`。
- 纯数字、抢首评、UI 文本仍然不得进入 `comments.items`。
- GPT 后续检查评论数量时应看 `main_comment_count + reply_comment_count`，不能只看 `comments.items.length`。

### comment_count_match_status 新取值

- `public_zero`
- `matched`
- `matched_with_replies`
- `partial_with_replies_filtered`
- `visible_count_but_items_empty`
- `extracted_more_than_public`
- `unknown`

### 验证结果

- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\douyin_auto_tool.ps1 -SelfTest` 通过。

### 风险与边界

- 本次只增强评论统计字段。
- 未修改评论采集 API。
- 未修改 DOM 评论解析逻辑。
- 未修改评论过滤规则。
- 未修改作品链接采集、抽帧、OCR、摘要、授权指标或 ZIP 输出主流程。
