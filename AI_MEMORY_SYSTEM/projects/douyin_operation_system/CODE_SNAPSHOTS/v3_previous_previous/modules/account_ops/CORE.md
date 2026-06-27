# 抖音代运营采集工具 CORE

本文件保存本项目长期稳定规则。除非采集边界、输出结构或业务目标变化，否则不要随意改动。

## 项目定位

本项目是 Windows 本地运行的抖音账号采集包工具，用于生成可交给 GPT 分析的账号资料包，服务于抖音代运营接手前诊断、未授权账号内容诊断和签约后授权数据补齐。

## 当前账号采集模块边界

当前阶段只优化账号采集模块：

- 输入抖音账号主页链接。
- 输出标准 `douyin_analysis_package.zip`。
- 不扩展账号诊断。
- 不生成运营方案。
- 不生成脚本。
- 不做自动发布。
- 不做商家建档。

## 合规边界

- 不绕过验证码。
- 不破解登录。
- 不抓取无权限内容。
- 只读取用户手动登录后当前可见页面或公开可见内容。
- 登录状态可保存在本机浏览器 profile/cookie 中，但不得上传或外传 cookie。
- 未授权数据不得伪造成授权数据。
- 未授权拿不到的数据必须保留 null，并标记为授权后待补齐。

## 采集模式

### public 未授权模式

用于接手前初步诊断。重点采集内容层和公开可见信息。

必填内容：

- 账号主页信息
- 主页第一屏截图
- 作品视觉顺序
- 作品标题/文案
- 发布时间原始值
- 是否置顶
- 封面图
- 关键帧和 contact sheet
- OCR 画面文字
- 口播/字幕转写状态
- 评论区可见评论
- 内容摘要
- 转化引导判断

### authorized 授权模式

用于签约后完整运营诊断。授权后才补齐：

- play_count
- authorized_like_count
- authorized_comment_count
- favorite_count
- share_count
- 粉丝画像
- 流量来源
- 完播率
- 5 秒播放率
- 互动率
- 涨粉数
- 主页访问数

## 默认采集数量

- 正式模式默认 `test_mode=false`。
- 正式模式默认 `max_works=30`。
- 账号作品数 <= 30 时采集全部作品。
- 账号作品数 > 30 时采集最近 30 条。
- 当命令行或界面明确指定小于 30 的采集数量时，正式模式必须尊重该指定数量。
- 测试模式必须手动传入 `--test-mode`，且在 summary/account_summary 中明确标记。

## 主页卡片规则

必须先从主页作品卡片生成 `card_records`，每条包含：

- visual_order
- card_modal_id
- card_text
- public_card_like_count
- row
- col
- card_bbox
- cover

规则：

- `card_text` 只能来自当前作品卡片 DOM，不能从整页 visible_text 截断。
- `public_card_like_count` 必须从作品卡片心形图标旁数字读取。
- `visual_order` 必须连续；失败作品也要生成 failed/partial 记录，不允许跳号。
- row/col 应结合 card_bbox 计算，避免重复或乱序。

## 作品绑定规则

- 打开作品后必须记录 `opened_modal_id`。
- `card_modal_id == opened_modal_id` 时，`content_mapping_status=ok`。
- 标题不一致只影响 `title_consistency_status`，不直接导致 `content_mapping_status=mismatch`。
- `canonical_title = card_text`。
- `detail_title = title`。
- `summary.md` 统一使用 `canonical_title`。

## 公开指标规则

- 未授权模式下，主页卡片心形数保存为 `public_card_like_count`。
- 来源字段为 `public_card_like_source=homepage_card`。
- 详情页没有复核到公开指标时，`public_metric_status=card_only`。
- 只有详情页明确读到不同数字时，才标记 `public_metric_status=mismatch`。
- 不要把公开页面数字误填到 share_count。
- 未授权拿不到真实分享数时，share_count 保持 null。

## 关键帧规则

每条视频先获取 `duration_seconds`。

抽帧策略：

- cover
- 0s
- 1s
- 2s
- 3s
- 5s
- 5 秒后每 3 秒一帧：8s、11s、14s、17s、20s，直到结束
- 额外保存 ending.jpg

如果视频小于 6 秒，至少输出：

- cover
- 0s
- 1s
- 2s
- 3s
- ending

图片规则：

- 所有帧使用 jpg。
- 宽度压缩到 720px 或 960px。
- 质量 70-80。
- 每条作品生成 `frames_contact_sheet.jpg`。

关键帧必须分两套：

- `full_frame`：完整网页截图，保留抖音 UI。
- `video_crop`：只裁剪视频主体画面，用于 OCR、摘要和画面节奏判断。

OCR 只能对 `video_crop` 执行。

## 抽帧稳定性规则

- 打开作品后必须等待可见媒体加载，再开始抽帧。
- 可见媒体优先识别 `video`，如果页面是图文或 video rect 不可用，可 fallback 到主图 `img`、`canvas` 或包含主画面的容器。
- seek 只能操作当前可见最大视频，避免误操作隐藏 video。
- 如果作品播放完或图文自动跳到下一条，必须重新打开原 `card_modal_id` 对应作品。
- 核心帧缺失时必须重试；核心帧包括 `cover`、`0s`、`1s`、`2s`、`3s`、`ending`。
- 重试前必须清理旧帧，重新打开原作品，重新等待媒体加载。
- `frame_status=ok` 和 `video_crop_status=ok` 应表示核心帧与 contact sheet 均可用。

## OCR 规则

- PaddleOCR 优先，Tesseract 可作为本地 fallback。
- `ocr_items.json` 记录 `frame_time`、`source_frame`、`cropped_video_frame_path`、`text`、`confidence`、`is_ui_text`、`clean_text`。
- OCR 乱码不能进入 summary.md。
- 价格判断必须有证据：`¥+数字`、`数字+元`、`人均+数字`、`套餐+价格` 等。
- 单独出现 `¥` 不能判断 price=true。

## 评论规则

- 评论入口优先使用键盘 `X` 打开，避免误触点赞。
- 显示“抢首评”代表没有评论。
- 评论图标旁有数字代表有评论，需要打开评论区采集。
- 采集评论时要在评论面板内滚动，不误触点赞。
- 不采集作者回复作为正式评论。
- 纯数字、抢首评、无意义 UI 文本不得写入 `comments.items`。
- 解析错位导致作者名或正文为纯数字、点赞数、回复数、UI 文本时，不得写入 `comments.items`。
- fallback 无法确认结构时只能放入 `raw_comments_debug`。
- 评论数不完整时标 `comment_status=partial`。
- 如果公开评论数大于 comments.items 数量，差异来自作者回复或过滤评论，可标 `ok_with_reply_filtered`。

## 语音转写规则

- 未配置 ASR 时不要标 ok。
- `speech_status=not_available`。
- `speech_transcription_status=not_configured`。
- `no_speech=unknown`。
- `transcript.txt` 中 transcript 为空字符串。

## 转化判断规则

conversion_flags 必须证据制。

没有 title/OCR/transcript/comment 的明确证据时，不能标 true。

每个 true 必须包含：

- evidence
- source

重点判断：

- 地址
- 价格
- 团购
- 私信
- 关注
- 预约
- 营业时间
- 活动
- 套餐

## 输出结构

最终输出必须是标准 ZIP。

根目录至少包含：

- `account_summary.md`
- `account_profile.json`
- `works.xlsx`
- `works.json`

每条作品独立文件夹，格式：

```text
序号_video_id/
├── meta.json
├── cover.jpg
├── frames/
├── frames_contact_sheet.jpg
├── transcript.txt
├── ocr_text.txt
├── ocr_items.json
├── comments.json
└── summary.md
```

`works.json` 必须是数组。

`works.xlsx` 必须用 openpyxl 或 exceljs 生成。

路径全部使用相对路径，不输出本机绝对路径。

## 状态字段

每条作品必须拆分状态：

- content_mapping_status
- title_consistency_status
- frame_status
- video_crop_status
- ocr_status
- comment_status
- speech_status
- public_metric_status
- authorized_metric_status

总体状态：

- `public_success`：未授权模式下内容层采集完整。
- `partial`：内容层部分缺失但有可分析材料。
- `failed`：标题、封面、关键帧、字幕/OCR 等核心内容层也没采到。

authorized_metric_pending 不应导致 public_success 失败。

## account_profile 规则

必须结构化字段：

- nickname
- douyin_id
- following_count
- follower_count
- total_likes
- works_count
- ip_location
- age_or_tag
- bio
- has_group_buy_entry
- has_group_buy_entry_evidence
- has_promo_content
- has_promo_content_evidence
- has_booking_content
- has_booking_content_evidence
- has_event_content
- has_event_content_evidence
- has_location
- has_location_evidence
- has_shop
- has_shop_evidence
- homepage_screenshot_path

location evidence 不得抓网页备案文本。

## account_summary 规则

必须统计：

- collection_mode
- authorization_status
- data_level
- 作品总数
- 成功采集数
- 失败数
- public_success_count
- content_collection_pending_count
- authorized_metric_pending_count
- missing_due_to_authorization
- missing_due_to_error
- 异常作品列表

## 运行模式字段规则

- 5 条样本包必须输出 `run_mode=sample_check`、`sample_size=5`、`formal_acceptance=false`。
- 手动指定小于 30 的采集数量，或显式使用 `--test-mode`，都属于样本检查包。
- 30 条正式包必须输出 `run_mode=formal_collection`、`formal_acceptance=true`。
- 默认 30 条正式采集遇到账号作品数小于等于 30 时，虽然实际采集数量小于 30，仍属于正式采集包。
- 这些字段必须写入 `account_summary.md`、`works.json`、每条作品 `meta.json`，并同步到 `works.xlsx`。

为什么这样定：GPT 检查样本包和正式包时必须先判断包的验收口径，避免把 5 条样本包误判为正式诊断包，也避免账号不足 30 条时把正式包误判为样本包。

## 评论状态补充规则

- 如果 `public_comment_count > 0` 且 `comments.items` 为空，不得标记 `ok_with_reply_filtered`。
- 如果页面显示有评论数但未抽取到有效评论，标记 `visible_count_but_items_empty`。
- 如果提取结果被过滤后没有可写入正式 items 的真实评论，标记 `partial_no_valid_comments_extracted`。
- `ok_with_reply_filtered` 只用于确认差异来自作者回复或无效占位评论被过滤，且仍有有效用户评论进入 `comments.items` 的情况。

为什么这样定：公开评论数表示页面存在可见评论入口，正式 items 为空时不能虚标采集成功，否则会掩盖评论采集失败或解析失败。

## 位置证据补充规则

- `has_location_evidence` 不得使用账号名兜底。
- 位置证据优先来自主页地址入口、简介地名、作品标题地名、评论区地址问答。
- 店铺身份判断可以记录到 `has_shop_evidence`，但不能替代位置证据。

为什么这样定：账号名常包含门店名或分店名，但不等于可验证地址。位置证据必须能支撑“地址/到店/导航”判断。

## 时长与媒体类型规则

- 如果 `duration_seconds` 不可用，但 `frames_contact_sheet` 和 `video_crop` 正常，标记 `duration_status=unavailable_but_frames_ok`。
- 如果作品表现为图文或静态卡片，标记 `media_type=static_or_image_card`。
- 如果可见视频时长正常，标记 `duration_status=ok`、`media_type=video`。

为什么这样定：图文或短静态作品可能无法稳定读取视频时长，但只要关键帧和裁剪图可用，仍能支持内容诊断，不应直接判失败。

## 标题输出补充规则

- `canonical_title` 是主标题，优先使用主页卡片 `card_text`。
- `detail_title` 只作为 Debug 信息保存，不参与主标题判断。
- `summary.md` 的主标题必须使用 `canonical_title`，不要把详情页标题错位污染到主标题。

为什么这样定：详情页标题更容易受弹窗错位、SEO 标题或页面环境影响；主页卡片文案是视觉顺序绑定的主证据。

## summary.md 规则

summary.md 不要混入：

- 网页 UI
- 搜索框
- 账号名
- 直播提示
- 评论文本
- OCR 乱码

视频画面简述只来自：

- 关键帧
- 可靠 OCR
- 口播转写

如果没有可靠内容，写“需根据关键帧判断”。

评论区反馈必须单独成节。

## 输出命名与 ZIP 防冲突规则（v1.0）

规则版本时间：`2026-01-24_1530`

本规则用于规范抖音代运营采集包、ZIP 包和后续交付文件命名，避免多商家并行时文件冲突。该规则不表示当前采集工具已扩展到账号诊断、运营方案、脚本生成、自动发布或商家建档。

### 统一命名规则

所有输出必须统一命名：

```text
{店铺名称}-{作品数量}-{时间}
```

时间格式：

```text
YYYYMMDD_HHMM
```

示例：

```text
星火奶茶店-001-20260124_1530.mp4
星火奶茶店-002-20260124_1530.txt
```

### ZIP 压缩包规则

所有 zip 文件必须存放在：

```text
/output_zip/
```

zip 命名规则：

```text
{店铺名称}-{作品数量}-{时间}.zip
```

示例：

```text
/output_zip/星火奶茶店-003-20260124_1530.zip
```

### 防冲突规则

- 不允许同名覆盖。
- 每个作品必须递增编号。
- 同商家必须连续编号。
- 不同商家必须隔离命名。
- 所有输出必须唯一。

### 当前运行模式

当前系统运行模式为：

```text
人工触发 + AI生成 + 结构化输出模式
```

当前不是自动执行系统。

### 当前限制

- 未实现自动文件夹隔离（每商家独立目录）。
- 未实现自动上传/同步机制。
