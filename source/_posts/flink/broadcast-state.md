---
title: Flink Broadcast State
date: 2022-02-23 22:26:13
tags:
- "Flink"
id: flink_broadcast_state
no_word_count: true
no_toc: false
categories: Flink
---

## Flink Broadcast State

### 简介

Broadcast State 意为将输入的内容广播至所有 Operator 中。在官方文档当中描述了这样的使用场景，输入流有以下两种：

1. 由颜色和形状组成的 KeyedStream 
2. 由规则组成的普通流

在程序运行时需要将这两种流 JOIN 起来，输出符合特定规则的统计结果。

### 实现

官网示例程序实现要求如下：

1. 输入形状和颜色的数据流。
2. 输入由名称，前一个数据的形状，最新数据的形状构成的数据流。
3. 寻找到颜色相同且形状符合规则的数据。

样例：

```java
import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.state.MapState;
import org.apache.flink.api.common.state.MapStateDescriptor;
import org.apache.flink.api.common.typeinfo.BasicTypeInfo;
import org.apache.flink.api.common.typeinfo.TypeHint;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.api.java.functions.KeySelector;
import org.apache.flink.api.java.typeutils.ListTypeInfo;
import org.apache.flink.streaming.api.datastream.BroadcastStream;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.KeyedStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.co.KeyedBroadcastProcessFunction;
import org.apache.flink.util.Collector;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

enum Shape {
    SQUARE,
    CIRCLE,
    TRIANGLE;
}

class Item {
    Shape shape;
    String color;

    Item(Shape shape, String color) {
        this.shape = shape;
        this.color = color;
    }

    public Shape getShape() {
        return shape;
    }

    public String getColor() {
        return color;
    }

    @Override
    public String toString() {
        return "{'shape':'" + this.shape.toString() + "','color': '" + this.color + "'}";
    }

}

class Rule {
    String name;
    Shape first;
    Shape second;

    Rule(String name, Shape first, Shape second) {
        this.name = name;
        this.first = first;
        this.second = second;
    }

    @Override
    public String toString() {
        return "{'name':'" + this.name + "','first': '" + this.first + "','second':'" + this.second + "'}";
    }

}

public class WQTest {

    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        /* Source */
        Collection<String> originCollection = new ArrayList<>();
        originCollection.add("SQUARE BLUE");
        originCollection.add("SQUARE BLUE");
        originCollection.add("CIRCLE BLUE");
        originCollection.add("CIRCLE RED");
        originCollection.add("CIRCLE BLUE");
        Collection<String> ruleCollection = new ArrayList<>();
        ruleCollection.add("1 SQUARE CIRCLE");

        /* Item Stream */
        DataStream<String> originStream = env.fromCollection(originCollection);
        DataStream<Item> itemStream = originStream.map(new MapFunction<String, Item>() {
            @Override
            public Item map(String s) throws Exception {
                String[] content = s.split(" ");
                return new Item(Shape.valueOf(content[0]), content[1]);
            }
        });
        KeyedStream<Item, String> colorPartitionedStream = itemStream.keyBy(new KeySelector<Item, String>() {
            @Override
            public String getKey(Item item) throws Exception {
                return item.getColor();
            }
        });

        /* Rule Stream */
        DataStream<Rule> ruleStream = env.fromCollection(ruleCollection).map(new MapFunction<String, Rule>() {
            @Override
            public Rule map(String s) throws Exception {
                String[] content = s.split(" ");
                return new Rule(content[0], Shape.valueOf(content[1]), Shape.valueOf(content[2]));
            }
        });
        MapStateDescriptor<String, Rule> ruleStateDescriptor = new MapStateDescriptor<>(
                "RulesBroadcastState",
                BasicTypeInfo.STRING_TYPE_INFO,
                TypeInformation.of(new TypeHint<Rule>() {
                }));
        BroadcastStream<Rule> ruleBroadcastStream = ruleStream.broadcast(ruleStateDescriptor);

        /* Broadcast Stream Process */
        DataStream<String> output = colorPartitionedStream.connect(ruleBroadcastStream).process(
                new KeyedBroadcastProcessFunction<String, Item, Rule, String>() {
                    private final MapStateDescriptor<String, List<Item>> mapStateDesc = new MapStateDescriptor<>(
                            "items",
                            BasicTypeInfo.STRING_TYPE_INFO,
                            new ListTypeInfo<>(Item.class));

                    private final MapStateDescriptor<String, Rule> ruleStateDescriptor = new MapStateDescriptor<>(
                            "RulesBroadcastState",
                            BasicTypeInfo.STRING_TYPE_INFO,
                            TypeInformation.of(new TypeHint<Rule>() {
                            }));

                    @Override
                    public void processBroadcastElement(Rule value,
                                                        Context ctx,
                                                        Collector<String> out) throws Exception {
                        ctx.getBroadcastState(ruleStateDescriptor).put(value.name, value);
                    }

                    @Override
                    public void processElement(Item value,
                                               ReadOnlyContext ctx,
                                               Collector<String> out) throws Exception {

                        final MapState<String, List<Item>> state = getRuntimeContext().getMapState(mapStateDesc);
                        final Shape shape = value.getShape();

                        for (Map.Entry<String, Rule> entry :
                                ctx.getBroadcastState(ruleStateDescriptor).immutableEntries()) {
                            final String ruleName = entry.getKey();
                            final Rule rule = entry.getValue();

                            List<Item> stored = state.get(ruleName);
                            if (stored == null) {
                                stored = new ArrayList<>();
                            }

                            if (shape == rule.second && !stored.isEmpty()) {
                                for (Item i : stored) {
                                    out.collect("MATCH: " + i + " - " + value);
                                }
                                stored.clear();
                            }

                            if (shape.equals(rule.first)) {
                                stored.add(value);
                            }

                            if (stored.isEmpty()) {
                                state.remove(ruleName);
                            } else {
                                state.put(ruleName, stored);
                            }
                        }
                    }
                }
        );
        output.print();
        env.execute();
    }

}
```

### 注意事项

- **不能跨任务通信**：用户必须确保所有任务对每个传入元素都以相同的方式修改 Broadcast State 的内容。否则，不同的任务可能会有不同的内容，导致结果不一致。
- **事件顺序因任务而异**：尽管广播流的元素可以保证所有元素(最终)都会到达所有下游任务，但元素可能以不同的顺序到达每个任务。因此，每个传入元素的状态更新不得依赖于传入事件的顺序。
- **所有任务都会检查其 Broadcast State**：这是一个设计决策，以避免在还原期间从同一文件读取所有任务(从而避免热点)，尽管它的代价是将检查点状态的大小增加了 p 倍(并行度)。Flink 保证在恢复/重新缩放时不会有重复和丢失数据。在以相同或更小的并行度进行恢复的情况下，每个任务都会读取其检查点状态。扩大规模后，每个任务读取自己的状态，其余任务(p_new-p_old) 以循环方式读取先前任务的检查点。
- **不适用 RocksDB State Backend**：Broadcast State 在运行时保存在内存中，并且应该相应地进行内存配置。

### 参考资料

[官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/dev/datastream/fault-tolerance/broadcast_state/)