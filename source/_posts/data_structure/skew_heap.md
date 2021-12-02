---
title: 斜堆
date: 2021-12-02 20:32:58
tags: "Python"
id: skew_heap
no_word_count: true
no_toc: false
categories: 数据结构
---

## 斜堆(Skew Heap)

```python
class Node:
    def __init__(self, key):
        self.key = key
        self.left = None
        self.right = None

    def __str__(self):
        return self.key

    def recursiveMerge(self, rsh_oot):
        if rsh_oot is self or rsh_oot is None:
            return self
        root1 = None
        root2 = None
        if rsh_oot.key < self.key:
            root1 = rsh_oot
            root2 = self
        else:
            root1 = self
            root2 = rsh_oot
        tmp_root = root2.recursiveMerge(root1.right)
        root1.right = root1.left
        root1.left = tmp_root
        return root1


def iterativeMerge(root1: Node, root2: Node):
    if root1 is None:
        return root2
    if root2 is None:
        return root1
    stack = []
    r1 = root1
    r2 = root2
    while r1 is not None and r2 is not None:
        if r1.key < root2.key:
            stack.append(r1)
            r1 = r1.right
        else:
            stack.append(r2)
            r2 = r2.right
    if r1 is not None:
        r = r1
    else:
        r = r2
    while len(stack) != 0:
        node = stack.pop()
        node.right = node.left
        node.left = r
        r = node
    return r


def buildHeap(list_a):
    queue = []
    for key in list_a:
        queue.append(Node(key))
    while len(queue) > 1:
        root1 = queue.pop()
        root2 = queue.pop()
        root_node = iterativeMerge(root1, root2)
        queue.append(root_node)
    root_node = queue.pop()
    return SkewHeap(root_node)


class SkewHeap:
    def __init__(self, root: Node):
        self.root = root

    def recursiveMerge(self, root1: Node, root2: Node):
        if root1 is None:
            return root2
        if root2 is None:
            return root1
        return root1.recursiveMerge(root2)

    def merge(self, h1, h2):
        root_node = iterativeMerge(h1.root, h2.root)
        return SkewHeap(root_node)

    def insert(self, x: int):
        self.root = iterativeMerge(Node(x), self.root)

    def extractMin(self):
        if self.root is None:
            return None
        min = self.root.key
        self.root = iterativeMerge(self.root.left, self.root.right)
        return min
```

### 参考资料

[斜堆(Skew Heap)](https://blog.csdn.net/ljsspace/article/details/6716818)