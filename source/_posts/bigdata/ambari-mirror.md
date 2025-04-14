---
title: Ambari 本地源搭建流程整理
date: 2025-04-14 22:26:13
tags: "Ambari"
id: ambari-mirror
no_word_count: true
no_toc: false
categories: 大数据
---

## Ambari 本地源搭建流程整理

### 简介

> 注：Ambari 终于推出了 3.0 版本，使用 Bigtop 代替了 HDP 。

将公网上的 Ambari 软件源下载至本地可以满足在内网安装和下载加速的功能。

### 手动搭建方式

> 注：此处使用 RockLinux 9 作为安装平台。

安装 createrepo 包

```bash
sudo dnf install createrepo
```

创建存储库目录：

```bash
sudo mkdir -p /var/www/html/ambari-repo
sudo chmod -R 755 /var/www/html/ambari-repo
```

下载依赖包：

```bash
cd /var/www/html/ambari-repo
wget -r -np -nH --cut-dirs=4 --reject 'index.html*' https://www.apache-ambari.com/dist/ambari/<version>/rocky9/
wget -r -np -nH --cut-dirs=4 --reject 'index.html*' https://www.apache-ambari.com/dist/bigtop/<version>/rocky9/
```

> 注：对应信息参照官方文档即可

- 修改文件权限

```bash
chmod -R ugo+rX /var/www/html/ambari-repo
```

- 补充 repo(若出现 repo 访问异常)

> 注：进入报错的文件夹输入如下命令。

```bash
cd /var/www/html/ambari-repo
sudo createrepo -g repodata/repomd.xml .
```

创建存储库元数据：

```bash
cd /var/www/html/ambari-repo
sudo createrepo .
```

安装 Nginx ：

```bash
sudo dnf install nginx
```

编写配置文件： 

```bash
sudo tee /etc/nginx/conf.d/ambari-repo.conf << EOF
server {
    listen 80;
    server_name _;
    root /var/www/html/ambari-repo;
    autoindex on;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
```

启动 Nginx ：

```bash
sudo systemctl enable nginx --now
```

- 检查服务

```bash
curl <server_ip>/
```

若出现文件夹则证明环境搭建正常。

在客户机上创建存储库配置文件：

```bash
sudo tee /etc/yum.repos.d/ambari.repo << EOF
[ambari]
name=Ambari Repository
baseurl=http://<server_ip>/ambari-repo
gpgcheck=0
enabled=1
EOF
```

清理并更新 yum 缓存：

```bash
sudo dnf clean all
sudo dnf makecache
```

### 参考资料

[官方文档](https://ambari.apache.org/docs/3.0.0/quick-start/download)
