---
title: GluonCV
date: 2023-11-29 21:41:32
tags: 
- "Python"
id: gluoncv
no_word_count: true
no_toc: false
---

## GluonCV

### 简介

GloonCV 提供了最先进的（SOTA）深度学习算法在计算机视觉中的实现。

### 安装

> 注：在测试中采用的系统版本是 Rocky Linux 9.3 Python 版本是 3.9.18 ，在训练和使用模型时使用显卡可以显著的减少训练时常。

访问 [安装手册页](https://cv.gluon.ai/install/install-more.html) 和[PyTorch](https://pytorch.org/get-started/locally/) 官网 可以获取更多的安装样例，本文仅使用 CPU 作为样例。 

```bash
pip3 install --upgrade mxnet
pip3 install torch torchvision torchaudio
pip3 install --upgrade gluoncv
```

### 使用

#### 目标识别(Object Detection)

编写如下样例程序即可：

```bash
from gluoncv import model_zoo, data, utils
from matplotlib import pyplot as plt

net = model_zoo.get_model('ssd_512_resnet50_v1_voc', pretrained=True)
im_fname = utils.download('https://github.com/dmlc/web-data/blob/master/' +
                          'gluoncv/detection/street_small.jpg?raw=true',
                          path='street_small.jpg')
x, img = data.transforms.presets.ssd.load_test(im_fname, short=512)
print('Shape of pre-processed image:', x.shape)
class_IDs, scores, bounding_boxes = net(x)

ax = utils.viz.plot_bbox(img, bounding_boxes[0], scores[0],
                         class_IDs[0], class_names=net.classes)
plt.show()
```

### 参考资料

[官方网站](https://cv.gluon.ai/)

[官方手册](https://cv.gluon.ai/contents.html)
