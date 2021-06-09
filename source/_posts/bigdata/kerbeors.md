---
title: Kerberos HA 搭建流程整理
date: 2020-12-02 23:25:13
tags: "Kerberos"
id: kerberos
no_word_count: true
no_toc: false
categories: 大数据
---

## Kerberos HA 搭建流程整理

### 简介

Kerberos 是一款身份认证软件。本次 HA 搭建采用了`crontab`+`kprop`的方式实现，具体内容参见 [官方文档](https://web.mit.edu/kerberos/krb5-devel/doc/admin/install_kdc.html) 。

### 主机安装

- 安装软件(主机)：

```bash
yum install -y krb5-server krb5-libs krb5-workstation
```

- 连接配置

```bash
vim /etc/krb5.conf
```

```text
includedir /etc/krb5.conf.d/

[logging]
default = FILE:/var/log/krb5libs.log
kdc = FILE:/var/log/krb5kdc.log
admin_server = FILE:/var/log/kadmind.log

[libdefaults]
default_realm = <realm>
dns_lookup_kdc = false
dns_lookup_realm = false
ticket_lifetime = 86400
renew_lifetime = 604800
forwardable = true
default_tgs_enctypes = des3-hmac-sha1 aes256-cts
default_tkt_enctypes = des3-hmac-sha1 aes256-cts
permitted_enctypes = des3-hmac-sha1 aes256-cts
udp_preference_limit = 1
kdc_timeout = 3000
rdns = false
pkinit_anchors = FILE:/etc/pki/tls/certs/ca-bundle.crt
default_ccache_name = KEYRING:persistent:%{uid}

[realms]
<realm> = {
kdc = <kdc_host1>
admin_server = <kdc_host1>
kdc = <kdc_host2>
#  admin_server = <kdc_host2>
}

[domain_realm]
.<domain> = <realm>
<domain> = <realm>
```

- 加密配置

```bash
vim /var/kerberos/krb5kdc/kdc.conf
```

```text
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 <realm> = {
  #master_key_type = aes256-cts
  max_life = 1d
  max_renewable_life= 7d 0h 0m 0s
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal
 }
```

- 权限配置

```bash
vim /var/kerberos/krb5kdc/kadm5.acl
```

```text
*/admin@<realm>	*
```

- 创建数据库:

```bash
kdb5_util create -s -r <realm>
```

- 启动服务

```bash
systemctl enable kadmin
systemctl enable krb5kdc
systemctl start kadmin
systemctl start krb5kdc
```

- 配置防火墙

```bash
firewall-cmd --permanent --add-service kerberos
firewall-cmd --permanent --add-service kadmin
firewall-cmd --permanent --add-service kprop
firewall-cmd --reload
```

- 新建账号

```bash
kadmin.local
```

```bash
addprinc cloudera-scm/admin
addprinc -randkey host/<kdc_ip1>
addprinc -randkey host/<kdc_ip2>
ktadd host/<kdc_ip1>
ktadd host/<kdc_ip2>
```

### 备机安装

- 安装软件

```bash
yum install -y krb5-server krb5-libs krb5-workstation
```

- 拷贝配置文件

```bash
scp <user>@<kdc_host1>:/etc/krb5.conf /etc/krb5.conf
scp <user>@<kdc_host1>:/etc/krb5.keytab /etc/krb5.keytab
scp <user>@<kdc_host1>:/var/kerberos/krb5kdc/kadm5.acl /var/kerberos/krb5kdc/kadm5.acl
scp <user>@<kdc_host1>:/var/kerberos/krb5kdc/kdc.conf /var/kerberos/krb5kdc/kdc.conf
scp <user>@<kdc_host1>:/var/kerberos/krb5kdc/.k5.<realm> /var/kerberos/krb5kdc/.k5.<realm>
```

- 编辑同步文件

```bash
vim /var/kerberos/krb5kdc/kpropd.acl
```

```text
host/<kdc_host1>@<realm>
host/<kdc_host2>@<realm>
```

- 配置防火墙

```bash
firewall-cmd --permanent --add-service kerberos
firewall-cmd --permanent --add-service kadmin
firewall-cmd --permanent --add-service kprop
firewall-cmd --reload
```

- 启动同步服务

```bash
systemctl start kprop --now
```

### 手动同步数据库

#### 主机

- 备份数据库

```bash
kdb5_util dump /var/kerberos/krb5kdc/master.dump
```

- 同步数据至备机

```bash
kprop -f /var/kerberos/krb5kdc/master.dump <kdc_host2>
```

> 注：若出现 SUCCESS 字样则代表传输成功。

#### 备机

- 关闭 `kprop` 服务

```bash
systemctl stop kprop
```

- 移除 `kprop` 同步配置

```bash
mv /var/kerberos/krb5kdc/kpropd.acl /var/kerberos/krb5kdc/kpropd.acl.bk
```

- 修改备机配置

```bash
vim /etc/krb5.conf
```

```text
includedir /etc/krb5.conf.d/

[logging]
default = FILE:/var/log/krb5libs.log
kdc = FILE:/var/log/krb5kdc.log
admin_server = FILE:/var/log/kadmind.log

[libdefaults]
default_realm = <realm>
dns_lookup_kdc = false
dns_lookup_realm = false
ticket_lifetime = 86400
renew_lifetime = 604800
forwardable = true
default_tgs_enctypes = des3-hmac-sha1 aes256-cts
default_tkt_enctypes = des3-hmac-sha1 aes256-cts
permitted_enctypes = des3-hmac-sha1 aes256-cts
udp_preference_limit = 1
kdc_timeout = 3000
rdns = false
pkinit_anchors = FILE:/etc/pki/tls/certs/ca-bundle.crt
default_ccache_name = KEYRING:persistent:%{uid}

[realms]
<realm> = {
kdc = <kdc_host1>
admin_server = <kdc_host1>
kdc = <kdc_host2>
#  admin_server = <kdc_host2>
}

[domain_realm]
.<domain> = <realm>
<domain> = <realm>
```

- 启动备机服务

```bash
systemctl start krb5kdc
systemctl start kadmin
```

- 测试数据库同步情况

```bash
kadmin.local
```

```bash
listprins
```

> 注: 若用户目录对应则证明此处同步正常。

- 配置服务开机启动

```bash
systemctl enable krb5kdc --now
systemctl stop kadmin
```

- 修改连接配置

```bash
vim /etc/krb5.conf
```

```bash
includedir /etc/krb5.conf.d/

[logging]
default = FILE:/var/log/krb5libs.log
kdc = FILE:/var/log/krb5kdc.log
admin_server = FILE:/var/log/kadmind.log

[libdefaults]
default_realm = <realm>
dns_lookup_kdc = false
dns_lookup_realm = false
ticket_lifetime = 86400
renew_lifetime = 604800
forwardable = true
default_tgs_enctypes = des3-hmac-sha1 aes256-cts
default_tkt_enctypes = des3-hmac-sha1 aes256-cts
permitted_enctypes = des3-hmac-sha1 aes256-cts
udp_preference_limit = 1
kdc_timeout = 3000
rdns = false
pkinit_anchors = FILE:/etc/pki/tls/certs/ca-bundle.crt
default_ccache_name = KEYRING:persistent:%{uid}

[realms]
<realm> = {
kdc = <kdc_host1>
admin_server = <kdc_host1>
kdc = <kdc_host2>
#  admin_server = <kdc_host2>
}

[domain_realm]
.<domain> = <realm>
<domain> = <realm>
```

- 修改远程同步配置

```bash
mv /var/kerberos/krb5kdc/kpropd.acl.bk /var/kerberos/krb5kdc/kpropd.acl
```

- 启动同步服务

```bash
systemctl start kprop 
```

> 注：此处的备机如果拥有全部数据库的话可以将 kpropd.acl 文件移除，暂时做为主机使用。

### 配置自动同步

- 在主机上编写同步脚本

```bash
vim /var/kerberos/krb5kdc/kprop_sync.sh
```

```text
#!/bin/bash
DUMP=/var/kerberos/krb5kdc/master.dump
SLAVE="<kdc_host2>"
TIMESTAMP=`date`
echo "Start at $TIMESTAMP"
kdb5_util dump $DUMP
kprop -f $DUMP -d $SLAVE
```

- 测试脚本运行情况

```bash
chmod 700 /var/kerberos/krb5kdc/kprop_sync.sh
bash /var/kerberos/krb5kdc/kprop_sync.sh
```

- 配置定时任务

```bash
crontab -e
```

```text
0 */30 * * * root /var/kerberos/krb5kdc/kprop_sync.sh > /var/kerberos/krb5kdc/lastupdate
```

- 开启定时任务

```bash
systemctl enable crond --now
```

### 测试

- 关闭主机 `kdc` 服务

```bash
systemctl stop krb5kdc
```

- 登录测试（账号密码）

```text
kinit cloudera-scm/admin@<realm>
```

- 查看目前的票据

```text
klist
```

- 销毁票据

```text
kdestroy
```

- 生成登录秘钥

```bash
kadmin.local
```

```text
xst -norandkey -k admin.keytab cloudera-scm/admin@<realm>
```

- 使用秘钥登录

```bash
kinit -kt admin.keytab cloudera-scm/admin@<realm>
```

### 客户端环境安装

- 软件安装

```bash
yum install -y krb5-workstation krb5-libs 
```

- 拷贝配置

```bash
scp <user>@<ip>:/etc/krb5.conf /etc/krb5.conf
```

### Windows 平台的注意事项

- Windows Server 和 Windows 专业版系统上可以使用 Windows 自己的 Kerberos (AD)
- Windows 平台的 Kerberos 与 MIT Kerberos (Linux) 并不是完全兼容的，如果有在 Windows 平台上开发应用程序的需求请选用 Windows AD。
- MIT Kerberos 提供了 Windows 版的客户端，支持浏览器调取 Kerberos 认证。

### Firefox 访问 Kerberos 认证服务

在访问开启 Kerberos 鉴权情况下的 WebHDFS 界面的时候需要如下配置浏览器： 

- 在地址栏输入 `about:config` 进入配置模式

- 查找如下配置项目

```bash
network.negotiate-auth.trusted-uris
```

- 将目标服务器加入此列表中

> 注：如果你使用的是 Windows 则还要把 network.auth.use-sspi 配置为 false

- 重启浏览器

### 常见问题

#### Message stream modified (41)

此问题需要注释 `renew_lifetime` 配置项

#### Hue 更新令牌

如果遇到 `Hue` 令牌相关的更新问题可以使用如下命令进行配置：

```bash
kadmin.local
```

```text
modprinc -maxrenewlife 90day krbtgt/<relam>
modprinc -maxrenewlife 90day +allow_renewable hue/<host>@<relam>
```
