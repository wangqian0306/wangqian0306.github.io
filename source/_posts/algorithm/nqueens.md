---
title: N 皇后问题
date: 2021-11-15 22:26:13
tags: "算法"
id: nqueens
no_word_count: true
no_toc: false
categories: 算法
---

## N 皇后问题

### 简介

**N 皇后问题** 研究的是如何将 N 个皇后放置在 N*N 大小的棋盘上，并且使皇后彼此之间不能相互攻击。

皇后的走法是：可以横直斜走，格数不限。因此要求皇后彼此之间不能相互攻击，等价于要求任何两个皇后都不能在同一行、同一列以及同一条斜线上。

例如：

```text
   0 1 2 3
0 | | |Q| |
1 |Q| | | |
2 | | | |Q|
3 | |Q| | |
```

### 解答方法

Leetcode 上有两种回溯法分别如下

#### 基于集合的回溯

> 为了防止混淆，下面的内容使用按列填入皇后的方式进行说明。

问题分析：

- 总列数等于皇后棋子的数量且皇后不能处于同一列，所以每一列都需要有一个皇后。
- 两个皇后不能处于同一斜线上，所以
    - 行下标与列下标之差不能相等(右下方向)。
    - 行下标与列下标之和不能相等(左下方向)。
- 确保上述过程重复执行直至遍历整个棋盘即可。

简化注释版代码：

```python
# 确定输入参数
n = 4

# 定义结果缓存
queens = [-1] * n


# 递归遍历方法
def solve(row: int, columns: int, diagonals1: int, diagonals2: int):
    # 若所有棋子已经放下则输出结果
    if row == n:
        print(queens)
    else:
        # 获取可以放置棋子的位置
        availablePositions = ((1 << n) - 1) & (~(columns | diagonals1 | diagonals2))
        # 遍历可以放置棋子的位置
        while availablePositions:
            # 获取最低位的位置
            position = availablePositions & (-availablePositions)
            # 将最低位放置为 0
            availablePositions = availablePositions & (availablePositions - 1)
            # 确定列的位置
            column = bin(position - 1).count("1")
            # 记录缓存结果
            queens[row] = column
            # 完成递归调用
            solve(row + 1, columns | position, (diagonals1 | position) << 1, (diagonals2 | position) >> 1)


# 递归遍历方法
solve(0, 0, 0, 0)
```

官方解法：

```python
class Solution:
    def solveNQueens(self, n: int) -> List[List[str]]:
        def generateBoard():
            board = list()
            for i in range(n):
                row[queens[i]] = "Q"
                board.append("".join(row))
                row[queens[i]] = "."
            return board

        def backtrack(row: int):
            if row == n:
                board = generateBoard()
                solutions.append(board)
            else:
                for i in range(n):
                    if i in columns or row - i in diagonal1 or row + i in diagonal2:
                        continue
                    queens[row] = i
                    columns.add(i)
                    diagonal1.add(row - i)
                    diagonal2.add(row + i)
                    backtrack(row + 1)
                    columns.remove(i)
                    diagonal1.remove(row - i)
                    diagonal2.remove(row + i)

        solutions = list()
        queens = [-1] * n
        columns = set()
        diagonal1 = set()
        diagonal2 = set()
        row = ["."] * n
        backtrack(0)
        return solutions
```

#### 基于位运算的回溯

> 此方法采用按行填写的方案完成。

问题分析：

- 总行数等于皇后棋子的数量且皇后不能处于同一行，所以每一行都需要有一个皇后。
- 两个皇后不能处于同一斜线上，所以左右位移落子之后的点来确定跳过的目标位置。
- 将不能放置棋子的位置标记设置为 1 将可以放置棋子的位置标记为 0，就可以利用二进制记录放置信息
    - 左移取得左下不能放置的点。
    - 右移取得右下不能放置的点。
    - 记录当前放置的点。
- 使用二进制的或操作就可以确定不能放置棋子的位置。
- 在获取到可以放置的位置之后可以通过如下手段获取单个棋子的位置。
    - `x&(-x)` 可以获得 x 的二进制表示中的最低位的 1 的位置。
    - `x&(x-1)` 可以将二进制中最低位的 1 置成 0。
- 确保上述过程重复执行直至遍历整个棋盘即可。

简化注释版代码：

```python
# 确定输入参数
queens = 4

# 确保皇后不能处于同一行
column = set()
# 确保皇后不能处于同一斜线(右下方向)
d1 = set()
# 确保皇后不能处于同一斜线(左下方向)
d2 = set()

# 皇后落子的每一列的坐标
result = [0, 0, 0, 0]


# 递归遍历方法
def backtrack(row: int):
    # 若所有棋子已经放下则输出结果
    if row == queens:
        print(result)
    # 遍历当前列
    for i in range(queens):
        # 若当前位置已经无法落子则跳往下一位置
        if (i in column) or (row - i in d1) or (row + i in d2):
            continue
        # 将皇后放置在此位置
        result[row] = i
        # 记录此位置的冲突数据
        column.add(i)
        d1.add(row - i)
        d2.add(row + i)
        # 前往下一行进行遍历
        backtrack(row + 1)
        # 移除此位置的冲突数据
        column.remove(i)
        d1.remove(row - i)
        d2.remove(row + i)


# 开始遍历第 0 行
backtrack(0)
```

官方解法：

```python
class Solution:
    def solveNQueens(self, n: int) -> List[List[str]]:
        def generateBoard():
            board = list()
            for i in range(n):
                row[queens[i]] = "Q"
                board.append("".join(row))
                row[queens[i]] = "."
            return board

        def solve(row: int, columns: int, diagonals1: int, diagonals2: int):
            if row == n:
                board = generateBoard()
                solutions.append(board)
            else:
                availablePositions = ((1 << n) - 1) & (~(columns | diagonals1 | diagonals2))
                while availablePositions:
                    position = availablePositions & (-availablePositions)
                    availablePositions = availablePositions & (availablePositions - 1)
                    column = bin(position - 1).count("1")
                    queens[row] = column
                    solve(row + 1, columns | position, (diagonals1 | position) << 1, (diagonals2 | position) >> 1)

        solutions = list()
        queens = [-1] * n
        row = ["."] * n
        solve(0, 0, 0, 0)
        return solutions
```

### 参考资料

[Leetcode 官方题解](https://leetcode-cn.com/problems/n-queens/solution/nhuang-hou-by-leetcode-solution/)

[交互过程试验](https://www.cs.usfca.edu/~galles/visualization/RecQueens.html)