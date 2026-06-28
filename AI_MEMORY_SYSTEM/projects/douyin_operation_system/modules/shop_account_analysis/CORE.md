# shop_account_analysis CORE

`shop_account_analysis` 是店铺账号深度分析模块，只负责读取 `account_ops` 生成的本地采集包，对店铺抖音账号进行深度诊断。

## 输入

- 用户上传的 ZIP 采集包。
- 或 Codex 本地 `output_zip` 路径。
- 或 `output/packages/{package_base_name}/` 目录。
- 或 `package_metadata.json`。

注意：采集包不默认存入 `AI_MEMORY_SYSTEM`。

## 输出

- 账号基础判断。
- 主页问题。
- 作品问题。
- 评论区用户需求。
- 内容垂直度。
- 本地转化问题。
- 接手账号后的运营方向。
- 接手风险。
- 下一步需要商家补充的资料。

## 边界

- 不采集账号。
- 不修改采集工具代码。
- 不创建商家长期大脑。
- 不生成视频脚本。
- 不自动发布。
- 不做发布后复盘。

## 采集包存储边界

1. 采集包 ZIP 默认保存在本地，不提交到 `AI_MEMORY_SYSTEM`。
2. `output_zip/` 保存 ZIP 包。
3. `output/packages/{package_base_name}/` 保存解压后的采集包目录。
4. `AI_MEMORY_SYSTEM` 不保存每个采集包本体。
5. `AI_MEMORY_SYSTEM` 只保存：
   - 采集包命名规则。
   - 输出路径规则。
   - `package_metadata` 字段要求。
   - 采集包检查标准。
   - 分析模块如何读取用户上传的 ZIP。
6. 如果需要 GPT 分析某个店铺，用户需要上传对应 ZIP 包，或者让 Codex 在本地读取该 ZIP 路径。
7. 如果需要长期追踪采集包，只记录 `package_metadata` 或 `package_index`，不保存大文件。
8. 不要把商家隐私数据、评论截图、视频关键帧批量提交到 GitHub 外部大脑。