# merchant_brain_factory CORE

`merchant_brain_factory` 用于根据账号诊断报告和商家基础资料，创建独立商家大脑。

## 输入

- `shop_account_analysis` 输出的账号诊断报告。
- 商家基础资料。
- 用户明确授权创建商家大脑的指令。

## 输出

- `merchants/{merchant_id}/` 下的独立商家大脑。

## 边界

当前只做规划和模板，不创建真实商家大脑，除非用户明确指定商家。

- 不采集账号。
- 不分析采集包。
- 不生成发布内容。
- 不自动发布。
- 不混用不同商家记忆。