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

### 参考资料

[参考代码](https://github.com/shianqi/3d-wind/blob/master/src/group/wind.js#L5C1-L5C40)
