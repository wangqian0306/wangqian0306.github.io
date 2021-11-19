---
title: 排序算法
date: 2021-11-18 20:32:58
tags: "Python"
id: sort
no_word_count: true
no_toc: false
categories: 数据结构
---

## 排序算法

### 冒泡排序(Bubble Sort)

```python
def bubble_sort(content_list: list[int]):
    for j in range(len(content_list) - 1, 0, -1):
        for i in range(j):
            if content_list[i] > content_list[i + 1]:
                content_list[i], content_list[i + 1] = content_list[i + 1], content_list[i]
```

### 选择排序(Selection sort)

```python
def selection_sort(content_list: list[int]):
    n = len(content_list)
    # 需要进行n-1次选择操作
    for i in range(n - 1):
        # 记录最小位置
        min_index = i
        # 从i+1位置到末尾选择出最小数据
        for j in range(i + 1, n):
            if content_list[j] < content_list[min_index]:
                min_index = j
        # 如果选择出的数据不在正确位置，进行交换
        if min_index != i:
            content_list[i], content_list[min_index] = content_list[min_index], content_list[i]
```

### 插入排序(Insertion Sort)

```python
def insert_sort(content_list: list[int]):
    # 从第二个位置，即下标为1的元素开始向前插入
    for i in range(1, len(content_list)):
        # 从第i个元素开始向前比较，如果小于前一个元素，交换位置
        for j in range(i, 0, -1):
            if content_list[j] < content_list[j - 1]:
                content_list[j], content_list[j - 1] = content_list[j - 1], content_list[j]
```

### 希尔排序(Shell Sort)

```python
def shell_sort(content_list: list[int]):
    n = len(content_list)
    # 初始步长
    gap = n / 2
    while gap > 0:
        # 按步长进行插入排序
        for i in range(gap, n):
            j = i
            # 插入排序
            while j >= gap and content_list[j - gap] > content_list[j]:
                content_list[j - gap], content_list[j] = content_list[j], content_list[j - gap]
                j -= gap
        # 得到新的步长
        gap = gap / 2
```

### 归并排序(Merge Sort)

```python
def merge_sort(content_list: list[int]):
    if len(content_list) <= 1:
        return content_list
    # 二分分解
    num = len(content_list) / 2
    left = merge_sort(content_list[:num])
    right = merge_sort(content_list[num:])
    # 合并
    return merge(left, right)


def merge(left: list[int], right: list[int]) -> list[int]:
    """合并操作，将两个有序数组left[]和right[]合并成一个大的有序数组"""
    # left与right的下标指针
    l, r = 0, 0
    result = []
    while l < len(left) and r < len(right):
        if left[l] < right[r]:
            result.append(left[l])
            l += 1
        else:
            result.append(right[r])
            r += 1
    result += left[l:]
    result += right[r:]
    return result
```

### 快速排序(Quick Sort)

```python
def quick_sort(content_list: list[int], start_index: int, end_index: int) -> None:
    """快速排序"""

    # 递归的退出条件
    if start_index >= end_index:
        return

    # 设定起始元素为要寻找位置的基准元素
    mid = content_list[start_index]

    # low为序列左边的由左向右移动的游标
    low = start_index

    # high为序列右边的由右向左移动的游标
    high = end_index

    while low < high:
        # 如果low与high未重合，high指向的元素不比基准元素小，则high向左移动
        while low < high and content_list[high] >= mid:
            high -= 1
        # 将high指向的元素放到low的位置上
        content_list[low] = content_list[high]

        # 如果low与high未重合，low指向的元素比基准元素小，则low向右移动
        while low < high and content_list[low] < mid:
            low += 1
        # 将low指向的元素放到high的位置上
        content_list[high] = content_list[low]

    # 退出循环后，low与high重合，此时所指位置为基准元素的正确位置
    # 将基准元素放到该位置
    content_list[low] = mid

    # 对基准元素左边的子序列进行快速排序
    quick_sort(content_list, start_index, low - 1)

    # 对基准元素右边的子序列进行快速排序
    quick_sort(content_list, low + 1, end_index)
```

### 桶排序(Bucket Sort)

```python
def bucket_sort(content_list: list[int]) -> None:
    """桶排序"""
    min_num = min(content_list)
    max_num = max(content_list)
    # 桶的大小
    bucket_range = (max_num - min_num) / len(content_list)
    # 桶数组
    count_list = [[] for _ in range(len(content_list) + 1)]
    # 向桶数组填数
    for i in content_list:
        count_list[int((i - min_num) // bucket_range)].append(i)
    content_list.clear()
    # 回填，这里桶内部排序直接调用了sorted
    for i in count_list:
        for j in sorted(i):
            content_list.append(j)
```

### 计数排序(Counting Sort)

```python
def counting_sort(content_list: list[int]) -> list[int]:
    # 桶的个数，这一是取决于，这一个列表中最大的那个数字
    bucket = [0] * (max(content_list) + 1)

    for num in content_list:  # 用num下标的位置，记录其出现的次数
        bucket[num] += 1
    i = 0  # nums 的索引
    # 循环遍历整个桶
    for j in range(len(bucket)):
        # 找到第j个元素，就是出现j的次数，如果不是0次没代表出现
        while bucket[j] > 0:
            # 出现了，就把这一个写入到原本的nums列表中，
            # 同时出现的次数减一，nums列表加一
            content_list[i] = j
            bucket[j] -= 1
            i += 1
    return content_list
```

### 基数排序(Radix Sort)

```python
def counting_sort_for_radix(input_array, place_value):
    count_array = [0] * 10
    input_size = len(input_array)

    for i in range(input_size):
        place_element = (input_array[i] // place_value) % 10
        count_array[place_element] += 1

    for i in range(1, 10):
        count_array[i] += count_array[i - 1]

    output_array = [0] * input_size
    i = input_size - 1
    while i >= 0:
        current_el = input_array[i]
        place_element = (input_array[i] // place_value) % 10
        count_array[place_element] -= 1
        new_position = count_array[place_element]
        output_array[new_position] = current_el
        i -= 1

    return output_array


def radix_sort(input_array):
    # Step 1 -> Find the maximum element in the input array
    max_el = max(input_array)

    # Step 2 -> Find the number of digits in the `max` element
    digit = 1
    while max_el > 0:
        max_el /= 10
        digit += 1

    # Step 3 -> Initialize the place value to the least significant place
    place_val = 1

    # Step 4
    output_array = input_array
    while digit > 0:
        output_array = counting_sort_for_radix(output_array, place_val)
        place_val *= 10
        digit -= 1

    return output_array
```

### 堆排序(HeapSort)

```python
def heapify(arr, n, i):
    largest = i  # Initialize largest as root
    l = 2 * i + 1     # left = 2*i + 1
    r = 2 * i + 2     # right = 2*i + 2
 
    # See if left child of root exists and is
    # greater than root
    if l < n and arr[largest] < arr[l]:
        largest = l
 
    # See if right child of root exists and is
    # greater than root
    if r < n and arr[largest] < arr[r]:
        largest = r
 
    # Change root, if needed
    if largest != i:
        arr[i], arr[largest] = arr[largest], arr[i]  # swap
 
        # Heapify the root.
        heapify(arr, n, largest)
 
# The main function to sort an array of given size

def heap_sort(arr):
    n = len(arr)
 
    # Build a maxheap.
    for i in range(n//2 - 1, -1, -1):
        heapify(arr, n, i)
 
    # One by one extract elements
    for i in range(n-1, 0, -1):
        arr[i], arr[0] = arr[0], arr[i]  # swap
        heapify(arr, i, 0)
```

### 参考资料

[RadixSort](https://stackabuse.com/radix-sort-in-python/)

[排序与搜索](https://jackkuo666.github.io/Data_Structure_with_Python_book/chapter6/section7.html)

[排序可视化](https://www.cs.usfca.edu/~galles/visualization/Algorithms.html)
