---
title: zookeeper 基础使用
date: 2020-06-09 22:43:13
tags: "Zookeeper"
id: zookeeper-cli
no_word_count: true
no_toc: false
categories: 大数据
---

## 数据模型

Zookeeper 提供的命名空间和标准的Linux文件系统是很类似的。每个数据节点都存储在 Zookeeper 命名空间的相应‘目录下’。

每个数据节点都具有以下的属性：

|属性|说明|
|:---:|:---:|
|cZxid|数据节点创建时的事务ID|
|ctime|数据节点创建时间|
|mZxid|数据节点被修改时的事务ID|
|mtime|数据节点修改时间|
|pZxid|数据节点的子节点最后一次被修改时的事务ID|
|cversion|子节点的更改次数|
|dataVersion|节点数据的更改次数|
|aclVersion|节点 ACL 的更改次数|
|ephemeralOwner|如果节点是临时节点，则表示创建该节点会话的 SessionID;如果是持久节点则为0x0|
|dataLength|数据内容的长度|
|numChildren|数据节点当前的子节点个数|

## CLI

- 链接到 Zookeeper
```bash
./zkCli.sh -server <ip>:<port>
```

- 创建节点
```bash
create [-s] [-e] [-c] [-t ttl] path [data] [acl]
```

- 获取节点信息
```bash
get [-s] [-w] path
```

- 查看节点列表
```bash
ls [-s] [-w] [-R] path
```

- 查看节点和属性列表
```bash
ls2 path [watch]
```

- 获取当前节点属性
```bash
stat [-w] path
```

- 修改节点
```bash
set [-s] [-v version] path data
```

- 删除节点
```bash
rmr <path>
```

参数说明:

|参数|说明|
|:---:|:---:|
|-w|注册(观察数据变化)|
|-e|临时数据(重启或者超时消失)|
|-s|含有序列(补充编号)|
|-R|递归|

### ACL

可以使用下面的命令来配置 ACL

```bash
setAcl [-s] [-v version] [-R] path acl
```

acl 的结构如下：

```text
<授权模式>:<授权对象>:<具体权限>
```

|授权模式|描述|
|:---:|:---:|
|world|只有一个用户: anyone，代表登录的所有人(默认)|
|ip|IP地址认证|
|auth|使用已经添加认证的用户认证|
|digest|使用“用户名:密码”的方式认证|

|权限|具体权限|描述|
|:---:|:---:|:---:|
|create|c|创建|
|delete|d|删除子节点|
|read|r|读取节点数据和显示子节点|
|write|w|设置节点数据|
|a|a|可以管理权限|

除此之外还可以

- 查看权限
```bash
getAcl [-s] path
```

- 添加认证用户(登录)
```bash
addauth scheme auth
```

> 注：在使用 auth 模式的时候需要先登录然后在配置权限。
