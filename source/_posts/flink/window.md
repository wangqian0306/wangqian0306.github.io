---
title: Flink Window
date: 2022-02-14 22:26:13
tags:
- "Flink"
id: flink_window
no_word_count: true
no_toc: false
categories: Flink
---

## Flink Window

### 简介

Window 即窗口操作把一个数据集切分为有限的数据片以便于聚合处理。当面对无边界的数据时，有些操作需要窗口(以定义大多数聚合操作需要的边界：汇总，外链接，以时间区域定义的操作；如最近 5 分钟 xx等)。
另一些则不需要(如过滤，映射，内链接等)。对有边界的数据，窗口是可选的，不过很多情况下仍然是一种有效的语义概念(如回填一大批的更新数据到之前读取无边界数据源处理过的数据，译者注：类似于 Lambda 架构)。
窗口基本上都是基于时间的；不过也有些系统支持基于记录数的窗口。这种窗口可以认为是基于一个逻辑上的时间域，该时间域中的元素包含顺序递增的逻辑时间戳。
窗口可以是对齐的，也就是说窗口应用于所有落在窗口时间范围内的数据。也可以是非对齐的，也就是应用于部分特定的数据子集(如按某个键值筛选的数据子集)。窗口可以分为如下的几种类型，详情如图所示：

![窗口类型划分](https://s2.loli.net/2022/02/14/N27kFuq1sKIYdhU.png)

**固定窗口(Fixed)** (有时叫滚动窗口 Tumbling)是按固定窗口大小定义的，比如说小时窗口或天窗口。它们一般是对齐窗口，也就是说，每个窗口都包含了对应时间段范围内的所有数据。有时为了把窗口计算的负荷均匀分摊到整个时间范围内，有时固定窗口会做成把窗口的边界的时间加上一个随机数，这样的固定窗口则变成了不对齐窗口。

**滑动窗口(Sliding)** 按窗口大小和滑动周期大小来定义，比如说小时窗口，每一分钟滑动一次。这个滑动周期一般比窗口大小小，也就是说窗口有相互重合之处。滑动窗口一般也是对齐的；尽管上面的图为了画出滑动的效果窗口没有遮盖到所有的键，但其实五个滑动窗口其实是包含了所有的3个键，而不仅仅是窗口3包含了所有的3个键。固定窗口可以看做是滑动窗口的一个特例，即窗口大小和滑动周期大小相等。

**会话窗口(Sessions)** 是在数据的子集上捕捉一段时间内的活动。一般来说会话按超时时间来定义，任何发生在超时时间以内的事件认为属于同一个会话。会话是非对齐窗口。如上图，窗口 2 只包含 key1，窗口 3 则只包含 key2。而窗口 1 和 4 都包含了 key3。

而在 Flink 中的窗口可以进行如下的划分：

- 键控窗口(Keyed Window)
- 非键控窗口(Non-Keyed Window)

### 窗口分类

#### 键控窗口

```text
stream
       .keyBy(...)               <-  keyed versus non-keyed windows
       .window(...)              <-  required: "assigner"
      [.trigger(...)]            <-  optional: "trigger" (else default trigger)
      [.evictor(...)]            <-  optional: "evictor" (else no evictor)
      [.allowedLateness(...)]    <-  optional: "lateness" (else zero)
      [.sideOutputLateData(...)] <-  optional: "output tag" (else no side output for late data)
       .reduce/aggregate/apply()      <-  required: "function"
      [.getSideOutput(...)]      <-  optional: "output tag"
```

#### 非键控窗口

```text
stream
       .windowAll(...)           <-  required: "assigner"
      [.trigger(...)]            <-  optional: "trigger" (else default trigger)
      [.evictor(...)]            <-  optional: "evictor" (else no evictor)
      [.allowedLateness(...)]    <-  optional: "lateness" (else zero)
      [.sideOutputLateData(...)] <-  optional: "output tag" (else no side output for late data)
       .reduce/aggregate/apply()      <-  required: "function"
      [.getSideOutput(...)]      <-  optional: "output tag"
```

> 注：[] 代表此操作为可选，建议采用键控窗口否则并行度会降低。

### 例程

#### 滚动窗口

```text
DataStream<T> input = ...;

// tumbling event-time windows
input
    .keyBy(<key selector>)
    .window(TumblingEventTimeWindows.of(Time.seconds(5)))
    .<windowed transformation>(<window function>);

// tumbling processing-time windows
input
    .keyBy(<key selector>)
    .window(TumblingProcessingTimeWindows.of(Time.seconds(5)))
    .<windowed transformation>(<window function>);

// daily tumbling event-time windows offset by -8 hours.
input
    .keyBy(<key selector>)
    .window(TumblingEventTimeWindows.of(Time.days(1), Time.hours(-8)))
    .<windowed transformation>(<window function>);
```

#### 滑动窗口

```text
DataStream<T> input = ...;

// sliding event-time windows
input
    .keyBy(<key selector>)
    .window(SlidingEventTimeWindows.of(Time.seconds(10), Time.seconds(5)))
    .<windowed transformation>(<window function>);

// sliding processing-time windows
input
    .keyBy(<key selector>)
    .window(SlidingProcessingTimeWindows.of(Time.seconds(10), Time.seconds(5)))
    .<windowed transformation>(<window function>);

// sliding processing-time windows offset by -8 hours
input
    .keyBy(<key selector>)
    .window(SlidingProcessingTimeWindows.of(Time.hours(12), Time.hours(1), Time.hours(-8)))
    .<windowed transformation>(<window function>);
```

#### 会话窗口

```text
DataStream<T> input = ...;

// event-time session windows with static gap
input
    .keyBy(<key selector>)
    .window(EventTimeSessionWindows.withGap(Time.minutes(10)))
    .<windowed transformation>(<window function>);
    
// event-time session windows with dynamic gap
input
    .keyBy(<key selector>)
    .window(EventTimeSessionWindows.withDynamicGap((element) -> {
        // determine and return session gap
    }))
    .<windowed transformation>(<window function>);

// processing-time session windows with static gap
input
    .keyBy(<key selector>)
    .window(ProcessingTimeSessionWindows.withGap(Time.minutes(10)))
    .<windowed transformation>(<window function>);
    
// processing-time session windows with dynamic gap
input
    .keyBy(<key selector>)
    .window(ProcessingTimeSessionWindows.withDynamicGap((element) -> {
        // determine and return session gap
    }))
    .<windowed transformation>(<window function>);
```

#### 全局窗口

```text
DataStream<T> input = ...;

input
    .keyBy(<key selector>)
    .window(GlobalWindows.create())
    .<windowed transformation>(<window function>);
```

> 注：此窗口方案仅在您还指定自定义触发器时才有效。

### Window Function

在定义了窗口分配器之后，我们需要指定我们想要在每个窗口上执行的计算被称为 Window Function 即窗口函数。

窗口函数分为以下几种：

- ReduceFunction
- AggregateFunction
- ProcessWindowFunction

其中的前两种可以更有效地执行。

#### ReduceFunction

合并相同 key 的内容

```text
DataStream<Tuple2<String, Long>> input = ...;

input
    .keyBy(<key selector>)
    .window(<window assigner>)
    .reduce(new ReduceFunction<Tuple2<String, Long>>() {
      public Tuple2<String, Long> reduce(Tuple2<String, Long> v1, Tuple2<String, Long> v2) {
        return new Tuple2<>(v1.f0, v1.f1 + v2.f1);
      }
    });
```

#### AggregateFunction

```text
private static class AverageAggregate
    implements AggregateFunction<Tuple2<String, Long>, Tuple2<Long, Long>, Double> {
  @Override
  public Tuple2<Long, Long> createAccumulator() {
    return new Tuple2<>(0L, 0L);
  }

  @Override
  public Tuple2<Long, Long> add(Tuple2<String, Long> value, Tuple2<Long, Long> accumulator) {
    return new Tuple2<>(accumulator.f0 + value.f1, accumulator.f1 + 1L);
  }

  @Override
  public Double getResult(Tuple2<Long, Long> accumulator) {
    return ((double) accumulator.f0) / accumulator.f1;
  }

  @Override
  public Tuple2<Long, Long> merge(Tuple2<Long, Long> a, Tuple2<Long, Long> b) {
    return new Tuple2<>(a.f0 + b.f0, a.f1 + b.f1);
  }
}

DataStream<Tuple2<String, Long>> input = ...;

input
    .keyBy(<key selector>)
    .window(<window assigner>)
    .aggregate(new AverageAggregate());
```

#### ProcessWindowFunction

ProcessWindowFunction 获得一个包含窗口所有元素的可迭代对象，以及一个可以访问时间和状态信息的 Context 对象，这使得它能够提供比其他窗口函数更大的灵活性。这是以性能和资源消耗为代价的，因为元素不能增量聚合，而是需要在内部缓冲，直到窗口被认为准备好处理。

```text
DataStream<Tuple2<String, Long>> input = ...;

input
  .keyBy(t -> t.f0)
  .window(TumblingEventTimeWindows.of(Time.minutes(5)))
  .process(new MyProcessWindowFunction());

public class MyProcessWindowFunction 
    extends ProcessWindowFunction<Tuple2<String, Long>, String, String, TimeWindow> {

  @Override
  public void process(String key, Context context, Iterable<Tuple2<String, Long>> input, Collector<String> out) {
    long count = 0;
    for (Tuple2<String, Long> in: input) {
      count++;
    }
    out.collect("Window: " + context.window() + "count: " + count);
  }
}
```

#### 具有增量聚合的 ProcessWindowFunction

ProcessWindowFunction 可以与 ReduceFunction 或 AggregateFunction 组合

> 注：此处暂略，参见官方文档。

### 参考资料

[官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/dev/datastream/operators/windows/#allowed-lateness)

