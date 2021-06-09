---
title: 大数据组件调优知识整理
date: 2020-06-11 23:17:13
tags:
- "Hadoop"
- "Kafka"
- "Spark"
id: performance
no_word_count: true
no_toc: false
categories: 大数据
---

## HDFS 调优

### 相关资料网站

[hdfs+yarn 参数调优](https://blog.csdn.net/qq_19917081/article/details/54575644)

[HDFS Settings for Better Hadoop Performance](https://community.cloudera.com/t5/Community-Articles/HDFS-Settings-for-Better-Hadoop-Performance/ta-p/245799)

### 参数调整

core-site.xml

- `io.file.buffer.size` 建议值与`Ambari`默认值一致为`131072`

> 较大的缓存都可以提供更高的数据传输，但这也就意味着更大的内存消耗和延迟

- `fs.trash.interval` 文件的删除时间，建议值为`1440`默认值为`360`

- `dfs.namenode.handler.count` 默认值`40`建议修改值`400`

> 每个 threads 使用 RPC 跟其他的 datanodes 沟通。当 datanodes 数量太多时会发現很容易出現 RPC timeout，解決方法是提升网络速度或提高这个值，但要注意的是 thread 数量多也表示 namenode 消耗的内存也随着增加。

- `dfs.datanode.readahead.bytes` 默认值`4M` 建议修改值`64M`

- 网络连接数
    - 系统内核的`net.core.somaxconn`默认值`128`建议修改值`1024`
    - `ipc.server.listen.queue.size`与上文保持一致

> 增大打开文件数据和网络连接上限，提高hadoop集群读写速度和网络带宽使用率(对系统修改大，不建议修改)

- `dfs.replication` 默认值`3`建议修改值`2`

> 减少副本块可以节约存储空间和时间

hdfs-site.xml

- `dfs.client.read.shortcircuit`建议值与`Ambari`默认值一致为`True`
- `dfs.domain.socket.path`建议值与`Ambari`默认值一致为`/var/lib/hadoop-hdfs/dn_socket`
- `dfs.namenode.avoid.read.stale.datanode`建议值与`Ambari`默认值一致为`True`
- `dfs.namenode.avoid.write.stale.datanode`建议值与`Ambari`默认值一致为`True`

## Yarn调优

### 相关资料网站

[YARN的Memory和CPU调优配置详解](http://blog.itpub.net/31496956/viewspace-2149054/)

### 参数调整

`containers = min (2*CORES, 1.8*DISKS, (Total available RAM) / MIN_CONTAINER_SIZE)`

`RAM-per-container = max(MIN_CONTAINER_SIZE, (Total Available RAM) / containers))`

|配置文件|配置设置|默认值|计算值|
|:---:|:---:|:---:|:---:|
|yarn-site.xml|yarn.nodemanager.resource.memory-mb|8192 MB|	= containers * RAM-per-container|
|yarn-site.xml|yarn.scheduler.minimum-allocation-mb|1024MB|	= RAM-per-container|
|yarn-site.xml|yarn.scheduler.maximum-allocation-mb|8192MB|	= containers * RAM-per-container|
|yarn-site.xml(check)|yarn.app.mapreduce.am.resource.mb|1536MB|	= 2 * RAM-per-container|
|yarn-site.xml(check)|yarn.app.mapreduce.am.command-opts|-Xmx1024m|	= 0.8 * 2 * RAM-per-container|
|mapred-site.xml|mapreduce.map.memory.mb|1024MB|= RAM-per-container|
|mapred-site.xml|mapreduce.reduce.memory.mb|1024MB|= 2 * RAM-per-container|
|mapred-site.xml|mapreduce.map.java.opts|-|= 0.8 * RAM-per-container|
|mapred-site.xml|mapreduce.reduce.java.opts|-|= 0.8 * 2 * RAM-per-container|

### 参数计算

参数调整计算脚本：

```python
#!/usr/bin/env python
import optparse
from pprint import pprint
import logging
import sys
import math
import ast

''' Reserved for OS + DN + NM, Map: Memory => Reservation '''
reservedStack = { 4:1, 8:2, 16:2, 24:4, 48:6, 64:8, 72:8, 96:12, 
                   128:24, 256:32, 512:64}
''' Reserved for HBase. Map: Memory => Reservation '''
  
reservedHBase = {4:1, 8:1, 16:2, 24:4, 48:8, 64:8, 72:8, 96:16, 
                   128:24, 256:32, 512:64}
GB = 1024

def getMinContainerSize(memory):
  if (memory <= 4):
    return 256
  elif (memory <= 8):
    return 512
  elif (memory <= 24):
    return 1024
  else:
    return 2048
  pass

def getReservedStackMemory(memory):
  if (reservedStack.has_key(memory)):
    return reservedStack[memory]
  if (memory <= 4):
    ret = 1
  elif (memory >= 512):
    ret = 64
  else:
    ret = 1
  return ret

def getReservedHBaseMem(memory):
  if (reservedHBase.has_key(memory)):
    return reservedHBase[memory]
  if (memory <= 4):
    ret = 1
  elif (memory >= 512):
    ret = 64
  else:
    ret = 2
  return ret
                    
def main():
  log = logging.getLogger(__name__)
  out_hdlr = logging.StreamHandler(sys.stdout)
  out_hdlr.setFormatter(logging.Formatter(' %(message)s'))
  out_hdlr.setLevel(logging.INFO)
  log.addHandler(out_hdlr)
  log.setLevel(logging.INFO)
  parser = optparse.OptionParser()
  memory = 0
  cores = 0
  disks = 0
  hbaseEnabled = True
  parser.add_option('-c', '--cores', default = 16,
                     help = 'Number of cores on each host')
  parser.add_option('-m', '--memory', default = 64, 
                    help = 'Amount of Memory on each host in GB')
  parser.add_option('-d', '--disks', default = 4, 
                    help = 'Number of disks on each host')
  parser.add_option('-k', '--hbase', default = "True",
                    help = 'True if HBase is installed, False is not')
  (options, args) = parser.parse_args()
  
  cores = int (options.cores)
  memory = int (options.memory)
  disks = int (options.disks)
  hbaseEnabled = ast.literal_eval(options.hbase)
  
  log.info("Using cores=" + str(cores) + " memory=" + str(memory) + "GB" +
            " disks=" + str(disks) + " hbase=" + str(hbaseEnabled))
  minContainerSize = getMinContainerSize(memory)
  reservedStackMemory = getReservedStackMemory(memory)
  reservedHBaseMemory = 0
  if (hbaseEnabled):
    reservedHBaseMemory = getReservedHBaseMem(memory)
  reservedMem = reservedStackMemory + reservedHBaseMemory
  usableMem = memory - reservedMem
  memory -= (reservedMem)
  if (memory < 2):
    memory = 2
    reservedMem = max(0, memory - reservedMem)
    
  memory *= GB
  
  containers = int (min(2 * cores,
                         min(math.ceil(1.8 * float(disks)),
                              memory/minContainerSize)))
  if (containers <= 2):
    containers = 3

  log.info("Profile: cores=" + str(cores) + " memory=" + str(memory) + "MB"
           + " reserved=" + str(reservedMem) + "GB" + " usableMem="
           + str(usableMem) + "GB" + " disks=" + str(disks))
    
  container_ram = abs(memory/containers)
  if (container_ram > GB):
    container_ram = int(math.floor(container_ram / 512)) * 512
  log.info("Num Container=" + str(containers))
  log.info("Container Ram=" + str(container_ram) + "MB")
  log.info("Used Ram=" + str(int (containers*container_ram/float(GB))) + "GB")
  log.info("Unused Ram=" + str(reservedMem) + "GB")
  log.info("yarn.scheduler.minimum-allocation-mb=" + str(container_ram))
  log.info("yarn.scheduler.maximum-allocation-mb=" + str(containers*container_ram))
  log.info("yarn.nodemanager.resource.memory-mb=" + str(containers*container_ram))
  map_memory = container_ram
  reduce_memory = 2*container_ram if (container_ram <= 2048) else container_ram
  am_memory = max(map_memory, reduce_memory)
  log.info("mapreduce.map.memory.mb=" + str(map_memory))
  log.info("mapreduce.map.java.opts=-Xmx" + str(int(0.8 * map_memory)) +"m")
  log.info("mapreduce.reduce.memory.mb=" + str(reduce_memory))
  log.info("mapreduce.reduce.java.opts=-Xmx" + str(int(0.8 * reduce_memory)) + "m")
  log.info("yarn.app.mapreduce.am.resource.mb=" + str(am_memory))
  log.info("yarn.app.mapreduce.am.command-opts=-Xmx" + str(int(0.8*am_memory)) + "m")
  log.info("mapreduce.task.io.sort.mb=" + str(int(0.4 * map_memory)))
  pass

if __name__ == '__main__':
  try:
    main()
  except(KeyboardInterrupt, EOFError):
    print("\nAborting ... Keyboard Interrupt.")
    sys.exit(1)
```

用法示例

```bash
python test.py -c 32 -m 128 -d 2 -k True
```

样例输出

```bash
 Using cores=32 memory=128GB disks=2 hbase=True
 Profile: cores=32 memory=81920MB reserved=48GB usableMem=80GB disks=2
 Num Container=4
 Container Ram=20480MB
 Used Ram=80GB
 Unused Ram=48GB
 yarn.scheduler.minimum-allocation-mb=20480
 yarn.scheduler.maximum-allocation-mb=81920
 yarn.nodemanager.resource.memory-mb=81920
 mapreduce.map.memory.mb=20480
 mapreduce.map.java.opts=-Xmx16384m
 mapreduce.reduce.memory.mb=20480
 mapreduce.reduce.java.opts=-Xmx16384m
 yarn.app.mapreduce.am.resource.mb=20480
 yarn.app.mapreduce.am.command-opts=-Xmx16384m
 mapreduce.task.io.sort.mb=8192
```

## Kafka调优

### broker 处理消息的最大线程数（默认为3）

num.network.threads=cpu核数+1

### broker 处理磁盘IO的线程数

num.io.threads=cpu核数*2
