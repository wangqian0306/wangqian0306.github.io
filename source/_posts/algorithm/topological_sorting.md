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

```text

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

```

### Parallel algorithms

```text
p processing elements with IDs from 0 to p-1
Input: G = (V, E) DAG, distributed to PEs, PE index j = 0, ..., p - 1
Output: topological sorting of G

function traverseDAGDistributed
    δ incoming degree of local vertices V
    Q = {v ∈ V | δ[v] = 0}                     // All vertices with indegree 0
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

简单实现：

```python

```

### 参考资料

[维基百科](https://en.wikipedia.org/wiki/Topological_sorting)
