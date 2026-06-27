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

## 2026-06-27 指定采集数量修复与 4 账号采集

### 已发生事实

- 修改 `douyin_auto_tool.ps1` 中正式模式采集数量计算逻辑。
- 当用户明确指定小于 30 的 `MaxWorks` 时，正式模式尊重指定数量。
- 运行 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\douyin_auto_tool.ps1 -SelfTest`，结果通过。
- 从 `C:\Users\cc\Desktop\新建文本文档 (3).txt` 读取 4 个抖音主页链接。
- 按顺序批量采集 4 个账号，每个账号指定 `-MaxWorks 5`。
- 第 1 个账号输出：`C:\Users\cc\Documents\抖音作品分析\output\douyin_package_20260627_233227\douyin_analysis_package.zip`。
- 第 2 个账号输出：`C:\Users\cc\Documents\抖音作品分析\output\douyin_package_20260627_233414\douyin_analysis_package.zip`。
- 第 3 个账号输出：`C:\Users\cc\Documents\抖音作品分析\output\douyin_package_20260627_233621\douyin_analysis_package.zip`。
- 第 4 个账号输出：`C:\Users\cc\Documents\抖音作品分析\output\douyin_package_20260627_233857\douyin_analysis_package.zip`。
- 批量采集日志：`C:\Users\cc\Documents\抖音作品分析\output\batch_collect_4x5_20260627_233226.log`。
- 更新 `CODE_EVOLUTION.md`，记录本次指定采集数量修复。
- 更新 `CORE.md`，补充“明确指定小于 30 的采集数量时正式模式必须尊重指定数量”规则。

### 影响范围

- 只修改账号采集模块数量计算逻辑。
- 未修改评论、OCR、抽帧、摘要、授权指标采集逻辑。
- 未修改全局记忆规则。
- 未修改 `project_brain`。
- 未生成 `_codex_delivery` 本地交付包。

### 验证结果

- 4 个输出包的 `works.json` 均为 5 条。
- 4 个输出包的 `visual_order` 均为 1-5 连续。
- 4 个输出包的 `status` 均为 `public_success=5`。
- 4 个输出包的 `frame_status` 均为 `ok=5`。
- 4 个输出包的 `video_crop_status` 均为 `ok=5`。
- 4 个输出包均生成标准 `douyin_analysis_package.zip`。

## 2026-06-28 采集输出字段与状态小优化

### 已发生事实

- 修改 `douyin_auto_tool.ps1`，新增 `run_mode`、`sample_size`、`formal_acceptance` 输出字段。
- 5 条样本包规则对应 `run_mode=sample_check`、`sample_size=5`、`formal_acceptance=false`。
- 30 条正式包规则对应 `run_mode=formal_collection`、`formal_acceptance=true`。
- 修改评论状态判断：当 `public_comment_count > 0` 且 `comments.items=0` 时，不再标记 `ok_with_reply_filtered`。
- 新增评论状态 `visible_count_but_items_empty` 和 `partial_no_valid_comments_extracted`。
- 修改主页资料解析：`has_location_evidence` 不再使用账号名兜底。
- 新增 `duration_status` 和 `media_type` 字段。
- 修改 `summary.md` 渲染：`canonical_title` 作为主标题，`detail_title` 只放入 Debug 信息区。
- 新增 SelfTest 断言，覆盖样本/正式 `run_mode` 判定以及失败记录的 `duration_status`、`media_type`、`formal_acceptance` 字段。
- 更新 `STATE.json` 和 `TASKS.json`，并修复两者为有效 UTF-8 JSON。
- 更新 `CORE.md`，补充运行模式、评论状态、位置证据、时长媒体类型和标题输出长期规则。
- 更新 `CODE_EVOLUTION.md`，记录本次采集代码行为变化。

### 影响范围

- 只修改账号采集模块与 `douyin_account_ops` 项目实例记忆文件。
- 未扩展账号诊断、运营方案、脚本生成、自动发布或商家建档。
- 未修改全局记忆规则。
- 未修改 `project_brain`。
- 未生成 `_codex_delivery` 本地交付包。

### 验证结果

- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\douyin_auto_tool.ps1 -SelfTest` 通过。
- `STATE.json` 可被 `ConvertFrom-Json` 正常解析。
- `TASKS.json` 可被 `ConvertFrom-Json` 正常解析。

## 2026-06-28 输出命名与 ZIP 防冲突规则同步

### 已发生事实

- 更新 `AI_MEMORY_SYSTEM/projects/douyin_account_ops/CORE.md`，追加输出命名、ZIP 目录、防冲突、连续编号和运行模式规则。
- 更新 `AI_MEMORY_SYSTEM/projects/douyin_account_ops/STATE.json`，同步当前阶段和输出规则字段。
- 更新 `AI_MEMORY_SYSTEM/projects/douyin_account_ops/TASKS.json`，加入输出命名、连续编号、ZIP 目录和防覆盖复测任务。
- 同步 `AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/index.json` 和 `active_projects.md` 的项目摘要。

### 影响范围

- 只修改 `douyin_account_ops` 项目实例记忆文件和项目注册摘要。
- 未修改抖音采集工具代码。
- 未修改全局记忆规则。
- 未修改 `project_brain`。

### 验证结果

- `STATE.json` 保持 JSON 格式。
- `TASKS.json` 保持 JSON 格式。
- `CORE.md` 包含 `{店铺名称}-{作品数量}-{时间}`、`/output_zip/` 和防冲突规则。
- registry 中 `douyin_account_ops` 摘要与 `STATE.json` 当前阶段一致。

## 2026-06-28 代码快照记录规则同步

### 已发生事实

- 更新 `AI_MEMORY_SYSTEM/projects/douyin_account_ops/CODE_EVOLUTION.md`。
- 在 `CODE_EVOLUTION.md` 中新增“最近3次完整代码版本快照”规则。
- 在标准记录格式中加入 `Code Snapshot History`、`v1`、`v2`、`v3`。
- 在 `CODE_EVOLUTION.md` 中新增快照轮转规则。

### 影响范围

- 只修改 `douyin_account_ops` 项目实例的外部大脑文件。
- 未修改抖音采集工具代码。
- 未修改全局记忆规则。
- 未修改 `project_brain`。

### 验证结果

- `CODE_EVOLUTION.md` 包含“最近3次完整代码版本快照”。
- `CODE_EVOLUTION.md` 包含 `Code Snapshot History`、`v1`、`v2`、`v3`。

## 2026-06-28 douyin_operation_system 5 条样本包复测与 output_zip 输出层修复

### 已发生事实

- 按 douyin_operation_system v2.0 规则读取 root 项目记忆与 modules/account_ops 模块记忆。
- 修改本地 douyin_auto_tool.ps1：新增 output_zip 输出目录、{店铺名称}-{作品数量}-{时间}.zip 命名、防同名覆盖路径生成。
- account_summary.md 新增 output_zip_path 与 output_zip_rule。
- 运行 powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\douyin_auto_tool.ps1 -SelfTest，结果通过。
- 使用主页链接采集 5 条样本包，生成 ZIP：C:\Users\cc\Documents\抖音作品分析\output_zip\未满_MOONFLOW官方号-005-20260628_0152.zip。
- 输出展开目录：C:\Users\cc\Documents\抖音作品分析\output\douyin_package_20260628_015210。
- works.json 为 5 条，visual_order 为 1-5 连续。
- run_mode=sample_check、sample_size=5、formal_acceptance=false。
- 5 条作品 content_mapping_status、frame_status、video_crop_status 均为 ok。
- 状态分布为 public_success=2、partial=3、failed=0。
- summary.md 未检出 OCR fallback 提示或明显 OCR 乱码污染。
- ZIP 条目检查通过，包含 account_summary.md、works.json、works.xlsx、card_records.json 和 5 个作品文件夹。

### 影响范围

- 只修改账号采集模块本地脚本的 ZIP 输出层与 account_summary 输出字段。
- 未扩展账号诊断、运营方案、脚本生成、自动发布或商家建档。
- 未修改 AI_MEMORY_SYSTEM/00_GLOBAL_MEMORY。
- 未生成 _codex_delivery 本地交付包。

### 验证结果

- SelfTest 通过。
- 5 条样本包基础检查通过。
- 仍需执行 30 条正式包复测。
