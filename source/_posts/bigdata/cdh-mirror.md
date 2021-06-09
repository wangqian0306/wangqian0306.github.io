---
title: CDH 本地源搭建流程整理
date: 2020-12-09 22:26:13
tags: "CDH"
id: cdh-mirror
no_word_count: true
no_toc: false
categories: 大数据
---

## CDH 本地源搭建流程整理

### 简述

将公网上的 CDH 软件源下载至本地可以满足在内网安装和下载加速的功能，具体的搭建方式可以采用以下方式。

- 手动搭建
- Nexus 软件源搭建

### 手动搭建方式

[Cloudera 官方文档](https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cm_ig_create_local_package_repo.html#download_publish_package_repo)

- 安装 `httpd` 服务

```bash
yum install -y httpd
```

- 创建同步文件夹

```bash
mkdir -p /var/www/html/cloudera-repos/cm6
```

- 拉取并解压软件包

```bash
cd /var/www/html/cloudera-repos/cm6
wget https://archive.cloudera.com/cm6/version/repo-as-tarball/cm6.3.1-redhat7.tar.gz
tar xvfz cm6.3.1-redhat7.tar.gz -C /var/www/html/cloudera-repos/cm6 --strip-components=1
```

- 同步软件源

```bash
wget https://archive.cloudera.com/cm6/6.3.1/allkeys.asc
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cdh6/<version>/<operating_system>/ -P /var/www/html/cloudera-repos
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/gplextras6/<version>/<operating_system>/ -P /var/www/html/cloudera-repos
```

- 修改文件权限

```bash
chmod -R ugo+rX /var/www/html/cloudera-repos/cdh6
chmod -R ugo+rX /var/www/html/cloudera-repos/gplextras6
```

- 启动服务

```bash
systemctl enable httpd
systemctl start httpd
```

- 检查服务

```bash
curl localhost/cloudera-repos/
```

若出现文件夹则证明环境搭建正常。

- 配置客户端

在需要安装 CDH 的客户机上新增 `/etc/yum.repos.d/cm.repo` 文件即可。

```bash
[cloudera-manager]
name=Cloudera Manager 6.3.1
baseurl=http://<server_ip>/cloudera-repos/cm6/6.3.1/redhat7/yum/
gpgkey=http://<server_ip>/cloudera-repos/cm6/6.3.1/redhat7/yum/RPM-GPG-KEY-cloudera
gpgcheck=0
enabled=1
autorefresh=0
type=rpm-md
```

### Nexus 软件源方式

Neuxs 可以作为 Proxy 缓存外网上的软件包。

> 注：此处采用 Docker 的方式运行 Nexus 软件源，需要 Docker 和 Docker-Compose 软件。

- 选定安装位置创建 `nexus` 文件夹

> 注：此处建议安装在 /opt 目录下

```bash
mkdir /opt/nexus
```

- 在 `nexus` 文件夹中新增 `docker-compose.yaml` 文件

```bash
vim /opt/nexus/docker-compose.yaml
```

```yaml
version: "2"

services:
  nexus:
    image: sonatype/nexus3
    volumes:
      - ./nexus-data:/nexus-data
    ports:
      - 8081:8081
```

- 开启服务

```bash
cd /opt/nexus
docker-compose up -d
```

- 查看默认密码

```bash
docker-compose exec nexus cat /nexus-data/admin.password
```

- 登录界面

访问 `http://<ip>:8081` 并使用 `admin` 账户进行登录。

- 配置代理

根据界面提示新增 `yum (proxy)` 类型代理，然后根据提示使用即可。
