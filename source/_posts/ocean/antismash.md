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

系统基于 Ubuntu 22.04.4 LTS

```bash
pyenv install anaconda3-2022.10
pyenv local anaconda3-2022.10
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict
sudo apt update
sudo apt install build-essential zlib1g-dev
sudo apt-get install hmmer2 hmmer diamond-aligner fasttree prodigal ncbi-blast+ muscle
conda install bioconda::glimmerhmm
conda install libgcc-ng
conda install bioconda::meme=4.11.2
wget https://dl.secondarymetabolites.org/releases/6.0.0/antismash-6.0.0.tar.gz
tar -xvf antismash-6.0.0.tar.gz
pip install ./antismash-6.0.0
download-antismash-databases
antismash --check-prereqs
```

> 注：由于 meme 版本不对所以此处方案没能成功安装，如果后续 antiSMASH 版本更新可以再尝试。

### 参考资料

[官方手册](https://docs.antismash.secondarymetabolites.org/)

[下载网站](https://dl.secondarymetabolites.org/releases/)
