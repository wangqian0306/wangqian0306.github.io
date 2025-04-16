---
title: n8n
date: 2025-04-15 22:26:13
tags:
- "AI"
id: n8n
no_word_count: true
no_toc: false
---

## n8n

### 简介

n8n 是一个开源的工作流自动化工具，它允许用户通过图形化界面创建复杂的自动化流程，而无需编写代码。

### 部署

#### Docker

可以使用如下命令简单部署 n8n

```bash
docker volume create n8n_data

docker run -it --rm --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n
```

##### 额外配置

在容器环境中可以使用环境变量的方式进行部署，例如：

```text
-e N8N_SECURE_COOKIE=false
```

允许跨设备访问：

```text
N8N_SECURE_COOKIE=false
```

修改时区为中国时间：

```text
GENERIC_TIMEZONE=Asia/Shanghai
```

本地隔离不访问外网的环境变量：

```text
N8N_DIAGNOSTICS_ENABLED=false
N8N_VERSION_NOTIFICATIONS_ENABLED=false
N8N_TEMPLATES_ENABLED=false
EXTERNAL_FRONTEND_HOOKS_URLS=
N8N_DIAGNOSTICS_CONFIG_FRONTEND=
N8N_DIAGNOSTICS_CONFIG_BACKEND=
```

#### 手动部署

使用如下命令安装依赖：

```bash
sudo apt install nodejs npm -y 
sudo npm install n8n -g
```

然后编写如下配置文件 `/n8n/n8n-config.json` ：

```json
{
  "auth": {
    "cookie": {
      "secure": false
    }
  },
  "versionNotifications": {
    "enabled": false
  },
  "templates": {
    "enabled": false
  },
  "diagnostics": {
    "enabled": false,
    "frontendConfig": "",
    "backendConfig": ""
  },
  "generic": {
    "timezone": "Asia/Shanghai"
  }
}
```

> 注：此处配置暂无文档，需要查看 [源码](https://github.com/n8n-io/n8n/blob/master/packages/cli/src/config/schema.ts)

使用如下命令，根据配置文件启动服务：

```bash
N8N_CONFIG_FILES=/n8n/n8n-config.json n8n start
```

如果需要更新版本则可以使用如下命令：

```bash
sudo npm update -g n8n
```

### 参考资料

[官方文档](https://docs.n8n.io/)

[官方项目](https://github.com/n8n-io/n8n)

[初级视频教程](https://www.youtube.com/playlist?list=PLlET0GsrLUL59YbxstZE71WszP3pVnZfI)

[高级视频教程](https://www.youtube.com/playlist?list=PLlET0GsrLUL5bxmx5c1H1Ms_OtOPYZIEG)
