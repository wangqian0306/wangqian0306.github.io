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
    TRIANGLE
}

class Color {
    String name;

    Color(String name) {
        this.name = name;
    }
}

class Item {
    Shape shape;
    Color color;

    Item(Shape shape, Color color) {
        this.shape = shape;
        this.color = color;
    }

    public Shape getShape() {
        return shape;
    }

    public Color getColor() {
        return color;
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
}

public class BroadcastTest {

    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        Collection<String> originCollection = new ArrayList<>();
        originCollection.add("SQUARE RED");
        originCollection.add("SQUARE BLUE");
        originCollection.add("CIRCLE BLUE");
        originCollection.add("CIRCLE RED");
        originCollection.add("TRIANGLE BLUE");
        Collection<String> ruleCollection = new ArrayList<>();
        ruleCollection.add("1 SQUARE CIRCLE");
        DataStream<String> originStream = env.fromCollection(originCollection);
        DataStream<Item> itemStream = originStream.map(new MapFunction<String, Item>() {
            @Override
            public Item map(String s) throws Exception {
                String[] content = s.split(" ");
                return new Item(Shape.valueOf(content[0]), new Color(content[1]));
            }
        });
        KeyedStream<Item, Color> colorPartitionedStream = itemStream.keyBy(new KeySelector<Item, Color>() {
            @Override
            public Color getKey(Item item) throws Exception {
                return item.getColor();
            }
        });
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
        DataStream<String> output = colorPartitionedStream.connect(ruleBroadcastStream).process(
                new KeyedBroadcastProcessFunction<Color, Item, Rule, String>() {
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

                            // there is no else{} to cover if rule.first == rule.second
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
        env.execute();
    }

}
```

### 参考资料

[官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/dev/datastream/fault-tolerance/broadcast_state/)