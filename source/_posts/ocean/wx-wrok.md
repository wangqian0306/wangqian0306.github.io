---
title: 企业微信内部应用
date: 2025-07-31 21:32:58
tags:
- "Java"
id: wx-work
no_word_count: true
no_toc: false
categories: 
- "Ocean"
---

## 企业微信内部应用

### 简介

可以创建内部应用，然后使用如下方式生成不同来源的二维码来标记客户。

### 接口清单

首先需要获取企业ID 即 corpid 和 token:

- corpid 在企业详情里面可以获取
- token 在内部应用详情中可以获取

然后需要在配置页的客户部分，打开 API 下拉窗口，然后配置内部应用访问客户的权限。

之后即可按照如下逻辑获取用户的渠道。

[配置客户联系「联系我」方式](https://developer.work.weixin.qq.com/document/path/92228#%E9%85%8D%E7%BD%AE%E5%AE%A2%E6%88%B7%E8%81%94%E7%B3%BB%E3%80%8C%E8%81%94%E7%B3%BB%E6%88%91%E3%80%8D%E6%96%B9%E5%BC%8F)

[获取客户列表](https://developer.work.weixin.qq.com/document/path/92113)

[获取客户详情](https://developer.work.weixin.qq.com/document/path/92114)

[批量获取客户详情](https://developer.work.weixin.qq.com/document/path/92994)

[修改客户备注](https://developer.work.weixin.qq.com/document/path/92115)

如有需求也可以通过企业微信的推送来对接新增的用户，直接进行标注

[回调配置](https://developer.work.weixin.qq.com/document/path/90930)

[添加企业客户事件](https://developer.work.weixin.qq.com/document/path/92130#%E6%B7%BB%E5%8A%A0%E4%BC%81%E4%B8%9A%E5%AE%A2%E6%88%B7%E4%BA%8B%E4%BB%B6)

