---
title: Xihe-GlobalOceanForecasting
date: 2024-11-19 23:09:32
tags:
- "Python"
id: xihe
no_word_count: true
no_toc: false
categories: "Ocean"
---

## Xihe-GlobalOceanForecasting

### 简介

2024年2月5日，国防科技大学气象海洋学院联合复旦大学大气与海洋科学系、中南大学计算机学院等单位，研制了首个数据驱动的全球1/12°高分辨率海洋环境预报大模型“羲和”。

### 使用流程和逻辑

羲和海洋大模型的数据来自三个部分：

- ERA5 大气再分析数据
- GHRSST 海表温度数据
- GLORYS12 海洋再分析数据

使用这些数据做训练可以形成模型，然后再输入如下变量即可完成预测：

- 表层变量（surface）
- 深层变量（deep）
- 静态变量（包含经纬度网格、掩膜数组和气候统计量）

> 注：详细描述参见官方项目 README 文件。

再制作输入数据时，可以获取一整月的来源数据，然后计算平均值，再使用插值法处理投影成 (2041, 4320) 大小即可作为输入数据集。

在准备好环境之后即可使用代码中的 `inference.py` 文件进行预测。

> 注：此时需要下载模型文件 file_path 和模型权重 project_path 作为基础资源，在 main 函数中需要设定输入和输出问文件夹以及输入文件对应的日期。

安装如下依赖之后即可运行官方项目：

```bash
python -m pip install --upgrade pip
pip install cinrad==1.9.1
pip install meteva==1.9.1.2
pip install pypots==0.8.1
pip install pyproj==3.7.0
pip install OWSLib==0.29.3
pip install dask==2024.11.1
pip install distributed==2024.11.1
pip install MetPy==1.6.3
pip install Pillow==11
pip install xarray==2024.10
pip install numpy==1.26.4
pip install rioxarray==0.17
pip install seaborn==0.13.2
pip install pandas==2.2.3
pip install imageio==2.36
pip install rasterio==1.4.2
pip install shapely==2.0.6
pip install geopandas==1.0.1
pip install cf-xarray==0.10.0
pip install networkx==3.3
pip install zarr==2.18.3
pip install jax==0.4.34
pip install transformers==4.46.2
pip install lightgbm==4.5.0
pip install xgboost==2.1.2
pip install cmaps==2.0.1
pip install scikit-learn==1.6.0rc1
pip install cartopy==0.24.1
pip install pytorch-lightning==2.4.0
pip install wandb==0.18.7
pip install gluonts==0.15.1
pip install onnx==1.16.2
pip install matplotlib==3.9.2
pip install statsmodels==0.14.2
pip install shap==0.46
pip install pytorch-tabnet==4.1.0
pip install torch torchvision torchaudio -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install scipy==1.13.1
pip install https://ms-release.obs.cn-north-4.myhuaweicloud.com/2.4.0/MindSpore/unified/x86_64/mindspore-2.4.0-cp39-cp39-linux_x86_64.whl --trusted-host ms-release.obs.cn-north-4.myhuaweicloud.com -i https://pypi.tuna.tsinghua.edu.cn/simple
```

示例代码如下：

```bash
python inference.py --lead_day 7 --save_path output_data
```

### 参考资料

[论文原文](https://arxiv.org/abs/2402.02995)

[官方项目](https://github.com/Ocean-Intelligent-Forecasting/XiHe-GlobalOceanForecasting)

[动手用羲和海洋AI大模型预报海温、流速 | GeoAI workshop](https://www.heywhale.com/home/competition/672897e65bbefcbb457ca425)