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

### wkhtmltopdf 

html 快捷转化为 PDF 的小工具（已经 Archived）。

#### 使用方式

使用如下命令安装：

```bash
sudo apt update
sudo apt upgrade
sudo apt install fonts-noto-cjk
sudo apt install wkhtmltopdf
```

然后使用如下命令运行即可：

```bash
wkhtmltopdf input.html output.pdf
```

如果有异步加载的内容可以使用如下逻辑：

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <script src="https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js"></script>
  <style>
    #main {
      width: 600px;
      height: 400px;
    }
  </style>
</head>
<body>
  <div id="main"></div>
  <script>
    var chart = echarts.init(document.getElementById('main'));
    chart.setOption({
      title: {
        text: '示例图表'
      },
      tooltip: {},
      xAxis: {
        data: ["A", "B", "C", "D"]
      },
      yAxis: {},
      series: [{
        name: '数量',
        type: 'bar',
        data: [5, 20, 36, 10]
      }]
    });
    chart.on('finished', function () {
      window.status = 'ready';
    });
  </script>
</body>
</html>
```

命令如下：

```bash
wkhtmltopdf --window-status ready input.html output.pdf
```
