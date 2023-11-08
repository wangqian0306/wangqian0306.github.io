---
title: Drools
date: 2023-11-08 21:05:12
tags: 
- "Java"
- "Spring Boot"
- "Drools"
id: drools
no_word_count: true
no_toc: false
categories: Spring
---

## Drools

### 简介

Drools 是一个业务规则管理系统(Business Rules Management System,BRMS) 解决方案。主要目的是将复杂的业务逻辑抽离出来，将其编辑成为配置文件便于后期进行修改。

### 使用方式

首先需要引入相关包：

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    annotationProcessor 'org.projectlombok:lombok'
    implementation 'org.drools:drools-core:9.44.0.Final'
    implementation 'org.kie:kie-spring:7.74.1.Final'
    implementation 'org.kie:kie-api:9.44.0.Final'
    implementation 'org.drools:drools-compiler:9.44.0.Final'
    implementation 'org.drools:drools-mvel:9.44.0.Final'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}
```

编写业务类：

```java
import lombok.Data;

@Data
public class Fare {
    private Long nightSurcharge = 0L;
    private Long rideFare = 0L;

    public Long getTotalFare() {
        return nightSurcharge + rideFare;
    }

}
```

```java
import lombok.Data;

@Data
public class TaxiRide {
    private Boolean isNightSurcharge;
    private Long distanceInMile;
}
```

编写规则文件：

```drools
import com.example.xxx.model.TaxiRide
import com.example.xxx.model.Fare
import java.util.*

global com.example.xxx.model.Fare rideFare;
dialect "mvel"

rule "Calculate Taxi Fare - Scenario 1"
    when
        taxiRideInstance:TaxiRide(isNightSurcharge == false && distanceInMile < 10);
    then
      	rideFare.setNightSurcharge(0L);
       	rideFare.setRideFare(70L);
end
```

编写配置类：

```java
import org.kie.api.KieServices;
import org.kie.api.builder.KieBuilder;
import org.kie.api.builder.KieFileSystem;
import org.kie.api.builder.KieModule;
import org.kie.api.runtime.KieContainer;
import org.kie.internal.io.ResourceFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

@Configuration
@ComponentScan("com.example.xxx.service")
public class TaxiFareConfiguration {

    public static final String drlFile = "TAXI_FARE_RULE.drl";

    @Bean
    public KieContainer kieContainer() {
        KieServices kieServices = KieServices.Factory.get();

        KieFileSystem kieFileSystem = kieServices.newKieFileSystem();
        kieFileSystem.write(ResourceFactory.newClassPathResource(drlFile));
        KieBuilder kieBuilder = kieServices.newKieBuilder(kieFileSystem);
        kieBuilder.buildAll();
        KieModule kieModule = kieBuilder.getKieModule();

        return kieServices.newKieContainer(kieModule.getReleaseId());
    }

}
```

编写服务类：

```java
import org.kie.api.runtime.KieContainer;
import org.kie.api.runtime.KieSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class TaxiFareCalculatorService {

    private static final Logger LOGGER = LoggerFactory.getLogger(TaxiFareCalculatorService.class);

    @Autowired
    private KieContainer kContainer;

    public Long calculateFare(TaxiRide taxiRide, Fare rideFare) {
        KieSession kieSession = kContainer.newKieSession();
        kieSession.setGlobal("rideFare", rideFare);
        kieSession.insert(taxiRide);
        kieSession.fireAllRules();
        kieSession.dispose();
        LOGGER.debug("!! RIDE FARE !! " + rideFare.getTotalFare());
        return rideFare.getTotalFare();
    }
}
```

之后即可使用测试类进行测试：

```java
import jakarta.annotation.Resource;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest
class ApplicationTests {

    @Resource
    private TaxiFareCalculatorService taxiFareCalculatorService;

    @Test
    void contextLoads() {
    }

    @Test
    public void whenNightSurchargeFalseAndDistLessThan10_thenFixWithoutNightSurcharge() {
        TaxiRide taxiRide = new TaxiRide();
        taxiRide.setIsNightSurcharge(false);
        taxiRide.setDistanceInMile(9L);
        Fare rideFare = new Fare();
        Long totalCharge = taxiFareCalculatorService.calculateFare(taxiRide, rideFare);

        assertNotNull(totalCharge);
        assertEquals(Long.valueOf(70), totalCharge);
    }
}
```

### 参考资料

[项目官网](https://www.drools.org/)

[官方手册](https://docs.drools.org/latest/drools-docs/drools/introduction/index.html)

[Drools Spring Integration](https://www.baeldung.com/drools-spring-integration)
