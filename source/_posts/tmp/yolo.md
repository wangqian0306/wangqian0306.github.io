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

此样例严格限制 Python 版本 >=3.7,<3.11

> 注：在训练和使用模型时使用显卡可以显著的减少训练时常。

在使用前可以访问 [PyTorch](https://pytorch.org/get-started/locally/) 官网根据实际情况获取安装命令然后进行安装。

使用如下命令安装依赖：

```bash
pip3 install ultralytics
```

使用如下 Python 程序进行测试：

```python
import ultralytics
ultralytics.checks()
```

使用如下命令安装 C 环境：

```bash
yum install gcc gcc-c++ cmake -y
```

使用如下命令安装 `ByteTrack` :

```bash
git clone https://github.com/ifzhang/ByteTrack.git
cd ByteTrack
sed -i 's/onnx==1.8.1/onnx==1.9.0/g' requirements.txt
sed -i 's/lap/lapx/g' requirements.txt
pip3 install -r requirements.txt
python3 setup.py develop
pip3 install cython; pip3 install 'git+https://github.com/cocodataset/cocoapi.git#subdirectory=PythonAPI'
pip3 install cython_bbox
pip3 install -q onemetric
pip3 install -q loguru lap thop
```

使用如下 Python 程序进行测试：

```python
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
import supervision
print("supervision.__version__:", supervision.__version__)
```

### 参考资料

[官方项目](https://github.com/ultralytics/ultralytics)

[官方手册](https://docs.ultralytics.com/)

[车辆跟踪识别](https://github.com/roboflow/notebooks/blob/main/notebooks/how-to-track-and-count-vehicles-with-yolov8.ipynb)
