---
title: Spring Data Elasticsearch
date: 2023-06-19 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Elasticsearch"
- "SSL"
id: spring-data-elasticsearch
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Data Elasticsearch

### 简介

Spring Data Elasticsearch 是一款使用 Spring 的核心概念的 Elasticsearch 客户端程序。

> 注：此项目为开源项目，更新不像原生客户端那样及时，使用时需要特别注意。

### 使用方式

- 引入依赖包

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-data-elasticsearch'
}
```

- 编写模型类

```java
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;

import java.time.LocalDateTime;

@Data
@Document(indexName = "book")
public class Book {

    @Id
    private String id;

    @Field(type = FieldType.Keyword, name = "author")
    private String author;

    @Field(type = FieldType.Date_Nanos, name = "publishDate")
    private LocalDateTime publishDate;
    
}
```

- 编写 Repository

```java
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;

public interface BookRepository extends ElasticsearchRepository<Book, String> {

}
```

- 配置链接地址(使用配置类)

```java
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.apache.http.ssl.SSLContextBuilder;
import org.apache.http.ssl.SSLContexts;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.data.elasticsearch.client.ClientConfiguration;
import org.springframework.data.elasticsearch.client.elc.ElasticsearchConfiguration;

import javax.net.ssl.SSLContext;
import java.io.InputStream;
import java.security.KeyStore;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;

@Slf4j
@Configuration
public class CustomESConfig extends ElasticsearchConfiguration {

    @Value("${elasticsearch.certsPath}")
    private String certsPath;

    @jakarta.annotation.Resource
    private ResourceLoader resourceLoader;

    @SneakyThrows
    @Override
    public ClientConfiguration clientConfiguration() {
        Resource resource = resourceLoader.getResource(certsPath);
        CertificateFactory factory = CertificateFactory.getInstance("X.509");
        Certificate trustedCa;
        try (InputStream is = resource.getInputStream()) {
            trustedCa = factory.generateCertificate(is);
        }
        KeyStore trustStore = KeyStore.getInstance("pkcs12");
        trustStore.load(null, null);
        trustStore.setCertificateEntry("ca", trustedCa);
        SSLContextBuilder sslContextBuilder = SSLContexts.custom()
                .loadTrustMaterial(trustStore, null);
        final SSLContext sslContext = sslContextBuilder.build();
        return ClientConfiguration.builder()
                .connectedTo("xxx.xxx.xxx.xxx:9200")
                .usingSsl(sslContext)
                .withBasicAuth("xxx", "xxxxx")
                .build();
    }

}
```

然后编写如下配置文件：

```yaml
elasticsearch:
  certsPath: classpath:http_ca.crt
```

- 配置链接地址(使用配置文件，需要 SpringBoot 版本大于 3.1)

```yaml
spring:
  ssl:
    bundle:
      pem:
        es:
          truststore:
            certificate: "classpath:http_ca.crt"
  elasticsearch:
    uris: https://xxx.xxx.xxx.xxx:9200
    username: xxx
    password: xxxx
    restclient:
      ssl:
        bundle: "es"
```

> 注：bundle 方式还可以用到其他需要 SSL 配置的数据库中，例如：MongoDB，Redis 等。

### 复杂查询

#### IN 查询

```java
TermsQueryField termsQueryField = new TermsQueryField.Builder()
                    .value(List.of("1","2","3").stream().map(FieldValue::of).toList())
                    .build();
```

#### 子查询

构建查询：

```java
NativeQueryBuilder nativeQueryBuilder = NativeQuery.builder();
Aggregation avgAgg = AggregationBuilders.avg(a -> a.field("value"));
Aggregation dateAgg = new Aggregation.Builder().dateHistogram(dH -> dH.field("messageTime").calendarInterval(CalendarInterval.Hour)).aggregations("avg_value",avgAgg).build();
nativeQueryBuilder.withAggregation("agg_by_date", dateAgg);
NativeQuery nativeQuery = nativeQueryBuilder.build()
```

结果解析：

```java
List<ElasticsearchAggregation> aggregationList = (List<ElasticsearchAggregation>) searchHit.getAggregations().aggregations();
for (ElasticsearchAggregation elasticsearchAggregation : aggregationList) {
    List<DateHistogramBucket> byHour = elasticsearchAggregation.aggregation().getAggregate().dateHistogram().buckets().array();
    for (DateHistogramBucket dbk : byHour) {
        Double value = dbk.aggregations().get("avg_value").avg().value()
    }
}
```

### 单元测试

在单元测试时可以加上 `@DataElasticsearchTest` 注解避免实际插入数据。

> 注：此注解当前失效，如需使用可以参照 [Issue](https://github.com/spring-projects/spring-boot/issues/35926)

### 参考资料

[官方文档](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/)

[Securing Spring Boot Applications With SSL](https://spring.io/blog/2023/06/07/securing-spring-boot-applications-with-ssl)
