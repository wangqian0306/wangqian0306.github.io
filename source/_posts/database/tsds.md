---
title: TSDS
date: 2022-12-05 23:09:32
tags:
- "Elasticsearch"
- "Elastic Stack"
id: tsds
no_word_count: true
no_toc: false
categories: "Elastic Stack"
---

## TSDS

### 简介

时序数据流(time series data stream,TSDS)是将带有时间戳的指标数据建模为一个或多个时间序列的一种存储方式，相较于普通的存储方式来说更节省存储空间。

> 注：此功能暂时处于试用阶段。

### 使用方式

创建生命周期

```text
PUT _ilm/policy/demo-lifecycle-policy
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_primary_shard_size": "50gb"
          }
        }
      },
      "warm": {
        "min_age": "30d",
        "actions": {
          "shrink": {
            "number_of_shards": 1
          },
          "forcemerge": {
            "max_num_segments": 1
          }
        }
      },
      "cold": {
        "min_age": "60d",
        "actions": {}
      },
      "delete": {
        "min_age": "735d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

创建模板

```text
PUT _component_template/my-mappings
{
  "template": {
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date",
          "format": "date_optional_time||epoch_millis"
        },
        "message": {
          "type": "wildcard"
        }
      }
    }
  },
  "_meta": {
    "description": "Mappings for @timestamp and message fields",
    "my-custom-meta-field": "More arbitrary metadata"
  }
}

# Creates a component template for index settings
PUT _component_template/my-settings
{
  "template": {
    "settings": {
      "index.lifecycle.name": "demo-lifecycle-policy"
    }
  },
  "_meta": {
    "description": "Settings for ILM",
    "my-custom-meta-field": "More arbitrary metadata"
  }
}
```

创建索引模板

```text
PUT _index_template/my-index-template
{
  "index_patterns": ["my-data-stream*"],
  "data_stream": { },
  "composed_of": [ "my-mappings", "my-settings" ],
  "priority": 500,
  "_meta": {
    "description": "Template for my time series data",
    "my-custom-meta-field": "More arbitrary metadata"
  }
}
```

创建索引：

```text
PUT _data_stream/my-data-stream
```

### 参考资料

[TSDS 官方文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/tsds.html)
