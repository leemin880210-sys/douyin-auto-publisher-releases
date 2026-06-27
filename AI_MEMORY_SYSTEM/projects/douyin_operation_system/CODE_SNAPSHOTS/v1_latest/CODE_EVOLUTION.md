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
