---
title: CDH 搭建流程整理
date: 2020-12-03 22:26:13
tags: "CDH"
id: cdh 
no_word_count: true
no_toc: false
categories: 大数据
---

## CDH 搭建流程整理

### 简述

> 注：CDH 已经关闭了免费下载途径。此文档仅供参考。

本文只是简要描述了 CDH 集群的搭建步骤，适用于测试和研发环境。如在安装过程中遇到问题可以参照 [官方文档](https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/installation.html) 。

### 基础环境准备

在 CDH 安装的所有主机上都需要执行以下命令

- 配置主机名

```bash
hostnamectl set-hostname <hostname>
```

- 配置域内解析

```bash
vim /etc/hosts
```

或者使用 DNS 。

- 配置网络主机名

```bash
vim /etc/sysconfig/network
```

```text
HOSTNAME=<hostname>
```

- 关闭防火墙

```bash
systemctl stop firewalld
systemctl disable firewalld
```

- 关闭 SELinux

```bash
setenforce 0
vim /etc/selinux/config
```

将状态设置为 `disable`

- 时钟同步

```bash
yum install -y ntp
systemctl start ntpd
systemctl enable ntpd
```

- 配置内存交换比例

```bash
sysctl vm.swappiness=10
echo "\nvm.swappiness=10" > /etc/sysctl.conf
```

- 配置THP

```bash
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo "\necho never > /sys/kernel/mm/transparent_hugepage/defrag\necho never > /sys/kernel/mm/transparent_hugepage/enabled\n" > /etc/rc.local
```

- JDK 安装及配置

```bash
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
alternatives --config java
```

- JDBC 配置

```bash
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz
tar -zxvf mysql-connector-java-5.1.46.tar.gz
mkdir -p /usr/share/java/
cd mysql-connector-java-5.1.46
cp mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar
```

- 安装软件源

> 注：此处需要修改为本地源

```bash
vim /etc/yum.repos.d/clouder-scm.repo
```

```text
[cloudera-manager]
name=Cloudera Manager 6.3.1
baseurl=http://<server_ip>/cloudera-repos/cm6/6.3.1/redhat7/yum/
gpgkey=http://<server_ip>/cloudera-repos/cm6/6.3.1/redhat7/yum/RPM-GPG-KEY-cloudera
gpgcheck=0
enabled=1
autorefresh=0
type=rpm-md
```

### 安装数据库

在 CDH 集群中需要寻找出一台设备来安装数据库

> 注：Cloudera 官方建议数据库和需要用到持久化的软件安装在同一台设备上。

- 安装数据库

```bash
yum install -y mariadb-server mariadb-devel mariadb
systemctl enabel mariadb
systemctl start mariadb
```

- 创建用户和数据库

```bash
mysql
```

```sql
use mysql;
create user mariadb@'%' identified by '<password>';
grant all privileges on *.* to mariadb@'%' identified by '123456';
flush privileges;
CREATE DATABASE scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE amon DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE rman DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE hue DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE metastore DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE sentry DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE nav DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE navms DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE oozie DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
```

> 注：数据库对应关系参见[官方文档](https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/install_cm_mariadb.html#install_cm_mariadb)

- 初始化数据库

```bash
/opt/cloudera/cm/schema/scm_prepare_database.sh -h <db_host> mysql scm mariadb <password>
```

### 服务安装

在 CDH 主机上执行下列命令

- 安装软件

```bash
yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server
```

- 启动服务

```bash
systemctl start cloudera-scm-server
systemctl enable cloudera-scm-server
```

等待3分钟之后检查 `http://<ip_address>:7180` 页面是否正常响应即可。

- 错误检查

```bash
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
```

### 服务增强

#### Oozie WebUI

- 根据界面提示安装软件

- 下载依赖包

```bash
wget http://archive.cloudera.com/gplextras/misc/ext-2.2.zip -P /var/lib/oozie
```

- 解压并修改权限

```bash
yum install -y unzip
cd /var/lib/oozie/
unzip ext-2.2.zip
chown -R oozie:oozie ext-2.2
```

### 数据备份及恢复

#### 备份

```bash
curl -u <admin_username>:<admin_password> "http://<cm_server_host>:7180/api/v32/cm/deployment" > cm-deployment.json
```

#### 恢复

> 注：此处功能需要企业版授权才可以使用。

- 关闭集群

- 登录 Cloudera Manager Server 所在设备

```bash
curl -H "Content-Type: application/json" --upload-file cm-deployment.json -u <admin_username>:<admin_password> http://<cm_server_host>:7180/api/v32/cm/deployment?deleteCurrentDeployment=true
```
