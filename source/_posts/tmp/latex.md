---
title: LaTeX
date: 2021-12-20 21:41:32
tags: "LaTeX"
id: latex
no_word_count: true
no_toc: false
categories: LaTeX
---

## LaTeX

### 简介

LaTeX 是一种基于 Τ <sub>Ε</sub> Χ 的排版系统。经常用于生成复杂表格个数学公式。

### 在 Hexo 中使用 LaTeX 公式

#### Hexo Math 方法

进入 Hexo 项目内的根目录输入如下命令

```bash
npm i hexo-math --save
```

在配置文件中新增如下配置项目：

```yaml
math:
  katex:
    css: 'https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/katex.min.css'
    options:
      throwOnError: false
  mathjax:
    css: 'https://cdn.jsdelivr.net/npm/hexo-math@4.0.0/dist/style.css'
    options:
      conversion:
        display: false
      tex:
      svg:
```

在目标文章中使用如下格式插入所需内容

```text
{% mathjax %}
\frac{1}{x^2-1}
{% endmathjax %}
```

#### Hexo Fluid 主题方法

安装如下依赖：

```bash
npm uninstall hexo-renderer-marked --save
npm install hexo-renderer-markdown-it --save
npm install @traptitech/markdown-it-katex --save
```

在 hexo 根目录中的 `_config.yaml` 中新增如下内容：

```yaml
markdown:
  preset: 'default'
  render:
    html: true
    xhtmlOut: false
    langPrefix: 'language-'
    breaks: false
    linkify: true
    typographer: true
    quotes: '“”‘’'
  enable_rules:
  disable_rules:
  plugins:
    - "markdown-it-emoji"
    - "@traptitech/markdown-it-katex"
  anchors:
    level: 2
    collisionSuffix: ''
    permalink: false
    permalinkClass: 'header-anchor'
    permalinkSide: 'left'
    permalinkSymbol: '¶'
    case: 0
    separator: '-'
```

在根目录的 `_config_fluid.yml` 文件里修改如下部分：

```yaml
post:
  math:
    enable: true
    specific: true
    engine: katex
```

在目标文章中使用如下格式插入所需内容

```text
$$\frac{1}{x^2-1}$$
```

> 注：此种方法在 IDEA 里也能正常显示。

### 参考资料

[Overleaf](https://www.overleaf.com/learn)

[hexo-math](https://github.com/hexojs/hexo-math)

[Hexo Fluid 配置指南](https://hexo.fluid-dev.com/docs/guide/#latex-%E6%95%B0%E5%AD%A6%E5%85%AC%E5%BC%8F)
