---
title: 三分搜索树
date: 2021-11-24 20:32:58
tags: "Python"
id: ternary
no_word_count: true
no_toc: false
categories: 数据结构
---

## 三分搜索树(Ternary Search Tree)

```python
class Node:
    lo = None
    hi = None
    eq = None
    endpoint = False

    def __init__(self, char):
        self.char = char

    def __repr__(self):
        # useful in debugging
        return ''.join(['[', self.char,
                        ('' if not self.endpoint else ' <end>'),
                        ('' if self.lo is None else ' lo: ' + self.lo.__repr__()),
                        ('' if self.eq is None else ' eq: ' + self.eq.__repr__()),
                        ('' if self.hi is None else ' hi: ' + self.hi.__repr__()), ']'])


def insert(node, string):
    if len(string) == 0:
        return node

    head = string[0]
    tail = string[1:]
    if node is None:
        node = Node(head)

    if head < node.char:
        node.lo = insert(node.lo, string)
    elif head > node.char:
        node.hi = insert(node.hi, string)
    else:
        if len(tail) == 0:
            node.endpoint = True
        else:
            node.eq = insert(node.eq, tail)

    return node


def search(node, string):
    if node is None or len(string) == 0:
        return False

    head = string[0]
    tail = string[1:]
    if head < node.char:
        return search(node.lo, string)
    elif head > node.char:
        return search(node.hi, string)
    else:
        # use 'and' for matches on complete words only,
        # versus 'or' for matches on string prefixes
        if len(tail) == 0 or node.endpoint:
            return True
        return search(node.eq, tail)


def suffixes(node):
    if node is not None:
        if node.endpoint:
            yield node.char

        if node.lo:
            for s in suffixes(node.lo):
                yield s
        if node.hi:
            for s in suffixes(node.hi):
                yield s
        if node.eq:
            for s in suffixes(node.eq):
                yield node.char + s


def autocompletes(node, string):
    if node is None or len(string) == 0:
        return []

    head = string[0]
    tail = string[1:]
    if head < node.char:
        return autocompletes(node.lo, string)
    elif head > node.char:
        return autocompletes(node.hi, string)
    else:
        if len(tail) == 0:
            # found the node containing the prefix string,
            # so get all the possible suffixes underneath
            return suffixes(node.eq)
        return autocompletes(node.eq, string[1:])


class Trie:
    # a simple wrapper
    root = None

    def __init__(self, string):
        self.append(string)

    def append(self, string):
        self.root = insert(self.root, string)

    def __contains__(self, string):
        return search(self.root, string)

    def autocomplete(self, string):
        return map(lambda x: string + x, autocompletes(self.root, string))
```

### 参考资料

[tire](https://gist.github.com/dpapathanasiou/58919e4813e05850e201d21329d0139f)