---
title: pdf
date: 2024-03-25 22:26:13
tags:
- "PDF"
id: pdf
no_word_count: true
no_toc: false
---

## pdf

### pdf2htmlEX

pdf2htmlEX 项目可以将 PDF 转换为 HTML，而不会丢失文本或格式。

#### 使用方式

```bash
docker run -ti --rm -v ./test.pdf:/pdf/ -w /pdf pdf2htmlex/pdf2htmlex --zoom 1.3 test.pdf
```

#### 参考资料

[官方项目](https://github.com/pdf2htmlEX/pdf2htmlEX)

[Wiki](https://github.com/pdf2htmlEX/pdf2htmlEX/wiki/Download-Docker-Image)

### Stirling-PDF

Stirling-PDF 是一个强大的、本地托管的基于 Web 的 PDF 操作工具，功能包括拆分、合并、转换、重新组织、添加图像、旋转、压缩等。

#### 使用方式

```yaml
services:
  stirling-pdf:
    image: frooodle/s-pdf:latest
    ports:
      - '8080:8080'
    volumes:
      - /location/of/trainingData:/usr/share/tessdata #Required for extra OCR languages
      - /location/of/extraConfigs:/configs
      - /location/of/customFiles:/customFiles/
      - /location/of/logs:/logs/
    environment:
      - DOCKER_ENABLE_SECURITY=false
      - INSTALL_BOOK_AND_ADVANCED_HTML_OPS=false
      - LANGS=en_GB
```

> 注：OCR 需要模型文件放在 trainingData 目录下，中文需要 chi_sim.traineddata 文件。

[模型文件地址](https://github.com/tesseract-ocr/tessdata)

#### 参考资料

[官方项目](https://github.com/Stirling-Tools/Stirling-PDF)
