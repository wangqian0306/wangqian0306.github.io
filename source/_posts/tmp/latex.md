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

- 进入 Hexo 项目内的根目录输入如下命令

```bash
npm i hexo-math --save
```

- 在配置文件中新增如下配置项目：

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

- 在目标文章中使用如下格式插入所需内容

```text
{% mathjax %}
\frac{1}{x^2-1}
{% endmathjax %}
```

### 参考资料

[Overleaf](https://www.overleaf.com/learn)

[hexo-math](https://github.com/hexojs/hexo-math)