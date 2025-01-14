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

### 单调栈

在遇到求取比此数据大或小的下一个数据场景下可以使用单调栈的思路解决问题：

```java
import java.util.Arrays;
import java.util.Deque;
import java.util.LinkedList;

public class Solution {
    public int[] nextGreaterElements(int[] nums) {
        int n = nums.length;
        int[] ret = new int[n];
        Arrays.fill(ret, -1);
        Deque<Integer> stack = new LinkedList<>();
        for (int i = 0; i < n * 2 - 1; i++) {
            while (!stack.isEmpty() && nums[stack.peek()] < nums[i % n]) {
                ret[stack.pop()] = nums[i % n];
            }
            stack.push(i % n);
        }
        return ret;
    }

    public static void main(String[] args) {
        Solution solution = new Solution();
        int[] nums = {1, 5, 3, 4};
        int[] ret = solution.nextGreaterElements(nums);
        System.out.println(Arrays.toString(ret));
    }

}
```

基本的处理流程如下：

1. 判断栈是否为空，且栈顶部的索引和要比对的索引谁大谁小
2. 如果符合规则，循环更新结果数据
3. 入栈

此处 LeetCode 官方采用了 Deque 而不是 Stack 的原因是：

1. Java官方文档建议用 Deque 代替旧的 Stack 类，因为 Deque 接口提供了更多的灵活性和更强的功能集。
2. 旧的 Stack 类继承自 Vector，这意味着它是线程安全的，但是这种安全性是通过同步方法实现的，这会导致不必要的性能损失。

### 参考资料

[Stacks and Queues in Python](https://stackabuse.com/stacks-and-queues-in-python/)
