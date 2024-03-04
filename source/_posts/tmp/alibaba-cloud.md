---
title: 阿里云 ECS 数据导出
date: 2024-03-04 22:26:13
tags:
- "Alibaba Cloud"
id: alibaba-cloud
no_word_count: true
no_toc: false
---

## 阿里云 ECS 数据导出

### 简介

如果有从阿里云 ECS 导出数据到本地的需求，可以参考以下方式。

### 使用方式

#### QEMU

QEMU 是一个通用的开源机器模拟器和虚拟器。

可以访问 [下载地址获取软件](https://www.qemu.org/download/)

#### 导入流程

1. 打开阿里云 ECS 控制台，进入实例列表页面，选择实例，选择快照一致性组，然后创建一致性组。
2. 进入镜像功能，创建自定义镜像，选择创建方式为快照，选择一致性组，创建镜像(建议勾选增加数据盘)。
3. 等待任务完成。
4. 进入 OSS 控制台，选择要下载的文件，使用迅雷等工具下载文件。
5. 使用 qemu-img 工具转换镜像文件为 vmdk 格式
6. 将 vmdk 导入 VMware

### 参考资料

[使用快照创建自定义镜像](https://help.aliyun.com/zh/ecs/user-guide/create-a-custom-image-from-a-snapshot-1)

[QEMU 软件下载](https://www.qemu.org/download)
