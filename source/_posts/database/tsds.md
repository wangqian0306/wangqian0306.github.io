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
PUT _ilm/policy/demo-sensor-lifecycle-policy
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_age": "1d",
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

> 注：官方网站中还设置了快照，如有需求可以进行参照。

创建模板

```text
PUT _component_template/demo-sensor-mappings
{
  "template": {
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date",
          "format": "date_optional_time||epoch_millis"
        },
        "sensor_id": {
          "type": "keyword",
          "time_series_dimension": true
        },
        "temperature": {
          "type": "half_float",
          "time_series_metric": "gauge"
        }
      }
    }
  },
  "_meta": {
    "description": "Mappings for @timestamp and sensor data"
  }
}

# Creates a component template for index settings
PUT _component_template/demo-sensor-settings
{
  "template": {
    "settings": {
      "index.lifecycle.name": "demo-sensor-lifecycle-policy",
      "index.look_ahead_time": "3h",
      "index.codec": "best_compression"
    }
  },
  "_meta": {
    "description": "Index settings for weather sensor data"
  }
}
```

创建索引模板

```text
PUT _index_template/demo-sensor-index-template
{
  "index_patterns": ["demo-sensor*"],
  "data_stream": { },
  "template": {
    "settings": {
      "index.mode": "time_series",
      "index.routing_path": ["sensor_id"]
    }
  },
  "composed_of": [ "demo-sensor-mappings", "demo-sensor-settings"],
  "priority": 500,
  "_meta": {
    "description": "Template for my weather sensor data"
  }
}
```

插入数据：

```text
POST demo-sensor-dev/_doc
{
  "@timestamp": "2099-05-06T16:21:15.000Z",
  "sensor_id": "SYKENET-000001",
  "location": "swamp",
  "temperature": 32.4,
  "humidity": 88.9
}
```

### 参考资料

[TSDS 官方文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/tsds.html)
