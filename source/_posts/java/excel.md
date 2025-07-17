---
title: 导出 Excel 
date: 2021-10-25 21:05:12
tags: 
- "JAVA"
- "Excel"
id: export-excel
no_word_count: true
no_toc: false
categories: JAVA
---

## 导出 Excel

### poi-ooxml

#### Maven 依赖

```xml
<!-- Excel Export -->
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi-ooxml</artifactId>
    <version>5.0.0</version>
</dependency>
```

#### 编码

- 编写工具包：

```java
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.streaming.SXSSFWorkbook;

import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.util.List;

public class ExcelUtil {

    /**
     * Excel 导出类
     *
     * @param response   响应
     * @param fileName   文件名
     * @param columnList 每列的标题名
     * @param dataList   导出的数据
     */
    public static void exportExcel(HttpServletResponse response, String fileName, List<String> columnList, List<List<String>> dataList) {
        //声明输出流
        OutputStream os = null;
        //设置响应头
        setResponseHeader(response, fileName);
        try {
            //获取输出流
            os = response.getOutputStream();
            //内存中保留1000条数据，以免内存溢出，其余写入硬盘
            SXSSFWorkbook wb = new SXSSFWorkbook(1000);
            //获取该工作区的第一个sheet
            Sheet sheet1 = wb.createSheet("sheet1");
            int excelRow = 0;
            //创建标题行
            Row titleRow = sheet1.createRow(excelRow++);
            for (int i = 0; i < columnList.size(); i++) {
                //创建该行下的每一列，并写入标题数据
                Cell cell = titleRow.createCell(i);
                cell.setCellValue(columnList.get(i));
            }
            //设置内容行
            if (dataList != null && dataList.size() > 0) {
                //序号是从1开始的
                int count = 1;
                //外层for循环创建行
                for (List<String> strings : dataList) {
                    Row dataRow = sheet1.createRow(excelRow++);
                    //内层for循环创建每行对应的列，并赋值
                    for (int j = -1; j < dataList.get(0).size(); j++) {//由于多了一列序号列所以内层循环从-1开始
                        Cell cell = dataRow.createCell(j + 1);
                        if (j == -1) {//第一列是序号列，不是在数据库中读取的数据，因此手动递增赋值
                            cell.setCellValue(count++);
                        } else {//其余列是数据列，将数据库中读取到的数据依次赋值
                            cell.setCellValue(strings.get(j));
                        }
                    }
                }
            }
            //将整理好的excel数据写入流中
            wb.write(os);
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            try {
                // 关闭输出流
                if (os != null) {
                    os.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    /*
        设置浏览器下载响应头
     */
    private static void setResponseHeader(HttpServletResponse response, String fileName) {
        try {
            try {
                fileName = new String(fileName.getBytes(), "ISO8859-1");
            } catch (UnsupportedEncodingException e) {
                e.printStackTrace();
            }
            response.setContentType("application/octet-stream;charset=UTF-8");
            response.setHeader("Content-Disposition", "attachment;filename=" + fileName);
            response.addHeader("Cache-Control", "no-cache");
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }

}
```

- 编写业务类

```java
import com.rainbowfish.health.physical.util.ExcelUtil;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.http.HttpEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletResponse;
import java.util.ArrayList;
import java.util.List;

@Api(tags = "Excel 下载接口")
@RestController
@RequestMapping("/api/v1/excel")
public class ExcelController {

    @GetMapping("/test")
    @ApiOperation(value = "测试下载 Excel ")
    public HttpEntity<ResultResponse> download(HttpServletResponse response) {
        List<String> record = new ArrayList<>();
        List<List<String>> recordList = new ArrayList<>();
        record.add("A");
        record.add("B");
        record.add("C");
        recordList.add(record);
        List<String> columnNameList = new ArrayList<>();
        columnNameList.add("编号");
        columnNameList.add("姓名");
        columnNameList.add("性别");
        columnNameList.add("住址");
        ExcelUtil.exportExcel(response, "download.xlsx", columnNameList, recordList);
        return new HttpEntity<>(null);
    }

}
```

### FastExcel

#### Gradle 依赖

```groovy
dependencies {
    implementation 'cn.idev.excel:fastexcel:1.2.0'
}
```

#### 编码

首先要编写导出模型：

```java
import cn.idev.excel.annotation.ExcelProperty;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class ExportData {

    @ExcelProperty("ID")
    private Long id;

    @ExcelProperty("文本")
    private String text;

    @ExcelProperty("日期时间")
    private LocalDateTime localDateTime;

    @ExcelProperty
    private BigDecimal bigDecimal;

}
```

然后编写假数据生成类：

```java
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class TestDataGenerator {

    private static final Random random = new Random();

    public static List<ExportData> generate(int count) {
        List<ExportData> dataList = new ArrayList<>();


        for (int i = 0; i < count; i++) {
            ExportData data = new ExportData();
            data.setId((long) (i + 1));
            data.setText("示例文本-" + i);
            data.setLocalDateTime(LocalDateTime.now().plusMinutes(i)); // 模拟不同时间
            data.setBigDecimal(BigDecimal.valueOf(Math.round(Math.random() * 1000000) / 100.0)); // 保留两位小数
            dataList.add(data);
        }

        return dataList;
    }
}
```

最后写服务即可：

```java
import cn.idev.excel.ExcelWriter;
import cn.idev.excel.FastExcel;
import cn.idev.excel.write.metadata.WriteSheet;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

@Service
public class ExportService {

    public void exportExcel(HttpServletResponse response) {
        // 设置响应头
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setCharacterEncoding("utf-8");
        String fileName = null;
        fileName = URLEncoder.encode("导出数据列表", StandardCharsets.UTF_8).replaceAll("\\+", "%20");
        response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");

        // 开始写入 Excel
        try (ExcelWriter writer = FastExcel.write(response.getOutputStream(), ExportData.class).build()) {
            WriteSheet sheet = FastExcel.writerSheet("用户数据").build();
            List<ExportData> exportDataList = TestDataGenerator.generate(10);
            writer.write(exportDataList, sheet);
            writer.finish();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

}
```

如需测试可以写 controller :

```java
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/export")
public class ExportController {

    @Resource
    private ExportService exportService;

    @GetMapping("/excel")
    public void export(HttpServletResponse response) {
        exportService.exportExcel(response);
    }

}
```

### 参考资料

[官方文档](https://poi.apache.org/components/spreadsheet/quick-guide.html)

[手把手教你springboot中导出数据到excel中](https://www.cnblogs.com/zaevn00001/p/13353744.html?utm_source=tuicool)

[FastExcel](https://readmex.com/fast-excel/fastexcel/)
