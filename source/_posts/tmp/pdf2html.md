---
title: pdf2htmlEX
date: 2024-03-25 22:26:13
tags:
- "PDF"
id: pdf2htmlEX
no_word_count: true
no_toc: false
---

## pdf2htmlEX

### 简介

pdf2htmlEX 项目可以将 PDF 转换为 HTML，而不会丢失文本或格式。

### 使用方式

#### Docker

```bash
docker run -ti --rm -v ./test.pdf:/pdf/ -w /pdf pdf2htmlex/pdf2htmlex --zoom 1.3 test.pdf
```

### 参考资料

[官方项目](https://github.com/pdf2htmlEX/pdf2htmlEX)

[Wiki](https://github.com/pdf2htmlEX/pdf2htmlEX/wiki/Download-Docker-Image)
