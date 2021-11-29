---
title: CDH 集成 Atlas
date: 2021-11-25 22:26:13
tags:
- "CDH"
- "Atlas"
id: atlas
no_word_count: true
no_toc: false
categories: 大数据
---

## CDH 集成 Atlas 

### 简介

Atlas 是一组可扩展和可扩展的核心基础治理服务——使企业能够有效和高效地满足其在 Hadoop 中的合规性要求，可以与整个企业数据生态系统集成。

### 版本说明

CDH 版本：6.3.2

Atlas 版本：2.1.0

> 注：由于 Atlas 2.2.0 与 Hive 2.1.0 

### 前置依赖

#### 软件依赖

- Java 8
- Maven 3.5+
- Python 2

#### Maven 配置

关闭 Maven HTTP 源安全检测，注释 `setting.xml` 中的以下行

```xml
<mirror>
  <id>maven-default-http-blocker</id>
  <mirrorOf>external:http:*</mirrorOf>
  <name>Pseudo repository to mirror external repositories initially using HTTP.</name>
  <url>http://0.0.0.0/</url>
  <blocked>true</blocked>
</mirror>
```

### 源码编译

- 获取并解压源码

```bash
wget https://dlcdn.apache.org/atlas/2.1.0/apache-atlas-2.1.0-sources.tar.gz --no-check-certificate
tar -zxvf apache-atlas-2.1.0-sources.tar.gz
```

- 进入解压后的文件夹，并编辑 `pom.xml` 文件

```bash
cd apache-atlas-sources-2.1.0/
```

- 在 `pom.xml` 文件的 `properties` 部分，修改如下版本包

```text
<hadoop.version>3.0.0-cdh6.3.2</hadoop.version>
<hbase.version>2.1.0-cdh6.3.2</hbase.version>
<hive.version>2.1.1-cdh6.3.2</hive.version>
<kafka.version>2.1.0-cdh6.3.2</kafka.version>
<zookeeper.version>3.4.5-cdh6.3.2</zookeeper.version>
```

- 在 `pom.xml` 文件的 `repository` 部分，新增 Cloudera 软件源

```xml
<repository>
    <id>cloudera</id>
    <url>https://repository.cloudera.com/artifactory/cloudera-repos</url>
</repository>
```

- 修改配置文件 `distro/src/conf/atlas-env.sh` 并新增如下内容

```bash
export HBASE_CONF_DIR=/etc/hbase/conf
export MANAGE_LOCAL_SOLR=false
export MANAGE_LOCAL_HBASE=false
```

- 编译打包

> 注：如果此处编译出现配置相关问题，则查看软件安装部分中的修改配置文件小节并编辑 `distro/src/conf/atlas-application.properties` 文件

```bash
mvn clean -DskipTests install
mvn clean -DskipTests package -Pdist
```

- 查看安装包

```bash
ll distro/target
```

### 软件安装

- 创建相应目录并解压软件

```bash
mkdir -p /opt/atlas
cp distro/target/apache-atlas-2.1.0-bin.tar.gz /opt/atlas
cd /opt/atlas
tar -zxvf apache-atlas-2.1.0-bin.tar.gz
```

- 修改配置文件 `conf/atlas-application.properties`

```text
atlas.graph.storage.backend=hbase
atlas.graph.storage.hostname=<zookeeper-1>:2181,<zookeeper-2>:2181,<zookeeper-3>:2181
atlas.graph.storage.hbase.table=apache_atlas_janus
atlas.graph.index.search.solr.mode=cloud
atlas.graph.index.search.solr.wait-searcher=true
atlas.graph.index.search.solr.zookeeper-url=<zookeeper-1>:2181,<zookeeper-2>:2181,<zookeeper-3>:2181/solr
atlas.graph.index.search.solr.zookeeper-connect-timeout=60000
atlas.graph.index.search.solr.zookeeper-session-timeout=60000
atlas.notification.embedded=false
atlas.kafka.zookeeper.connect=<zookeeper-1>:2181,<zookeeper-2>:2181,<zookeeper-3>:2181
atlas.kafka.bootstrap.servers=<zookeeper-1>:2181,<zookeeper-2>:2181,<zookeeper-3>:2181
atlas.kafka.zookeeper.session.timeout.ms=60000
atlas.kafka.zookeeper.connection.timeout.ms=30000
atlas.kafka.enable.auto.commit=true
atlas.audit.hbase.zookeeper.quorum=<zookeeper-1>:2181,<zookeeper-2>:2181,<zookeeper-3>:2181
```

- 同步 `hbase`,`solr`,`zookeeper` 配置文件至 `conf` 目录下

### 与各组件集成

参照官方文档

[与 HBase 集成](http://atlas.apache.org/#/HookHBase)

> 注：其他组件请在左侧导航栏中寻找

### 参考资料

[环境篇：Atlas2.0.0兼容CDH6.2.0部署](https://www.cnblogs.com/ttzzyy/p/12853572.html)

[CDH6.3.2 Atlas-2.1.0安装打包使用，亲测可用](https://blog.csdn.net/qq_38822927/article/details/120309256)