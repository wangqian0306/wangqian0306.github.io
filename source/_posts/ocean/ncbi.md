---
title: NCBI
date: 2024-02-02 23:09:32
tags:
- "NCBI"
id: ncbi
no_word_count: true
no_toc: false
categories: "Ocean"
---

## NCBI 

### 简介

美国国家生物技术信息中心(National Center for Biotechnology Information) 通过提供对生物医学和基因组信息的访问来促进科学和健康。

### 数据下载

NCBI 中的数据需要使用 Aspera 软件或官网指定的下载工具进行下载。

### 数据使用

在本地使用需要 Blast 工具进行检索和使用。

### 请求接口

在官网的检索逻辑可以使用如下方式实现：

#### 检索物种

请求内容：

```bash
curl https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=genome&term=Pseudoalteromonas%20lipolytica&retmode=json
```

返回内容：

```json
{
  "header": {
    "type": "esearch",
    "version": "0.3"
  },
  "esearchresult": {
    "count": "1",
    "retmax": "1",
    "retstart": "0",
    "idlist": [
      "24143"
    ],
    "translationset": [
      {
        "from": "Pseudoalteromonas lipolytica",
        "to": "\"Pseudoalteromonas lipolytica\"[Organism]"
      }
    ],
    "translationstack": [
      {
        "term": "\"Pseudoalteromonas lipolytica\"[Organism]",
        "field": "Organism",
        "count": "1",
        "explode": "Y"
      },
      "GROUP"
    ],
    "querytranslation": "\"Pseudoalteromonas lipolytica\"[Organism]"
  }
}
```

> 注：其中 esearchresult.idlist 字段中的内容既是详情。

#### 查看详细信息

请求内容：

```bash
curl https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=assembly&id=27562771,22115781,22115651,8268061,1267311,1256401,1228791,1194231,885031,781391,498841,124281&retmode=json
```

响应内容：

```json
{
  "header": {
    "type": "esummary",
    "version": "0.3"
  },
  "result": {
    "uids": [
      "12673111"
    ],
    "12673111": {
      "uid": "12673111",
      "rsuid": "",
      "gbuid": "33154618",
      "assemblyaccession": "GCA_021644345.2",
      "lastmajorreleaseaccession": "GCA_021644345.2",
      "latestaccession": "GCA_021644345.4",
      "chainid": "21644345",
      "assemblyname": "PDT001145882.3",
      "ucscname": "",
      "ensemblname": "",
      "taxid": "287",
      "organism": "Pseudomonas aeruginosa (g-proteobacteria)",
      "speciestaxid": "287",
      "speciesname": "Pseudomonas aeruginosa",
      "assemblytype": "haploid",
      "assemblystatus": "Contig",
      "assemblystatussort": 6,
      "wgs": "ABEUHA02",
      "gb_bioprojects": [
        {
          "bioprojectaccn": "PRJNA288601",
          "bioprojectid": 288601
        }
      ],
      "gb_projects": [],
      "rs_bioprojects": [],
      "rs_projects": [],
      "biosampleaccn": "SAMN22068470",
      "biosampleid": "22068470",
      "biosource": {
        "infraspecieslist": [],
        "sex": "",
        "isolate": "2021QW-00053"
      },
      "coverage": "47",
      "partialgenomerepresentation": "false",
      "primary": "33154608",
      "assemblydescription": "NCBI Pathogen Detection Assembly PDT001145882.3",
      "releaselevel": "Major",
      "releasetype": "Major",
      "asmreleasedate_genbank": "2022/05/06 00:00",
      "asmreleasedate_refseq": "1/01/01 00:00",
      "seqreleasedate": "2022/05/02 00:00",
      "asmupdatedate": "2022/05/06 00:00",
      "submissiondate": "2022/05/02 00:00",
      "lastupdatedate": "2022/05/06 00:00",
      "submitterorganization": "Centers for Disease Control and Prevention. Division of Healthcare Quality Promotion",
      "refseq_category": "na",
      "anomalouslist": [],
      "exclfromrefseq": [
        "from large multi-isolate project"
      ],
      "propertylist": [
        "excluded-from-refseq",
        "full-genome-representation",
        "genbank_has_annotation",
        "has_annotation",
        "replaced",
        "replaced_genbank",
        "wgs"
      ],
      "fromtype": "",
      "synonym": {
        "genbank": "GCA_021644345.2",
        "refseq": "",
        "similarity": ""
      },
      "contign50": 98929,
      "scaffoldn50": 98929,
      "annotrpturl": "",
      "ftppath_genbank": "ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/021/644/345/GCA_021644345.2_PDT001145882.3",
      "ftppath_refseq": "",
      "ftppath_assembly_rpt": "ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/021/644/345/GCA_021644345.2_PDT001145882.3/GCA_021644345.2_PDT001145882.3_assembly_report.txt",
      "ftppath_stats_rpt": "ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/021/644/345/GCA_021644345.2_PDT001145882.3/GCA_021644345.2_PDT001145882.3_assembly_stats.txt",
      "ftppath_regions_rpt": "",
      "busco": {
        "refseqannotationrelease": "",
        "buscolineage": "",
        "buscover": "",
        "complete": "",
        "singlecopy": "",
        "duplicated": "",
        "fragmented": "",
        "missing": "",
        "totalcount": ""
      },
      "sortorder": "9C6X0C0F9999010700216443459700",
      "meta": " ..."
    }
  }
```

其中重点字段如下：

- `results.<x>.refseq_category` 若为 `reference genom` 则有文章详细阐述
- `results.<x>.exclfromrefseq` 此处为注意事项
- `results.<x>.biosource` 此处为 Modifyer 类型，若 infraspecieslist 不为空则证明其为 strain 类型。

#### 数据下载

请求内容：

```cmd
curl -X POST "https://api.ncbi.nlm.nih.gov/datasets/v2/genome/download?filename=demo.zip" \
-H "Content-Type: application/json" \
-d '{
  "accessions": [
    "GCA_014925285.1"
  ],
  "include_annotation_type": [
    "GENOME_GFF",
    "PROT_FASTA",
    "CDS_FASTA",
    "GENOME_FASTA"
  ]
}' \
-o demo.zip
```

响应内容：

下载结果

> 注：此处由于网络问题，下载最好加上 api_token 且还是会失败，建议采用命令的形式完成。

### 使用命令

使用如下命令安装脚本：

```bash
curl -o datasets 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/datasets'
sudo chmod a+x datasets
sudo mv datasets /usr/local/bin
```

使用如下命令即可下载基因文件：

```bash
datasets download genome accession GCF_037619325.1 GCF_900116435.1 --include genome,gff3,cds,protein --filename all_genomes.zip
```

### 参考资料

[NCBI 数据下载页](https://www.ncbi.nlm.nih.gov/home/download/)

[Aspera 软件下载](https://www.ibm.com/products/aspera/downloads)

[Entrez Programming Utilities Help](https://www.ncbi.nlm.nih.gov/books/NBK25500/)

[NCBI Datasets v2 REST API](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/api/rest-api/)
