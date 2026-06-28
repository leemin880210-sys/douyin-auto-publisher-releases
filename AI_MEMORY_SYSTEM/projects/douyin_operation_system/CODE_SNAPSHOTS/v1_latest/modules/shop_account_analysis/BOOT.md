# shop_account_analysis BOOT

本模块是 `douyin_operation_system` 的店铺账号深度分析模块。

## 强制读取顺序

1. `BOOT.md`
2. `STATE.json`
3. `TASKS.json`
4. `CORE.md`
5. `ANALYSIS_FRAMEWORK.md`
6. `REPORT_TEMPLATE.md`
7. `LOGS.md`

## 模块边界

- 只读取用户上传的 ZIP 采集包、本地 `output_zip` 路径、`output/packages/{package_base_name}/` 目录或 `package_metadata.json`。
- 不采集账号。
- 不修改采集工具代码。
- 不创建商家长期大脑。
- 不生成视频脚本。
- 不自动发布。
- 不做发布后复盘。

当前模块处于规划状态，必须等用户明确授权后才能执行账号深度分析。