---
title: Simple Python Version Management(pyenv)
date: 2023-11-27 21:41:32
tags: 
- "Python"
id: pyenv
no_word_count: true
no_toc: false
---

## Simple Python Version Management(pyenv)

### 简介

pyenv 是一款多个版本 Python 的管理工具。

### 安装方式

使用如下命令安装：

- CentOS, Fedora, Rocky Linux

```bash
yum -y install git gcc zlib-devel bzip2-devel readline-devel sqlite-devel openssl-devel libffi libffi-devel tk-devel xz xz-devel -y
curl https://pyenv.run | bash
```

- Ubuntu

```bash
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev openssl git -y
curl https://pyenv.run | bash
```

然后在 `~/.bashrc` 中添加如下内容：

```text
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
```

### 基本使用

列出已装的 Python ：

```bash
pyenv versions
```

查看可以安装的 Python 版本：

```bash
pyenv install -l
```

安装特定版本的 Python：

```bash
pyenv install <VERSION>
```

> 注：如果没有精细的版本可以省略，比方说 3.10 的最新版可以略写为 3.10

切换版本：

```bash
pyenv local <VERSION>
```

创建 venv 环境：

```bash
pyenv virtualenv <version> <venv_name>
```

列出 venv 环境：

```bash
pyenv virtualenvs
```

使用 venv 环境：

```bash
pyenv activate <venv_name>
```

退出 venv 环境：

```bash
pyenv deactivate
```

卸载版本：

```bash
pyenv uninstall <VERSION>
```

更新软件：

```bash
pyenv update
```

### 参考资料

[官方项目](https://github.com/pyenv/pyenv)

[安装脚本项目](https://github.com/pyenv/pyenv-installer)
