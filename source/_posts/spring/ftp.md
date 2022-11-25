---
title: Spring Integration FTP/FTPS Adapters
date: 2022-11-24 21:32:58
tags:
- "Java"
- "Spring Boot"
- "FTP"
id: spring-integration-ftp
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Integration FTP/FTPS Adapters

### 简介

Spring 官方为 FTP 和 FTPS 文件传输提供了插件。

### 使用方式

引入依赖：

```xml
<dependency>
    <groupId>org.springframework.integration</groupId>
    <artifactId>spring-integration-ftp</artifactId>
    <version>6.0.0</version>
</dependency>
```

编写链接配置：

```java
import org.apache.commons.net.ftp.FTP;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPFile;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.expression.ExpressionParser;
import org.springframework.expression.spel.standard.SpelExpressionParser;
import org.springframework.integration.file.remote.session.CachingSessionFactory;
import org.springframework.integration.file.remote.session.SessionFactory;
import org.springframework.integration.ftp.session.DefaultFtpSessionFactory;
import org.springframework.integration.ftp.session.FtpRemoteFileTemplate;
import org.springframework.integration.ftp.session.FtpSession;

@Configuration
public class FTPConfiguration {

    @Bean
    public SessionFactory<FTPFile> ftpSessionFactory() {
        DefaultFtpSessionFactory sf = new DefaultFtpSessionFactory() {
            @Override
            public synchronized FtpSession getSession() {
                return super.getSession();
            }
        };
        sf.setHost("xxx.xxx.xxx.xxx");
        sf.setPort(21);
        sf.setUsername("xxx");
        sf.setPassword("xxx");
        sf.setControlEncoding("UTF-8");
        sf.setFileType(FTP.BINARY_FILE_TYPE);
        sf.setClientMode(FTPClient.PASSIVE_LOCAL_DATA_CONNECTION_MODE);
        CachingSessionFactory<FTPFile> csf = new CachingSessionFactory<>(sf);
        csf.setPoolSize(1);
        return csf;
    }

    @Bean
    public FtpRemoteFileTemplate ftpRemoteFileTemplate(@Qualifier("ftpSessionFactory") SessionFactory<FTPFile> sessionFactory) {
        FtpRemoteFileTemplate ftpRemoteFileTemplate = new FtpRemoteFileTemplate(sessionFactory);
        ExpressionParser parser = new SpelExpressionParser();
        ftpRemoteFileTemplate.setRemoteDirectoryExpression(parser.parseExpression("''"));
        ftpRemoteFileTemplate.setExistsMode(FtpRemoteFileTemplate.ExistsMode.STAT);
        return ftpRemoteFileTemplate;
    }

}
```

> 注：在使用匿名模式时将用户设为 "anonymous" 密码设为 "" 即可。

编写业务类：

```java
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPFile;
import org.springframework.http.ResponseEntity;
import org.springframework.integration.file.support.FileExistsMode;
import org.springframework.integration.ftp.session.FtpRemoteFileTemplate;
import org.springframework.messaging.support.GenericMessage;
import org.springframework.util.FileCopyUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.FileSystems;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/test")
public class TestController {

    @Resource
    FtpRemoteFileTemplate ftpRemoteFileTemplate;

    @GetMapping
    public ResponseEntity<List<FTPFile>> ls(@RequestParam String path) {
        FTPFile[] result = ftpRemoteFileTemplate.list(path);
        return ResponseEntity.ok(Arrays.stream(result).collect(Collectors.toList()));
    }

    @GetMapping("/read")
    public ResponseEntity<String> read(@RequestParam String path) {
        if (!ftpRemoteFileTemplate.exists(path)) {
            throw new RuntimeException("file not exist");
        }
        final ByteArrayOutputStream cache = new ByteArrayOutputStream();
        boolean success = ftpRemoteFileTemplate.get(path, stream -> FileCopyUtils.copy(stream, cache));
        if (success) {
            return ResponseEntity.ok(cache.toString());
        } else {
            throw new RuntimeException("file not exist");
        }
    }

    @GetMapping("/download")
    public void download(@RequestParam String path, HttpServletResponse httpServletResponse) {
        if (!ftpRemoteFileTemplate.exists(path)) {
            throw new RuntimeException("file not exist");
        }
        FTPFile file = ftpRemoteFileTemplate.list(path)[0];
        if (file.isDirectory()) {
            throw new RuntimeException("path is directory");
        }
        httpServletResponse.reset();
        httpServletResponse.setContentType("application/octet-stream;charset=utf-8");
        httpServletResponse.setHeader(
                "Content-disposition",
                "attachment; filename=" + file.getName());
        OutputStream out;
        try {
            out = httpServletResponse.getOutputStream();
        } catch (IOException e) {
            throw new RuntimeException("outputStream error");
        }
        boolean success = ftpRemoteFileTemplate.get(path, stream -> FileCopyUtils.copy(stream, out));
        if (!success) {
            throw new RuntimeException("copy error");
        }
    }

    @PostMapping
    public Boolean write(@RequestParam MultipartFile file, @RequestParam String path) throws IOException {
        String dest = FileSystems.getDefault().getPath(path, file.getOriginalFilename()).toString();
        String originName = ftpRemoteFileTemplate.send(new GenericMessage<>(file.getInputStream().readAllBytes()), path, FileExistsMode.REPLACE);
        ftpRemoteFileTemplate.rename(originName, dest);
        return true;
    }

    @PutMapping
    public Boolean mkdir(@RequestParam String path) {
        try {
            return ftpRemoteFileTemplate.getSession().mkdir(path);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    @DeleteMapping
    public Boolean delete(@RequestParam String path) throws IOException {
        if (!ftpRemoteFileTemplate.exists(path)) {
            throw new RuntimeException("file or directory not exist");
        }
        FTPFile[] files = ftpRemoteFileTemplate.list(path);
        if (files.length == 0) {
            return ftpRemoteFileTemplate.getSession().rmdir(path);
        } else if (files.length == 1) {
            FTPClient ftpClient = (FTPClient) ftpRemoteFileTemplate.getSession().getClientInstance();
            if (ftpClient.deleteFile(path)) {
                return true;
            } else {
                throw new RuntimeException("directory not empty");
            }
        } else {
            throw new RuntimeException("directory not empty");
        }
    }
}
```

> 注：此处代码并没有详细进行完善，使用时请注意。

编写测试类：

```http
### mkdir
PUT http://localhost:8080/test?path=demo

### upload file
POST http://localhost:8080/test
Content-Type: multipart/form-data; boundary=WebAppBoundary

--WebAppBoundary
Content-Disposition: form-data; name="file"; filename="demo.txt"

< ./demo.txt
--WebAppBoundary--
Content-Disposition: form-data; name="path"

demo
--WebAppBoundary--

### ls
GET http://localhost:8080/test?path=/

### cat
GET http://localhost:8080/test/read?path=demo/demo.txt

### download
GET http://localhost:8080/test/download?path=demo/demo.txt

### rm
DELETE http://localhost:8080/test?path=demo
```

### 参考文档

[官方手册](https://docs.spring.io/spring-integration/docs/current/reference/html/ftp.html#ftp)
