---
title: Home Assistant 折腾教程
date: 2022-11-11 21:41:32
tags: "Home Assistant"
id: home-assistant
no_word_count: true
no_toc: false
---

## Home Assistant 折腾教程

### 简介

Home Assistant 是一款开源的家庭自动化控制平台，主要针对于本地控制和隐私性。

### 安装方式

Home Assistant 可以通过四种方式进行安装：

- OS(系统级别安装)
- Container(独立容器)
- Core(使用 Python venv 手动安装)
- Supervised(在系统中安装软件)

官方推荐的安装方式为：

- OS
- Container

不同的安装方式有不同的支持项：

|                                          功能                                          | OS  | Container | Core | Supervised |
|:------------------------------------------------------------------------------------:|:---:|:---------:|:----:|:----------:|
|             [Automations](https://www.home-assistant.io/docs/automation)             | :o: |    :o:    | :o:  |    :o:     |
|                [Dashboards](https://www.home-assistant.io/dashboards)                | :o: |    :o:    | :o:  |    :o:     |
|              [Integrations](https://www.home-assistant.io/integrations)              | :o: |    :o:    | :o:  |    :o:     |
|              [Blueprints](https://www.home-assistant.io/docs/blueprint)              | :o: |    :o:    | :o:  |    :o:     |
|                                    Uses container                                    | :o: |    :o:    | :x:  |    :o:     |
| [Supervisor](https://www.home-assistant.io/docs/glossary/#home-assistant-supervisor) | :o: |    :x:    | :x:  |    :o:     |
|                   [Add-ons](https://www.home-assistant.io/addons)                    | :o: |    :x:    | :x:  |    :o:     |
|          [Backups](https://www.home-assistant.io/common-tasks/os/#backups)           | :o: |    :o:    | :o:  |    :o:     |
|                                      Managed OS                                      | :o: |    :x:    | :x:  |    :x:     |

### 参考资料

[官方文档](https://www.home-assistant.io/)