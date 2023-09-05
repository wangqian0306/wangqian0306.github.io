---
title: AsciiDoc
date: 2021-03-08 22:26:13
tags:
- "Asciidoc"
id: asciidoc
no_word_count: true
no_toc: false
---

## Asciidoc

### 简介

AsciiDoc 是一种文本文档格式，可以用于书写文档，文章，手册，书籍和 UNIX 手册。AsciiDoc文件可以使用asciidoc命令转换成HTML和DocBook文件格式。AsciiDoc结构先进：AsciiDoc语法和输出标签(几乎可以转换成任意的 SGML/XML 标记)都可以由用户自己定义和扩展。

适用场景：

- 可自定义的表格及表注释
- 多文件进行合并渲染
- 掺杂图表和数学公示以及代码分行注释
- 可以使用各种主题

> 注：Asciidoc 像是增强版的 Markdown 相较于 LaTeX 来说更为简便。

### 处理器

AsciiDoc 语言可以编写文档，这是一种基于文本的书写格式。AsciiDoc 语言被设计为不显眼且简洁，以简化写作。但是 AsciiDoc 本身并不是一种发布格式。它更像是一种速记方式。这就是 AsciiDoc 处理器的用武之地。

AsciiDoc 有很多的处理器(例如 Asciidoctor)读取 AsciiDoc 源并将其转换为可发布的格式，例如 HTML 5 或 PDF。它还可以将其转换为本身可以由发布工具链（例如 DocBook）处理的格式。

### 与 IDEA 集成

首先需要在 IDEA 的插件商店安装如下插件

- AsciiDoc 

> 注：虽然名字是 AsciiDoc 但实际上是 Asciidoctor 的插件。

### Asciidoctor 环境安装

Asciidoctor 需要 ruby 环境才能进行安装具体命令如下：

```bash
dnf install ruby -y
gem install asciidoctor
gem install asciidoctor-pdf --pre
```

此外由于 `Asciidoctor` 不支持中文，所以还需要自行安装中文字体和字形，可以使用 [参考字库及文件](https://github.com/life888888/asciidoctor-pdf-cjk-ext) 中的 `notosans-cjk-sc.zip` 压缩包来预览渲染结果，使用命令如下：

```bash
asciidoctor-pdf -a pdf-theme=default-notosans-cjk-sc-theme.yml -a pdf-fontsdir=. test.adoc
```

### 参考资料

[语法文档](https://docs.asciidoctor.org/asciidoc/latest/)

[处理器文档](https://docs.asciidoctor.org/asciidoctor/latest/)

[参考字库及文件](https://github.com/life888888/asciidoctor-pdf-cjk-ext)