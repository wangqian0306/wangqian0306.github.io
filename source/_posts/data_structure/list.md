---
title: 链表
date: 2021-11-18 20:32:58
tags: "Python"
id: list
no_word_count: true
no_toc: false
categories: 数据结构
---

## 链表

### 单向链表

```python
class LinkListNode(object):
    """
    链表结点
    """

    def __init__(self, data=None, next_node=None):
        self.data = data
        self.next = next_node

    def __str__(self):
        return str(self.data)


class LinkList(object):
    """
    单链表类
    """

    def __init__(self):
        self.head = LinkListNode()  # 表头的空结点指针 Dummy node
        self.tail = self.head

    def __str__(self):
        head = self.head.next
        output_str = "LinkList["
        while head:
            output_str += str(head.data) + str(", ")
            head = head.next
        output_str += "]"
        return output_str

    def push_back(self, data):
        self.tail.next = LinkListNode(data)
        self.tail = self.tail.next

    def back(self):
        if self.tail:
            return self.tail.data
        else:
            return None

    def pop_back(self):
        if self.tail != self.head:
            node_to_remove = self.head.next
            prev_node = self.head
            while node_to_remove and node_to_remove.next:
                prev_node = node_to_remove
                node_to_remove = node_to_remove.next
            prev_node.next = None
            self.tail = prev_node
            del node_to_remove

    def front(self):
        if self.head.next:
            return self.head.next.data
        else:
            return None

    def push_front(self, data):
        self.head.next = LinkListNode(data, self.head.next)
        if self.tail == self.head:
            self.tail = self.head.next

    def pop_front(self):
        if self.head != self.tail:
            first_node = self.head.next
            self.head.next = first_node.next
            if not self.head.next:
                self.tail = self.head
            del first_node

    def remove_at(self, index):
        if index < 0 or self.tail == self.head:
            return False
        node_to_remove = self.head.next
        prev_node = self.head
        for i in range(index):
            prev_node = node_to_remove
            node_to_remove = node_to_remove.next
            if not node_to_remove:
                return False
        prev_node.next = node_to_remove.next
        if not prev_node.next:
            self.tail = prev_node
        del node_to_remove
        return True

    def is_empty(self):
        return self.tail == self.head

    def size(self):
        count = 0
        cur_node = self.head.next
        while cur_node:
            count += 1
            cur_node = cur_node.next
        return count

    @staticmethod
    def print_list(list_head):
        """
        打印链表
        :param list_head: 链表头结点
        :return:None
        """
        output_str = str(list_head)
        print(output_str)
```

### 双向链表

```python
class Node(object):
    """双向链表节点"""

    def __init__(self, item):
        self.item = item
        self.next = None
        self.prev = None


class DLinkList(object):
    """双向链表"""

    def __init__(self):
        self._head = None

    def is_empty(self):
        """判断链表是否为空"""
        return self._head is None

    def length(self):
        """返回链表的长度"""
        cur = self._head
        count = 0
        while cur is not None:
            count += 1
            cur = cur.next
        return count

    def travel(self):
        """遍历链表"""
        cur = self._head
        while cur is not None:
            print(cur.item)
            cur = cur.next

    def add(self, item):
        """头部插入元素"""
        node = Node(item)
        if self.is_empty():
            # 如果是空链表，将_head指向node
            self._head = node
        else:
            # 将node的next指向_head的头节点
            node.next = self._head
            # 将_head的头节点的prev指向node
            self._head.prev = node
            # 将_head 指向node
            self._head = node

    def append(self, item):
        """尾部插入元素"""
        node = Node(item)
        if self.is_empty():
            # 如果是空链表，将_head指向node
            self._head = node
        else:
            # 移动到链表尾部
            cur = self._head
            while cur.next is not None:
                cur = cur.next
            # 将尾节点cur的next指向node
            cur.next = node
            # 将node的prev指向cur
            node.prev = cur

    def search(self, item):
        """查找元素是否存在"""
        cur = self._head
        while cur is not None:
            if cur.item == item:
                return True
            cur = cur.next
        return False
```

### 参考资料

[常见数据结构Part1(数组和链表)](https://blog.csdn.net/wangdingqiaoit/article/details/78757533)

[链表](https://jackkuo666.github.io/Data_Structure_with_Python_book/chapter3/section3.html)