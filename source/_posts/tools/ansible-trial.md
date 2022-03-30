---
title: Ansible 试用
date: 2022-03-28 23:09:32
tags:
- "Ansible"
- "Python"
id: ansible-trial
no_word_count: true
no_toc: false
categories: "工具"
---

## Ansible 试用

### 简介

本文会简述 Ansible 的使用方式。

### 配置目标地址 

在项目中会存在 `hosts` 或 `hosts.yaml` 文档，通过此文档可以指定安装服务的位置。

在官方实例中提供了 `hosts.yaml` 的四种样例：

- 不指定组的主机

```yaml
# 样例 1: 对于这样的主机需要将其放在 'all' 或 'ungrouped' 参数下，在样例中定义了 4 个主机，有一个主机还被配置了两个参数
all:
  hosts:
      green.example.com:
          ansible_ssh_host: 191.168.100.32
          anyvariable: value
      blue.example.com:
      192.168.100.1:
      192.168.100.10:
```

- 指定组的主机

```yaml
# 样例 2: 4 个位于 webservers 组中的主机，并且它们全都具有相同的配置项
webservers:
  hosts:
     alpha.example.org:
     beta.example.org:
     192.168.1.100:
     192.168.1.110:
  vars:
    http_port: 8080
```

- 使用子组的方式

```yaml
# 样例 3：可以选定范围的方式指定主机并将子组和变量添加到组中。子组和普通组一样可以定义全部内容，并且子组会从父组继承全部变量，同样父组也会包含子组中的所有主机。
# testing 组是父组，webservers 组是它的子组。而且在 testing 组中已经指定了 www[001:006].example.com 的主机
webservers:
  hosts:
    gamma1.example.org:
    gamma2.example.org:
testing:
  hosts:
    www[001:006].example.com:
  vars:
    testing1: value1
  children:
    webservers:
other:
  children:
    webservers:
      gamma3.example.org
```

> 注：testing 组包含下面所有主机：
> gamma1.example.org 
> gamma2.example.org 
> gamma3.example.org 
> www001.example.com 
> www002.example.com 
> www003.example.com 
> www004.example.com 
> www005.example.com 
> www006.example.com

- 全局参数

```yaml
# 样例 4：全局参数，在 `all` 组中的参数会具有最低级的优先级
all:
  vars:
      commontoall: thisvar
```

### 配置用户的方式

可以使用如下的方式覆写：

- 在运行时使用 `-u` 参数
- 将用户相关信息存储在库中
- 将用户信息存储在配置文件中
- 设置环境变量

### 参考资料

[官方文档](https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html)

[官方样例](https://github.com/ansible/ansible/blob/devel/examples)