---
title: 拓扑排序
date: 2021-07-19 22:26:13
tags: "算法"
id: topological_sorting
no_word_count: true
no_toc: false
categories: 算法
---

## 拓扑排序

### 简介

拓扑排序是遍历 DAG 的方式。实现此算法有如下几种方式：

- Kahn's algorithm
- Depth-first search
- Parallel algorithms

### Kahn's algorithm

概念原理：

```text
L ← Empty list that will contain the sorted elements
S ← Set of all nodes with no incoming edge

while S is not empty do
    remove a node n from S
    add n to L
    for each node m with an edge e from n to m do
        remove edge e from the graph
        if m has no other incoming edges then
            insert m into S

if graph has edges then
    return error   (graph has at least one cycle)
else 
    return L   (a topologically sorted order)
```

简单实现：

```python
class Node:

    def __init__(self, id: int, name):
        self.id = id
        self.name = name

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
        self.require_map = {}
        self.node_list = node_list
        self.relation_list = relation_list
        for node in self.node_list:
            self.require_map[node] = set()
        for relation in self.relation_list:
            values = self.require_map.get(relation.to_node)
            values.add(relation.from_node)

    def topological_sort(self):
        l = []
        s = set(self.get_no_incoming_node())
        edges_copy = self.relation_list.copy()
        cache = []

        while s:
            n = s.pop()
            if n not in l:
                l.append(n)
            cache.append(n)
            for m in self.get_each_node_m_with_an_edge_e_from_n_to_m(n):
                self.remove_edge(edges_copy, n, m)
                if self.check_no_incoming_edges(m, l):
                    if m not in l:
                        l.append(m)
            qualify_nodes = set(self.get_qualified_node(l))
            s = qualify_nodes.difference(cache)
        if edges_copy:
            raise RuntimeError("图中至少含有一个环")
        else:
            return l

    def get_no_incoming_node(self) -> set[Node]:
        for key in self.require_map.keys():
            if len(self.require_map.get(key)) == 0:
                yield key

    def get_qualified_node(self, node_list: list[Node]):
        for key in self.require_map.keys():
            if (len(self.require_map.get(key)) == 0) or (set(self.require_map.get(key)).issubset(set(node_list))):
                yield key

    def get_each_node_m_with_an_edge_e_from_n_to_m(self, n: Node) -> list[Node]:
        for relation in self.relation_list:
            if relation.from_node == n:
                yield relation.to_node

    @staticmethod
    def remove_edge(edge_list: list[Relation], from_node: Node, to_node: Node):
        for edge in edge_list:
            if (edge.from_node == from_node) and (edge.to_node == to_node):
                edge_list.remove(edge)
                break

    def check_no_incoming_edges(self, m: Node, node_list: list[Node]) -> bool:
        return set(self.require_map.get(m)).issubset(set(node_list))


if __name__ == "__main__":
    y = Node(1, "y")
    x = Node(2, "x")
    b = Node(3, "b")
    a = Node(4, "a")
    r1 = Relation(1, y, x)
    r2 = Relation(2, y, b)
    r3 = Relation(3, x, a)
    r4 = Relation(4, b, a)
    g = Graph([x, y, b, a], [r1, r2, r3, r4])
    print(g.topological_sort())
```

### Depth-first search

概念原理：

```text
L ← Empty list that will contain the sorted nodes
while exists nodes without a permanent mark do
    select an unmarked node n
    visit(n)

function visit(node n)
    if n has a permanent mark then
        return
    if n has a temporary mark then
        stop   (not a DAG)

    mark n with a temporary mark

    for each node m with an edge from n to m do
        visit(m)

    remove temporary mark from n
    mark n with a permanent mark
    add n to head of L
```

简单实现：

```python
class Node:

    def __init__(self, id: int, name):
        self.id = id
        self.name = name
        self.temporary_mark = False
        self.permanent_mark = False

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
        self.l = []

    def topological_sort(self):
        # Depth-first search
        unmarked_node = self.node_list.copy()
        while unmarked_node:
            n = unmarked_node.pop()
            self.visit(n)
        return self.l

    def visit(self, n: Node):
        if n.permanent_mark:
            return
        if n.temporary_mark:
            raise RuntimeError("图中至少含有一个环")

        n.temporary_mark = True

        for m in self.get_each_node_m_with_an_edge_e_from_n_to_m(n):
            self.visit(m)

        n.temporary_mark = False
        n.permanent_mark = True
        self.l.insert(0, n)

    def get_each_node_m_with_an_edge_e_from_n_to_m(self, n: Node) -> list[Node]:
        for relation in self.relation_list:
            if relation.from_node == n:
                yield relation.to_node


if __name__ == "__main__":
    y = Node(1, "y")
    x = Node(2, "x")
    b = Node(3, "b")
    a = Node(4, "a")
    r1 = Relation(1, y, x)
    r2 = Relation(2, y, b)
    r3 = Relation(3, x, a)
    r4 = Relation(4, b, a)
    g = Graph([x, y, b, a], [r1, r2, r3, r4])
    print(g.topological_sort())
```

### Parallel algorithms

```text
p processing elements with IDs from 0 to p-1
Input: G = (V, E) DAG, distributed to PEs, PE index j = 0, ..., p - 1
Output: topological sorting of G

function traverseDAGDistributed
    δ incoming degree of local vertices V
    Q = {v ∈ V | δ[v] = 0}                     // All vertices with in degree 0
    nrOfVerticesProcessed = 0

    do                 
        global build prefix sum over size of Q     // get offsets and total amount of vertices in this step
        offset = nrOfVerticesProcessed + sum(Qi, i = 0 to j - 1)          // j is the processor index
        foreach u in Q                                       
            localOrder[u] = index++;
            foreach (u,v) in E do post message (u, v) to PE owning vertex v
        nrOfVerticesProcessed += sum(|Qi|, i = 0 to p - 1)
        deliver all messages to neighbors of vertices in Q  
        receive messages for local vertices V
        remove all vertices in Q
        foreach message (u, v) received:
            if --δ[v] = 0
                add v to Q
    while global size of Q > 0

    return localOrder
```

### 参考资料

[维基百科](https://en.wikipedia.org/wiki/Topological_sorting)
