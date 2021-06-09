---
title: JAVA 版本的短网址算法
date: 2020-06-20 20:04:13
tags: "JAVA"
id: short_url
no_word_count: true
no_toc: false
categories: JAVA
---

## 简介

在线上活动中经常需要用到短网址来做活动或者推广，但是好像一直没有思考过具体实现的方案。

## 实现思路

### Hash 取余

在这个问题第一次出现在我脑海里的时候我想用类似于布轮过滤器类似的方案，通过取余数配合进制转换的方案实现功能。

- 采取多次 Hash 来减少 Hash 重复和取余相同的问题
- 将短网址和代加密的长网址对应关系存储至数据库，并设定为唯一键，捕捉取余相同的问题
- 在 Hash 前拼接时间字符串来为异常做捕捉

### 各种转 “62进制”

比方说可以用：

- Unix 时间戳
- 雪花算法
- 数据库自增键

在这里就简单写下进制转换的方法吧，具体实现可以随便嵌套。

```java

import java.time.LocalDateTime;
import java.time.ZoneOffset;

public class ShortURLUtil {

    static final char[] DIGITS = {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
            'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
            'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D',
            'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
            'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
            'Y', 'Z'};

    public static String getShortURL(long seq) {
        StringBuilder sBuilder = new StringBuilder();
        do {
            int remainder = (int) (seq % 62);
            sBuilder.append(DIGITS[remainder]);
            seq = seq / 62;
        } while (seq != 0);
        return sBuilder.toString();
    }
}
```
