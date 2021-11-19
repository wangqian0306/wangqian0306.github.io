---
title: 栈和队列
date: 2021-11-18 20:32:58
tags: "Python"
id: basic 
no_word_count: true
no_toc: false
categories: 数据结构
---

## 栈和队列

### 栈

```python
class Stack:

    def __init__(self):
        self.stack = []

    def pop(self):
        if len(self.stack) < 1:
            return None
        return self.stack.pop()

    def push(self, item):
        self.stack.append(item)

    def size(self):
        return len(self.stack)
```

### 队列

```python
class Queue:

    def __init__(self):
        self.queue = []

    def enqueue(self, item):
        self.queue.append(item)

    def dequeue(self):
        if len(self.queue) < 1:
            return None
        return self.queue.pop(0)

    def size(self):
        return len(self.queue) 
```

### 参考资料

[Stacks and Queues in Python](https://stackabuse.com/stacks-and-queues-in-python/)