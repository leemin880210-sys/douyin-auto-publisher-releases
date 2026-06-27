# Code Evolution Memory（代码演进日志）

## 作用
记录本项目所有关键代码变更，保证 Codex 在每次修改时可以追踪历史演进，避免重复修改或结构断裂。

---

## 规则

1. 每次修改代码必须追加一条记录。
2. 不允许覆盖历史记录。
3. 必须包含：
   - 修改时间
   - 修改内容
   - 修改原因
   - 修改文件路径
   - 修改前状态
   - 修改后状态
4. 每一个代码修改记录必须维护“最近3次完整代码版本快照”。
5. 代码快照必须使用统一的 `Code Snapshot History` 格式。
6. 如果历史版本不足3次，缺失版本必须明确写为“无历史版本”。
7. AI_MEMORY_SYSTEM v2.0 下，完整代码快照必须同步保存到 `CODE_SNAPSHOTS/`。

---

## 最近3次代码快照

系统必须为每一个代码修改记录保存：

### 1. 最新版本（v1 - 当前版本）

完整修改后的代码。

### 2. 上一版本（v2）

修改前最近一次代码。

### 3. 上上版本（v3）

再之前的一次代码。

---

## Code Snapshot History

每条代码修改记录必须包含以下快照结构：

### v1（最新版本）

```text
完整代码片段或 CODE_SNAPSHOTS/v1_latest 路径
```

### v2（上一版本）

```text
完整代码片段或 CODE_SNAPSHOTS/v2_previous 路径；如果不存在，则写：无历史版本
```

### v3（上上版本）

```text
完整代码片段或 CODE_SNAPSHOTS/v3_previous_previous 路径；如果不存在，则写：无历史版本
```

---

## 快照轮转规则

当发生新的代码修改时：

1. 新代码写入 v1。
2. 修改前的 v1 下移为 v2。
3. 修改前的 v2 下移为 v3。
4. 修改前的 v3 超出最近3次范围，不再保留在当前记录的快照区。
5. 历史记录本身不得覆盖或删除。

---

## 示例记录格式

### 2026-06-27

- 修改内容：优化脚本生成逻辑
- 修改原因：提升稳定性
- 修改路径：/script/generator.py
- 修改前：使用旧模板A
- 修改后：使用模板B
- 备注：禁止回滚旧逻辑

## Code Snapshot History

### v1（最新版本）

```text
使用模板B后的完整代码
```

### v2（上一版本）

```text
使用旧模板A时的完整代码
```

### v3（上上版本）

```text
无历史版本
```

---

## 2026-06-28 AI_MEMORY_SYSTEM 容器 v2.0 升级

- 修改内容：启用 CHAT_LOGS.md 与 CODE_SNAPSHOTS 三版本完整源码快照结构。
- 修改原因：让 AI_MEMORY_SYSTEM 从项目业务组织进一步收敛为外部记忆容器，保证聊天可追溯、代码可回滚、项目可恢复。
- 修改路径：
  - `AI_MEMORY_SYSTEM/README.md`
  - `AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/index.json`
  - `AI_MEMORY_SYSTEM/01_PROJECT_REGISTRY/active_projects.md`
  - `AI_MEMORY_SYSTEM/projects/douyin_operation_system/CHAT_LOGS.md`
  - `AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/`
  - `AI_MEMORY_SYSTEM/projects/douyin_operation_system/BOOT.md`
  - `AI_MEMORY_SYSTEM/projects/douyin_operation_system/STATE.json`
  - `AI_MEMORY_SYSTEM/projects/douyin_operation_system/TASKS.json`
  - `AI_MEMORY_SYSTEM/projects/douyin_operation_system/CORE.md`
  - `AI_MEMORY_SYSTEM/projects/douyin_operation_system/LOGS.md`
  - `AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_EVOLUTION.md`
- 修改前：项目有 BOOT/STATE/TASKS/CORE/LOGS/CODE_EVOLUTION，但缺少强制 CHAT_LOGS 和文件级 CODE_SNAPSHOTS 三版本目录。
- 修改后：项目具备 CHAT_LOGS.md、CODE_SNAPSHOTS/v1_latest、v2_previous、v3_previous_previous，并在 BOOT/TASKS/CORE 中写入 v2.0 执行规则。
- 备注：未修改 GLOBAL_MEMORY；未修改业务代码；历史源项目目录未删除。

## Code Snapshot History

### v1（最新版本）

```text
AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v1_latest/
```

### v2（上一版本）

```text
AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v2_previous/
```

### v3（上上版本）

```text
AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v3_previous_previous/
```

---

## 强制约束

- Codex 在修改任何代码前必须读取本文件。
- 修改后必须追加记录。
- 修改后必须维护最近3次完整代码版本快照。
- 修改后必须滚动更新 `CODE_SNAPSHOTS/`。
- 不允许跳过记录步骤。

## 2026-06-28 account_ops ZIP 输出层与样本复测

- 修改内容：本地 douyin_auto_tool.ps1 增加 output_zip 输出目录、{店铺名称}-{作品数量}-{时间}.zip 命名、防同名覆盖路径生成，并在 account_summary.md 写入 output_zip_path 与 output_zip_rule。
- 修改原因：执行 douyin_operation_system 中的统一 ZIP 命名和防冲突规则。
- 修改文件路径：C:\Users\cc\Documents\抖音作品分析\douyin_auto_tool.ps1
- 修改前状态：ZIP 输出在单次采集目录下，固定名为 douyin_analysis_package.zip。
- 修改后状态：ZIP 输出到 C:\Users\cc\Documents\抖音作品分析\output_zip\，本次文件为 C:\Users\cc\Documents\抖音作品分析\output_zip\未满_MOONFLOW官方号-005-20260628_0152.zip，采集目录只保留原始展开文件。
- 验证：SelfTest 通过；5 条样本包生成并通过基础检查。

## Code Snapshot History

### v1（最新版本）
AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v1_latest/douyin_auto_tool.ps1

### v2（上一版本）
AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v2_previous/NO_PREVIOUS_VERSION.md

### v3（上上版本）
AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v3_previous_previous/NO_PREVIOUS_PREVIOUS_VERSION.md

## 2026-06-28 account_ops 相对 ZIP 路径与评论统计字段

- 修改内容：account_summary.md 的 output_zip_path 改为项目相对路径；新增 valid_comment_items_count、reply_items_count、comment_count_match_status；works.xlsx 同步新增列。
- 修改原因：5 条样本包通过基础检查后，GPT 复核要求去除本机绝对路径，并补齐评论统计解释字段。
- 修改文件路径：C:\Users\cc\Documents\抖音作品分析\douyin_auto_tool.ps1
- 修改前状态：account_summary.md 写入 C:\Users\... 绝对路径；评论统计只体现 comments_count_collected/comments_status。
- 修改后状态：account_summary.md 写入 output_zip 相对路径；评论统计可区分有效评论数、过滤回复数和公开评论数匹配状态。
- 验证：SelfTest 通过；重新采集 5 条样本包并检查 works.json、comments.json、account_summary.md 和 ZIP 条目。

## Code Snapshot History

### v1（最新版本）
AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v1_latest/douyin_auto_tool.ps1

### v2（上一版本）
AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v2_previous/douyin_auto_tool.ps1

### v3（上上版本）
AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v3_previous_previous/NO_PREVIOUS_PREVIOUS_VERSION.md

## 2026-06-28 account_ops 评论结构与包元数据小修

### 变更原因

5 条样本包已通过基础检查，但仍需把评论回复、DOM 异常解析和包级元数据进一步标准化，避免回复污染正式评论 items，避免无法确认结构的 DOM 节点进入正式评论，并让 GPT 检查包时直接读取统一包元数据。

### 影响文件

- douyin_auto_tool.ps1
- AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v1_latest/douyin_auto_tool.ps1
- AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v2_previous/douyin_auto_tool.ps1
- AI_MEMORY_SYSTEM/projects/douyin_operation_system/CODE_SNAPSHOTS/v3_previous_previous/douyin_auto_tool.ps1

### 代码变化

- API 评论采集拆分主评论 items 与回复 eplies。
- web_comment_reply_api 写入 eplies，不再写入 comments.items。
- 评论合并按 uthor_name + text 去重，遍历顺序保持 API 主评论优先、DOM 仅补漏。
- dom_node 结果写入 aw_comments_debug，不进入正式 comments.items。
- eply_items_count 优先来自 eplies.Count。
- 新增 package_metadata.json，并在 account_summary.md 中同步包元数据字段。
- 每次运行开始清空旧的包元数据状态，避免连续运行沿用旧值。

### 行为变化

- GPT 检查评论时可以区分正式主评论与回复。
- API 和 DOM 重复评论不会重复计入正式评论。
- DOM 节点解析异常不会污染正式评论列表。
- 包元数据可从 package_metadata.json 直接读取，路径均为项目相对路径。

### 验证结果

- powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\\douyin_auto_tool.ps1 -SelfTest 通过。
- 使用新测试链接采集 5 条样本，生成 $zipRel。
- works.json 共 5 条，visual_order 1-5 连续。
- content_mapping_status 全部 ok。
- frame_status/video_crop_status 全部 ok。
- failed_count=0。
- comments.items 中 web_comment_reply_api=0、dom_node=0、重复项=0。
- ZIP 包含 package_metadata.json。

### 风险与边界

- 本次未改变采集主流程、作品卡片点击逻辑、抽帧策略或 OCR 策略。
- 本次未扩展账号诊断、运营方案、脚本生成、自动发布或商家建档。
- 仍需后续用 30 条正式包复测评论分流和包元数据规则。