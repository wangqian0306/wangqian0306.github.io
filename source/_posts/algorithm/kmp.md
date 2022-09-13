---
title: KMP 算法
date: 2022-09-13 22:26:13
tags: "算法"
id: kmp
no_word_count: true
no_toc: false
categories: 算法
---

## KMP 算法

### 简介

```python
class Solution:
    def resolve(self, haystack: str, needle: str) -> int:
        a = len(needle)
        b = len(haystack)
        if a == 0:
            return 0
        next_array = self.get_next(a, needle)
        p = -1
        for j in range(b):
            while p >= 0 and needle[p + 1] != haystack[j]:
                p = next_array[p]
            if needle[p + 1] == haystack[j]:
                p += 1
            if p == a - 1:
                return j - a + 1
        return -1

    @staticmethod
    def get_next(a, needle):
        next_array = ['' for i in range(a)]
        k = -1
        next_array[0] = k
        for i in range(1, len(needle)):
            while k > -1 and needle[k + 1] != needle[i]:
                k = next_array[k]
            if needle[k + 1] == needle[i]:
                k += 1
            next_array[i] = k
        return next_array


txt = "ABABDABACDABABCABAB"
pat = "ABABCABAB"
s = Solution()
print(s.resolve(txt,pat))
```

### 参考资料

[视频图解](https://www.bilibili.com/video/BV1gr4y1B7dF)

[源码](https://www.geeksforgeeks.org/python-program-for-kmp-algorithm-for-pattern-searching-2/)
