---
title: 数据合并
date: 2024-08-06 21:32:58
tags:
- "Java"
- "Spring Boot"
id: merge
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

## 数据合并

### 简介

在使用多种来源的数据时，可能会涉及到性能问题，此处针对 WebClient 和 RestClient 方式进行试用。

### 实现方式

#### WebClient

编写 `WebClientController.java` 文件 

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/web-client")
public class WebClientController {

    private static final Logger log = LoggerFactory.getLogger(WebClientController.class);

    private final WebClient webClient;

    public WebClientController(WebClient.Builder builder) {
        this.webClient = builder.baseUrl("https://api.open-meteo.com/v1/forecast").build();
    }

    private CompletableFuture<OpenMeteoResponse> getCMA(BigDecimal lat, BigDecimal lon) {
        log.error("start cma {}", Thread.currentThread().getName());
        long startTime = System.currentTimeMillis();
        CompletableFuture<OpenMeteoResponse> cache = this.webClient.get().uri(
                uriBuilder -> uriBuilder
                        .queryParam("latitude", lat)
                        .queryParam("longitude", lon)
                        .queryParam("hourly", "temperature_2m")
                        .queryParam("timezone", "Asia/Shanghai")
                        .queryParam("models", "cma_grapes_global")
                        .queryParam("forecast_days", "1")
                        .build()
        ).retrieve().bodyToMono(OpenMeteoResponse.class).toFuture();
        long endTime = System.currentTimeMillis();
        log.error("end cma {}", endTime - startTime);
        return cache;
    }

    private CompletableFuture<OpenMeteoResponse> getGFS(BigDecimal lat, BigDecimal lon) {
        log.error("start gfs {}", Thread.currentThread().getName());
        long startTime = System.currentTimeMillis();
        CompletableFuture<OpenMeteoResponse> cache = this.webClient.get().uri(
                uriBuilder -> uriBuilder
                        .queryParam("latitude", lat)
                        .queryParam("longitude", lon)
                        .queryParam("hourly", "temperature_2m")
                        .queryParam("timezone", "Asia/Shanghai")
                        .queryParam("models", "gfs_global")
                        .queryParam("forecast_days", "1")
                        .build()
        ).retrieve().bodyToMono(OpenMeteoResponse.class).toFuture();
        long endTime = System.currentTimeMillis();
        log.error("end gfs {}", endTime - startTime);
        return cache;
    }

    private CompletableFuture<OpenMeteoResponse> getIcon(BigDecimal lat, BigDecimal lon) {
        log.error("start gfs {}", Thread.currentThread().getName());
        long startTime = System.currentTimeMillis();
        CompletableFuture<OpenMeteoResponse> cache = this.webClient.get().uri(
                uriBuilder -> uriBuilder
                        .queryParam("latitude", lat)
                        .queryParam("longitude", lon)
                        .queryParam("hourly", "temperature_2m")
                        .queryParam("timezone", "Asia/Shanghai")
                        .queryParam("models", "icon_global")
                        .queryParam("forecast_days", "1")
                        .build()
        ).retrieve().bodyToMono(OpenMeteoResponse.class).toFuture();
        long endTime = System.currentTimeMillis();
        log.error("end gfs {}", endTime - startTime);
        return cache;
    }

    private CompletableFuture<OpenMeteoResponse> getGraphCast(BigDecimal lat, BigDecimal lon) {
        log.error("start gfs {}", Thread.currentThread().getName());
        long startTime = System.currentTimeMillis();
        CompletableFuture<OpenMeteoResponse> cache = this.webClient.get().uri(
                uriBuilder -> uriBuilder
                        .queryParam("latitude", lat)
                        .queryParam("longitude", lon)
                        .queryParam("hourly", "temperature_2m")
                        .queryParam("timezone", "Asia/Shanghai")
                        .queryParam("models", "gfs_graphcast025")
                        .queryParam("forecast_days", "1")
                        .build()
        ).retrieve().bodyToMono(OpenMeteoResponse.class).toFuture();
        long endTime = System.currentTimeMillis();
        log.error("end gfs {}", endTime - startTime);
        return cache;
    }

    public Mono<List<OpenMeteoResponse>> getMergedData(BigDecimal lat, BigDecimal lon) {
        List<CompletableFuture<OpenMeteoResponse>> futures = List.of(
                getCMA(lat, lon),
                getGFS(lat, lon),
                getIcon(lat, lon),
                getGraphCast(lat, lon)
        );

        CompletableFuture<Void> allOf = CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]));

        return Mono.fromFuture(allOf.thenApply(v -> futures.stream()
                .map(CompletableFuture::join)
                .collect(Collectors.toList())));
    }

    @GetMapping
    private Mono<List<OpenMeteoResponse>> getOpenMeteoResponse(@RequestParam(defaultValue = "52.5625") BigDecimal lat, @RequestParam(defaultValue = "13.375") BigDecimal lon) {
        return getMergedData(lat, lon);
    }

}
```

之后即可使用 `test.http` 文件进行测试：

```text
###
GET http://localhost:8080/api/web-client

```

#### RestClient

编写 `RestClientController.java` 文件 

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/rest-client")
public class RestClientController {

    private static final Logger log = LoggerFactory.getLogger(RestClientController.class);
    private final RestClient restClient;

    public RestClientController(RestClient.Builder builder) {
        this.restClient = builder.baseUrl("https://api.open-meteo.com/v1/forecast").build();
    }

    private OpenMeteoResponse getCMA(BigDecimal lat, BigDecimal lon) {
        log.error("start cma {}", Thread.currentThread().getName());
        long startTime = System.currentTimeMillis();
        OpenMeteoResponse cache = this.restClient.get().uri(
                uriBuilder -> uriBuilder
                        .queryParam("latitude", lat)
                        .queryParam("longitude", lon)
                        .queryParam("hourly", "temperature_2m")
                        .queryParam("timezone", "Asia/Shanghai")
                        .queryParam("models", "cma_grapes_global")
                        .queryParam("forecast_days", "1")
                        .build()
        ).retrieve().body(OpenMeteoResponse.class);
        long endTime = System.currentTimeMillis();
        log.error("end cma {}", endTime - startTime);
        return cache;
    }

    private OpenMeteoResponse getGFS(BigDecimal lat, BigDecimal lon) {
        log.error("start gfs {}", Thread.currentThread().getName());
        long startTime = System.currentTimeMillis();
        OpenMeteoResponse cache = this.restClient.get().uri(
                uriBuilder -> uriBuilder
                        .queryParam("latitude", lat)
                        .queryParam("longitude", lon)
                        .queryParam("hourly", "temperature_2m")
                        .queryParam("timezone", "Asia/Shanghai")
                        .queryParam("models", "gfs_global")
                        .queryParam("forecast_days", "1")
                        .build()
        ).retrieve().body(OpenMeteoResponse.class);
        long endTime = System.currentTimeMillis();
        log.error("end gfs {}", endTime - startTime);
        return cache;
    }

    private OpenMeteoResponse getICON(BigDecimal lat, BigDecimal lon) {
        log.error("start icon {}", Thread.currentThread().getName());
        long startTime = System.currentTimeMillis();
        OpenMeteoResponse cache = this.restClient.get().uri(
                uriBuilder -> uriBuilder
                        .queryParam("latitude", lat)
                        .queryParam("longitude", lon)
                        .queryParam("hourly", "temperature_2m")
                        .queryParam("timezone", "Asia/Shanghai")
                        .queryParam("models", "icon_global")
                        .queryParam("forecast_days", "1")
                        .build()
        ).retrieve().body(OpenMeteoResponse.class);
        long endTime = System.currentTimeMillis();
        log.error("end icon {}", endTime - startTime);
        return cache;
    }

    private OpenMeteoResponse getGraphCast(BigDecimal lat, BigDecimal lon) {
        log.error("start graphcast {}", Thread.currentThread().getName());
        long startTime = System.currentTimeMillis();
        OpenMeteoResponse cache = this.restClient.get().uri(
                uriBuilder -> uriBuilder
                        .queryParam("latitude", lat)
                        .queryParam("longitude", lon)
                        .queryParam("hourly", "temperature_2m")
                        .queryParam("timezone", "Asia/Shanghai")
                        .queryParam("models", "gfs_graphcast025")
                        .queryParam("forecast_days", "1")
                        .build()
        ).retrieve().body(OpenMeteoResponse.class);
        long endTime = System.currentTimeMillis();
        log.error("end graphcast {}", endTime - startTime);
        return cache;
    }

    private List<OpenMeteoResponse> getMergedData(BigDecimal lat, BigDecimal lon) {
        List<OpenMeteoResponse> data = new ArrayList<>();
        data.add(getCMA(lat, lon));
        data.add(getGFS(lat, lon));
        data.add(getICON(lat, lon));
        data.add(getGraphCast(lat, lon));
        return data;
    }

    @GetMapping
    private List<OpenMeteoResponse> getOpenMeteoResponse(@RequestParam(defaultValue = "52.5625") BigDecimal lat, @RequestParam(defaultValue = "13.375") BigDecimal lon) {
        return getMergedData(lat, lon);
    }

}
```

之后即可使用 `test.http` 文件进行测试：

```text
### 
GET http://localhost:8080/api/rest-client

```

### 总结

经过多次测试 WebClient 有明显的性能优势。

> 注：在测试时可以多选几个点避免缓存问题，或者多次测试取平均值。
