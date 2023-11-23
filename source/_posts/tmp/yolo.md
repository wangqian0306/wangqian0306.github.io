---
title: YOLO
date: 2023-11-23 21:41:32
tags: 
- "Python"
id: yolo
no_word_count: true
no_toc: false
---

## YOLO 

### 简介

YOLO(You Only Look Once) 是一款目标检测和图像分割模型。

> 注：AGPL-3.0 协议，可以付费商用。

### 使用场景

#### 车辆跟踪识别

> 注：在训练和使用模型时使用显卡可以显著的减少训练时常。

使用如下命令安装依赖：

```bash
pip3 install ultralytics
```

使用如下 Python 程序进行测试：

```python
from IPython import display
display.clear_output()

import ultralytics
ultralytics.checks()
```

使用如下命令安装 `ByteTrack` :

```bash
git clone https://github.com/ifzhang/ByteTrack.git
cd ByteTrack
sed -i 's/onnx==1.8.1/onnx==1.9.0/g' requirements.txt
pip3 install -r requirements.txt
python3 setup.py develop
pip3 install cython; pip3 install 'git+https://github.com/cocodataset/cocoapi.git#subdirectory=PythonAPI'
pip3 install cython_bbox
pip3 install -q onemetric
pip3 install -q loguru lap thop
```

使用如下 Python 程序进行测试：

```python
from IPython import display
display.clear_output()


import sys
sys.path.append(f"{HOME}/ByteTrack")


import yolox
print("yolox.__version__:", yolox.__version__)
```

使用如下命令安装 `Roboflow Supervision` ：

```bash
pip3 install supervision==0.1.0
```

使用如下 Python 程序进行测试：

```python
from IPython import display
display.clear_output()


import supervision
print("supervision.__version__:", supervision.__version__)
```

### 参考资料

[官方项目](https://github.com/ultralytics/ultralytics)

[官方手册](https://docs.ultralytics.com/)

[车辆跟踪识别](https://github.com/roboflow/notebooks/blob/main/notebooks/how-to-track-and-count-vehicles-with-yolov8.ipynb)
