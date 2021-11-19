---
title: 查找算法
date: 2021-11-18 20:32:58
tags: "Python"
id: search
no_word_count: true
no_toc: false
categories: 数据结构
---

## 查找算法

### 顺序查找(Liner Search)

```python
def liner_search(arr: list, x) -> int:
    for i in range(arr.__len__()):
        if arr[i] == x:
            return i
    return -1
```

### 二分查找(Binary Search)

```python
def binary_search(arr: list, l_index: int, r_index: int, x):
    if r_index >= l_index:
        mid = int(l_index + (r_index - l_index) / 2)
        if arr[mid] == x:
            return mid
        elif arr[mid] > x:
            return binary_search(arr, l_index, mid - 1, x)
            # 元素大于中间位置的元素，只需要再比较右边的元素
        else:
            return binary_search(arr, mid + 1, r_index, x)
    else:
        return -1
```
