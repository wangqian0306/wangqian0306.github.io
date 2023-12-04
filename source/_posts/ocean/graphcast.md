---
title: GraphCast
date: 2023-11-21 23:09:32
tags:
- "Python"
id: graphcast
no_word_count: true
no_toc: false
categories: "Ocean"
---

## GraphCast

### 简介

GraphCast 是一种基于机器学习的天气预报方式，单纯使用数据进行训练和预测而不是采用当前数据进行计算。

### 使用方式

安装依赖：

```bash
pip install --upgrade https://github.com/deepmind/graphcast/archive/master.zip
pip uninstall -y shapely
yum install gcc gcc-c++ python3.11-devel epel-release -y
yum install geos geos-devel -y
pip install shapely --no-binary shapely
git clone https://github.com/deepmind/graphcast
cd graphcast
```

具体使用请参见 [Colab](https://colab.research.google.com/github/deepmind/graphcast/blob/master/graphcast_demo.ipynb)

在项目中可以找到 `graphcast.py` 文件，此文件即时程序运行的入口。可以参照如下代码从头开始训练模型：

```python

```

### 参考资料

[Learning skillful medium-range global weather forecasting 论文 ](https://www.science.org/stoken/author-tokens/ST-1550/full)

[GraphCast: AI model for faster and more accurate global weather forecasting 博客](https://deepmind.google/discover/blog/graphcast-ai-model-for-faster-and-more-accurate-global-weather-forecasting/)

[graphcast 官方项目](https://github.com/google-deepmind/graphcast)

[Colab (Notepad)](https://colab.research.google.com/github/deepmind/graphcast/blob/master/graphcast_demo.ipynb)
