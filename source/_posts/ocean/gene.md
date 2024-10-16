---
title: SequenceServer
date: 2024-08-08 23:09:32
tags:
- "GENE"
id: sequenceserver
no_word_count: true
no_toc: false
categories:
- "Ocean"
---

## SequenceServer

### 简介

SequenceServer 是基于 BLAST 的一款基因检索服务。

### 使用方式

首先需要拉取镜像：

```bash
docker pull wurmlab/sequenceserver:latest
```

然后下载样例基因文件：

```bash
mkdir db
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz
gunzip GCF_000005845.2_ASM584v2_genomic.fna.gz
mv GCF_000005845.2_ASM584v2_genomic.fna ./db/demo.fna
```

然后根据基因库文件生成索引：

```bash
docker run --rm -v /xxx/db:/db -it wurmlab/sequenceserver:latest /sequenceserver/bin/sequenceserver -m
```

默认的配置只支持同时运行一个查询任务，需要修改配置文件 `sequenceserver.conf`。

```text
---
:host: 0.0.0.0
:port: 4567
:databases_widget: classic
:options:
  :blastn:
    :default:
      :description:
      :attributes:
      - "-task blastn"
      - "-evalue 1e-5"
  :blastp:
    :default:
      :description:
      :attributes:
      - "-evalue 1e-5"
  :blastx:
    :default:
      :description:
      :attributes:
      - "-evalue 1e-5"
  :tblastx:
    :default:
      :description:
      :attributes:
      - "-evalue 1e-5"
  :tblastn:
    :default:
      :description:
      :attributes:
      - "-evalue 1e-5"
:num_threads: 5
:num_jobs: 5
:job_lifetime: 43200
:cloud_share_url: https://share.sequenceserver.com/api/v1/shared-job
:large_result_warning_threshold: 262144000
:optimistic: false
:database_dir: "/db"
```

> 注：job_lifetime 代表查询的保存时间，单位是分钟，默认是 30 天。

之后可以编写 `docker-compose.yaml` 文件管理服务：

```yaml
services:
  sequenceserver:
    image: wurmlab/sequenceserver:latest
    ports:
      - "4567:4567"
    volumes:
      - "./db:/db"
      - "./sequenceserver.conf:/root/.sequenceserver.conf"
```

使用如下命令运行文件即可：

```bash
docker-compose up -d
```

之后访问 [http://localhost:4567](http://localhost:4567) 在文本输入框内进行检索即可，样例如下：

```text
>demo
CTCCTAAAGGGCCCAGCAAGACCAGCTGGTTGATAGGTCGGATGTGGACGCGCTGCAAGGCGTTGAGCTAACCGATACTA
```

如果有需要也可以使用接口调用数据请参照 [接口文档](https://sequenceserver.com/doc/api/)，例如使用 `curl` ：

获取数据库 ID 用于检索：

```bash
curl $BASEURL/searchdata.json
```

发起搜索请求：

```bash
jobUrl=$(curl -v -X POST -Fsequence=ATGTTACCACCAACTATTAGAATTTCAG -Fmethod=blastn -Fdatabases[]=3c0a5bc06f2596698f62c7ce87aeb62a --write-out '%{redirect_url}' $BASEURL)
```

> 注：CSRF 如果异常可以注释掉 `lib/sequenceserver/routes.rb` 中的 `use Rack::Csrf, raise: true, skip: ['POST:/cloud_share']` 

### 参考资料

[官方网站](https://sequenceserver.com/)

[项目源码](https://github.com/wurmlab/sequenceserver)

[接口文档](https://sequenceserver.com/doc/api/)
