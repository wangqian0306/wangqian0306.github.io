---
title: 生成激活码
date: 2025-01-02 22:26:13
tags:
- "Java"
id: activation
no_word_count: true
no_toc: false
---

## 生成激活码

### 实现方式

使用 Java 自带的 SecureRandom 类可以生成随机码，用于实现卡券等功能。

```java
import java.security.SecureRandom;
import java.util.HashSet;
import java.util.Set;

public class ActivationCodeUtil {

    private static final String COMPLEX_CODE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    private static final String SIMPLE_CODE = "0123456789";

    private static final int SWITCH_SIZE = 999;

    private static final int CODE_LENGTH = 6;

    private static final int MAX_TICKET_NUM = 9999;

    public static Set<String> generate(Integer num) {
        SecureRandom random = new SecureRandom();
        Set<String> result = new HashSet<>();
        while (result.size() < num) {
            String codeSet = num < SWITCH_SIZE ? SIMPLE_CODE : COMPLEX_CODE;
            StringBuilder activationCode = new StringBuilder();
            for (int i = 0; i < CODE_LENGTH; i++) {
                int index = random.nextInt(codeSet.length());
                activationCode.append(codeSet.charAt(index));
            }
            result.add(activationCode.toString());
        }
        return result;
    }

}
```