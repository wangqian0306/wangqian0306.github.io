---
title: minikube 环境安装
date: 2020-12-29 21:41:32
tags:
- "Container"
- "Docker"
id: minikube
no_word_count: true
no_toc: false
categories: Kubernetes
---

## minikube 环境安装

### 简介

minikube 是单机简化版的 kubernetes 环境，目前提供了多种方式运行集群，本文采用了 Docker 的方式完成了部署和使用操作。

### 安装

#### Linux

> 注: 此处需要 Docker 作为基础环境，并且需要一个可以使用 docker 和 sudo 的用户来运行下面的命令。

- 安装软件包

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

#### Windows

- 安装软件包

```bash
choco install minikube
```

### 服务配置

- 启动服务

> 注：此处使用 centos7 原版的 docker 发现了程序bug，在使用 docker-ce 的时候没有遇到问题。

```bash
minikube start --driver=docker --image-mirror-country='cn' --image-repository='registry.cn-hangzhou.aliyuncs.com/google_containers' 
```

> 注：如果需要查看详细日志可以使用 `--alsologtostderr -v=1` 参数。

- 安装操作命令

```bash
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubelet kubeadm kubectl
```

### 基础使用

- 创建外部服务(LoadBalancer)

```bash
kubectl create deployment hello-node --image=registry.cn-hangzhou.aliyuncs.com/google_containers/echoserver:1.4
kubectl expose deployment hello-node --type=LoadBalancer --port=8080
minikube service hello-node
```

- 创建外部服务(NodePort)

```bash
kubectl create deployment hello-node --image=registry.cn-hangzhou.aliyuncs.com/google_containers/echoserver:1.4
kubectl expose deployment hello-node --type=NodePort --port=8080
minikube service hello-node
```

- 清除服务

```bash
kubectl delete service hello-node
kubectl delete deployment hello-node
```

### 常用命令

- 端口转发

```bash
kubectl port-forward service/hello-node 7080:8080
```

- 转发所有 LoadBalancer 端口

```bash
minikube tunnel
```

- 开启图形界面

```bash
minikube dashboard
```

- 暂停 Kubernetes 集群

```bash
minikube pause
```

- 停止集群

```bash
minikube stop
```

- 删除所有 minikube 集群

```bash
minikube delete --all
```

### 注意事项

minikube 在创建的过程中会在 Docker 网卡上创建独立的虚拟网卡。主机可能无法访问虚拟机中的内容。