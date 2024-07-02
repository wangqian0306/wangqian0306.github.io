---
title: MySQL InnoDB Cluster
date: 2024-07-02 23:09:32
tags: 
- "MySQL"
- "MySQL Router"
id: mysql-innodb-cluster
no_word_count: true
no_toc: false
categories: "MySQL"
---

## MySQL InnoDB Cluster

### 简介

MySQL 的一种高可用方案，具体实现方式参见下图：

![MySQL InnoDB Cluster](https://dev.mysql.com/doc/mysql-shell/8.4/en/images/innodb-cluster-overview.png)

### 服务部署

#### 容器版

可以试用 [mysql-docker-compose-examples](https://github.com/neumayer/mysql-docker-compose-examples) 项目。

> 注：示例项目的 MySQL Router 只开放了 6446 端口，此端口仅供读写使用，还可以开放 6447 端口，此端口负责只读请求。

#### 本地部署

> 注：此处需要提前搭建好 MySQL 服务器，可以参照 MySQL 文档。

使用如下命令进入交互式命令行：

```bash
mysqlsh
```

使用如下命令即可链接到数据库，并将其初始化：

```text
shell.connect('root@localhost:3306')
dba.configureInstance()
```

在所有节点被初始化完成后即可使用如下命令创建 InnoDB 集群：

```text
dba.createCluster('devCluster')
```

然后使用如下命令添加实例至集群:

```text
dba.getCluster().addInstance('root@mysql-2:3306')
```

> 注：此处需要输入密码并选择恢复方式，建议在刚搭建的服务中采用 Clone 。配置完成后需要重启服务，如果使用容器记得配置持久卷。

之后可以采用如下命令检查集群状态：

```text
dba.getCluster().status()
```

### 测试

#### 负载均衡

使用如下命令安装依赖：

```bash
pip install sqlalchemy mysql-connector-python
```

```python
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

DATABASE_URI = 'mysql+mysqlconnector://root:mysql@localhost:6447'

engine = create_engine(
    DATABASE_URI,
    pool_size=10,
    max_overflow=20,
    pool_recycle=3600,
    pool_pre_ping=True
)

Session = sessionmaker(bind=engine)
session = Session()
query = text('SELECT @@server_id as server_id')
result = session.execute(query).fetchone()
print("Server ID" + result[0])
session.close()
```

多次运行此服务即可看到，请求被传输到了不同的设备上执行。

### 参考资料

[MySQL 官方文档](https://dev.mysql.com/doc/)

[mysql-docker-compose-examples](https://github.com/neumayer/mysql-docker-compose-examples)