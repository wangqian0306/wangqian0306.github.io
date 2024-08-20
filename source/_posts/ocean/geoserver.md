---
title: GeoServer
date: 2023-09-01 23:09:32
tags:
- "GeoServer"
- "Linux"
id: geoserver
no_word_count: true
no_toc: false
categories: "Ocean"
---

## GeoServer

### 简介

GeoServer 是一款支持多种 GIS 协议类型的自建服务器。

### 部署方式

可以使用 docker 部署

```yaml
version: '3'
services:
  geoserver:
    image: docker.osgeo.org/geoserver:2.24.x
    ports:
      - "8080:8080"
    environment:
      - INSTALL_EXTENSIONS=true
      - STABLE_EXTENSIONS=ysld,h2
    volumes:
      - ./data:/opt/geoserver_data
```

> 注：若没有数据可以不填写数据目录。

之后即可访问 [http://localhost:8080/geoserver/web](http://localhost:8080/geoserver/web) ，然后使用如下账号密码即可完成登录。

账号：admin

密码：geoserver

### 数据来源

GeoServer 可以作为代理，接管天地图或 OpenStreetMap 等 WMS,WMTS 服务。

也可以接入 shp 文件或 PostGIS 数据等内容。

> 注：[POI数据](https://www.poi86.com/) 可以在此处下载国内的 shp 数据文件。

### 常见问题

#### 忘记密码

在容器中的 `/opt/geoserver_data/security/usergroup/default` 目录中有一个 `users.xml` 文件，该文件存储的就是用户有和密码信息。可以通过修改该文件的方式来完成密码重置，默认的用户信息如下：
 
```xml
<user enabled="true" name="admin" password="digest1:D9miJH/hVgfxZJscMafEtbtliG0ROxhLfsznyWfG38X2pda2JOSV4POi55PQI4tw"/>
```

> 注：此处情况仅适用于默认加密方式，如果还出了问题就直接覆盖 `security` 文件夹。 

### 自行实现

如有相关简单的需求也可以通过其他方式接入 SpringBoot , 例如将结构 shp 文件展示成图片。

编辑 `build.gradle` 文件：

```bash
repositories {
    maven { url 'https://repo.osgeo.org/repository/release/'}
    mavenCentral()
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-webflux'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'io.projectreactor:reactor-test'
    implementation 'org.geotools:gt-main:31.2'
    implementation 'org.geotools:gt-image:31.2'
    implementation 'org.geotools:gt-shapefile:31.2'
    implementation 'org.geotools:gt-render:31.2'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}
```

编辑 `TestController.java` ：

```java
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.geotools.api.data.FileDataStore;
import org.geotools.api.data.FileDataStoreFinder;
import org.geotools.api.data.SimpleFeatureSource;
import org.geotools.api.referencing.crs.CoordinateReferenceSystem;
import org.geotools.api.style.Style;
import org.geotools.geometry.jts.ReferencedEnvelope;
import org.geotools.map.FeatureLayer;
import org.geotools.map.Layer;
import org.geotools.map.MapContent;
import org.geotools.renderer.lite.StreamingRenderer;
import org.geotools.styling.SLD;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;

@RestController
public class TestController {

    private static final Logger log = LoggerFactory.getLogger(TestController.class);

    @Value("classpath:/static/ne_110m_coastline.shp")
    private Resource shp;

    @GetMapping(value = "/demo",produces = MediaType.IMAGE_PNG_VALUE)
    public ResponseEntity<byte[]> getTile() throws IOException {
        File shpFile = shp.getFile();
        FileDataStore store = FileDataStoreFinder.getDataStore(shpFile);
        SimpleFeatureSource featureSource = store.getFeatureSource();
        MapContent map = new MapContent();
        Style style = SLD.createSimpleStyle(featureSource.getSchema());
        Layer layer = new FeatureLayer(featureSource, style);
        map.layers().add(layer);
        CoordinateReferenceSystem coordinateReferenceSystem = map.getCoordinateReferenceSystem();
        log.warn(coordinateReferenceSystem.getCoordinateSystem().getName().getCode());
        Rectangle imageBounds = new Rectangle(800, 600);
        ReferencedEnvelope mapArea = map.getViewport().getBounds();
        BufferedImage image = new BufferedImage(imageBounds.width, imageBounds.height, BufferedImage.TYPE_INT_ARGB);
        StreamingRenderer renderer = new StreamingRenderer();
        renderer.setMapContent(map);
        Graphics2D g2d = image.createGraphics();
        renderer.paint(g2d, imageBounds, mapArea);
        g2d.dispose();
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        ImageIO.write(image, "png", outputStream);
        return ResponseEntity.ok().contentType(MediaType.IMAGE_PNG).body(outputStream.toByteArray());
    }

}
```

### 参考资料

[官方文档](https://geoserver.org/)
