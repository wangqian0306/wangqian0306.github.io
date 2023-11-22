---
title: Jupyter notebook
date: 2023-11-22 23:09:32
tags:
- "Python"
id: jupyter
no_word_count: true
no_toc: false
categories: "Python"
---

## Jupyter notebook

### 简介

Jupyter Notebook(前身是IPython Notebook)是一个基于 Web 的交互式计算环境，用于创建 Jupyter Notebook 文档。Jupyter Notebook 文档是一个 JSON 文档，包含一个有序的输入/输出单元格列表，这些单元格可以包含代码、文本、数学、图表和媒体内容，通常使用“.ipynb”作为扩展名。

### 使用方式

> 注：安装需要 Python 3 环境。

```bash
pip install notebook
firewall-cmd --permanent --add-port=8888/tcp
firewall-cmd --reload
jupyter notebook --ip 0.0.0.0
```

之后根据命令行提示即可通过局域网访问此网页

### 参考资料

[官方网站](https://jupyter.org/)

[官方文档](https://docs.jupyter.org/en/latest/index.html)
