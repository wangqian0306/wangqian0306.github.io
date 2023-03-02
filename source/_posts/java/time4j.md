---
title: Time4J
date: 2023-03-01 21:05:12
tags: "JAVA"
id: time4j
no_word_count: true
no_toc: false
categories: JAVA
---

## Time4J

### 简介

在处理农历等日期问题时可以引入 Time4J 。

### 使用方式

引入依赖：

```groovy
dependencies {
    implementation group: 'net.time4j', name: 'time4j-base', version: '5.9.2'
}
```

编写代码：

```java
import net.time4j.PlainDate;
import net.time4j.calendar.ChineseCalendar;
import net.time4j.calendar.EastAsianMonth;
import net.time4j.calendar.EastAsianYear;

import java.time.LocalDate;

public class Test {
    public static void main(String[] args) {
        // 农历转公历
        ChineseCalendar calendar = ChineseCalendar.of(EastAsianYear.forGregorian(2023), EastAsianMonth.valueOf(1), 1);
        LocalDate chineseNewYear = calendar.transform(PlainDate.axis()).toTemporalAccessor();
        System.out.println(chineseNewYear);
    }
}
```

```java
import net.time4j.PlainDate;
import net.time4j.calendar.ChineseCalendar;

import java.util.Locale;

public class Test {
    public static void main(String[] args) {
        PlainDate plainDate = PlainDate.of(2023, 1, 1);
        ChineseCalendar calendar = plainDate.transform(ChineseCalendar.axis());
        System.out.println(calendar.get(ChineseCalendar.YEAR_OF_CYCLE).getZodiac(Locale.CHINES));
        System.out.println(calendar.get(ChineseCalendar.YEAR_OF_CYCLE).getDisplayName(Locale.CHINES));
        System.out.println(calendar.getMonth());
        System.out.println(calendar.getDayOfMonth());
    }
}
```

### 参考资料

[官方项目](https://github.com/MenoData/Time4J)
