# 模块路由规则

## 路由执行原则

1. 用户请求必须先匹配模块。
2. 如果用户请求涉及多个模块，先确认当前允许执行哪个模块。
3. 当前默认只允许执行 `account_ops` 相关任务。
4. `shop_account_analysis` 需要用户明确提供采集包并授权分析。
5. `merchant_brain_factory` 需要用户明确指定商家并授权建档。
6. `content_pipeline` 需要用户明确授权生成内容。
7. `data_review` 需要用户提供发布后数据并明确授权复盘。
8. 未授权不得跨模块执行。

## 路由表

当用户说“采集账号”“检查采集包”“抖音主页链接”“ZIP 包结构”时，进入：

```text
modules/account_ops/
```

当用户说“分析账号”“深度分析店铺”“账号问题”“接手方向”“主页诊断”“作品诊断”时，进入：

```text
modules/shop_account_analysis/
```

当用户说“给商家建档”“创建商家大脑”“这个商家长期运营”“电子运营官”时，进入：

```text
modules/merchant_brain_factory/
```

当用户说“根据素材做内容”“混剪方向”“视频脚本”“发布文案”时，进入：

```text
modules/content_pipeline/
```

当用户说“发布后复盘”“作品数据分析”“调整下一轮内容”时，进入：

```text
modules/data_review/
```

如果用户没有明确模块，AI 必须先询问，不得自行跨模块执行。
