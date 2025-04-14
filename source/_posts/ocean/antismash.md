---
title: antismash
date: 2024-07-11 23:09:32
tags:
- "antiSMASH "
id: antismash
no_word_count: true
no_toc: false
categories: "Ocean"
---

### 简介

antiSMASH 框架允许检测基因组中共存的生物合成基因簇，称为生物合成基因簇 (BGC)。

### 安装方式

#### 系统安装

系统基于 Ubuntu 24.04.4 LTS

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https
sudo wget http://dl.secondarymetabolites.org/antismash-stretch.list -O /etc/apt/sources.list.d/antismash.list
sudo wget -q -O- http://dl.secondarymetabolites.org/antismash.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install hmmer2 hmmer diamond-aligner fasttree prodigal ncbi-blast+ glimmerhmm muscle3 meme-suite -y
sudo apt install python3-pip python3-virtualenv git -y
git clone https://github.com/antismash/antismash.git
virtualenv -p $(which python3) ~/asenv
source ~/asenv/bin/activate
pip install ./antismash
download-antismash-databases
antismash --prepare-data
```

> 注：此处需要注意版本问题，源码下载尽可能使用稳定版，切换分支到指定版本，此处是特殊需求。

若遇到下载指纹不匹配的问题，可以选择修改 `antismash/download_databases.py` 文件，并重新执行安装和下载流程。

测试命令如下：

```bash
antismash --genefinding-tool prodigal --taxon bacteria --genefinding-gff3 <name>.gff <name>.fna --cb-knownclusters --cb-general --cc-mibig --clusterhmmer --cb-subclusters --fullhmmer --asf --pfam2go --smcog-trees --output-dir <name>
```

#### Docker

如果只是想运行命令可以使用如下方式：

```bash
mkdir ~/bin
curl -q https://dl.secondarymetabolites.org/releases/latest/docker-run_antismash-lite > ~/bin/run_antismash
chmod a+x ~/bin/run_antismash
```

下载数据集：

```bash
curl -q https://dl.secondarymetabolites.org/releases/latest/download_antismash_databases_docker > demo_dl
chmod a+x demo_dl
mkdir -p /data/databases
./demo_dl /data/databases
```

之后使用如下命令即可：

```bash
run_antismash <input file> <output directory> [antismash options]
```

如果想自定义可以遵循如下逻辑：

如果需要进入容器中试用其他工具可以使用如下命令：

```bash
docker run --rm -it --entrypoint="" antismash/standalone:latest /bin/bash
```

运行脚本：

```bash
docker run --rm antismash/standalone:latest -v ./db:/dataset -v ./input:/input -v ./output:/output --genefinding-tool prodigal --taxon bacteria --genefinding-gff3 <name>.gff <name>.fna --cb-knownclusters --cb-general --cc-mibig --clusterhmmer --cb-subclusters --fullhmmer --asf --pfam2go --smcog-trees --output-dir output
```

> 注：此处暂未验证。

官方除了命令行的方式之外还提供了 web 界面，如需远程调用可以尝试使用 [websmash](https://github.com/antismash/websmash) 

```text
FROM antismash/standalone:latest
WORKDIR /web
RUN apt-get update && apt-get install -y git uwsgi
RUN git clone https://github.com/antismash/websmash.git
RUN cd websmash
RUN pip install -r requirements.txt
CMD ["uwsgi"]
```

### 参考资料

[官方手册](https://docs.antismash.secondarymetabolites.org/)

[下载网站](https://dl.secondarymetabolites.org/releases/)
