---
title: IK 分词器
date: 2022-10-11 23:09:32
tags:
- "Elasticsearch"
- "IK Analysis plugin"
id: ik
no_word_count: true
no_toc: false
categories: "Elastic Stack"
---

## IK 分词器

### 简介

IK 分词器(IK Analysis) 是针对于 Elasticsearch 的一款分词插件。该插件提供了如下内容：

- Analyzer
  - `ik_smart`
  - `ik_max_word`
- Tokenizer
  - `ik_smart`
  - `ik_max_word`

### 安装

方式一：

- 在 [官方网站](https://github.com/medcl/elasticsearch-analysis-ik/releases) 上下载对应版本的压缩包
- 创建 `<es_path>/plugins/ik` 文件夹
- 将压缩包里的内容解压至此文件夹中
- 重启 elasticsearch

方式二：

- 进入 elasticsearch 安装根目录运行如下命令：

```text
./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/<version>/elasticsearch-analysis-ik-<version>.zip
```

### 试用

- 检测分词结果

```text
GET <index>/_analyze
{
  "analyzer": "ik_max_word",
  "text": ["白日依山尽，黄河入海流。"]
}
```

- 存储并查询数据

```text
PUT demo
{
  "mappings": {
    "properties": {
      "content":{
        "type": "text",
        "analyzer": "ik_max_word",
        "search_analyzer": "ik_smart"
      }
    }
  }
}

POST demo/_doc
{
  "content":"白日依山尽，黄河入海流。"
}

POST demo/_doc
{
  "content":"黄河西来决昆仑，咆哮万里触龙门。"
}

POST demo/_doc
{
  "content":"倒泻银河事有无，掀天浊浪只须臾。"
}

POST demo/_search
{
  "query" : { "match" : { "content" : "黄河" }}
}
```

### 配置字典

在 `{plugins}/elasticsearch-analysis-ik-*/config/IKAnalyzer.cfg.xml` 配置文件中：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
	<comment>IK Analyzer 扩展配置</comment>
	<!--用户可以在这里配置自己的扩展字典 -->
	<entry key="ext_dict">custom/mydict.dic;custom/single_word_low_freq.dic</entry>
	 <!--用户可以在这里配置自己的扩展停止词字典-->
	<entry key="ext_stopwords">custom/ext_stopword.dic</entry>
 	<!--用户可以在这里配置远程扩展字典 -->
	<entry key="remote_ext_dict">location</entry>
 	<!--用户可以在这里配置远程扩展停止词字典-->
	<entry key="remote_ext_stopwords">http://xxx.com/xxx.dic</entry>
</properties>
```

> 注：词典返回需要有 Header `Last-Modified` 和 `ETag`，文件编码是 `UTF-8`，一行一个词且换行符为 `\n`。

### 参考资料

[官方文档](https://github.com/medcl/elasticsearch-analysis-ik)
