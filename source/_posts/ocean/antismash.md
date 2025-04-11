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

#### Docker

创建本地卷路径

```bash
mkdir input
mkdir output
wget -P output https://github.com/antismash/antismash/blob/master/antismash/test/integration/data/nisin.gbk
```

然后编写如下 `docker-compose.yaml` 文件即可

```bash
services:
  anti:
    image: antismash/standalone:latest
    command: [nisin.gbk]
    user: <uid>:<gid>
    volumes: 
      - "./input:/input"
      - "./output:/output"
```

使用如下命令，等待命令完成后，即可在 /output 目录获取到处理结果。

```bash
docker-compose up
```

如果需要进入容器中试用其他工具可以使用如下命令：

```bash
docker run --rm -it --entrypoint="" antismash/standalone:latest /bin/bash
```

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

#### 系统安装(失败)

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

##### 数据下载指纹不一致

在下载数据时遇到了 sha256sum mismatch 的问题。

想使用如下逻辑进行修复：

```bash
curl -q https://dl.secondarymetabolites.org/releases/latest/download_antismash_databases_docker > demo_dl
chmod a+x demo_dl
mkdir db
./demo_dl db
```

此处即可使用 Docker 下载数据库，将其移动至 `~/asenv/lib/python<version>/site-packages/antismash/databases` 内之后正常使用即可。

### 参考资料

[官方手册](https://docs.antismash.secondarymetabolites.org/)

[下载网站](https://dl.secondarymetabolites.org/releases/)
