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

#### 在地图上叠加热力图

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

然后还可以使用如下代码的生成瓦片：

```python
from PIL import Image


def interpolate_color(config: list, value: int) -> tuple:
    if value is None:
        return 0, 0, 0, 0
    lower_entry = None
    higher_entry = None
    for entry in config:
        if entry[0] <= value:
            lower_entry = entry
        if entry[0] >= value:
            higher_entry = entry
            break

    if lower_entry is None:
        return tuple(higher_entry[1])
    elif higher_entry is None:
        return tuple(lower_entry[1])

    check = (higher_entry[0] - lower_entry[0])
    if check == 0:
        return lower_entry[1][0], lower_entry[1][1], lower_entry[1][2], 255
    else:
        ratio = (value - lower_entry[0]) / (higher_entry[0] - lower_entry[0])
    result = interpolate_color_between(lower_entry[1], higher_entry[1], ratio)
    return result


def interpolate_color_between(color1: tuple, color2: tuple, ratio: int) -> tuple:
    r1, g1, b1 = color1
    r2, g2, b2 = color2

    r = int(r1 + (r2 - r1) * ratio)
    g = int(g1 + (g2 - g1) * ratio)
    b = int(b1 + (b2 - b1) * ratio)
    a = 255
    return r, g, b, a


def draw_image(rgba_array: list, width: int, height: int) -> Image:
    image = Image.new("RGBA", (width, height))
    image.putdata(rgba_array)
    return image


def get_rgba_list(data: list, config: dict) -> list:
    cache = []
    for d in data:
        cache.append(interpolate_color(config, d))
    return cache


def fake_data_generator(x: int, y: int, value: int) -> list:
    cache = []
    for i in range(x * y):
        cache.append(value)
    return cache;


if __name__ == "__main__":
    x = 45
    y = 45
    data = fake_data_generator(45, 45, 305)

    config = [
        [193, [255, 255, 255]],
        [215, [237, 220, 237]],
        [230, [227, 204, 229]],
        [245, [206, 169, 212]],
        [260, [139, 97, 184]],
        [275, [51, 76, 160]],
        [290, [76, 159, 199]],
        [305, [211, 243, 149]],
        [320, [248, 144, 43]],
        [335, [148, 21, 50]],
        [350, [44, 0, 15]],
    ]
    rgba_list = get_rgba_list(data, config)
    img = draw_image(rgba_list, y, x).resize((256, 256))
    img.save("tile.webp", "WEBP")
```

> 注：但是此处因为投影系产生了图像偏移的问题。

绘制大陆架，海岸线

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
