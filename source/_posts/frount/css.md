---
title: CSS 常用内容
date: 2025-05-06 22:26:13
tags:
- "CSS"
id: css
no_word_count: true
no_toc: false
---

## CSS 常用内容

### 简介

层叠样式表(英文全称：Cascading Style Sheets)是一种用来表现 HTML 或XML 等文件样式的计算机语言。

### 常用情况

#### PDF 中显示表格

```html
<!DOCTYPE html>
<html lang="zh">
<head>
  <meta charset="UTF-8" />
  <title>服务器运行情况报告</title>
  <script src="https://cdn.jsdelivr.net/npm/echarts@5.4.3/dist/echarts.min.js"></script>
  <style>
    body {
      margin: 0;
      font-family: "Helvetica Neue", Arial, sans-serif;
    }
    .container {
      display: grid;
      grid-template-columns: 1fr 1fr;
      grid-template-rows: repeat(3, 300px);
      gap: 10px;
      padding: 20px;
      width: 210mm;
      height: 297mm;
      box-sizing: border-box;
    }
    .chart {
      border: 1px solid #ccc;
      padding: 5px;
    }
    @media print {
      body {
        margin: 0;
      }
      .container {
        page-break-inside: avoid;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <div id="chart1" class="chart"></div>
    <div id="chart2" class="chart"></div>
    <div id="chart3" class="chart"></div>
    <div id="chart4" class="chart"></div>
    <div id="chart5" class="chart"></div>
    <div id="chart6" class="chart"></div>
  </div>

  <script>
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    const chart1 = echarts.init(document.getElementById('chart1'));
    chart1.setOption({
      title: { text: "服务器请求数", left: "center", top: 10 },
      tooltip: { trigger: "axis" },
      xAxis: { type: "category", data: days },
      yAxis: { type: "value" },
      series: [{
        data: [120, 132, 101, 134, 90, 230, 210],
        type: 'line',
        smooth: true,
        areaStyle: {},
        lineStyle: { width: 2 }
      }]
    });

    const chart2 = echarts.init(document.getElementById('chart2'));
    chart2.setOption({
      title: { text: "新增用户数", left: "center", top: 10 },
      tooltip: { trigger: "axis" },
      xAxis: { type: "category", data: days },
      yAxis: { type: "value" },
      series: [{
        data: [20, 32, 41, 34, 50, 30, 70],
        type: 'line',
        smooth: true,
        areaStyle: {},
        lineStyle: { width: 2 }
      }]
    });

    const chart3 = echarts.init(document.getElementById('chart3'));
    chart3.setOption({
      title: { text: "系统报错次数", left: "center", top: 10 },
      tooltip: { trigger: "axis" },
      xAxis: { type: "category", data: days },
      yAxis: { type: "value" },
      series: [{
        data: [2, 5, 1, 0, 3, 4, 2],
        type: 'line',
        smooth: true,
        areaStyle: {},
        lineStyle: { width: 2 }
      }]
    });

    const chart4 = echarts.init(document.getElementById('chart4'));
    chart4.setOption({
      title: { text: "数据量变化（GB）", left: "center", top: 10 },
      tooltip: { trigger: "axis" },
      xAxis: { type: "category", data: days },
      yAxis: { type: "value" },
      series: [{
        data: [50, 70, 65, 80, 90, 120, 110],
        type: 'line',
        smooth: true,
        areaStyle: {},
        lineStyle: { width: 2 }
      }]
    });

    const chart5 = echarts.init(document.getElementById('chart5'));
    chart5.setOption({
      title: { text: "网络带宽（Mbps）", left: "center", top: 10 },
      tooltip: { trigger: "axis" },
      xAxis: { type: "category", data: days },
      yAxis: { type: "value" },
      series: [{
        data: [100, 120, 130, 90, 110, 140, 150],
        type: 'line',
        smooth: true,
        areaStyle: {},
        lineStyle: { width: 2 }
      }]
    });

    const chart6 = echarts.init(document.getElementById('chart6'));
    chart6.setOption({
      title: { text: "内存使用情况（GB）", left: "center", top: 10 },
      tooltip: { trigger: "axis" },
      xAxis: { type: "category", data: days },
      yAxis: { type: "value" },
      series: [{
        data: [4, 4.5, 5, 5.5, 6, 6.5, 7],
        type: 'line',
        smooth: true,
        areaStyle: {},
        lineStyle: { width: 2 }
      }]
    });
  </script>
</body>
</html>
```
