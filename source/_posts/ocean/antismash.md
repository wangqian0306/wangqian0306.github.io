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

系统基于 Ubuntu 22.04.4 LTS，且：

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

> 注：装起来是真费劲啊。。。。

### 参考资料

[官方手册](https://docs.antismash.secondarymetabolites.org/)

[下载网站](https://dl.secondarymetabolites.org/releases/)
