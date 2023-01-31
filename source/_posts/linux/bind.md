---
title: BIND 服务安装及配置流程
date: 2020-12-01 21:57:04
tags:
- "Linux"
- "DNS"
id: bind
no_word_count: true
no_toc: false
categories: Linux
---

## BIND 服务安装及配置流程

### 简介

BIND 是 DNS 服务软件，在本文中会有 `bind1`,`bind2` 两台设备完成此次安装。

### 主机搭建

- 配置 Hostname

```bash
hostnamectl set-hostname <bind1_host>.<domain>
```

- 安装软件：

```bash
yum -y install bind bind-utils
```

- 配置服务

```bash
mv /etc/named.conf /etc/named.conf.bk
vim /etc/named.conf
```

填入如下配置

```text
options {
	listen-on port 53 { any; };
	listen-on-v6 { any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	recursing-file  "/var/named/data/named.recursing";
	secroots-file   "/var/named/data/named.secroots";
	allow-query     { any; };
    allow-transfer  { localhost; <bind-2_ip>; };

	recursion yes;

	dnssec-enable yes;
	dnssec-validation yes;

	bindkeys-file "/etc/named.root.key";

	managed-keys-directory "/var/named/dynamic";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

zone "<domain>" IN {
        type master;
        file "<domain>.lan";
        allow-update { none; };
};

zone "<reverse_ip_area>.in-addr.arpa" IN {
       type master;
       file "<reverse_ip_area>.db";
       allow-update { none; };
};
```

> 注：reverse_ip_area 为反向书写的IP地址(去掉最后一位)，例如： 1.168.192

- 配置正向解析

```bash
vim /var/named/<domain>.lan
```

```text
$TTL 86400
@   IN  SOA     dlp.<domain>. <bind1_host>.<domain>. (
        2019100301  ;Serial
        3600        ;Refresh
        1800        ;Retry
        604800      ;Expire
        86400       ;Minimum TTL
)

        IN  NS      dlp.<domain>.
        
        IN  A       <bind1_ip>

        IN  MX 10   dlp.<domain>.

dlp     IN  A       <bind1_ip>
<bind1_host>  IN  A       <bind1_ip>
<bind2_host>  IN  A       <bind2_ip>
```

- 配置反向解析

```bash
vim /var/named/<reverse_ip_area>.db
```

```text
$TTL 86400
@   IN  SOA     dlp.<domain>. <bind1_host>.<domain>. (
        2019100301  ;Serial
        3600        ;Refresh
        1800        ;Retry
        604800      ;Expire
        86400       ;Minimum TTL
)
        IN  NS      dlp.<domain>.

<bind1_ip>      IN  PTR     dlp.<domain>.
<bind1_ip>      IN  PTR     <bind1_host>.<domain>.
<bind2_ip>      IN  PTR     <bind2_host>.<domain>.
```

> 注：此处 IP 只填写最后一位

- 启动服务

```bash
systemctl enable --now named
firewall-cmd --add-service=dns --permanent
firewall-cmd --reload
```

### 从机搭建

从机搭建逻辑与主机相同，但是只需要配置 `/etc/named.conf` 文件即可

- 配置 Hostname

```bash
hostnamectl set-hostname <bind2_host>.<domain>
```

- 安装软件：

```bash
yum -y install bind bind-utils
```

- 配置服务

```bash
mv /etc/named.conf /etc/named.conf.bk
vim /etc/named.conf
```

```text
options {
    listen-on port 53 { any; };
	listen-on-v6 { any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	recursing-file  "/var/named/data/named.recursing";
	secroots-file   "/var/named/data/named.secroots";
    allow-query     { any; };
    allow-transfer  { localhost; <bind-2_ip>; };

	recursion yes;

	dnssec-enable yes;
	dnssec-validation yes;

	bindkeys-file "/etc/named.root.key";

	managed-keys-directory "/var/named/dynamic";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

zone "<domain>" IN {
        type slave;
        masters { <bind1_ip>; };
        masterfile-format text;
        file "slaves/<domain>.lan";
        notify no;
};

zone "<reverse_ip_area>.in-addr.arpa" IN {
       type slave;
       masters { <bind1_ip>; };
       masterfile-format text;
       file "slaves/reverse_ip_area.db";
       notify no;
};
```

- 启动服务

```bash
systemctl enable --now named
firewall-cmd --add-service=dns --permanent
firewall-cmd --reload
```

- 检查配置文件同步

```bash
ls /var/named/slaves/
```

若出现配置文件则证明解析正常。

### 使用配置好的 BIND 服务器

- 获取网卡信息

```bash
nmcli connection show
```

- 修改网卡配置

```bash
nmcli connection modify <name> ipv4.dns <dns_server_ip>
nmcli connection down <name>; nmcli connection up <name>
```

### 动态配置

bind 服务适配了 RFC2136 规范，如果在 `/etc/named.conf` 文件中打开配置项，即可完成动态更新。

```text
allow-update { any; };
```

测试命令如下：

```bash
nsupdate
```

然后输入如下内容：

```text
> server <server_ip>
> zone <domain>
> update add <host> 86400 A <ip>
> send
> quit
```

之后即可进行如下测试：

```bash
ping <host>
```

> 注：若出现配置的 IP 则证明动态更新成功。

### 常见问题

#### Permission Denied

此处问题大多是由于 SELinux 权限限制的问题可以暂时关闭 SELinux 进行测试

```bash
setenforce 0
```

> 注: 此处命令只能是单次生效如果需要完全关闭则还需要修改配置文件

```bash
vim /etc/selinux/conf
```

然后修改配置项即可 `SELINUX=disabled`

### 参考资料

[官方文档](https://bind9.readthedocs.io/en/latest/index.html)

[RFC2136](https://www.rfc-editor.org/rfc/rfc2136)
