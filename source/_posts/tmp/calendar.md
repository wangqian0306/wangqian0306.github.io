---
title: 日历折腾记录
date: 2023-02-20 22:26:13
tags:
- "CalDAV"
id: calendar
no_word_count: true
no_toc: false
---

## 日历折腾记录

### 简介

目前市面上的大多数日历都支持 CalDAV 协议，可以通过订阅的方式持续拉取日程信息。

> 注：对于国外日历软件来说非常有用，可以在 Home-Assistant 或 Google Calendar 上标记节假日和调休。

### 常用技巧

#### 节假日和调休

可以订阅如下地址：

```text
https://www.shuyz.com/githubfiles/china-holiday-calender/master/holidayCal.ics
```

#### 生日

由于 Google Calendar 不支持农历格式的生日提醒，所以需要手动进行添加，可以访问如下地址在线生成订阅地址。

```
https://lunar-calendar-anniversary-ics.vercel.app/
```

> 注：如果是公历的生日可以直接添加联系人并指定生日即可。

#### 纪念日检索

可以使用如下 SQL 语句检索最近 7 天内的纪念日。

```mysql
SELECT *
FROM users
WHERE DATE_ADD(brith,
               INTERVAL YEAR(CURDATE()) - YEAR(brith)
                   + IF(DAYOFYEAR(CURDATE()) > DAYOFYEAR(brith), 1, 0)
               YEAR)
          BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY);
```

### 参考资料

[中国节假日补班日历](https://github.com/lanceliao/china-holiday-calender)

[农历纪念日日历订阅生成工具](https://github.com/baranwang/lunar-calendar-anniversary-ics)
