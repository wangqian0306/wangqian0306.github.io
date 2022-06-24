---
title: 安装 fcitx5 输入法
date: 2022-06-24 20:04:13
tags: "Linux"
id: fcitx
no_word_count: true
no_toc: false
categories: Linux
---

## 安装 fcitx5 输入法

### 简介

Fcitx5 是一个轻量级核心的输入法框架，通过插件提供额外的语言支持。它是 Fcitx 的继任者。

### 安装

#### 单次使用

可以使用如下命令在 Fedora 平台上安装 Fcitx5 输入法：

```bash
dnf install fcitx5 kcm-fcitx5 fcitx5-chinese-addons fcitx5-table-extra fcitx5-zhuyin fcitx5-configtool
fcitx5
```

另起一个终端开启图形化配置

```bash
fcitx5-config-qt
```

#### 永久使用

在单次使用配置完成后，使用如下命令：

```bash
alternatives --config xinputrc
```

> 注：然后选择 fcitx5 项即可。

添加自启动

```bash
ln -s /usr/share/applications/org.fcitx.Fcitx5.desktop ~/.config/autostart/
```

### 参考资料

[fedora 35 安装 fcitx5 拼音输入法](https://insidelinuxdev.net/article/a0cr1x.html)