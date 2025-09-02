---
title: Copernicus
date: 2025-08-25 23:09:32
tags:
- "Copernicus"
- "Python"
id: copernicus
no_word_count: true
no_toc: false
categories: "Ocean"
---

## Copernicus

### 简介

哥白尼(Copernicus)，是欧盟太空计划的地球观测的产物，可以使用 Python 方便的下载哥白尼项目的预测数据。

### 使用方式

安装依赖：

```text
pip install copernicusmarine netCDF4 xarray pyproj
```

访问 [官方网站](https://data.marine.copernicus.eu/products) 选择数据集，之后也可以通过文件中的名字来做内容过滤

根据网页上的 product_id 查看 dataset_id ：

```python
import json

import copernicusmarine

with open("wave_conf.json", 'r') as conf_schedule:
    conf = json.load(conf_schedule)

print(copernicusmarine.describe(product_id="GLOBAL_ANALYSISFORECAST_PHY_001_024", disable_progress_bar=True))

```

下载数据代码如下：

```python
import copernicusmarine

# Copernicus Marine 平台账号
USERNAME = "你的用户名"
PASSWORD = "你的密码"

# 数据集 ID（举例：全球海浪预报 3 小时分辨率）
dataset_id = "cmems_mod_glo_wav_anfc_0.2deg_PT3H-i"

# 筛选条件：下载 2025年8月1日的文件
# 你可以改成 20250802 或者用通配符批量下载
filter_rule = "*20250801*.nc"

# 输出目录
outdir = "./downloads"

# 下载文件
result = copernicusmarine.get(
    username=USERNAME,
    password=PASSWORD,
    dataset_id=dataset_id,
    filter=filter_rule,       # 文件名通配符
    no_directories=True,      # 全部平铺到 outdir
    output_directory=outdir,
)

print("下载完成！文件列表：")
for f in result.files:
    print(" -", f.file_path)
```

### 参考资料

[How to download and subset original data using the GET function in Python?](https://help.marine.copernicus.eu/en/articles/9730123-how-to-download-and-subset-original-data-using-the-get-function-in-python)
