---
title: Docker 安装和基础命令
date: 2020-04-03 21:41:32
tags:
- "Container"
- "Docker"
id: docker
no_word_count: true
no_toc: false
categories: Container
---

## Docker 安装

### Yum 自带

使用如下命令进行安装

CentOS 7:

```bash
yum install docker -y
```

### Docker CE

使用如下命令进行安装：

- 清除原版软件

```bash
yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
```

- 新增官方源

```bash
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

- 安装软件

```bash
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## 关闭 SELinux

- 修改服务状态

```bash
setenforce 0
```

- 全局配置

```bash
vim /etc/selinux/config
```

修改如下内容

```text
SELINUX=disabled
```

## 非 Root 用户使用 Docker

使用如下命令进行服务配置

```bash
sudo groupadd docker
sudo usermod -aG docker <使用Docker的非Root用户>
sudo systemctl enable docker --now
sudo chmod 666 /var/run/docker.sock
```

## Dockerfile

可以参照[官方文档](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#dockerfile-instructions)

## 常用命令

拉取镜像

```bash
docker pull <镜像名>
```

构建镜像

```bash
docker build <Dockerfile所在目录的路径> -t <镜像名>
```

查看镜像列表

```bash
docker images
```

运行镜像并在运行结束后清除镜像

```bash
docker run -d <镜像ID/镜像名> --rm
```

查看容器列表

```bash
docker ps -a
```

以交互式命令行进入容器

```bash
docker exec -it <容器ID/容器名> <容器交互式命令>
```

> 注：常见的容器交互式命令为bash,但alpine的镜像需要用sh。

删除镜像

```bash
docker rm -f <容器ID/容器名>
```

删除容器

```bash
docker rmi -f <镜像ID/镜像名>
```

删除容器名为空的容器

```bash
docker rmi -f  `docker images | grep '<none>' | awk '{print $3}'` 
```

清除所有的容器相关内容

```bash
docker system prune -a
```

登录 DockerHub

```bash
docker login -u <用户名>
```

推送 Docker

```bash
docker push <镜像名>
```

将 Docker 保存为 tar 包

```bash
docker save -o <文件名>.tar <镜像名>
```

将tar包导入为镜像

```bash
docker load -i <文件名>.tar
```

查看镜像中的内容：

```bash
docker run -it --entrypoint /bin/bash --name <name> <image>
```

## 配置远程链接

Docker 采用了C/S架构，所以能在客户机上仅仅安装一个 docker-cli 就可以方便的链接服务器使用Docker了。

### 开启服务端远程链接

修改 daemon 配置，新增如下项目

```json
{
  "hosts": [
    "tcp://0.0.0.0:2375"
  ]
}
```

服务端允许docker链接

```bash
firewall-cmd --permanent --add-service=docker
firewall-cmd --reload
```

重启 docker 服务

```bash
systemctl restart docker
```

### 客户端配置

#### win 10

安装 docker-cli(需要管理员权限和`Chocolatey`软件)

```commandline
choco install docker-cli -y
```

在系统变量中新增如下环境变量即可

```text
DOCKER_HOST=tcp://<remote_ip>:2375
```

检测远程链接是否可用

```commandline
docker info
```

## 配置代理

创建代理配置文件：

```bash
mkdir -p /etc/systemd/system/docker.service.d
vim /etc/systemd/system/docker.service.d/proxy.conf
```

```text
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:8888/"
Environment="HTTPS_PROXY=http://127.0.0.1:8888/"
Environment="NO_PROXY=localhost,127.0.0.1,.example.com
```

重启服务

```bash
systemctl daemon-reload
systemctl restart docker
```

## 常见问题及解决方案

### 网络错误

在`docker`构建时发生`registry`链接失败的问题，可以通过如下方式进行解决

查看目前的容器网络列表

```bash
docker network ls
```

删除构建失败容器相关的网络即可

```bash
docker network rm <NETWORK ID>
```

> 注: 可以使用docker-compose。`docker-compose down`命令可以更好的管理容器相关内容。