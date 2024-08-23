---
title: Tropycal 
date: 2024-07-09 23:09:32
tags:
- "Tropycal"
- "Python"
id: tropycal
no_word_count: true
no_toc: false
categories: 
- "Ocean"
---

## Tropycal 

### 简介

Tropycal 是一个 Python 包，用于检索和分析过去和实时的热带气旋数据。

Tropycal 可以读取 HURDAT2 和 IBTrACS 再分析数据以及美国国家飓风中心(NCAR)的追踪数据，并使它们符合相同的格式，可用于执行气候、季节和个别风暴分析。

### 使用方式

使用如下命令安装依赖：

```bash
pip install tropycal
pip install shapely
pip install cartopy
```

编写如下脚本即可访问当前的气旋数据：

```python
from tropycal import realtime

realtime_obj = realtime.Realtime()

for storm in realtime_obj.list_active_storms():
    print(realtime_obj.get_storm(storm).to_dict())
```

可以编写如下代码获取到预测内容：

```python
from tropycal import realtime

realtime_obj = realtime.Realtime()

for storm in realtime_obj.list_active_storms():
    print(realtime_obj.get_storm(storm).get_forecast_realtime())
```

由于项目原始的设计问题，导致在转 json 时会出现很多的异常值，可以利用如下思路处理：

```python
import math

import json
from tropycal import realtime

def set_value(value_list:list):
    cache = []
    for i in value_list:
        if isinstance(i,float):
            print(i)
            if i== float('nan'):
                cache.append(null)
            else:
                cache.append(i)
    return cache

realtime_cache = realtime.Realtime()
storm_list = realtime_cache.list_active_storms()
result = []
for storm in storm_list:
    ele = realtime_cache.get_storm(storm).to_dict()
    for key in ele.keys():
        if isinstance(ele[key],list):
            ele[key] = set_value(ele[key])
        result.append(ele)
print(json.dumps(result))
```

### 参考资料

[官方项目](https://github.com/tropycal/tropycal)

[官方文档](https://tropycal.github.io/tropycal/)

[HFSA 预测](https://www.emc.ncep.noaa.gov/hurricane/HFSA/index.php)

[HFSA 数据](https://noaa-nws-hafs-pds.s3.amazonaws.com/index.html)
