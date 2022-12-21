---
title: NFS StorageClass
date: 2022-12-21 21:41:32
tags:
- "Container"
- "Docker"
- "Kubernetes"
id: nfs-sc
no_word_count: true
no_toc: false
categories: Kubernetes
---

## NFS StorageClass

### 简介

StorageClass 是 Kubernetes 为了动态配置存储而产生的概念，本文会整理为 NFS 服务安装 Storage Class 的过程。NFS 服务安装的部分请参照其他文档。

Kubernetes 官方并没有提供内置的驱动而建议采用如下两种外部驱动：

- NFS Ganesha
- NFS subdir

> 注：由于 NFS subdir 提供了 Helm Chart 安装较为方便，所以本文优先采用此种方式。

### NFS subdir 外部驱动

> 注：运行需要拉取 k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2 镜像。

然后运行下面的命令即可：

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=x.x.x.x --set nfs.path=/exported/path
```

### 参考资料

[官方文档](https://kubernetes.io/zh-cn/docs/concepts/storage/storage-classes/#nfs)

[nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)
