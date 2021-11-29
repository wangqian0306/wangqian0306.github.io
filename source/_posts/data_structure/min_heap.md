---
title: 小顶堆
date: 2021-11-26 20:32:58
tags: "Python"
id: min-heap
no_word_count: true
no_toc: false
categories: 数据结构
---

## 小顶堆(Min Heap)

```python
class MinHeap:
    def __init__(self):
        self.__values: list = []

    def __swap(self, i, j):
        self.__values[int(i)], self.__values[int(j)] = self.__values[int(j)], self.__values[int(i)]

    def push(self, data):
        self.__values.append(data)
        i = len(self.__values) - 1
        while i != 0 and self.__values[int(i)] < self.__values[int((i - 1) / 2)]:
            self.__swap(i, (i - 1) / 2)
            i -= 1
            i /= 2

    def top(self):
        if len(self.__values) == 0: return None
        return self.__values[0]

    def pop(self):
        top = self.__values[0]
        self.__swap(0, len(self.__values) - 1)
        self.__values.pop()
        i = 0
        while True:
            left = 2 * i + 1
            right = 2 * i + 2
            max_ = i
            if left < len(self.__values) and self.__values[left] < self.__values[max_]: max_ = left
            if right < len(self.__values) and self.__values[right] < self.__values[max_]: max_ = right
            if max_ == i: break
            self.__swap(i, max_)
            i = max_
        return top

    def isEmpty(self):
        return len(self.__values) == 0

    def __len__(self):
        return len(self.__values)

    @staticmethod
    def fromList(data_list: list):
        heap = MinHeap()
        for i in data_list:
            heap.push(i)
        return heap
```

### 参考资料

[python实现小顶堆MinHeap和哈夫曼树HaffumanTree](https://blog.csdn.net/qq_45592128/article/details/112056978)