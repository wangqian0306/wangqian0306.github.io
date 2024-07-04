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

### 容器中使用

编写 `hello-cron` 脚本：

```text
* * * * * echo "Hello world" >> /var/log/cron.log 2>&1

```

> 注：此处需要使用 Linux 换行符且最后一行要是空行。

编写 `Dockerfile` 即可：

```bash
FROM ubuntu:latest

RUN apt-get update && apt-get -y install cron

COPY hello-cron /etc/cron.d/hello-cron

RUN chmod 0644 /etc/cron.d/hello-cron

RUN crontab /etc/cron.d/hello-cron

RUN touch /var/log/cron.log

CMD cron && tail -f /var/log/cron.log
```

### 参考资料

[维基百科 cron](https://en.wikipedia.org/wiki/Cron)

[在线Cron表达式生成器](https://www.matools.com/cron)

[How to run a cron job inside a docker container](https://stackoverflow.com/questions/37458287/how-to-run-a-cron-job-inside-a-docker-container)
