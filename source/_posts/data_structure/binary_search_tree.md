---
title: 二叉搜索树
date: 2021-11-18 20:32:58
tags: "Python"
id: binary_search_tree
no_word_count: true
no_toc: false
categories: 数据结构
---

## 二叉搜索树(Binary Search Tree)

```python
class Node:
    def __init__(self, key):
        self.left = None
        self.right = None
        self.val = key


def insert(root, key):
    if root is None:
        return Node(key)
    else:
        if root.val == key:
            return root
        elif root.val < key:
            root.right = insert(root.right, key)
        else:
            root.left = insert(root.left, key)
    return root


def inorder(root):
    if root:
        inorder(root.left)
        print(root.val)
        inorder(root.right)


def min_value_node(node):
    current = node
    while current.left is not None:
        current = current.left
    return current


def delete_node(root, key):
    if root is None:
        return root
    if key < root.key:
        root.left = delete_node(root.left, key)
    elif key > root.key:
        root.right = delete_node(root.right, key)
    else:
        if root.left is None:
            temp = root.right
            root = None
            return temp
        elif root.right is None:
            temp = root.left
            root = None
            return temp
        temp = min_value_node(root.right)
        root.key = temp.key
        root.right = delete_node(root.right, temp.key)
    return root


def search(root, key):
    if root is None:
        return None
    if key > root.val:
        return search(root.right, key)
    elif key < root.val:
        return search(root.left, key)
    else:
        return root
```