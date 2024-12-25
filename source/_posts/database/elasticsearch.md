---
title: Elasticsearch 入门
date: 2020-07-04 23:09:32
tags:
- "Elasticsearch"
- "Elastic Stack"
id: elasticsearch
no_word_count: true
no_toc: false
categories: "Elastic Stack"
---

## Elasticsearch 入门

### 简介

Elasticsearch 是一个分布式、RESTful 风格的搜索和数据分析引擎。

### 本地安装

在 CentOS 中可以使用如下命令配置软件源

```bash
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
vim /etc/yum.repos.d/elastic.repo
```

写入如下配置项即可

```text
[elasticsearch]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
```

在写入完成后可以使用如下命令安装软件

```bash
sudo yum install --enablerepo=elasticsearch elasticsearch
```

- 配置

软件配置在 `/etc/elasticsearch` 目录中。

默认日志在 `/var/log/elasticsearch` 目录中。

- JDK 配置建议

Xms 和 Xms 设置成一样。

XMx 不要超过机器内存的 50 %，不要超过 30 GB。

- 启动服务

```bash
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
```

- 关闭服务

```bash
sudo systemctl stop elasticsearch.service
```

### 容器化安装

- 编写如下 Docker Compose 文件

```yaml
services:
  es:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.15.1
    environment:
      - discovery.type=single-node
    ulimits:
      memlock:
        soft: -1
        hard: -1
    ports:
      - 9200:9200
      - 9300:9300
```

- 使用如下命令启动运行

```bash
docker-compose up -d
```

> 注：建议与 kibana 一起部署，详情参见 kibana 章节。

### 生产环境配置推荐

- 开启 X-Pack 用户管理机制
- 使用自签名 SSL 证书(https)保证集群内部沟通加密
- 设置 3 个主节点做故障冗余
- 日志类的应用，单个分片不要大于 50 GB
- 搜索类的应用，单个分片不要超过 20 GB

### 基本命令整理

查看集群信息

```text
### 查看基本信息
GET /

### 查看健康状态
GET /_cat/health?
```

索引操作

```text
### 创建索引
PUT demo

### 获取索引列表
GET _cat/indices

### 查询索引详情
GET demo

### 修改索引
PUT /demo/_settings
{
  "aliase": {
    "test": {}
  },
  "index" : {
    "refresh_interval" : null
  }
}

### 删除索引
DELETE demo
```

索引模板

```text
### 创建索引模板
PUT _template/<name>
{
  "index_patterns": [
    "<patterns>"
  ], 
  "mappings": {
    "properties": {}
  }
}

### 查询索引模板详情
GET _template/demo_template

### 获取索引模板列表
GET _cat/templates

### 删除索引模板
DELETE _template/demo_template
```

字段映射：

```json
{
  "mappings": {
    "properties": {
      "distance": {
        "type": "long"
      },
      "route_length_miles": {
        "type": "alias",
        "path": "distance" 
      },
      "transit_mode": {
        "type": "keyword"
      }
    }
  }
}
```

数据类型：

- aggregate_metric_*
- alias
- arrays
- binary
- boolean
- completion
- date
- date_nanos
- dense_vector
- flattened
- geo_point
- geo_shape
- histogram
- ip
- join
- keyword
- nested
- numeric
  - long
  - integer
  - short
  - byte
  - double
  - float
  - half_float
  - scaled_float
  - unsigned_long
- percolator
- point
- integer_range
- float_range
- long_range
- double_range
- date_range
- ip_range
- rank_feature
- rank_features
- search_as_you_type
- orientation
- shape
  - orientation
  - ignore_malformed
  - ignore_z_value
  - coerce
- text
- version

数据操作

```text
### 插入数据
PUT demo/_doc/1
{
  "name": "demo",
  "age": 18
}

### 根据 ID 获取数据
GET demo/_doc/1

### 查询数据
GET demo/_search

### 修改数据
POST demo/_doc/1
{
  "name": "demo",
  "age": 20
}

### 删除数据
DELETE demo/_doc/1
```

查询操作：

> 注：此处内容为查询接口输入参数。

```json
{
  "from": 0,
  "size": 20,
  "_source": ["result_field_1","result_field_2"],
  "query": {
    "bool": {
      "must": [],
      "filter": [],
      "must_not": [],
      "should": [],
      "minimum_should_match": 1,
      "boost": 1.0
    },
    "boosting": {
      "positive": {
      },
      "negative": {
      },
      "negative_boost": 0.5
    },
    "constant_score": {
      "filter": {
      },
      "boost": 1.2
    },
    "dis_max": {
      "queries": [
      ],
      "tie_breaker": 0.7
    },
    "function_score": {
      "query": {},
      "boost": "5",
      "random_score": {},
      "boost_mode": "multiply"
    },
    "intervals": {},
    "match": {"<key>": "<content>"},
    "match_bool_prefix": {"<key>": "<content>"},
    "match_phrase": {"<key>": "<content>"},
    "match_phrase_prefix": {"<key>": "<content>"},
    "combined_fields": {
      "query": "<content>",
      "fields": [
        "<field_1>",
        "<field_2>"
      ]
    },
    "multi_match": {
      "query": "<content>",
      "fields": [
        "<field_1>",
        "<field_2>"
      ]
    },
    "query_string": {
      "query": "<content>",
      "default_field": "content"
    },
    "simple_query_string": {
      "query": "<content>",
      "fields": [
        "<field_1>",
        "<field_2>"
      ],
      "default_operator": "and"
    },
    "term": {"<key>": "<content>"},
    "range": {
      "<key>": {
        "gte": "<date>",
        "gt": "<date>",
        "lte": "<date>",
        "lt": "<date>"
      }
    },
    "geo_bounding_box": {},
    "geo_distance": {},
    "geohash_grid": {},
    "geo_polygon": {},
    "geo_shape": {},
    "shape": {},
    "nested": {
      "path": "<field>",
      "query": {}
    },
    "has_child": {},
    "has_parent": {},
    "parent_id": {},
    "match_all": {},
    "span_containing": {},
    "span_near": {},
    "span_first": {},
    "span_not": {},
    "span_or": {},
    "span_term": {},
    "span_within": {},
    "distance_feature": {},
    "more_like_this": {},
    "percolate": {},
    "rank_feature": {},
    "script": {},
    "script_score": {},
    "wrapper": {},
    "pinned": {},
    "exists": {"<key>": "<content>"},
    "fuzzy": {"<key>": "<content>"},
    "ids": {"values": ["<id_1>","<id_2>"]},
    "prefix": {"<key>": "<content>"},
    "regexp": {},
    "terms": {"<key>": ["<content_1>","<content_2>"]},
    "terms_set": {},
    "wildcard": {}
  },
  "sort": [
    {
      "<field>": {
        "order": "desc"
      }
    }
  ]
}
```

聚合操作：

```json
{
  "size": 0,
  "query": {},
  "aggs": {
    "<result_field>": {
      "AGG_TYPE": {}
    }
  }
}
```

例如：

```json
{
  "size": 0,
  "aggs": {
    "result": {
      "terms": {
        "field": "<field>"
      },
      "aggs": {
        "sum": {
          "field": "<field>"
        }
      }
    }
  }
}
```

按照时间聚合：

```json
{
  "size": 0,
  "aggs": {
    "group_by_xxx": {
      "terms": {
        "field": "xxx"
      },
      "aggs": {
        "window_by_hour": {
          "date_histogram": {
            "field": "xxx",
            "interval": "1d"
          },
          "aggs": {
            "avg_xxx": {
              "avg": {
                "field": "xxx"
              }
            }
          }
        }
      }
    }
  }
}
```

### 常见问题

#### 索引不可写入

使用如下方式修改配置即可

`POST`: `http://<host>:<port>/_settings`

```json
{
  "index": {
    "blocks": {
      "read_only_allow_delete": "false"
    }
  }
}
```

> 注：若修改之后不生效请检查磁盘剩余空间。

### 参考资料

[官方文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html)

[安装手册](https://www.elastic.co/guide/en/elasticsearch/reference/8.8/rpm.html#rpm-running-systemd)