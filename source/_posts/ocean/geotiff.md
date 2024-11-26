---
title: GeoTIFF
date: 2024-11-25 23:09:32
tags:
- "Python"
id: geotiff
no_word_count: true
no_toc: false
categories: "Ocean"
---

## GeoTIFF

### 简介

GeoTIFF 是一种公共领域元数据标准，允许将地理参考信息嵌入 TIFF 文件中。潜在的附加信息包括地图投影、坐标系、椭球体、基准以及为文件建立精确空间参考所需的所有其他信息。

### 使用方式

安装依赖包：

```bash
pip install rasterio
```

#### 读取文件

```python
import rasterio

# 打开 merge.tiff 文件
file_path = "merge.tiff"

with rasterio.open(file_path) as dataset:
    # 打印文件的元数据信息
    print("文件元数据：")
    print(dataset.meta)
    
    # 打印更多详细的元数据
    print("\n详细元数据信息：")
    print(f"宽度 (Width): {dataset.width}")
    print(f"高度 (Height): {dataset.height}")
    print(f"波段数量 (Number of bands): {dataset.count}")
    print(f"数据类型 (Data type): {dataset.dtypes}")
    print(f"坐标参考系 (CRS): {dataset.crs}")
    print(f"仿射变换 (Transform): {dataset.transform}")
    print(f"边界范围 (Bounds): {dataset.bounds}")
    
    # 检查并打印波段的描述
    for band_id in range(1, dataset.count + 1):
        print(f"\n波段 {band_id} 的描述:")
        print(dataset.descriptions[band_id - 1])

    data = dataset.read(1)
    demo_list = data.tolist()
    print(demo_list[0])
    print(len(demo_list[0]))
```

#### 写入文件

```python
def buildArray(number:int):
    result = []
    for i in range(180):
        cache = []
        for j in range(360):
            cache.append(number)
        result.append(cache)
    return result

import numpy as np
import rasterio
from rasterio.transform import Affine
from rasterio.crs import CRS

driver = 'GTiff'
dtype = 'int16'
nodata = None
width = 360
height = 180
count = 2
crs = CRS.from_wkt('GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AXIS["Latitude",NORTH],AXIS["Longitude",EAST],AUTHORITY["EPSG","4326"]]')
transform = Affine(1.0, 0.0, -0.5, 0.0, -1.0, 90.0)


metadata = {
    'driver': driver,
    'dtype': dtype,
    'nodata': nodata,
    'width': width,
    'height': height,
    'count': count,
    'crs': crs,
    'transform': transform
}

band1 = np.array(buildArray(180), dtype=np.int16)
band2 = np.array(buildArray(180), dtype=np.int16)

# Write the GeoTIFF
output_path = "sample.tiff"
with rasterio.open(output_path, 'w', **metadata) as dst:
    dst.write(band1, 1)  # Write Band 1
    dst.write(band2, 2)  # Write Band 2

print(f"GeoTIFF file created: {output_path}")
```

除了把原始数据直接写入 tiff 中之外还可以针对数据进行分级规划。比方说可以按照如下方式进行处理：

```python
import json


def process_2d_array(input_array, func):
    """
    对二维数组中的每个元素应用函数处理，返回一个新的二维数组。

    :param input_array: 输入的二维数组
    :param func: 用于处理每个元素的函数
    :return: 处理后的二维数组
    """
    return [[func(value) for value in row] for row in input_array]


def data_to_int(data, max_value=32):
    """
    将数据转换为 -300 到 300 的整型数据。

    :param data: 原始数据值，可以为负值
    :param max_value: 最大速度的绝对值 (默认 32)
    :return: 映射到 -300 到 300 的整型值
    """
    if abs(data) > max_value:
        data = max_value if data > 0 else -max_value  # 限制在 [-max_value, max_value]

    # 映射公式：将 [-max_value, max_value] 映射到 [-300, 300]
    mapped_value = (data / max_value) * 300
    return round(mapped_value)


def process(filename, result_name):
    with open(filename, "r") as f:
        text = f.read()
        input_array = json.loads(text)
        output_array = process_2d_array(input_array, data_to_int)
        output_json = json.dumps(output_array, indent=4)
        with open(result_name, "w") as file:
            file.write(output_json)


if __name__ == "__main__":
    process("u_wind_filtered.json", "u_wind_modified.json")
    process("v_wind_filtered.json", "v_wind_modified.json")
```

> 注：此处数据采用 180 个长度为 360 的数组(二维数组，数据分辨率为 1 度)。

### 参考资料

[参考代码](https://github.com/shianqi/3d-wind/blob/master/src/group/wind.js#L5C1-L5C40)

[官方项目](https://github.com/rasterio/rasterio)

[官方文档](https://rasterio.readthedocs.io/en/stable/)
