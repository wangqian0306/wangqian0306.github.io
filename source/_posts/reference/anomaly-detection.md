---
title: Anomaly detection
date: 2022-10-12 22:43:13
tags:
- "Elastic Stack"
id: anomaly-detection
no_word_count: true
no_toc: false
categories: 参考资料
---

## 异常检测

### 简介

在数据分析中，异常检测(也称为异常值检测，有时也称为新颖性检测)通常被理解为识别罕见项目，事件或观察结果，这些项目，事件或观察结果与大多数数据明显偏离并且不符合明确定义的正常行为概念。这些例子可能会引起人们对由不同机制产生的怀疑，或看起来与该组数据的其余部分不一致。

存在三大类异常检测技术。监督式异常检测技术需要一个被标记为“正常”和“异常”的数据集，并涉及训练分类器。但是，由于标记数据的一般不可用以及类固有的不平衡性质，此方法很少用于异常检测。半监督异常检测技术假定数据的某些部分已标记。这可能是正常或异常数据的任意组合，但通常情况下，技术会从给定的正常训练数据集构造表示正常行为的模型，然后测试模型生成测试实例的可能性。无监督异常检测技术假设数据是未标记的，并且由于其更广泛和相关的应用，因此是迄今为止最常用的。

异常检测可识别异常值，以回答“发生了什么通常不会发生？"而预测则的目标则是发现 “未来将会怎样”，例如Amazon QuickSight 就使用随机切割森林(RCF)算法的内置版本。

### 试用

#### 插入样本数据

```python

```

#### 修改数据类型

```text

```

#### 创建任务

```text

```

#### 查看结果

```text

```

### 参考资料

[Elasticsearch Anomaly detection](https://www.elastic.co/guide/en/machine-learning/current/ml-ad-overview.html)

[Amazon QuickSight](https://docs.aws.amazon.com/quicksight/latest/user/concept-of-ml-algorithms.html)

[OpenSearch 文档](https://opensearch.org/blog/odfe-updates/2019/11/real-time-anomaly-detection-in-open-distro-for-elasticsearch/)
