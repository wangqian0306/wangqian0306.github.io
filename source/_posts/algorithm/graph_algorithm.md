---
title: 图算法
date: 2021-12-06 22:26:13
tags: "算法"
id: graph-algorithm
no_word_count: true
no_toc: false
categories: 算法
---

## 图算法

### 广度优先算法 BFS

```python
class Node:

    def __init__(self, id: int, name):
        self.id = id
        self.name = name
        self.explored = False

    def __str__(self):
        return f"Node({self.id},{self.name})"

    def __repr__(self):
        return f"Node({self.id},{self.name})"


class Relation:

    def __init__(self, id: int, from_node: Node, to_node: Node):
        self.from_node = from_node
        self.to_node = to_node
        self.id = id

    def __str__(self):
        return f"Relation({self.id},{self.from_node},{self.to_node})"

    def __repr__(self):
        return f"Relation({self.id},{self.from_node},{self.to_node})"


class Graph:

    def __init__(self, node_list: list[Node], relation_list: list[Relation]):
        self.node_list = node_list
        self.relation_list = relation_list

    def bfs(self, root: Node, name: str):
        q = []
        root.explored = True
        q.append(root)
        while len(q) != 0:
            v = q.pop(0)
            if v.name == name:
                return v
            for relation in self.relation_list:
                if relation.from_node == v:
                    if not relation.to_node.explored:
                        relation.to_node.explored = True
                        q.append(relation.to_node)

```

### 深度优先算法 DFS

略(参见拓扑排序文章)

### 联通分量

> 注：要查找图的所有组件，请遍历其顶点，只要循环到达尚未包含在先前找到的组件中的顶点，就开始新的广度优先或深度优先搜索。

### 最短路径算法

```python

```

### 最小生成树

```python

```

### 拓扑排序

略(参照独立文章)

### 弗洛伊德算法

```python

```

### Kruskal 最小生成树

```python

```
