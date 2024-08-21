---
title: 瓦片地图
date: 2024-04-19 23:09:32
tags:
- "GeoServer"
- "Python"
id: tile
no_word_count: true
no_toc: false
categories: "Ocean"
---

## 瓦片地图

### 简介

瓦片地图金字塔模型是一种多分辨率层次模型，从瓦片金字塔的底层到顶层，分辨率越来越低，但表示的地理范围不变。

### 使用场景

#### 坐标转化

安装依赖库：

```bash
pip install cartopy pillow matplotlib
```

首先可以用如下函数进行坐标和瓦片的互相转化：

```python
import math

TILE_SIZE = 256


def lon_to_pixel_x(lon, zoom):
    pixel_x = (lon + 180) / 360 * (TILE_SIZE << zoom)
    return pixel_x


def lat_to_pixel_y(lat, zoom):
    sin_lat = math.sin(lat * math.pi / 180)
    return (0.5 - math.log((1 + sin_lat) / (1 - sin_lat)) / (4 * math.pi)) * (TILE_SIZE << zoom)


def lat_lon_to_tile(lon, lat, zoom):
    px = lon_to_pixel_x(lon, zoom)
    py = lat_to_pixel_y(lat, zoom)
    tx = int(px / TILE_SIZE)
    ty = int(py / TILE_SIZE)
    return tx, ty


def tile_to_latlon(x, y, z):
    n = 2.0 ** z
    lon_left = x / n * 360.0 - 180.0
    lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * y / n)))
    lat_top = math.degrees(lat_rad)

    lon_right = (x + 1) / n * 360.0 - 180.0
    lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * (y + 1) / n)))
    lat_bottom = math.degrees(lat_rad)

    return lat_top, lon_left, lat_bottom, lon_right


if __name__ == "__main__":
    print(tile_to_latlon(14, 6, 4))
    print(lat_lon_to_tile(135, 40.97, 4))
```

#### 绘制大陆架，海岸线

```python
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import matplotlib.pyplot as plt

# 创建一个绘图对象
fig = plt.figure(figsize=(256, 256))
ax = plt.axes(projection=ccrs.Mercator())

# 添加地理特征
ax.add_feature(cfeature.COASTLINE, edgecolor='red')
# 显示图形
plt.savefig('map_with_cartopy.png', bbox_inches='tight')
```

#### 将相关数据绘制成瓦片

此处记录下实现方式：

1. 获取到数据和其 GPS 坐标点位
2. 将坐标点转化为 EPSG:3857 (Web Mercator)投影系坐标
3. 明确投影坐标到实际图上的坐标(x,y)
4. 使用线性插值法补充数据(此处结合实际的层级进行数据插入，例如z=3时总的像素数是 2048*2048)
4. 将点位数组绘制成图