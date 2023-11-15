---
title: Apache PDFBox
date: 2023-07-24 21:05:12
tags:
- "JAVA"
- "PDF"
id: pdfBox
no_word_count: true
no_toc: false
categories: JAVA
---

## Apache PDFBox

### 简介

Apache PDFBox 库是一个用于处理 PDF 文档的开源 Java 工具。

### 使用方式

引入依赖：

```groovy
dependencies {
    implementation 'org.apache.pdfbox:pdfbox:2.0.30'
}
```

编写生成代码：

```java
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;

import java.io.IOException;

public class PDFGenerator {

    public static void main(String[] args) {
        String pdfFilePath = "output.pdf";
        String imgPath = "<image_path>";
        try {
            // Create a new document
            PDDocument document = new PDDocument();
            PDPage page1 = new PDPage(PDRectangle.A4);
            document.addPage(page1);

            // Create content stream
            PDPageContentStream contentStream = new PDPageContentStream(document, page1);

            // Set image position and size
            float x = 100; // X-coordinate
            float y = 500; // Y-coordinate
            float width = 300; // Image width
            float height = 200; // Image height

            // Add image to the page
            contentStream.drawImage(PDImageXObject.createFromFile(imgPath, document), x, y, width, height);

            contentStream.close();

            PDPage page2 = new PDPage(PDRectangle.A4);
            document.addPage(page2);
            PDPageContentStream contentStream2 = new PDPageContentStream(document, page2);

            // Draw table
            drawTableHeaders(contentStream2);
            drawTableRow(contentStream2, 1, "Data 1", "Value 1");
            drawTableRow(contentStream2, 2, "Data 2", "Value 2");
            contentStream2.close();


            document.save(pdfFilePath);
            document.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static void drawTableHeaders(PDPageContentStream contentStream) throws IOException {
        float margin = 50;
        float yStart = 700;
        float tableWidth = 500;
        float yPosition = yStart;
        float rowHeight = 20;
        float cellMargin = 5f;

        float[] columnWidths = {200, 300}; // Adjust column widths as needed

        // Draw table headers
        contentStream.setFont(PDType1Font.HELVETICA_BOLD, 12);
        contentStream.setLineWidth(1f);
        contentStream.moveTo(margin, yPosition);
        contentStream.lineTo(margin + tableWidth, yPosition);
        contentStream.stroke();

        yPosition -= rowHeight;
        contentStream.beginText();
        contentStream.newLineAtOffset(margin + cellMargin, yPosition - 15);
        contentStream.showText("Column 1");
        contentStream.newLineAtOffset(columnWidths[0], 0);
        contentStream.showText("Column 2");
        contentStream.endText();
    }

    private static void drawTableRow(PDPageContentStream contentStream, int rowNum, String data1, String data2) throws IOException {
        float margin = 50;
        float yStart = 700;
        float tableWidth = 500;
        float yPosition = yStart - rowNum * 20;
        float rowHeight = 20;
        float cellMargin = 5f;

        float[] columnWidths = {200, 300}; // Adjust column widths as needed

        // Draw table row
        contentStream.setLineWidth(1f);
        contentStream.moveTo(margin, yPosition);
        contentStream.lineTo(margin + tableWidth, yPosition);
        contentStream.stroke();

        yPosition -= rowHeight;
        contentStream.beginText();
        contentStream.setFont(PDType1Font.HELVETICA, 12);
        contentStream.newLineAtOffset(margin + cellMargin, yPosition - 15);
        contentStream.showText(data1);
        contentStream.newLineAtOffset(columnWidths[0], 0);
        contentStream.showText(data2);
        contentStream.endText();
    }
}
```

### 参考资料

[官方网站](https://pdfbox.apache.org/)

[官方项目](https://github.com/apache/pdfbox)
