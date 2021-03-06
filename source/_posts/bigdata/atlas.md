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

> 注：构建时请使用部署了服务的 CDH 集群内的任意主机。

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

- 修改 Hive Hook 适配代码

`org/apache/atlas/hive/bridge/HiveMetaStoreBridge.java(577)`

```text
String catalogName = hiveDB.getCatalogName() != null ? hiveDB.getCatalogName().toLowerCase() : null;
```

改为

```text
String catalogName = null;
```

`org/apache/atlas/hive/hook/AtlasHiveHookContext.java(81)`

```text
this.metastoreHandler = (listenerEvent != null) ? metastoreEvent.getIHMSHandler() : null;
```

```text
this.metastoreHandler = null;
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

此处需要将 Atals 配置文件放入各个组件中，但是由于 CDH 每次运行的配置文件是动态生成的所以需要将配置文件使用如下命令压缩至 jar 包中

```bash
zip -u <atlas_home>/hook/hive/atlas-plugin-classloader-2.1.0.jar atlas-application.properties
```

> 注：此条压缩命令不可改变，如果变更会导致 jar 包内的文件路径映射问题，导致 Hook 无法读取配置文件以至于组件启动失败。

在如下配置项中新增配置：

- hive-site.xml 的 Hive 服务高级配置代码段（安全阀）
- hive-site.xml 的 Hive 客户端高级配置代码段（安全阀）
- hive-site.xml 的 HiveServer2 高级配置代码段（安全阀）

配置如下内容：

```xml
<property>
    <name>hive.exec.post.hooks</name>
    <value>org.apache.atlas.hive.hook.HiveHook</value>
</property>
```

在 hive-env.sh 的 Gateway 客户端环境高级配置代码段（安全阀）中新增如下内容:

```text
HIVE_AUX_JARS_PATH=<atlas_path>/hook/hive
```

在 Hive 辅助 JAR 目录中新增如下内容:

```text
<atlas_path>/hook/hive
```

重启 Hive 和 Atlas 即可

如果遇到问题请参照官方文档

[与 Hive 集成](http://atlas.apache.org/#/HookHive)

> 注：其他组件请在左侧导航栏中寻找

### 手动添加元数据

请求方式： POST

请求地址： `http://<atlas_host>:21000/api/atlas/v2/entity`

- 创建数据库实例

```json
{
  "entity": {
    "attributes": {
      "owner": "<user>",
      "ownerName": "<user>",
      "name": "mysql_instance",
      "qualifiedName": "mysql_instance@<mysql_host>",
      "rdbms_type": "mysql",
      "description": "dashboard database",
      "contact_info": "jdbc://<mysql_host>:3306/<mysql_db>",
      "platform": "Linux",
      "hostname": "<mysql_host>",
      "protocol": "mysql protocol",
      "port": "3306"
    },
    "typeName": "rdbms_instance",
    "status": "ACTIVE"
  }
}
```

- 创建数据库

```json
{
  "entity": {
    "attributes": {
      "owner": "<user>",
      "ownerName": "<user>",
      "name": "<database>",
      "displayText": "",
      "qualifiedName": "<database>@<mysql_host>",
      "description": "",
      "instance": {
        "guid": "<数据库实例 ID>",
        "typeName": "rdbms_instance",
        "entityStatus": "ACTIVE"
      }
    },
    "typeName": "rdbms_db",
    "status": "ACTIVE"
  }
}
```

- 创建数据表

```json
{
  "entity": {
    "attributes": {
      "owner": "<user>",
      "ownerName": "<user>",
      "name": "<table_name>",
      "db": {
        "guid": "<数据库 ID>",
        "typeName": "rdbms_db"
      },
      "qualifiedName": "<database>.<table>@<host>",
      "description": "",
      "replicatedTo": null,
      "replicatedFrom": null
    },
    "typeName": "rdbms_table",
    "status": "ACTIVE"
  }
}
```

- 创建列

```json
{
  "entity": {
    "attributes": {
      "owner": "<user>",
      "ownerName": "<user>",
      "name": "<column>",
      "qualifiedName": "<database>.<table>.<column>@<host>",
      "default_value": null,
      "isPrimaryKey": false,
      "indexes": [],
      "isNullable": false,
      "data_type": "datetime",
      "comment": "",
      "table": {
        "guid": "<table>",
        "typeName": "rdbms_table"
      }
    },
    "typeName": "rdbms_column",
    "status": "ACTIVE"
  }
}
```

- 创建变化关系

```json
{
  "entity": {
    "attributes": {
      "owner": null,
      "ownerName": null,
      "outputs": [
        {
          "guid": "<output_id>",
          "typeName": "<output_type>"
        }
      ],
      "queryGraph": null,
      "replicatedTo": null,
      "userDescription": null,
      "replicatedFrom": null,
      "recentQueries": [],
      "qualifiedName": "<name>",
      "displayName": null,
      "inputs": [
        {
          "guid": "<input_id>",
          "typeName": "<input_type>"
        }
      ],
      "description": null,
      "userName": "",
      "queryId": "",
      "clusterName": "primary",
      "name": "<name>",
      "queryText": "",
      "startTime": 1638773124750,
      "operationType": " ",
      "queryPlan": "Not Supported",
      "endTime": 1638773124750
    },
    "typeName": "Process",
    "status": "ACTIVE"
  }
}
```

### 参考资料

[环境篇：Atlas2.0.0兼容CDH6.2.0部署](https://www.cnblogs.com/ttzzyy/p/12853572.html)

[CDH6.3.2 Atlas-2.1.0安装打包使用，亲测可用](https://blog.csdn.net/qq_38822927/article/details/120309256)