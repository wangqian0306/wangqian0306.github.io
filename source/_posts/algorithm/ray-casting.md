---
title: Ray casting 算法
date: 2022-01-12 22:26:13
tags: "算法"
id: ray-casting
no_word_count: true
no_toc: false
categories: 算法
---

## Ray casting 算法

### 简介

光线投射算法是基于图像序列的直接体绘制算法。从图像的每一个像素，沿固定方向（通常是视线方向）发射一条光线，光线穿越整个图像序列，并在这个过程中，对图像序列进行采样获取颜色信息，同时依据光线吸收模型将颜色值进行累加，直至光线穿越整个图像序列，最后得到的颜色值就是渲染图像的颜色。

### 简单实现

```python
import sys
from collections import namedtuple

Pt = namedtuple('Pt', 'x, y')  # Point
Edge = namedtuple('Edge', 'a, b')  # Polygon edge from a to b
Polygon = namedtuple('Polygon', 'name, edges')  # Polygon

_eps = 0.00001
_huge = sys.float_info.max
_tiny = sys.float_info.min


def ray_intersect_seg(p, edge):
    """ takes a point p=Pt() and an edge of two endpoints a,b=Pt() of a line segment returns boolean
    """
    a, b = edge
    if a.y > b.y:
        a, b = b, a
    if p.y == a.y or p.y == b.y:
        p = Pt(p.x, p.y + _eps)

    if (p.y > b.y or p.y < a.y) or (
            p.x > max(a.x, b.x)):
        return False

    if p.x < min(a.x, b.x):
        intersect = True
    else:
        if abs(a.x - b.x) > _tiny:
            m_red = (b.y - a.y) / float(b.x - a.x)
        else:
            m_red = _huge
        if abs(a.x - p.x) > _tiny:
            m_blue = (p.y - a.y) / float(p.x - a.x)
        else:
            m_blue = _huge
        intersect = m_blue >= m_red
    return intersect


def _odd(x): return x % 2 == 1


def is_point_inside(p, poly_list):
    ln = len(poly_list)
    return _odd(sum(ray_intersect_seg(p, edge)
                    for edge in poly_list.edges))


def poly_print(polygon):
    print("\n  Polygon(name='%s', edges=(" % polygon.name)
    print('   ', ',\n    '.join(str(e) for e in polygon.edges) + '\n    ))')


if __name__ == '__main__':
    polys = [
        Polygon(name='square', edges=(
            Edge(a=Pt(x=0, y=0), b=Pt(x=10, y=0)),
            Edge(a=Pt(x=10, y=0), b=Pt(x=10, y=10)),
            Edge(a=Pt(x=10, y=10), b=Pt(x=0, y=10)),
            Edge(a=Pt(x=0, y=10), b=Pt(x=0, y=0))
        )),
        Polygon(name='square_hole', edges=(
            Edge(a=Pt(x=0, y=0), b=Pt(x=10, y=0)),
            Edge(a=Pt(x=10, y=0), b=Pt(x=10, y=10)),
            Edge(a=Pt(x=10, y=10), b=Pt(x=0, y=10)),
            Edge(a=Pt(x=0, y=10), b=Pt(x=0, y=0)),
            Edge(a=Pt(x=2.5, y=2.5), b=Pt(x=7.5, y=2.5)),
            Edge(a=Pt(x=7.5, y=2.5), b=Pt(x=7.5, y=7.5)),
            Edge(a=Pt(x=7.5, y=7.5), b=Pt(x=2.5, y=7.5)),
            Edge(a=Pt(x=2.5, y=7.5), b=Pt(x=2.5, y=2.5))
        )),
        Polygon(name='strange', edges=(
            Edge(a=Pt(x=0, y=0), b=Pt(x=2.5, y=2.5)),
            Edge(a=Pt(x=2.5, y=2.5), b=Pt(x=0, y=10)),
            Edge(a=Pt(x=0, y=10), b=Pt(x=2.5, y=7.5)),
            Edge(a=Pt(x=2.5, y=7.5), b=Pt(x=7.5, y=7.5)),
            Edge(a=Pt(x=7.5, y=7.5), b=Pt(x=10, y=10)),
            Edge(a=Pt(x=10, y=10), b=Pt(x=10, y=0)),
            Edge(a=Pt(x=10, y=0), b=Pt(x=2.5, y=2.5))
        )),
        Polygon(name='exagon', edges=(
            Edge(a=Pt(x=3, y=0), b=Pt(x=7, y=0)),
            Edge(a=Pt(x=7, y=0), b=Pt(x=10, y=5)),
            Edge(a=Pt(x=10, y=5), b=Pt(x=7, y=10)),
            Edge(a=Pt(x=7, y=10), b=Pt(x=3, y=10)),
            Edge(a=Pt(x=3, y=10), b=Pt(x=0, y=5)),
            Edge(a=Pt(x=0, y=5), b=Pt(x=3, y=0))
        )),
    ]
    test_points = (Pt(x=5, y=5), Pt(x=5, y=8),
                   Pt(x=-10, y=5), Pt(x=0, y=5),
                   Pt(x=10, y=5), Pt(x=8, y=5),
                   Pt(x=10, y=10))

    print("\n TESTING WHETHER POINTS ARE WITHIN POLYGONS")
    for poly in polys:
        poly_print(poly)
        print('   ', '\t'.join("%s: %s" % (p, is_point_inside(p, poly))
                               for p in test_points[:3]))
        print('   ', '\t'.join("%s: %s" % (p, is_point_inside(p, poly))
                               for p in test_points[3:6]))
        print('   ', '\t'.join("%s: %s" % (p, is_point_inside(p, poly))
                               for p in test_points[6:]))
```

### 参考资料

[Ray casting Algorithm](https://rosettacode.org/wiki/Ray-casting_algorithm)
