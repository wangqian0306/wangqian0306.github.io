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
        sf.setHost("192.168.1.170");
        sf.setPort(21);
        sf.setUsername("anonymous");
        sf.setPassword("");
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
        ftpRemoteFileTemplate.setExistsMode(FtpRemoteFileTemplate.ExistsMode.NLST);
        return ftpRemoteFileTemplate;
    }

}
```

编写业务类：

```java

```

### 参考文档

[官方手册](https://docs.spring.io/spring-integration/docs/current/reference/html/ftp.html#ftp)
