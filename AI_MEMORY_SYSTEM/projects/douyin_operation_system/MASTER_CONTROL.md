# MASTER_CONTROL（系统总控制器）

## 语义层职责

`MASTER_CONTROL.md` 只负责【执行权限】。

只回答：

- 能不能做

不回答：

- 当前阶段
- 未来规划
- 系统结构细节

## 当前执行权限

允许执行：

- `account_ops`

允许动作：

- 读取采集包
- 生成采集包
- 检查采集包

禁止执行：

- `shop_account_analysis`
- `merchant_brain_factory`
- `merchants` 真实商家大脑创建
- `content_pipeline`
- `data_review`
- 自动运营方案
- 视频脚本生成
- 自动发布
- 跨模块执行

## 权限判断规则

- 能不能做，以本文件为准。
- 状态是什么，以 `STATE.json` 为准。
- 下一步做什么，以 `TASKS.json` 为准。
- 系统有哪些模块，以 `PROJECT_FRAMEWORK.md` 为准。
