---
title: Flink 侧输出流
date: 2022-03-02 22:26:13
tags:
- "Flink"
id: flink_side_output
no_word_count: true
no_toc: false
categories: Flink
---

## Flink 侧输出流

### 简介

在 DataStream API 中除了通常操作产生的主流之外，还可以生成任意数量的侧输出流，且主流于侧输出流的数据类型可以不同。可以生成侧输出流的函数如下：

- ProcessFunction
- KeyedProcessFunction
- CoProcessFunction
- KeyedCoProcessFunction
- ProcessWindowFunction
- ProcessAllWindowFunction

### 使用示例

向侧输出流中输入内容的示例如下：

```text
DataStream<Integer> input = ...;

final OutputTag<String> outputTag = new OutputTag<String>("side-output"){};

SingleOutputStreamOperator<Integer> mainDataStream = input
  .process(new ProcessFunction<Integer, Integer>() {

      @Override
      public void processElement(
          Integer value,
          Context ctx,
          Collector<Integer> out) throws Exception {
        // emit data to regular output
        out.collect(value);

        // emit data to side output
        ctx.output(outputTag, "sideout-" + String.valueOf(value));
      }
    });
```

还可以通过如下方式处理侧输出流：

```text
final OutputTag<String> outputTag = new OutputTag<String>("side-output"){};

SingleOutputStreamOperator<Integer> mainDataStream = ...;

DataStream<String> sideOutputStream = mainDataStream.getSideOutput(outputTag);
```

### 参考资料

[官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/dev/datastream/side_output/)
