---
title: DataX
date: 2022-11-15 22:43:13
tags: "DataX"
id: datax
no_word_count: true
no_toc: false
categories: 大数据
---

## DataX

### 简介

DataX 是阿里云 DataWorks数据集成 的开源版本，在阿里巴巴集团内被广泛使用的离线数据同步工具/平台。DataX 实现了包括 MySQL、Oracle、OceanBase、SqlServer、Postgre、HDFS、Hive、ADS、HBase、TableStore(OTS)、MaxCompute(ODPS)、Hologres、DRDS 等各种异构数据源之间高效的数据同步功能。

### 安装

前置条件

- JDK 1.8+
- Python 2+

```bash
wget https://datax-opensource.oss-cn-hangzhou.aliyuncs.com/<version>/datax.tar.gz
tar -zxvf datax.tar.gz
cd datax
```

检测环境脚本：

```bash
python ./bin/datax.py ./job/job.json
```

### 读取 MySQL 并存储至 Hive

DataX 是通过写入 HDFS 文件的方式完成了写入 Hive 的功能，所以需要注意写入文件的位置和数据表的存储类型。

```hiveql
use default;
CREATE TABLE demo
(
    id     INT,
    username       String
)
    ROW FORMAT DELIMITED
        FIELDS TERMINATED BY '\t'
    STORED AS TEXTFILE;
```

```json
{
  "job": {
    "setting": {
      "speed": {
        "channel": 1
      },
      "errorLimit": {
        "record": 0,
        "percentage": 0.02
      }
    },
    "content": [
      {
        "reader": {
          "name": "mysqlreader",
          "parameter": {
            "username": "root",
            "password": "xxxx",
            "column": [
              "id",
              "username"
            ],
            "connection": [
              {
                "table": [
                  "user"
                ],
                "jdbcUrl": [
                  "jdbc:mysql://xxx.xxx.xxx.xxx:3306/test"
                ]
              }
            ]
          }
        },
        "writer": {
          "name": "hdfswriter",
          "parameter": {
            "defaultFS": "hdfs://xxxx.xxxx.xxxx:8020",
            "fileType": "text",
            "path": "/user/hive/warehouse/demo",
            "fileName": "20221116",
            "column": [
              {
                "name": "id",
                "type": "INT"
              },
              {
                "name": "username",
                "type": "STRING"
              }
            ],
            "writeMode": "append",
            "fieldDelimiter": "\t",
            "haveKerberos": true,
            "kerberosKeytabFilePath": "/<path>/hive.keytab",
            "kerberosPrincipal": "hive/xxx"
          }
        }
      }
    ]
  }
}
```

```bash
python ./bin/datax.py <path_to_json_file>
```

### 参考资料

[官方项目](https://github.com/alibaba/DataX)
