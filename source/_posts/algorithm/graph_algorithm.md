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

### 广度优先算法(Breadth-First Search)

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

### 深度优先算法(Depth-First Search)

略(参见拓扑排序文章)

### 联通分量(Connected Components)

> 注：要查找图的所有组件，请遍历其顶点，只要循环到达尚未包含在先前找到的组件中的顶点，就开始新的广度优先或深度优先搜索。

### 最短路径算法(Dijkstra's Shortest Path)

```python
import sys


class Graph(object):
    def __init__(self, nodes, init_graph):
        self.nodes = nodes
        self.graph = self.construct_graph(nodes, init_graph)

    def construct_graph(self, nodes, init_graph):
        '''
        This method makes sure that the graph is symmetrical. In other words, if there's a path from node A to B with a value V, there needs to be a path from node B to node A with a value V.
        '''
        graph = {}
        for node in nodes:
            graph[node] = {}

        graph.update(init_graph)

        for node, edges in graph.items():
            for adjacent_node, value in edges.items():
                if graph[adjacent_node].get(node, False) == False:
                    graph[adjacent_node][node] = value

        return graph

    def get_nodes(self):
        "Returns the nodes of the graph."
        return self.nodes

    def get_outgoing_edges(self, node):
        "Returns the neighbors of a node."
        connections = []
        for out_node in self.nodes:
            if self.graph[node].get(out_node, False) != False:
                connections.append(out_node)
        return connections

    def value(self, node1, node2):
        "Returns the value of an edge between two nodes."
        return self.graph[node1][node2]


def dijkstra_algorithm(graph, start_node):
    unvisited_nodes = list(graph.get_nodes())

    # We'll use this dict to save the cost of visiting each node and update it as we move along the graph
    shortest_path = {}

    # We'll use this dict to save the shortest known path to a node found so far
    previous_nodes = {}

    # We'll use max_value to initialize the "infinity" value of the unvisited nodes
    max_value = sys.maxsize
    for node in unvisited_nodes:
        shortest_path[node] = max_value
    # However, we initialize the starting node's value with 0
    shortest_path[start_node] = 0

    # The algorithm executes until we visit all nodes
    while unvisited_nodes:
        # The code block below finds the node with the lowest score
        current_min_node = None
        for node in unvisited_nodes:  # Iterate over the nodes
            if current_min_node == None:
                current_min_node = node
            elif shortest_path[node] < shortest_path[current_min_node]:
                current_min_node = node

        # The code block below retrieves the current node's neighbors and updates their distances
        neighbors = graph.get_outgoing_edges(current_min_node)
        for neighbor in neighbors:
            tentative_value = shortest_path[current_min_node] + graph.value(current_min_node, neighbor)
            if tentative_value < shortest_path[neighbor]:
                shortest_path[neighbor] = tentative_value
                # We also update the best path to the current node
                previous_nodes[neighbor] = current_min_node

        # After visiting its neighbors, we mark the node as "visited"
        unvisited_nodes.remove(current_min_node)

    return previous_nodes, shortest_path


def print_result(previous_nodes, shortest_path, start_node, target_node):
    path = []
    node = target_node

    while node != start_node:
        path.append(node)
        node = previous_nodes[node]

    # Add the start node manually
    path.append(start_node)

    print("We found the following best path with a value of {}.".format(shortest_path[target_node]))
    print(" -> ".join(reversed(path)))


nodes = ["Reykjavik", "Oslo", "Moscow", "London", "Rome", "Berlin", "Belgrade", "Athens"]

init_graph = {}
for node in nodes:
    init_graph[node] = {}

init_graph["Reykjavik"]["Oslo"] = 5
init_graph["Reykjavik"]["London"] = 4
init_graph["Oslo"]["Berlin"] = 1
init_graph["Oslo"]["Moscow"] = 3
init_graph["Moscow"]["Belgrade"] = 5
init_graph["Moscow"]["Athens"] = 4
init_graph["Athens"]["Belgrade"] = 1
init_graph["Rome"]["Berlin"] = 2
init_graph["Rome"]["Athens"] = 2
graph = Graph(nodes, init_graph)
previous_nodes, shortest_path = dijkstra_algorithm(graph=graph, start_node="Reykjavik")
print_result(previous_nodes, shortest_path, start_node="Reykjavik", target_node="Belgrade")
```

### 最小生成树(Prim's Minimum Cost Spanning Tree)

```python
# Prim's Algorithm in Python

INF = 9999999
# number of vertices in graph
N = 5
#creating graph by adjacency matrix method
G = [[0, 19, 5, 0, 0],
     [19, 0, 5, 9, 2],
     [5, 5, 0, 1, 6],
     [0, 9, 1, 0, 1],
     [0, 2, 6, 1, 0]]

selected_node = [0, 0, 0, 0, 0]

no_edge = 0

selected_node[0] = True

# printing for edge and weight
print("Edge : Weight\n")
while (no_edge < N - 1):
    
    minimum = INF
    a = 0
    b = 0
    for m in range(N):
        if selected_node[m]:
            for n in range(N):
                if ((not selected_node[n]) and G[m][n]):  
                    # not in selected and there is an edge
                    if minimum > G[m][n]:
                        minimum = G[m][n]
                        a = m
                        b = n
    print(str(a) + "-" + str(b) + ":" + str(G[a][b]))
    selected_node[b] = True
    no_edge += 1
```

### 拓扑排序(Topological Sort)

略(参照独立文章)

### 弗洛伊德算法(Floyd-Warshall)

```python

```

### Kruskal 最小生成树(Kruskal Minimum Cost Spanning Tree Algorithm)

```python

```
