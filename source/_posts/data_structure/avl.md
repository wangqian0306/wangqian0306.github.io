---
title: 平衡二叉树 date: 2021-11-18 20:32:58 tags: "Python"
id: balanced_binary_tree no_word_count: true no_toc: false categories: 数据结构
---

## 平衡二叉树(Balanced Binary Tree,AVL Tree)

```python
class TreeNode(object):
    def __init__(self, val):
        self.val = val
        self.left = None
        self.right = None
        self.height = 1


class AVLTree(object):
    def insert(self, root, key):
        if not root:
            return TreeNode(key)
        elif key < root.val:
            root.left = self.insert(root.left, key)
        else:
            root.right = self.insert(root.right, key)
        root.height = 1 + max(self.get_height(root.left),
                              self.get_height(root.right))
        balance = self.get_balance(root)
        if balance > 1 and key < root.left.val:
            return self.right_rotate(root)
        if balance < -1 and key > root.right.val:
            return self.left_rotate(root)
        if balance > 1 and key > root.left.val:
            root.left = self.left_rotate(root.left)
            return self.right_rotate(root)
        if balance < -1 and key < root.right.val:
            root.right = self.right_rotate(root.right)
            return self.left_rotate(root)
        return root

    def delete(self, root, key):
        if not root:
            return root
        elif key < root.val:
            root.left = self.delete(root.left, key)
        elif key > root.val:
            root.right = self.delete(root.right, key)
        else:
            if root.left is None:
                temp = root.right
                root = None
                return temp
            elif root.right is None:
                temp = root.left
                root = None
                return temp
            temp = self.get_min_value_node(root.right)
            root.val = temp.val
            root.right = self.delete(root.right,
                                     temp.val)
        if root is None:
            return root
        root.height = 1 + max(self.get_height(root.left),
                              self.get_height(root.right))
        balance = self.get_balance(root)
        if balance > 1 and self.get_balance(root.left) >= 0:
            return self.get_height(root)
        if balance < -1 and self.get_balance(root.right) <= 0:
            return self.left_rotate(root)
        if balance > 1 and self.get_balance(root.left) < 0:
            root.left = self.left_rotate(root.left)
            return self.get_height(root)
        if balance < -1 and self.get_balance(root.right) > 0:
            root.right = self.get_height(root.right)
            return self.left_rotate(root)
        return root

    def left_rotate(self, z):
        y = z.right
        t2 = y.left
        y.left = z
        z.right = t2
        z.height = 1 + max(self.get_height(z.left),
                           self.get_height(z.right))
        y.height = 1 + max(self.get_height(y.left),
                           self.get_height(y.right))
        return y

    def right_rotate(self, z):
        y = z.left
        t3 = y.right
        y.right = z
        z.left = t3
        z.height = 1 + max(self.get_height(z.left),
                           self.get_height(z.right))
        y.height = 1 + max(self.get_height(y.left),
                           self.get_height(y.right))
        return y

    def get_height(self, root):
        if not root:
            return 0
        return root.height

    def get_balance(self, root):
        if not root:
            return 0
        return self.get_height(root.left) - self.get_height(root.right)

    def get_min_value_node(self, root):
        if root is None or root.left is None:
            return root
        return self.get_min_value_node(root.left)

    def preOrder(self, root):
        if not root:
            return
        print("{0} ".format(root.val))
        self.preOrder(root.left)
        self.preOrder(root.right)


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