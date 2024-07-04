---
title: NetCDF
date: 2022-07-05 23:09:32
tags:
- "JAVA"
- "Python"
id: netcdf
no_word_count: true
no_toc: false
categories: "Ocean"
---

## NetCDF

### 简介

NetCDF(Network Common Data Form)是一种自描述、与机器无关、基于数组的科学数据格式，同时也是支持创建、访问和共享这一数据格式的函数库。
此格式是由美国大气科学研究大学联盟(UCAR) 针对科学是数据的特点进行开发的，常见的文件后缀名为 `.nc`。
此种数据格式以已经广泛的应用于大气科学、水文、海洋学、环境模拟、地球物理等诸多领域。

### 读取方式

#### Java

可以使用 Maven 或 Gradle 来引入依赖包：

```xml
<repositories>
    <repository>
        <id>unidata-all</id>
        <name>Unidata All</name>
        <url>https://artifacts.unidata.ucar.edu/repository/unidata-all/</url>
    </repository>
</repositories>
```

```xml
<dependencies>
    <dependency>
        <groupId>edu.ucar</groupId>
        <artifactId>cdm-core</artifactId>
        <version>${netcdfJavaVersion}</version>
        <scope>compile</scope>
    </dependency>
</dependencies>
```

```groovy
repositories {
    maven {
        url "https://artifacts.unidata.ucar.edu/repository/unidata-all/"
    }
}
dependencies {
    implementation 'edu.ucar:netcdfAll:5.4.1'
}
```

```java
import ucar.ma2.Array;
import ucar.nc2.NetcdfFile;
import ucar.nc2.NetcdfFiles;
import ucar.nc2.Variable;
import ucar.nc2.write.Ncdump;

import java.io.IOException;

public class SimpleRead {

  private static final String PATH = "<path>";

  public static void main(String[] args) throws IOException {
    try (NetcdfFile ncfile = NetcdfFiles.open(PATH)) {
      Variable v = ncfile.findVariable("<xxx>");
      if (v == null) {
        return;
      }
      Array data = v.read();
      String arrayStr = Ncdump.printArray(data, "<xxx>", null);
      System.out.println(arrayStr);
    } catch (IOException ioe) {
      System.out.println(ioe.getMessage());
    }
  }
}
```

#### Python

```bash 
pip install netCDF4 
```

```python
import netCDF4
from netCDF4 import Dataset

nc_obj=Dataset('20200809_prof.nc')
# 查看参数列表
print(nc_obj.variables.keys())
# 查看变量信息
print(nc_obj.variables['<xxx>'])
# 查看变量属性
print(nc_obj.variables['<xxx>'].ncattrs())
#读取数据值
arr_xxx=(nc_obj.variables['<xxx>'][:])
```

### 参考资料

[维基百科-NetCDF](https://zh.wikipedia.org/wiki/NetCDF)

[netCDF-Java](https://docs.unidata.ucar.edu/netcdf-java/current/userguide/index.html)

[netCDF4-Python](https://unidata.github.io/netcdf4-python/)
