---
title: 哈希表
date: 2021-11-23 20:32:58
tags: "Python"
id: hash_table
no_word_count: true
no_toc: false
categories: 数据结构
---

## 哈希表

### 拉链法(Open Hash Tables (Closed Addressing))

```python
class HashTable:
    def __init__(self, size: int):
        self.size = size
        self.table = {}
        for i in range(size):
            self.table[i] = []

    def insert(self, content):
        self.table[hash(content) % self.size].append(content)

    def search(self, content):
        for cache in self.table[hash(content) % self.size]:
            if content == cache:
                return True
        return False

    def pretty_print(self):
        for key in self.table.keys():
            print(f"key:{key} values:{self.table[key]}")
```

### 开地址法(Closed Hash Tables, using buckets)

```python
class HashTable:
    def __init__(self, size: int, bucket_size: int):
        self.size = size
        self.table = []
        self.bucket_size = bucket_size
        self.extra = []
        for i in range(size):
            for j in range(bucket_size):
                self.table.append(None)

    def insert(self, content):
        flag = True
        index = hash(content) % self.size
        for i in range(index * self.bucket_size, (index + 1) * self.bucket_size):
            if self.table[i] is None or self.table[i] == content:
                self.table[i] = content
                flag = False
                break
        if flag:
            self.extra.append(content)

    def search(self, content):
        index = hash(content) % self.size
        for i in range(index * self.bucket_size, (index + 1) * self.bucket_size):
            if self.table[i] == content:
                return True
        for cache in self.extra:
            if cache == content:
                return True
        return False

    def pretty_print(self):
        for index in range(self.size):
            cache = []
            for i in range(index * self.bucket_size, (index + 1) * self.bucket_size):
                cache.append(self.table[i])
            print(f"bucket:{index} value:{cache}")
        print(f"extra: {self.extra}")
```
