# 抖音代运营采集工具 LOGS

## 2026-06-27 接入 AI_MEMORY_SYSTEM

### 已发生事实

- 从 GitHub 读取 `AI_MEMORY_SYSTEM/README.md`。
- 从 GitHub 读取 `AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/index.json`。
- 创建 `AI_MEMORY_SYSTEM/projects/douyin_account_ops/BOOT.md`。
- 创建 `AI_MEMORY_SYSTEM/projects/douyin_account_ops/STATE.json`。
- 创建 `AI_MEMORY_SYSTEM/projects/douyin_account_ops/TASKS.json`。
- 创建 `AI_MEMORY_SYSTEM/projects/douyin_account_ops/CORE.md`。
- 创建 `AI_MEMORY_SYSTEM/projects/douyin_account_ops/LOGS.md`。
- 创建 `AI_MEMORY_SYSTEM/projects/douyin_account_ops/PROJECT_INDEX.md`。
- 更新 `AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/index.json`，注册 `douyin_account_ops` 项目。

### 影响范围

- 只新增 `douyin_account_ops` 项目实例。
- 未修改 `AI_MEMORY_SYSTEM/00_GLOBAL_MEMORY`。
- 未修改 `project_brain` 项目实例。
- 未修改抖音采集工具代码。

### 验证结果

- `STATE.json` 保持 JSON 格式。
- `TASKS.json` 保持 JSON 格式。
- 注册表包含 `douyin_account_ops` 项目信息。

## 2026-06-27 正式 30 条公开采集

### 已发生事实

- 执行正式公开采集，参数为 `test_mode=false`、`max_works=30`、`collection_mode=public`。
- 使用账号主页链接：`https://www.douyin.com/user/MS4wLjABAAAALfxHOC_6CdyTENk6oSNGu-e8cpuvEsPPjwJJn41bZVr5P0QB_lA9hUeQzFeoJcpp?from_tab_name=main`。
- 生成输出目录：`C:\Users\cc\Documents\抖音作品分析\output\douyin_package_20260627_214556`。
- 生成 ZIP：`C:\Users\cc\Documents\抖音作品分析\output\douyin_package_20260627_214556\douyin_analysis_package.zip`。
- `works.json` 为数组，共 30 条作品。
- `visual_order` 为 1-30 连续。
- `content_mapping_status` 共 30 条为 `ok`。
- 状态分布为 `public_success=22`、`partial=6`、`failed=2`。
- `public_metric_status` 分布为 `ok=25`、`card_only=5`。
- `authorized_metric_pending_count=30`。

### 影响范围

- 未修改抖音采集工具代码。
- 未修改全局记忆规则。
- 未修改 `project_brain`。
- 未生成 `_codex_delivery` 本地交付包。

### 验证结果

- 正式采集包已生成并压缩为标准 ZIP。
- 第 2 条和第 16 条 `frame_status`、`video_crop_status` 为 `failed`。
- 当前包可供 GPT 检查，但仍存在内容层采集失败样本。

## 2026-06-27 账号采集模块稳定性优化

### 已发生事实

- 修改 `douyin_auto_tool.ps1` 的主画面识别逻辑：裁剪优先使用可见最大 `video`，必要时 fallback 到主图 `img`、`canvas` 或包含主画面的容器。
- 修改 `douyin_auto_tool.ps1` 的 seek 逻辑：只操作当前可见最大视频，避免误操作隐藏 video。
- 修改 `douyin_auto_tool.ps1` 的作品锁定逻辑：作品自动跳转时重新打开原作品链接，并等待目标 `card_modal_id/opened_modal_id` 恢复。
- 修改 `douyin_auto_tool.ps1` 的抽帧重试逻辑：核心帧缺失时也触发重试；重试前清理旧帧、重新打开原作品并重新等待媒体加载。
- 修改 `douyin_auto_tool.ps1` 的输出记录：每条作品 `meta.json` 写入 `frame_errors` 和 `video_crop_errors`。
- 修改 `douyin_auto_tool.ps1` 的失败 transcript 输出：未配置 ASR 时写入 `speech_transcription_status: not_configured` 和空 transcript。
- 修改 `douyin_auto_tool.ps1` 的评论最终入库过滤：纯数字、抢首评、UI 文本、解析错位的纯数字作者名不写入 `comments.items`。

### 影响范围

- 只修改账号采集模块。
- 未扩展账号诊断、运营方案、脚本生成、自动发布或商家建档。
- 未修改全局记忆规则。
- 未修改 `project_brain`。
- 未生成 `_codex_delivery` 本地交付包。

### 验证结果

- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\douyin_auto_tool.ps1 -SelfTest` 通过。
- 测试模式 2 条采集生成 `C:\Users\cc\Documents\抖音作品分析\output\douyin_package_20260627_223215\douyin_analysis_package.zip`。
- 测试模式 2 条结果为 `public_success=2`、`partial=0`、`failed=0`。
- 正式模式 30 条采集生成 `C:\Users\cc\Documents\抖音作品分析\output\douyin_package_20260627_223538\douyin_analysis_package.zip`。
- 正式模式 30 条结果为 `public_success=29`、`partial=1`、`failed=0`。
- 正式模式 30 条 `visual_order` 为 1-30 连续。
- 正式模式 30 条 `content_mapping_status` 全部为 `ok`。
- 正式模式 30 条 `frame_status` 全部为 `ok`。
- 正式模式 30 条 `video_crop_status` 全部为 `ok`。
- 正式模式 30 条 `comments.json` 未检测到纯数字、抢首评或 UI 文本进入正式 `items`。
- 正式模式 30 条 `transcript.txt` 均保持 `speech_transcription_status: not_configured`，未伪装语音转写。

## 2026-06-27 新增代码演进记录文件

### 已发生事实

- 新增 `AI_MEMORY_SYSTEM/projects/douyin_account_ops/CODE_EVOLUTION.md`。
- 在 `CODE_EVOLUTION.md` 中记录采集代码演进的用途、记录边界、标准格式。
- 在 `CODE_EVOLUTION.md` 中补记 2026-06-27 账号采集模块稳定性优化的代码变化、行为变化、验证结果和边界。
- 更新 `PROJECT_INDEX.md`，登记 `CODE_EVOLUTION.md` 的文件作用。
- 更新 `STATE.json`，记录当前外部大脑已新增代码演进记录文件。
- 更新 `TASKS.json`，加入后续采集代码修改必须同步记录到 `CODE_EVOLUTION.md` 的待执行规则。

### 影响范围

- 只修改 `douyin_account_ops` 项目实例的外部大脑文件。
- 未修改抖音采集工具代码。
- 未修改全局记忆规则。
- 未修改 `project_brain`。
- 未生成 `_codex_delivery` 本地交付包。

### 验证结果

- `STATE.json` 保持 JSON 格式。
- `TASKS.json` 保持 JSON 格式。
- `CODE_EVOLUTION.md` 已创建并包含 2026-06-27 采集稳定性优化记录。
