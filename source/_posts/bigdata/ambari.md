---
title: Ambari 搭建流程整理
date: 2025-04-14 22:26:13
tags: "Ambari"
id: ambari 
no_word_count: true
no_toc: false
categories: 大数据
---

## Ambari 搭建流程整理

本文只是简要描述了 Ambari 集群的搭建步骤，适用于测试和研发环境。如在安装过程中遇到问题可以参照 [官方文档](https://ambari.apache.org/docs/3.0.0/quick-start/environment-setup/bare-metal-kvm-setup) 。

> 注：在生产环境上需要开放对应服务端口，详情参照官方文档即可。

### 基础环境准备

在 Ambari 安装的所有主机上都需要执行以下命令

- 更新系统依赖，安装必备软件

```bash
dnf update -y
dnf install -y sudo openssh-server openssh-clients which iproute net-tools less vim-enhanced
dnf install -y wget curl tar unzip git
```

- 配置主机名

```bash
sudo hostnamectl set-hostname <hostname>
```

- 配置域内解析

```bash
sudo vim /etc/hosts
```

或者使用 DNS 。

- 配置网络主机名

```bash
sudo vim /etc/sysconfig/network
```

```text
HOSTNAME=<hostname>
```

- 关闭防火墙

```bash
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```

- 关闭 SELinux

```bash
sudo setenforce 0
sudo vim /etc/selinux/config
```

将状态设置为 `disable`

- 时钟同步

```bash
sudo dnf install -y ntp
sudo systemctl start ntpd --now
```

- 配置内存交换比例

```bash
sudo sysctl vm.swappiness=10
sudo echo "\nvm.swappiness=10" > /etc/sysctl.conf
```

- 配置THP

```bash
sudo echo never > /sys/kernel/mm/transparent_hugepage/defrag
sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled
sudo echo "\necho never > /sys/kernel/mm/transparent_hugepage/defrag\necho never > /sys/kernel/mm/transparent_hugepage/enabled\n" > /etc/rc.local
```

- JDK 安装及配置

```bash
sudo dnf install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
sudo alternatives --config java
```

- JDBC 配置

```bash
wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.28/mysql-connector-java-8.0.28.jar \
  -O /usr/share/java/mysql-connector-java.jar
```

- 安装软件源

> 注：此处需要修改为本地源

```bash
vim /etc/yum.repos.d/ambari.repo
```

```text
[ambari]
name=Ambari Repository
baseurl=http://<server_ip>/ambari-repo
gpgcheck=0
enabled=1
```

清理并更新 yum 缓存：

```bash
sudo dnf clean all
sudo dnf makecache
```

安装依赖：

```bash
sudo dnf install -y python3-distro
sudo dnf install -y java-17-openjdk-devel
sudo dnf install -y ambari-agent
```

### 安装数据库

在 Ambari 集群中需要寻找出一台设备来安装数据库：

- 安装数据库

```bash
sudo dnf install -y mariadb-server mariadb-devel mariadb
sudo systemctl enabel mariadb --now
```

> 注：也可以采用 MySQL 8.0

使用如下命令初始化数据库：

```sql
CREATE USER 'ambari'@'localhost' IDENTIFIED BY 'ambari';
GRANT ALL PRIVILEGES ON *.* TO 'ambari'@'localhost';
CREATE USER 'ambari'@'%' IDENTIFIED BY 'ambari';
GRANT ALL PRIVILEGES ON *.* TO 'ambari'@'%';
CREATE DATABASE ambari CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE hive;
CREATE DATABASE ranger;
CREATE DATABASE rangerkms;
CREATE USER 'hive'@'%' IDENTIFIED BY 'hive';
GRANT ALL PRIVILEGES ON hive.* TO 'hive'@'%';
CREATE USER 'ranger'@'%' IDENTIFIED BY 'ranger';
GRANT ALL PRIVILEGES ON *.* TO 'ranger'@'%' WITH GRANT OPTION;
CREATE USER 'rangerkms'@'%' IDENTIFIED BY 'rangerkms';
GRANT ALL PRIVILEGES ON rangerkms.* TO 'rangerkms'@'%';
FLUSH PRIVILEGES;
```

然后导入初始化 SQL 即可：

```bash
mysql -uambari -pambari ambari < /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql
```

若没找到 sql 文件可以 [下载 SQL](https://github.com/apache/ambari/blob/trunk/ambari-server/src/main/resources/Ambari-DDL-MySQL-CREATE.sql)

### 服务安装

在 Ambari 主机上执行如下命令：

```bash
ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar
echo "server.jdbc.url=jdbc:mysql://localhost:3306/ambari?useSSL=true&verifyServerCertificate=false&enabledTLSProtocols=TLSv1.2" \
  >> /etc/ambari-server/conf/ambari.properties
ambari-server setup -s \
  -j /usr/lib/jvm/java-1.8.0-openjdk \
  --ambari-java-home /usr/lib/jvm/java-17-openjdk \
  --database=mysql \
  --databasehost=localhost \
  --databaseport=3306 \
  --databasename=ambari \
  --databaseusername=ambari \
  --databasepassword=ambari
```

> 注：此处链接启用了 TLS 若链接失败可以尝试修改 jdbc 配置。 

启动服务：

```bash
ambari-server start
```

在其余节点上执行如下命令：

```bash
sed -i "s/hostname=.*/hostname=<leader_ip_address>/" /etc/ambari-agent/conf/ambari-agent.ini
ambari-agent start
```

等待 3 分钟之后检查 `http://<leader_ip_address>:8080` 页面是否正常响应即可。

> 注：默认账号 admin 密码 admin

主机错误检查：

```bash
tail -f /var/log/ambari-server/ambari-server.log
```

从机错误检查：

```bash
tail -f /var/log/ambari-server/ambari-agent.log
```
