---
title: Ansible 安装
date: 2022-03-28 23:09:32
tags:
- "Ansible"
- "Python"
id: ansible-install
no_word_count: true
no_toc: false
categories: "工具"
---

## Ansible 安装

### 简介

Ansible 一款由 Python 编写的自动化工具。Ansible 可以从控制节点远程管理机器和其他设备(默认情况下，通过 SSH 协议)。

> 注：使用 Ansible 可以轻松的管理集群。使用一台控制节点管理很多台设备，非常适合部署集群。

### 安装

#### 使用 Pip 安装

```bash
python -m pip install ansible
python -m pip install paramiko
```

#### 在 CentOS Fedora 上安装

- CentOS

```bash
yum install epel-release
yum install ansible
```

- Fedora

```bash
dnf install ansible
```

#### 在 Ubuntu 上安装

```bash
apt update
apt install software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt install ansible
```

### 检测安装情况

```bash
ansible all -m ping --ask-pass
```

### 安装命令补全

#### 各版本的安装方式

- Pip

```bash
python -m pip install argcomplete
```

- Fedora

```bash
dnf install python-argcomplete
```

- CentOS

```bash
yum install python-argcomplete
```

- Ubuntu

```bash
apt install python3-argcomplete
```

#### 命令补全配置

- 全局配置

```bash
activate-global-python-argcomplete
```

> 注：上述方式需要 bash 版本大于 4.2。可以使用 `bash --version` 命令查看 bash 版本、 

- 独立命令配置

```bash
vim /etc/profile.d/argcomplete.sh
```

然后新增如下内容

```text
$ eval $(register-python-argcomplete ansible)
$ eval $(register-python-argcomplete ansible-config)
$ eval $(register-python-argcomplete ansible-console)
$ eval $(register-python-argcomplete ansible-doc)
$ eval $(register-python-argcomplete ansible-galaxy)
$ eval $(register-python-argcomplete ansible-inventory)
$ eval $(register-python-argcomplete ansible-playbook)
$ eval $(register-python-argcomplete ansible-pull)
$ eval $(register-python-argcomplete ansible-vault)
```

> 注：此种方式暂未完成测试。

### 参考文档

[官方文档](https://docs.ansible.com/ansible/latest/installation_guide/)
