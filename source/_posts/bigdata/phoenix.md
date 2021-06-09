---
title: Phoenix 搭建流程整理
date: 2020-12-06 22:26:13
tags:
- "CDH"
- "Phoenix"
id: phoenix
no_word_count: true
no_toc: false
categories: 大数据
---

## Phoenix 搭建流程整理

### 简介

Phoenix 是一个开源的HBASE SQL层应用程序。

### 安装流程

- CSD 激活

在 CM 主机上执行如下命令放入激活文件

```bash
mkdir -p /opt/cloudera/csd/
wget https://archive.cloudera.com/phoenix/6.2.0/csd/PHOENIX-1.0.jar -P /opt/cloudera/csd/
```

- Parcel 配置

进入 CDH 然后配置如下 parcel

```text
https://archive.cloudera.com/phoenix/6.2.0/parcels/
```

安装分配并激活此 parcel 即可

- 安装服务

在 Parcel 配置完成后需要重启 scm-server 服务才可以进行安装

```bash
systemctl restart cloudera-scm-server
```

之后使用界面安装即可

### 测试

#### Python

```bash
pip3 install -i https://mirrors.cloud.tencent.com/pypi/simple --user phoenixdb
```

```python
import phoenixdb
import phoenixdb.cursor

database_url = 'http://192.168.2.116:8765/'
conn = phoenixdb.connect(database_url, autocommit=True)

cursor = conn.cursor()
#cursor.execute("CREATE TABLE asd (id INTEGER PRIMARY KEY, username VARCHAR)")
cursor.execute("UPSERT INTO asd VALUES (?, ?)", (2, 'wq'))
#cursor.execute("SELECT * FROM asd")
#print(cursor.fetchall())

#cursor = conn.cursor(cursor_factory=phoenixdb.cursor.DictCursor)
#cursor.execute("SELECT * FROM USERS WHERE id=1")
#print(cursor.fetchone()['USERNAME'])
```

#### Java

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>org.example</groupId>
  <artifactId>wqphoenix</artifactId>
  <version>1.0-SNAPSHOT</version>
  <repositories>
    <repository>
      <id>cloudera</id>
      <url>https://repository.cloudera.com/artifactory/cloudera-repos/</url>
    </repository>
  </repositories>
  <dependencies>
    <dependency>
      <groupId>org.apache.phoenix</groupId>
      <artifactId>phoenix-core</artifactId>
      <version>5.0.0.7.1.4.0-203</version>
    </dependency>
    <dependency>
      <groupId>org.apache.hadoop</groupId>
      <artifactId>hadoop-common</artifactId>
      <version>3.0.0-cdh6.3.1</version>
    </dependency>
    <dependency>
      <groupId>org.projectlombok</groupId>
      <artifactId>lombok</artifactId>
      <optional>true</optional>
      <version>1.18.16</version>
    </dependency>
  </dependencies>
</project>
```

```java
package org.example.wqphoenix;

import lombok.extern.slf4j.Slf4j;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.util.Properties;

@Slf4j
public class Demo {

    public static void main(String[] args) {
        Properties props = new Properties();
        props.setProperty("phoenix.query.timeoutMs", "100000");
        props.setProperty("hbase.rpc.timeout", "100000");
        props.setProperty("hbase.client.scanner.timeout.period", "100000");
//        props.setProperty("phoenix.schema.isNamespaceMappingEnabled", "true");
        try {
            Class.forName("org.apache.phoenix.jdbc.PhoenixDriver");
            String url = "jdbc:phoenix:cdh-3.rainbowfish11000.local:2181";
            DriverManager.setLoginTimeout(10);
            Connection conn = DriverManager.getConnection(url, props);
            Statement statement = conn.createStatement();
            long time = System.currentTimeMillis();

            String create_sql = "CREATE TABLE Test (id INTEGER PRIMARY KEY, username VARCHAR)";
            statement.execute(create_sql);

            String insert_sql = "UPSERT INTO Test VALUES (3, 'demo')";
            statement.executeUpdate(insert_sql);

            String sql = "SELECT * FROM Test";
            ResultSet rs = statement.executeQuery(sql);
            while (rs.next()) {
                System.out.println("*****************");
                System.out.println(String.valueOf(rs.getInt(1)));
                System.out.println(rs.getString(2));
            }
            rs.close();

            long timeUsed = System.currentTimeMillis() - time;
            System.out.println("time " + timeUsed + "mm");
            statement.close();
            conn.commit();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

```

### 参考资料

[参考文档](https://www.it610.com/article/1283322739968458752.htm)