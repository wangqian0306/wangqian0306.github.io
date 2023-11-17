---
title: awt
date: 2023-07-24 21:05:12
tags:
- "JAVA"
id: awt
no_word_count: true
no_toc: false
categories: JAVA
---

## AWT

### 简介

抽象视窗工具组(Abstract Window Toolkit，简称：AWT) 是Java的平台独立的视窗系统，也是图形和使用界面的工具包。

### 常见使用样例

#### 获取图像宽高

```java
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

public class ImageSizeExample {

    public static void main(String[] args) {
        String imagePath = "path/to/your/image.jpg";

        try {
            File imageFile = new File(imagePath);
            BufferedImage bufferedImage = ImageIO.read(imageFile);

            int width = bufferedImage.getWidth();
            int height = bufferedImage.getHeight();

            System.out.println("Image Width: " + width);
            System.out.println("Image Height: " + height);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

#### 合并图片并设定位置

```java
import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

public class ImageCombine {
    public static void main(String[] args) {
        try {
            BufferedImage image1 = ImageIO.read(new File("path/to/image1.jpg"));
            BufferedImage image2 = ImageIO.read(new File("path/to/image2.jpg"));
            BufferedImage combined = new BufferedImage(image1.getWidth(), image1.getHeight(), BufferedImage.TYPE_INT_ARGB);
            Graphics g = combined.getGraphics();
            g.drawImage(image1, 0, 0, null);
            g.drawImage(image2, 50, 50, null);
            g.dispose();
            File outputImage = new File("path/to/output.jpg");
            ImageIO.write(combined, "jpg", outputImage);
            System.out.println("Images combined successfully!");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```