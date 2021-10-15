---
title: JMX 使用
date: 2021-10-14 23:09:32
tags:
- "JConsul"
- "JMX Exporter"
- "Prometheus"
id: jmx-exporter
no_word_count: true
no_toc: false
categories: "工具"
---

## JMX 使用

### 简介

JMX（Java Management Extensions，即Java管理扩展）是一个为应用程序、设备、系统等植入管理功能的框架。

### 本机使用

JDK 中默认附带了 jconsul 工具，可以使用 `jconsul` 命令打开图形界面。

### Prometheus 监控

Prometheus 提供了 JMX Exporter 工具提取 JMX 数据。

#### Java Agent 方式

访问 [官方网站](https://github.com/prometheus/jmx_exporter) 获得最新版本的 jar 包，然后编写如下配置文件:

```yaml
startDelaySeconds: 0
hostPort: 127.0.0.1:1234
username: 
password: 
jmxUrl: service:jmx:rmi:///jndi/rmi://127.0.0.1:1234/jmxrmi
ssl: false
lowercaseOutputName: false
lowercaseOutputLabelNames: false
whitelistObjectNames: ["org.apache.cassandra.metrics:*"]
blacklistObjectNames: ["org.apache.cassandra.metrics:type=ColumnFamily,*"]
rules:
  - pattern: 'org.apache.cassandra.metrics<type=(\w+), name=(\w+)><>Value: (\d+)'
    name: cassandra_$1_$2
    value: $3
    valueFactor: 0.001
    labels: {}
    help: "Cassandra metric $1 $2"
    cache: false
    type: GAUGE
    attrNameSnakeCase: false
```

使用如下命令启动程序：

```bash
java -javaagent:./jmx_prometheus_javaagent-0.16.1.jar=8080:config.yaml -jar yourJar.jar
```

#### HTTP Server 方式

使用如下命令进行调试

```bash
git clone https://github.com/prometheus/jmx_exporter.git
cd jmx_exporter
./mvnw package
java -cp collector/target/collector*.jar io.prometheus.jmx.JmxScraper service:jmx:rmi:///jndi/rmi://<host>:<port>/jmxrmi
```

> 注：若输出参数则证明程序运行正常，配置无误。

调试完成后可以在 `jmx_prometheus_httpserver` 构建出的文件夹内找到可安装的 deb 包和 jar 包，或者使用如下脚本直接运行服务器：

```bash
java -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.port=<port> -jar jmx_prometheus_httpserver/target/jmx_prometheus_httpserver-${version}-jar-with-dependencies.jar <port> example_configs/httpserver_sample_config.yml
```
