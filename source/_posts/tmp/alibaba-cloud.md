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

导出数据需要先安装如下工具，然后再按照导入流程进行操作。

#### ossutil

ossutil 是阿里云 OSS 的命令行管理工具。

可以访问如下地址获取 [安装手册和下载地址](https://www.alibabacloud.com/help/zh/oss/developer-reference/install-ossutil#4c30f1a48ce9y)

安装之后需要使用如下命令进行配置：

```bash
ossutil config
```

然后依次配置如下参数：

- accessKeyID ，访问 [RAM 访问控制页](https://ram.console.aliyun.com/users) 选择用户，在 AccessKey 部分即可创建，需要授予 OSS 全部管理权限。
- accessKeySecret ，同上。
- region ，此参数可以定位到 [OSS地域和访问域名](https://www.alibabacloud.com/help/zh/oss/user-guide/regions-and-endpoints#concept-zt4-cvy-5db) 中进行查看，此项需要填写 地域ID。
- endpoint , 同上，此项需要填写 外网Endpoint 或 内网Endpoint 。

配置完成后可以使用如下命令进行检测：

- 列出目录

```bash
ossutil ls
```

- 下载或上传文件

```bash
ossutil cp <path/ObjectName> <path/ObjectName>
```

#### QEMU

QEMU 是一个通用的开源机器模拟器和虚拟器。

可以访问 [下载地址获取软件](https://www.qemu.org/download/)

> 注：在 windows 中可以使用 chocolatey 便捷安装 `choco install qemu`。

#### 导入流程

1. 打开阿里云 ECS 控制台，进入实例列表页面，选择实例，选择快照一致性组，然后创建一致性组。
2. 进入镜像功能，创建自定义镜像，选择创建方式为快照，选择一致性组，创建镜像(建议勾选增加数据盘)。
3. 等待任务完成。
4. 进入 OSS 控制台，选择要下载的文件，使用 ossutil 工具下载文件并进行解压。

> 注：此处可以选择晚上0点到8点进行下载，收费少一些。

```bash
tar -zxvf <filename>
```

5. 使用 qemu-img 工具转换镜像文件为 vmdk 格式。

```bash
qemu-img convert -p -f raw <filename>.raw -O vmdk <diskname>.vmdk
```

6. 创建一个空的虚拟机。
7. 将 vmdk 做为磁盘配置在虚拟机中。

> 注：在本地启动服务时遇到了 `dracut-initqueue timeout could not boot` 问题，解决方案参见重构 grub 并重装内核文档。

### 参考资料

[使用快照创建自定义镜像](https://help.aliyun.com/zh/ecs/user-guide/create-a-custom-image-from-a-snapshot-1)

[QEMU 软件下载](https://www.qemu.org/download)

[阿里云命令行工具](https://open.aliyun.com/tools/cli)

[安装 ossutil](https://www.alibabacloud.com/help/zh/oss/developer-reference/install-ossutil)
