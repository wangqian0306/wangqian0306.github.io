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

启动完成后可以持久化环境变量：

```bash
vim ~/.bashrc
```

然后新增如下配置：

```text
N8N_CONFIG_FILES=/n8n/n8n-config.json
```

#### 服务部署

在完成手动部署后可以使用 pm2 进行管理，安装逻辑如下：

```bash
sudo npm install pm2 -g
```

然后需要使用如下命令启动服务：

```bash
pm2 startup systemd
pm2 start n8n
pm2 save
```

使用如下命令即可查看服务状态：

```bash
pm2 list
```

使用如下命令查看服务日志：

```bash
pm2 logs <name>
```

使用如下终止任务：

```bash
pm2 stop <name>
```

使用如下命令删除服务：

```bash
pm2 delete <name>
```

### 注意事项

> 注：建议先看完官方教程再使用。

1. 注意节点的位置关系，执行顺序是从左到右从上到下。
2. Python 代码不在本机运行在浏览器中，查看日志去找浏览器 console 和服务命令的输出。
3. 注意输出内容的个数，单个和多个的处理逻辑是不一样的。
4. 结果默认是数组，无需单独处理，默认情况直接取对象就可以了。
5. 数据结果在不涉及到节点的情况下都可以通过节点名称跨位置拉取，直接拖拽就行
6. 指令运行采用的是 sh 不是 bash
7. 在 Http 请求的翻页结果中页码从 0 开始，结果对象使用 `$response` 根据提示操作即可
8. AI Agent 节点的输入有默认值，依照默认值填写即可
9. 在测试的时候可以禁用某些节点屏蔽报错

### 参考资料

[官方文档](https://docs.n8n.io/)

[官方项目](https://github.com/n8n-io/n8n)

[初级视频教程](https://www.youtube.com/playlist?list=PLlET0GsrLUL59YbxstZE71WszP3pVnZfI)

[高级视频教程](https://www.youtube.com/playlist?list=PLlET0GsrLUL5bxmx5c1H1Ms_OtOPYZIEG)

[API 文档](https://docs.n8n.io/api/api-reference/)
