---
title: cron
date: 2022-12-01 20:04:13
tags: "Linux"
id: cron
no_word_count: true
no_toc: false
categories: Linux
---

## cron

### 简介

在Linux系统中，计划任务一般是由 cron 承担。在cron启动后，它会读取它的所有配置文件(全局性配置文件 `/etc/crontab`，以及每个用户的计划任务配置文件)，然后 cron 会根据命令和执行时间来按时来调用度工作任务。

### 安装和使用

安装软件

```bash
yum install cronie -y
```

启动服务

```bash
systemctl enable crond --now
```

cron 表达式说明

```text
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of the month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of the week (0 - 6) (Sunday to Saturday;
# │ │ │ │ │                                   7 is also Sunday on some systems)
# │ │ │ │ │
# * * * * * <command to execute>
```

查看用户的定时任务

```bash
corntab -l
```

编辑用户的定时任务

```bash
crontab -e
```

删除用户的定时任务

```bash
crontab -r
```

### 参考资料

[维基百科 cron](https://en.wikipedia.org/wiki/Cron)

[在线Cron表达式生成器](https://www.matools.com/cron)
