---
title: Jenkins
date: 2023-12-12 21:41:32
id: jenkins
no_word_count: true
no_toc: false
---

## Jenkins

### 简介

Jenkins 是一个开源、可扩展的持续集成、交付、部署(软件/代码的编译、打包、部署)的平台。

### 密码重置

- 找到配置目录

> 注：服务安装版

```bash
cd /var/lib/jenkins
```

> 注：Docker 版

```bash
cd /var/jenkins_home
```

- 修改配置文件

```bash
vim config.xml
```

改写如下配置：

```xml
<useSecurity>false</useSecurity>
```

- 重新启动服务
- 访问服务，改写如下配置：

```text
- Manage Jenkins
  - Configure Global Security
    - Enable Security
      - Security Realm
        - Jenkins's own user database
      - Authentication
        - Role-based strategy
```

> 注：此处权限部分请根据实际情况修改。

- 重新设置密码，改写如下配置：

```text
- People
  - <user>
    - Configure
      - Password
```

- 重新启动服务即可，无需修改配置文件

### 参考资料

[官网](https://www.jenkins.io/)
