---
title: Hive HA
date: 2021-01-13 22:26:13
tags:
- "Hive"
- "CDH"
id: hive-ha
no_word_count: true
no_toc: false
categories: 大数据
---

## Hive HA

### 简介

本 HA 方案采用将 Hive 与 ZooKeeper 结合的方式，将多个 HiveServer 进行整合，并通过 ZooKeeper 对外提供服务。

### 配置

#### HiveServer2

- 进入设置
- 筛选 HiveServer2 服务
- 搜索 xml 配置
- 新增如下配置项

```xml
<property>
    <name>hive.server2.support.dynamic.service.discovery</name>
    <value>true</value>
</property>
```

```xml
<property>
    <name>hive.server2.zookeeper.namespace</name>
    <value>hiveserver2</value>
</property>
```

- 保存并重启服务

> 注：除了此种方案之外还可以使用 HAProxy 具体参见 [官方文档](https://docs.cloudera.com/documentation/enterprise/5-9-x/topics/admin_ha_hiveserver2.html)

#### Hive Metastore

- 进入设置
- 筛选 Hive Metastore Server 服务
- 选择 Advanced 类型
- 找到 Hive Metastore Delegation Token Store 配置项
- 将其修改为 org.apache.hadoop.hive.thrift.DBTokenStore
- 保存并重启服务

[官方文档](https://docs.cloudera.com/documentation/enterprise/5-9-x/topics/admin_ha_hivemetastore.html#concept_zjr_qdt_xp)

### 连接样例

- pom.xml

```xml
<dependencies>
    <dependency>
        <groupId>org.apache.hadoop</groupId>
        <artifactId>hadoop-common</artifactId>
        <version>3.0.0-cdh6.3.1</version>
    </dependency>
    <dependency>
        <groupId>org.apache.hadoop</groupId>
        <artifactId>hadoop-client</artifactId>
        <version>3.0.0-cdh6.3.1</version>
    </dependency>
    <dependency>
        <groupId>org.apache.hive</groupId>
        <artifactId>hive-jdbc</artifactId>
        <version>2.1.1-cdh6.3.1</version>
    </dependency>
    <dependency>
        <groupId>org.apache.hive</groupId>
        <artifactId>hive-exec</artifactId>
        <version>2.1.1-cdh6.3.1</version>
    </dependency>
</dependencies>
```


```java
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.security.UserGroupInformation;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class Test {

    private static final String jdbc_class = "org.apache.hive.jdbc.HiveDriver";
    private static final String connection = "jdbc:hive2://<zookeeper_host_1>:<zookeeper_port_1>,<zookeeper_host_2>:<zookeeper_port_2>/<db>;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2";
    public static String krb5ConfigPath = "<krb5.conf_path>";
    public static String krb5KeytabPath = "<keytab_path>";
    public static String krb5Username = "<principal>";

    public static void main(String[] args) throws Exception {
        System.setProperty("java.security.krb5.conf", krb5ConfigPath);
        Configuration configuration = new Configuration();
        configuration.set("hadoop.security.authentication", "kerberos");
        try {
            UserGroupInformation.setConfiguration(configuration);
            UserGroupInformation.loginUserFromKeytab(krb5Username, krb5KeytabPath);
        } catch (IOException e) {
            System.out.println("auth error");
            e.printStackTrace();
        }
        String sql = "SHOW tables";
        try {
            Class.forName(jdbc_class);
            Connection con = DriverManager.getConnection(connection);
            Statement stmt = con.createStatement();
            ResultSet rs = stmt.executeQuery(sql);
            while (rs.next()) {
                System.out.println(rs.getString(1));
            }
            con.close();
        } catch (Exception e) {
            System.out.println("connection error or execute error");
            System.out.println(e.getMessage());
        }
    }
}
```

> 注: 如果没有开启 Kerberos 则可以删去 String sql 之前的内容。