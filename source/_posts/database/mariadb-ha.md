---
title: MariaDB HA 搭建流程整理
date: 2020-12-10 23:09:32
tags: "MariaDB"
id: mariadb-ha
no_word_count: true
no_toc: false
categories: "MariaDB"
---

## MariaDB HA 搭建流程整理

### 简介

本次搭建采用 主从同步 + KeepAlived 方案实现。两台设备分别为 `mariadb1`,`mariadb2`

### 主主互备

- 软件安装

```bash
yum install mariadb-server
```

- 服务配置

```bash
vim /etc/my.cmf
```

```text
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
max_connections=1000
log-bin=mysql-bin
server-id=1
binlog_format=MIXED

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
```

> 注: 此处的 server-id 需要配置成不一样的值。

- 配置 [Open Files Limit](https://mariadb.com/kb/en/systemd/#configuring-the-open-files-limit)

```bash
systemctl edit mariadb.service
```

```text
[Service]

LimitNOFILE=infinity
```

- 启动服务

```bash
systemctl enable mariadb --now
```

- 创建用户

```sql
create user mysync@'%' identified by '123456';
grant REPLICATION SLAVE ON *.* to mysync@'%';
FLUSH PRIVILEGES;
```

- 检查数据状态

```sql
show master status;
```

- 配置从机同步(A->B 和 B->A)

```sql
use mysql;
change master to
master_host='<mariadb2>',
master_user='mysync',
master_password='123456',
master_log_file='<mariadb2_file>',
master_log_pos=<mariadb2_pos>;
start slave;
```

```sql
use mysql;
change master to
master_host='<mariadb1>',
master_user='mysync',
master_password='123456',
master_log_file='<mariadb1_file>',
master_log_pos=<mariadb1_pos>;
start slave;
```

> 注：master_log_pos 和 master_log_file 要从主机的数据状态当中获得。

- 状态检查

```sql
show slave status;
```

如果观察到如下内容则代表配置正常。

```text
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
```

### Keepalived

- 安装软件

```bash
yum -y install keepalived
```

- 编写检测脚本(所有设备)

```bash
vim /etc/keepalived/check_mysql.sh
```

```bash
#!/bin/bash

MYSQL_PING=`mysqladmin ping`
MYSQL_OK="mysqld is alive"
if [[ "$MYSQL_PING" != "$MYSQL_OK" ]]
   then
      echo "mysql is not running"
      killall keepalived
    else
      echo "mysql is running"
fi
```

```bash
chmod +x /etc/keepalived/check_mysql.sh
```

- 获取网卡信息

```bash
nmcli connection show
```

> 注：获取到的网卡名需要填入下一步的配置文件中，两台设备都记得要检查

- 配置 Keepalived 服务 (主要节点)

> 注：配置中的 interface 要指定当前的网卡，并且需要根据设备优先级设定 priority，且虚拟 IP 地址要与目前 IP 不冲突。

```bash
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bk
vim /etc/keepalived/keepalived.conf 
```

```text
! Configuration File for keepalived
global_defs {
}
vrrp_script check_mysql {
  script "/etc/keepalived/check_mysql.sh"
  interval 2
}
vrrp_instance VI_1 {
  state BACKUP
  interface <name>
  virtual_router_id 51
  priority 100
  advert_int 1
  nopreempt
  authentication {
    auth_type PASS
    auth_pass 1111
  }
  virtual_ipaddress {
    <virtual_ip>
  }
  track_script {
    check_mysql
  }
}
```

- 配置 Keepalived 服务 (次要节点)

```bash
vim /etc/keepalived/keepalived.conf 
```

```text
! Configuration File for keepalived
global_defs {
}
vrrp_script check_mysql {
  script "/etc/keepalived/check_mysql.sh"
  interval 2
}
vrrp_instance VI_1 {
  state BACKUP
  interface <name>
  virtual_router_id 51
  priority 90
  advert_int 1
  nopreempt
  authentication {
    auth_type PASS
    auth_pass 1111
  }
  virtual_ipaddress {
    <virtual_ip>
  }
  track_script {
    check_mysql
  }
}
```

- 启动服务

```bash
systemctl enable keepalived --now
```

- 运行状态检测

使用 `ping <virtual_ip>` 可以用来检测服务运行情况

在 keepalived 的设备上输入 `ip a` 然后检查绑定的网卡上是否存在 IP 挂载的情况即可。

### 常见问题

#### keepalived.pid 文件不存在

如果出现了 `keepalived.pid` 文件不存在而引发的服务运行异常，请检查 `/etc/keepalived` 目录中是否有正确的配置文件。

#### 网卡配置调整

在网卡经过配置后虚拟 IP 连接异常

> 注：在网卡相关信息有修改的时候需要重启 keepalived 服务。

```bash
systemctl restart keepalived
```
