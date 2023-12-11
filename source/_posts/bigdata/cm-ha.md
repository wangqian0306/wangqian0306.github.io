---
title: Cloudera Manager HA 搭建流程整理
date: 2020-12-03 22:26:13
tags: "CDH"
id: cm-ha
no_word_count: true
no_toc: false
categories: 大数据
---

## Cloudera Manager HA 搭建流程整理

### 简介

Cloudera Manager 有以下五个部分：

- Cloudera Manager Server
- Cloudera Management Service
    - Activity Monitor
    - Alert Publisher
    - Event Server
    - Host Monitor
    - Service Monitor
    - Reports Manager
    - Cloudera Navigator Audit Server
- 关系型数据库
- 文件存储
- Cloudera Manager Agent

> 注：目前 Cloudera Manager 的 HA 方式是采用负载均衡器实现的且目前仅支持主备的HA方案，并不支持双活。HAProxy 和 NFS 等服务的 HA 在 Cloudera 官方文档中并未进行说明。

为了实现 HA 的效果需要如下三种服务

- HAProxy (端口转发)
- NFS(文件同步)
- Pacemaker, Corosync (故障转移)

![cm-ha](https://docs.cloudera.com/documentation/enterprise/6/6.3/images/cm_ha_lb_setup.png)

注意事项：

- 不要在现有 CDH 集群中的任何主机上托管 Cloudera Manager 或 Cloudera Management Service 角色，因为这会使故障转移配置变得复杂，并且重叠的故障域可能导致故障和错误跟踪的问题。
- 采用相同配置的硬件设备部署主备服务。这样做能确保故障转移不会导致性能下降。
- 为主机和备机配置不同的电源和网络，这样做能限制重叠的故障域。
- 其中 Cloudera Management Service 所在设备会有 Hostname 修改,CDH 集群会无法对其进行管理故不能安装任何大数据组件。
- 本次部署时的 NFS 服务不能搭建在 MGMT 主机上。

为了方便说明，下面将采用如下所示的简写

|简写|主机|
|:---:|:---:|
|CMS|CMSHostname|
|MGMT|MGMTHostname|
|NFS|NFS Store|
|DB|Databases|

如果在配置过程中遇到了问题请参阅 [官方文档](https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/admin_cm_ha_steps.html)

### 前置准备

如果之前已经安装了 CDH 集群则需要在界面上停止集群并且使用如下命令关闭集群和服务。

```bash
systemctl stop cloudera-scm-server
sysyemctl stop cloudera-scm-agent
```

并且在新部署的设备上执行如下命令：

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

```bash
wget https://archive.cloudera.com/cm6/6.3.1/redhat7/yum/cloudera-manager.repo -P /etc/yum.repos.d/
rpm --import https://archive.cloudera.com/cm6/6.3.1/redhat7/yum/RPM-GPG-KEY-cloudera
```

### CMS 配置

- 安装服务

```bash
yum install haproxy -y
```

- 服务初始化配置(可选)

```bash
vim /etc/haproxy/haproxy.cfg
```

在服务检测部分有转发限定的相关的配置，为了方便测试可以通过注释下面的内容来关闭此项检测

```text
option forwardfor       except 127.0.0.0/8
```

在服务安装完成后内部存在默认样例，在实际环境中可以注释如下内容关闭此样例

```text
frontend  main *:5001
    acl url_static       path_beg       -i /static /images /javascript /stylesheets
    acl url_static       path_end       -i .jpg .gif .png .css .js

    use_backend static          if url_static
    default_backend             app
```

```text
backend static
    balance     roundrobin
    server      static 127.0.0.1:4331 check
```

```text
backend app
    balance     roundrobin
    server  app1 127.0.0.1:5001 check
    server  app2 127.0.0.1:5002 check
    server  app3 127.0.0.1:5003 check
    server  app4 127.0.0.1:5004 check
```

- 关闭 SE-Linux

```bash
setenforce 0
vim /etc/selinux/config
```

- 开放连接

```bash
setsebool -P haproxy_connect_any=1
```

- 编辑 HAProxy 配置文件

```bash
vim /etc/haproxy/haproxy.cnf
```

- Cloudera Manager Server 端口转发配置

```text
listen cmf :7180
    mode tcp
    option tcplog
    server cmfhttp1 <CMS1>:7180 check
    server cmfhttp2 <CMS2>:7180 check

listen cmfavro :7182
    mode tcp
    option tcplog
    server cmfavro1 <CMS1>:7182 check
    server cmfavro2 <CMS2>:7182 check

listen cmfhttps :7183
    mode tcp
    option tcplog
    server cmfhttps1 <CMS1>:7183 check
    server cmfhttps2 <CMS2>:7183 check
```

- 检测配置项

```bash
haproxy -f /etc/haproxy/haproxy.cfg -c
```

- 启动服务

```bash
systemctl enable haproxy --now
```

### MGMT 配置

- 安装服务

```bash
yum install haproxy -y
```

- 服务初始化配置(可选)

```bash
vim /etc/haproxy/haproxy.cfg
```

在服务检测部分有转发限定的相关的配置，为了方便测试可以通过注释下面的内容来关闭此项检测

```text
option forwardfor       except 127.0.0.0/8
```

在服务安装完成后内部存在默认样例，在实际环境中可以注释如下内容关闭此样例

```text
frontend  main *:5001
    acl url_static       path_beg       -i /static /images /javascript /stylesheets
    acl url_static       path_end       -i .jpg .gif .png .css .js

    use_backend static          if url_static
    default_backend             app
```

```text
backend static
    balance     roundrobin
    server      static 127.0.0.1:4331 check
```

```text
backend app
    balance     roundrobin
    server  app1 127.0.0.1:5001 check
    server  app2 127.0.0.1:5002 check
    server  app3 127.0.0.1:5003 check
    server  app4 127.0.0.1:5004 check
```

- 关闭 SE-Linux

```bash
setenforce 0
vim /etc/selinux/config
```

- 开放连接

```bash
setsebool -P haproxy_connect_any=1
```

- 编辑 HAProxy 配置文件

```bash
vim /etc/haproxy/haproxy.cfg
```

- Activity Monitor 端口转发配置

```text
listen am1 :8087
    mode tcp
    option tcplog
    server am1a <MGMT1>:8087 check
    server am1b <MGMT2>:8087 check
listen am2 :9087
    mode tcp
    option tcplog
    server am2a <MGMT1>:9087 check
    server am2b <MGMT2>:9087 check
listen am3 :9998
    mode tcp
    option tcplog
    server am3a <MGMT1>:9998 check
    server am3b <MGMT2>:9998 check
listen am4 :9999
    mode tcp
    option tcplog
    server am4a <MGMT1>:9999 check
    server am4b <MGMT2>:9999 check
```

- Alert Publisher 端口转发配置

```text
listen ap1 :10101
    mode tcp
    option tcplog
    server ap1a <MGMT1>:10101 check
    server ap1b <MGMT2>:10101 check
```

- Event Server 端口转发配置

```text
listen es1 :7184
    mode tcp
    option tcplog
    server es1a <MGMT1>:7184 check
    server es1b <MGMT2>:7184 check
listen es2 :7185
    mode tcp
    option tcplog
    server es2a <MGMT1>:7185 check
    server es2b <MGMT2>:7185 check
listen es3 :8084
    mode tcp
    option tcplog
    server es3a <MGMT1>:8084 check
    server es3b <MGMT2>:8084 check
```

- Host Monitor 端口转发配置

```text
listen hm1 :8091
    mode tcp
    option tcplog
    server hm1a <MGMT1>:8091 check
    server hm1b <MGMT2>:8091 check
listen hm2 :9091
    mode tcp
    option tcplog
    server hm2a <MGMT1>:9091 check
    server hm2b <MGMT2>:9091 check
listen hm3 :9994
    mode tcp
    option tcplog
    server hm3a <MGMT1>:9994 check
    server hm3b <MGMT2>:9994 check
listen hm4 :9995
    mode tcp
    option tcplog
    server hm4a <MGMT1>:9995 check
    server hm4b <MGMT2>:9995 check
```

- Service Monitor 端口转发配置

```text
listen sm1 :8086
    mode tcp
    option tcplog
    server sm1a <MGMT1>:8086 check
    server sm1b <MGMT2>:8086 check
listen sm2 :9086
    mode tcp
    option tcplog
    server sm2a <MGMT1>:9086 check
    server sm2b <MGMT2>:9086 check
listen sm3 :9996
    mode tcp
    option tcplog
    server sm3a <MGMT1>:9996 check
    server sm3b <MGMT2>:9996 check
listen sm4 :9997
    mode tcp
    option tcplog
    server sm4a <MGMT1>:9997 check
    server sm4b <MGMT2>:9997 check
```

- Cloudera Manager Agent  端口转发配置

```text
listen mgmt-agent :9000
    mode tcp
    option tcplog
    server mgmt-agenta <MGMT1>:9000 check
    server mgmt-agentb <MGMT2>:9000 check
```

- Reports Manager 端口转发配置

```text
listen rm1 :5678
    mode tcp
    option tcplog
    server rm1a <MGMT1>:5678 check
    server rm1b <MGMT2>:5678 check
listen rm2 :8083
    mode tcp
    option tcplog
    server rm2a <MGMT1>:8083 check
    server rm2b <MGMT2>:8083 check
```

- Cloudera Navigator Audit Server 端口转发配置

```text
listen cn1 :7186
    mode tcp
    option tcplog
    server cn1a <MGMT1>:7186 check
    server cn1b <MGMT2>:7186 check
listen cn2 :7187
    mode tcp
    option tcplog
    server cn2a <MGMT1>:8083 check
    server cn2b <MGMT2>:8083 check
listen cn3 :8089
    mode tcp
    option tcplog
    server cn3a <MGMT1>:8089 check
    server cn3b <MGMT2>:8089 check
```

- 检测配置项

```bash
haproxy -f /etc/haproxy/haproxy.cfg -c
```

- 启动服务

```bash
systemctl enable haproxy --now
```

- 检查服务状态

```bash
systemctl status haproxy
```

### NFS 配置

> 注：NFS 设备最好搭建在 CDH 集群之外，方便后期维护。

- 服务安装

```bash
yum install -y nfs-utils
```

- 创建挂载文件夹

```bash
mkdir -p /home/cloudera-scm-server
mkdir -p /home/cloudera-host-monitor
mkdir -p /home/cloudera-scm-agent
mkdir -p /home/cloudera-scm-eventserver
mkdir -p /home/cloudera-scm-headlamp
mkdir -p /home/cloudera-service-monitor
mkdir -p /home/cloudera-scm-navigator
mkdir -p /home/etc-cloudera-scm-agent
mkdir -p /home/cloudera-scm-csd
```

- 编写连接配置文件

```bash
vim /etc/exports.d/cloudera-manager.exports
```

填入如下内容

```text
/home/cloudera-scm-server *(rw,sync,no_root_squash,no_subtree_check)
/home/cloudera-host-monitor *(rw,sync,no_root_squash,no_subtree_check)
/home/cloudera-scm-agent *(rw,sync,no_root_squash,no_subtree_check)
/home/cloudera-scm-eventserver *(rw,sync,no_root_squash,no_subtree_check)
/home/cloudera-scm-headlamp *(rw,sync,no_root_squash,no_subtree_check)
/home/cloudera-service-monitor *(rw,sync,no_root_squash,no_subtree_check)
/home/cloudera-scm-navigator *(rw,sync,no_root_squash,no_subtree_check)
/home/etc-cloudera-scm-agent *(rw,sync,no_root_squash,no_subtree_check)
/home/cloudera-scm-csd *(rw,sync,no_root_squash,no_subtree_check)
```

- 启动服务

```bash
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=nfs
firewall-cmd --reload
systemctl enable rpcbind --now
systemctl enable nfs --now
```

- 查看服务运行状态

```bash
showmount -e
```

若显示的出上文中配置的文件夹则证明服务运行正常，如果遇到问题可以试试下面的命令。

- 刷新挂载列表

```bash
exportfs -a
```

### Cloudera Manager Server 偏移测试

在完成上述内容后就可以进行 Cloudera Manager Server 偏移测试了。

**千万注意主备不能同时启动，如果主备同时启动可能损坏数据库**

#### CMS 1 配置（主）

- 安装服务并初始化数据库

若 CMS 1 之前已经安装过了 Cloudera Manager Server 则可以跳过此步骤。

```bash
yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server
/opt/cloudera/cm/schema/scm_prepare_database.sh -h <db_host> mysql scm mariadb <password>
```

- 安装 NFS

```bash
yum install -y nfs-utils
```

- 拷贝原有文件

若 CMS 1 没有装过 Cloudera Manager Server 则可以执行如下命令将配置文件备份传输至  NFS 服务器。

```bash
scp -r /var/lib/cloudera-scm-server/* <user>@<NFS>:/home/cloudera-scm-server/
```

> 注：如果 CDH 集群中安装过扩展 Parcels 则需要同步主备两台设备上的 csd 授权文件。具体位置位于  Administration > Settings > Custom Service Descriptors > Local Descriptor Repository Path。

- 创建挂载目录

```bash
rm -rf /var/lib/cloudera-scm-server
mkdir -p /var/lib/cloudera-scm-server
```

- 挂载存储目录

```bash
mount -t nfs <NFS>:/home/cloudera-scm-server /var/lib/cloudera-scm-server
```

- 配置开机挂载

```bash
vim /etc/fstab
```

填入如下内容

```text
<NFS>:/home/cloudera-scm-server /var/lib/cloudera-scm-server nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
```

- 启动服务

```bash
systemctl start cloudera-scm-server
```

- 检查服务状态

访问 `http://<CMS1>:7180` 查看服务运行情况

- 关闭 HTTP Referer Check

进入 `Administration`->`Settings`->`Category`->`Security` 配置中

关闭 `HTTP Referer Check` 属性

- 检查负载均衡服务状态

访问 `http://<CMS>:7180` 查看服务运行情况

- 关闭主机

```bash
systemctl stop cloudera-scm-server
```

#### CMS 2 配置（备）

- 安装服务

```bash
yum install -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server
```

- 安装 NFS

```bash
yum install -y nfs-utils
```

- 创建挂载目录

```bash
rm -rf /var/lib/cloudera-scm-server
mkdir -p /var/lib/cloudera-scm-server
```

- 挂载存储目录

```bash
mount -t nfs <NFS>:/home/cloudera-scm-server /var/lib/cloudera-scm-server
```

- 配置开机挂载

```bash
vim /etc/fstab
```

填入如下内容

```text
<NFS>:/home/cloudera-scm-server /var/lib/cloudera-scm-server nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
```

- 拷贝数据库配置文件

```bash
mkdir -p /etc/cloudera-scm-server
scp <ssh-user>@<CMS1>:/etc/cloudera-scm-server/db.properties /etc/cloudera-scm-server/db.properties
```

- 关闭开机启动

```bash
systemctl disable cloudera-scm-server
```

- 启动备机

```bash
systemctl start cloudera-scm-server
```

- 检查服务状态

访问 `http://CMS2:7180` 查看服务运行情况

- 检查负载均衡服务状态

访问 `http://CMS:7180` 查看服务运行情况

- 关闭备机

```bash
systemctl stop cloudera-scm-server
```

- 完成测试

在备机关闭完成后，需要返回至主机，开启**主机**上的 `cloudera-scm-server` 服务

```bash
systemctl start cloudera-scm-server
```

#### Agent 配置

- 修改 Agent 连接的目标主机

修改 CDH 集群中除了 MGMT1,MGMT2,CMS1,CMS2 设备上的所有 Agent 配置

```bash
vim /etc/cloudera-scm-agent/config.ini
```

修改如下配置项：

```text
server_host=<CMS>
```

- 重启 Agent 服务

```bash
systemctl restart cloudera-scm-agent
```

### Cloudera Mangement Service 偏移测试

由于 Cloudera Management Service 当中存储的内容没什么用，所以此处采用了删除重新安装的方式。

#### MGMT 1  配置

- 安装服务

```bash
yum install -y cloudera-manager-daemons cloudera-manager-agent
```

- 拷贝配置文件至 NFS

```bash
scp -R /etc/cloudera-scm-agent <user>@<NFS>:/home/etc-cloudera-scm-agent
```

- 安装 NFS

```bash
yum install -y nfs-utils
```

- 创建存储目录

```bash
mkdir -p /var/lib/cloudera-host-monitor
mkdir -p /var/lib/cloudera-scm-agent
mkdir -p /var/lib/cloudera-scm-eventserver
mkdir -p /var/lib/cloudera-scm-headlamp
mkdir -p /var/lib/cloudera-service-monitor
mkdir -p /var/lib/cloudera-scm-navigator
mkdir -p /etc/cloudera-scm-agent
```

- 挂载存储目录

```bash
mount -t nfs <NFS>:/home/cloudera-host-monitor /var/lib/cloudera-host-monitor
mount -t nfs <NFS>:/home/cloudera-scm-agent /var/lib/cloudera-scm-agent
mount -t nfs <NFS>:/home/cloudera-scm-eventserver /var/lib/cloudera-scm-eventserver
mount -t nfs <NFS>:/home/cloudera-scm-headlamp /var/lib/cloudera-scm-headlamp
mount -t nfs <NFS>:/home/cloudera-service-monitor /var/lib/cloudera-service-monitor
mount -t nfs <NFS>:/home/cloudera-scm-navigator /var/lib/cloudera-scm-navigator
mount -t nfs <NFS>:/home/etc-cloudera-scm-agent /etc/cloudera-scm-agent
```

- 配置开机挂载

```bash
vim /etc/fstab
```

填入如下内容

```text
<NFS>:/home/cloudera-host-monitor /var/lib/cloudera-host-monitor nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/cloudera-scm-agent /var/lib/cloudera-scm-agent nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/cloudera-scm-eventserver /var/lib/cloudera-scm-eventserver nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/cloudera-scm-headlamp /var/lib/cloudera-scm-headlamp nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/cloudera-service-monitor /var/lib/cloudera-service-monitor nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/cloudera-scm-navigator /var/lib/cloudera-scm-navigator nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/etc-cloudera-scm-agent /etc/cloudera-scm-agent nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
```

- 修改 Agent 配置

```bash
vim /etc/cloudera-scm-agent/config.ini
```

修改如下配置项

```bash
server_host=<CMS>
listening_hostname=<MGMT>
```

- 配置 Hosts

```bash
vim /etc/hosts
```

新增如下内容

```text
<MGMT1_IP> <MGMT>
```

- 检查 Hosts

```bash
ping <MGMT>
```

若目标地址 IP 与 MGMT1_IP(本机 IP) 相同则证明配置无误。

- 配置 UID 和 GID

> 注：此处需要和 MGMT1 完成统一配置且与两台设备的其他服务不冲突。

检查设备上`cloudera-scm`用户的 UID 和 GID

```bash
cat /etc/passwd
```

配置设备上的 UID 和 GID

```bash
usermod -u <UID> cloudera-scm
groupmod -g <UID> cloudera-scm
```

检查之前用户的遗留文件夹

```bash
find / -user <UID_Origin> -type d
```

切换权限至当前用户

```bash
chown -R cloudear-scm:cloudear-scm <dir>
```

- 修改文件夹所属用户

```bash
chown -R cloudera-scm:cloudera-scm /var/lib/cloudera-scm-eventserver
chown -R cloudera-scm:cloudera-scm /var/lib/cloudera-scm-navigator
chown -R cloudera-scm:cloudera-scm /var/lib/cloudera-service-monitor
chown -R cloudera-scm:cloudera-scm /var/lib/cloudera-host-monitor
chown -R cloudera-scm:cloudera-scm /var/lib/cloudera-scm-agent
chown -R cloudera-scm:cloudera-scm /var/lib/cloudera-scm-headlamp
```

- 启动服务

```bash
systemctl restart cloudera-scm-agent
```

- 检查注册情况

访问 `http://<CMS>:7180` 查看主机列表，若 `<MGMT>` 出现在列表中则证明安装成功。

- 删除并重新安装服务

在页面当中删除 `Cloudera Management Service` 服务，然后点击右上角的 `Add` 按钮在新设备上安装服务

- 关闭 MGMT系列设备上的 Hostname 检查

由于此处采用了 Hosts 文件完成了解析所以需要根据页面上的红色提示关闭 Hostname 检查

- 服务启动测试

在安装完成后需要开启集群和`Cloudera Management Service` 服务进行检查。

- 关闭服务

在界面上关闭集群和 `Cloudera Management Service` 服务

- 关闭 Agent 服务

```bash
systemctl stop cloudera-scm-agent
```

#### MGMT 2 配置

- 安装服务

```bash
yum install -y cloudera-manager-daemons cloudera-manager-agent
```

- 安装 NFS

```bash
yum install -y nfs-utils
```

- 挂载存储目录

```bash
mount -t nfs <NFS>:/home/cloudera-host-monitor /var/lib/cloudera-host-monitor
mount -t nfs <NFS>:/home/cloudera-scm-agent /var/lib/cloudera-scm-agent
mount -t nfs <NFS>:/home/cloudera-scm-eventserver /var/lib/cloudera-scm-eventserver
mount -t nfs <NFS>:/home/cloudera-scm-headlamp /var/lib/cloudera-scm-headlamp
mount -t nfs <NFS>:/home/cloudera-service-monitor /var/lib/cloudera-service-monitor
mount -t nfs <NFS>:/home/cloudera-scm-navigator /var/lib/cloudera-scm-navigator
mount -t nfs <NFS>:/home/etc-cloudera-scm-agent /etc/cloudera-scm-agent
```

- 配置开机挂载

```bash
vim /etc/fstab
```

填入如下内容

```text
<NFS>:/home/cloudera-host-monitor /var/lib/cloudera-host-monitor nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/cloudera-scm-agent /var/lib/cloudera-scm-agent nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/cloudera-scm-eventserver /var/lib/cloudera-scm-eventserver nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/cloudera-scm-headlamp /var/lib/cloudera-scm-headlamp nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/cloudera-service-monitor /var/lib/cloudera-service-monitor nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/cloudera-scm-navigator /var/lib/cloudera-scm-navigator nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
<NFS>:/home/etc-cloudera-scm-agent /etc/cloudera-scm-agent nfs auto,noatime,nolock,intr,tcp,actimeo=1800 0 0
```

- 修改 Agent 配置

```bash
vim /etc/cloudera-scm-agent/config.ini
```

修改如下配置项

```bash
server_host=<CMS>
listening_hostname=<MGMT>
```

- 配置 Hosts

```bash
vim /etc/hosts
```

新增如下内容

```text
<MGMT2_IP> <MGMT>
```

- 检查 Hosts

```bash
ping <MGMT>
```

若目标地址 IP 与 MGMT2_IP(本机 IP) 相同则证明配置无误。

- 配置 UID 和 GID

> 注：此处需要和 MGMT1 完成统一配置且与两台设备的其他服务不冲突。

检查设备上`cloudera-scm`用户的 UID 和 GID

```bash
cat /etc/passwd
```

配置设备上的 UID 和 GID

```bash
usermod -u <UID> cloudera-scm
groupmod -g <UID> cloudera-scm
```

- 启动服务

```bash
systemctl start cloudera-scm-agent
```

> 注：如果因为用户修改的情况造成启动失败，可以尝试重启设备。

- 检查注册情况

访问 `http://<CMS>:7180` 查看主机列表，若 `<MGMT>` 出现在列表中并且 IP 地址变为了 `MGMT2_IP`则证明安装成功。

- 服务启动测试

在页面上启动 `Cloudera Management Service` 服务，然后在本机执行下列语句查看是否服务运行在本机上。

```bash
ps -elf | grep "scm"
```

- 关闭服务

在页面上关闭服务，然后输入如下命令关闭备机上的所有服务。

```bash
systemctl stop cloudera-scm-agent
```

- 完成测试

在备机关闭完成后，需要返回至主机，开启**主机**上的 `cloudera-scm-agent` 服务

```bash
systemctl start cloudera-scm-agent
```

### 故障检测配置

在 CMS1,CMS2,MGMT1,MGMT2 四台设备上都需要执行下面的命令：

- 安装软件

```bash
wget http://download.opensuse.org/repositories/network:/ha-clustering:/Stable/CentOS_CentOS-7/network:ha-clustering:Stable.repo -P /etc/yum.repos.d/
yum install -y pacemaker corosync crmsh
```

- `corosync` 配置

如果存在 `/etc/default/corosync` 文件则需要修改如下配置项

```text
START=yes
```

- 关闭`corosync`开机启动

```bash
systemctl disable corosync
```

#### CMS1 和 CMS 2

- 编辑 `corosync` 配置文件

```bash
vim /etc/corosync/corosync.conf
```

```text
totem {
version: 2
secauth: off
cluster_name: cmf
transport: udpu
}

nodelist {
  node {
        ring0_addr: <CMS1>
        nodeid: 1
       }
  node {
        ring0_addr: <CMS2>
        nodeid: 2
       }
}

quorum {
provider: corosync_votequorum
two_node: 1
}
```

- 创建检测脚本

```bash
vim /etc/rc.d/init.d/cloudera-scm-server
```

填入如下内容：

```text
#!/bin/bash

case "$1" in
  start)
        systemctl start cloudera-scm-server.service
        ;;
  stop)
        systemctl stop cloudera-scm-server.service
        ;;
  status)
        systemctl status -l cloudera-scm-server.service
        ;;
  restart)
        systemctl restart cloudera-scm-server.service
        ;;
  *)
        echo '$1 = start|stop|status|restart'
        ;;
esac
```

- 修改脚本权限

```bash
chmod 755 /etc/rc.d/init.d/cloudera-scm-server
```

- 启动服务

```bash
systemctl start corosync
systemctl enab corosync
```

- 关闭 `cloudera-scm-server` 服务自启动和服务

```bash
systemctl disable cloudera-scm-server
systemctl stop cloudera-scm-server
```

- 启动 `pacemaker`

```bash
systemctl start pacemaker
systemctl enable pacemaker
```

- 检查节点状态

```bash
crm status
```

若 CMS1 和 CMS2 都处在节点列表中则证明配置正确。

- 配置 `pacemaker`

```bash
crm configure property no-quorum-policy=ignore
crm configure property stonith-enabled=false
crm configure rsc_defaults resource-stickiness=100
```

- 将 `cloudera-scm-server` 进行托管

```bash
crm configure primitive cloudera-scm-server lsb:cloudera-scm-server
```

> 注：此处在第二台设备中运行此命令时提示任务已经存在。

- 启动服务

```bash
crm resource start cloudera-scm-server
```

- 检测服务状态

```bash
crm status
```

然后访问 `http://<CMS>:7180` 检查服务运行状态。

- 测试服务迁移

```bash
crm resource move cloudera-scm-server <CMS2>
```

- 检测服务状态

```bash
crm status
```

然后访问 `http://<CMS>:7180` 检查服务运行状态。

> 注：在迁移完成后建议到备机上检测服务运行状态，确保服务运行正常。

#### MGMT1 和 MGMT2

- 编辑 `corosync` 配置文件

```bash
vim /etc/corosync/corosync.conf
```

```text
totem {
version: 2
secauth: off
cluster_name: mgmt
transport: udpu
}

nodelist {
  node {
        ring0_addr: <MGMT1>
        nodeid: 1
       }
  node {
        ring0_addr: <MGMT2>
        nodeid: 2
       }
}

quorum {
provider: corosync_votequorum
two_node: 1
}
```

- 创建检测脚本

```bash
vim /etc/rc.d/init.d/cloudera-scm-agent
```

填入如下内容：

```text
#!/bin/bash

case "$1" in
  start)
        systemctl start cloudera-scm-agent.service
        ;;
  stop)
        systemctl stop cloudera-scm-agent.service
        ;;
  status)
        systemctl status -l cloudera-scm-agent.service
        ;;
  restart)
        systemctl restart cloudera-scm-agent.service
        ;;
  *)
        echo '$1 = start|stop|status|restart'
        ;;
esac
```

- 修改脚本权限

```bash
chmod 755 /etc/rc.d/init.d/cloudera-scm-agent
```

- 启动服务

```bash
systemctl start corosync
systemctl enable corosync
```

- 关闭 `cloudera-scm-agent` 服务自启动和服务

```bash
systemctl disable cloudera-scm-agent
systemctl stop cloudera-scm-agent
```

- 启动 `pacemaker`

```bash
systemctl start pacemaker
systemctl enable pacemaker
```

- 检查节点状态

```bash
crm status
```

若 MGMT1 和 MGMT2 都处在节点列表中则证明配置正确。

- 配置 `pacemaker`

```bash
crm configure property no-quorum-policy=ignore
crm configure property stonith-enabled=false
crm configure rsc_defaults resource-stickiness=100
```

- 创建 OCF( Open Cluster Framework)

```bash
mkdir -p /usr/lib/ocf/resource.d/cm
```

- 编辑配置文件

```bash
vim /usr/lib/ocf/resource.d/cm/agent
```

填入如下内容：

```text
#!/bin/sh
#######################################################################
# CM Agent OCF script
#######################################################################
#######################################################################
# Initialization:
: ${__OCF_ACTION=$1}
OCF_SUCCESS=0
OCF_ERROR=1
OCF_STOPPED=7
#######################################################################

meta_data() {
        cat <<END
<?xml version="1.0"?>
<!DOCTYPE resource-agent SYSTEM "ra-api-1.dtd">
<resource-agent name="Cloudera Manager Agent" version="1.0">
<version>1.0</version>

<longdesc lang="en">
 This OCF agent handles simple monitoring, start, stop of the Cloudera
 Manager Agent, intended for use with Pacemaker/corosync for failover.
</longdesc>
<shortdesc lang="en">Cloudera Manager Agent OCF script</shortdesc>

<parameters />

<actions>
<action name="start"        timeout="20" />
<action name="stop"         timeout="20" />
<action name="monitor"      timeout="20" interval="10" depth="0"/>
<action name="meta-data"    timeout="5" />
</actions>
</resource-agent>
END
}

#######################################################################

agent_usage() {
cat <<END
 usage: $0 {start|stop|monitor|meta-data}
 Cloudera Manager Agent HA OCF script - used for managing Cloudera Manager Agent and managed processes lifecycle for use with Pacemaker.
END
}

agent_start() {
    systemctl start cloudera-scm-agent
    if [ $? =  0 ]; then
        return $OCF_SUCCESS
    fi
    return $OCF_ERROR
}

agent_stop() {
    systemctl stop cloudera-scm-agent
    if [ $? =  0 ]; then
        return $OCF_SUCCESS
    fi
    return $OCF_ERROR
}

agent_monitor() {
        # Monitor _MUST!_ differentiate correctly between running
        # (SUCCESS), failed (ERROR) or _cleanly_ stopped (NOT RUNNING).
        # That is THREE states, not just yes/no.
        systemctl status cloudera-scm-agent 
        if [ $? = 0 ]; then
            return $OCF_SUCCESS
        fi
        return $OCF_STOPPED
}


case $__OCF_ACTION in
meta-data)      meta_data
                exit $OCF_SUCCESS
                ;;
start)          agent_start;;
stop)           agent_stop;;
monitor)        agent_monitor;;
usage|help)     agent_usage
                exit $OCF_SUCCESS
                ;;
*)              agent_usage
                exit $OCF_ERR_UNIMPLEMENTED
                ;;
esac
rc=$?
exit $rc
```

- 修改配置权限

```bash
chmod 770 /usr/lib/ocf/resource.d/cm/agent
```

- 将 `cloudera-scm-server` 进行托管

```bash
crm configure primitive cloudera-scm-agent ocf:cm:agent
```

- 开启服务

```bash
crm resource start cloudera-scm-agent
```

- 测试服务偏移

```bash
crm resource move cloudera-scm-agent <MGMT2>
```

### 常见问题

#### crm 权限不足

如果出现这样的问题可以再次修改 crm 所需文件的权限，然后使用如下命令：

```bash
crm resource cleanup <service>
```

然后重新管理服务即可

```bash
crm resource <option> <service>
```
