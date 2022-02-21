---
title: Flink State
date: 2022-02-17 22:26:13
tags:
- "Flink"
id: flink_state
no_word_count: true
no_toc: false
categories: Flink
---

## Flink State

### 简介

State 是指流计算过程中计算节点的中间计算结果或元数据属性，比如在 aggregation 过程中要在 state 中记录中间聚合结果，比如 Apache Kafka 作为数据源时候，我们也要记录已经读取记录的 offset，这些 State 数据在计算过程中会进行持久化(插入或更新)。所以Apache Flink中的State就是与时间相关的，Apache Flink任务的内部数据(计算数据和元数据属性)的快照。

Flink 内部按照算子和数据分组角度将 State 划分为如下两类：

- KeyedState 这里面的 key 是我们在 SQL 语句中对应的 GroupBy/PartitionBy 里面的字段，key 的值就是 GroupBy/PartitionBy 字段组成的 Row 的字节数组，每一个 key 都有一个属于自己的 State，key 与 key 之间的 State 是不可见的；
- OperatorState Flink 内部的 Source Connector 的实现中就会用 OperatorState 来记录 source 数据读取的 offset。
  - OperatorState 的作用范围限定为单个任务，由同一并行任务所处理的所有数据都可以访问到相同的 State
  - OperatorState 对于同一子任务而言是共享的
  - OperatorState 不能由相同或不同算子的另一个子任务访问

自带数据存储后端有如下两种：

- HashMapStateBackend
- EmbeddedRocksDBStateBackend

如果没有其他配置，系统将使用 HashMapStateBackend。

通常情况下应该采用 HashMapStateBackend 仅在处理大量 State，超大窗口及大量键值对 State 时应当选择 HashMapStateBackend。

### 配置

使用 HashMapStateBackend 可以进行如下配置

```text
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
env.setStateBackend(new HashMapStateBackend());
```

如果使用 EmbeddedRocksDBStateBackend 则需要额外引入如下包：

```xml
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-statebackend-rocksdb_2.11</artifactId>
    <version>1.14.3</version>
    <scope>provided</scope>
</dependency>
```

```text
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
env.setStateBackend(new EmbeddedRocksDBStateBackend());
```

### 样例

#### KeyedState

在经过 keyBy 操作之后就可以获得 KeyedStream 对象，针对 KeyedStream 对象可以使用如下 State：

- ValueState<T> :储存单个值的 State
- MapState<UK,UV> :储存 Map 形式的 State
- ListState<T> :储存 List 形式的 State
- ReducingState<T> :只存储一个元素，而不是一个列表。它的运行方式是将新元素通过 add(value: T) 加入后，与已有的状态元素使用 ReduceFunction 合并为一个元素，并更新至 State。
- AggregatingState<IN,OUT> :运行方式与 ReducingState 类似，但是可以指定不同的输入输出类。

```text
public class CountWindowAverage extends RichFlatMapFunction<Tuple2<Long, Long>, Tuple2<Long, Long>> {

    /**
     * The ValueState handle. The first field is the count, the second field a running sum.
     */
    private transient ValueState<Tuple2<Long, Long>> sum;

    @Override
    public void flatMap(Tuple2<Long, Long> input, Collector<Tuple2<Long, Long>> out) throws Exception {

        // access the state value
        Tuple2<Long, Long> currentSum = sum.value();

        // update the count
        currentSum.f0 += 1;

        // add the second field of the input value
        currentSum.f1 += input.f1;

        // update the state
        sum.update(currentSum);

        // if the count reaches 2, emit the average and clear the state
        if (currentSum.f0 >= 2) {
            out.collect(new Tuple2<>(input.f0, currentSum.f1 / currentSum.f0));
            sum.clear();
        }
    }

    @Override
    public void open(Configuration config) {
        ValueStateDescriptor<Tuple2<Long, Long>> descriptor =
                new ValueStateDescriptor<>(
                        "average", // the state name
                        TypeInformation.of(new TypeHint<Tuple2<Long, Long>>() {}) // type information
        sum = getRuntimeContext().getState(descriptor);
        if (sum == null){
            sum = Tuple2.of(0L, 0L);
        }
    }
}

// this can be used in a streaming program like this (assuming we have a StreamExecutionEnvironment env)
env.fromElements(Tuple2.of(1L, 3L), Tuple2.of(1L, 5L), Tuple2.of(1L, 7L), Tuple2.of(1L, 4L), Tuple2.of(1L, 2L))
        .keyBy(value -> value.f0)
        .flatMap(new CountWindowAverage())
        .print();
```

此外还可以为 State 设置 TTL

```text
import org.apache.flink.api.common.state.StateTtlConfig;
import org.apache.flink.api.common.state.ValueStateDescriptor;
import org.apache.flink.api.common.time.Time;

StateTtlConfig ttlConfig = StateTtlConfig
    .newBuilder(Time.seconds(1))
    .setUpdateType(StateTtlConfig.UpdateType.OnCreateAndWrite)
    .setStateVisibility(StateTtlConfig.StateVisibility.NeverReturnExpired)
    .build();
    
ValueStateDescriptor<String> stateDescriptor = new ValueStateDescriptor<>("text state", String.class);
stateDescriptor.enableTimeToLive(ttlConfig);
```

#### OperatorState

通常无须使用 OperatorState。它主要是一种特殊类型的状态，主要用在对接数据源或没有可以对状态进行分区的键的场景。

```text
public class BufferingSink
        implements SinkFunction<Tuple2<String, Integer>>,
                   CheckpointedFunction {

    private final int threshold;

    private transient ListState<Tuple2<String, Integer>> checkpointedState;

    private List<Tuple2<String, Integer>> bufferedElements;

    public BufferingSink(int threshold) {
        this.threshold = threshold;
        this.bufferedElements = new ArrayList<>();
    }

    @Override
    public void invoke(Tuple2<String, Integer> value, Context contex) throws Exception {
        bufferedElements.add(value);
        if (bufferedElements.size() >= threshold) {
            for (Tuple2<String, Integer> element: bufferedElements) {
                // send it to the sink
            }
            bufferedElements.clear();
        }
    }

    @Override
    public void snapshotState(FunctionSnapshotContext context) throws Exception {
        checkpointedState.clear();
        for (Tuple2<String, Integer> element : bufferedElements) {
            checkpointedState.add(element);
        }
    }

    @Override
    public void initializeState(FunctionInitializationContext context) throws Exception {
        ListStateDescriptor<Tuple2<String, Integer>> descriptor =
            new ListStateDescriptor<>(
                "buffered-elements",
                TypeInformation.of(new TypeHint<Tuple2<String, Integer>>() {}));

        checkpointedState = context.getOperatorStateStore().getListState(descriptor);

        if (context.isRestored()) {
            for (Tuple2<String, Integer> element : checkpointedState.get()) {
                bufferedElements.add(element);
            }
        }
    }
}
```

### 参考资料

[state 官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/dev/datastream/fault-tolerance/state/)

[state_backends 官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/ops/state/state_backends/)

[Apache Flink 漫谈系列(04) - State](https://developer.aliyun.com/article/667562?spm=a2c6h.13262185.0.0.60da7e18Eon9c4)

[Flink状态管理详解：Keyed State和Operator List State深度解析](https://www.cnblogs.com/felixzh/p/13167665.html)