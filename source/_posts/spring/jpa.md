---
title: Spring Data JPA
date: 2022-05-06 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Spring Data JPA"
id: jpa
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Data JPA

### 简介

Spring Data JPA 旨在通过减少实际需要的工作量来显着改进数据访问层的实现。

### 常见使用方式

#### 自动获取更新时间创建时间等内容

首先需要按照如下样例创建模型类

```java
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedBy;
import org.springframework.data.annotation.LastModifiedDate;

import javax.persistence.Entity;
import javax.persistence.Id;
import java.util.Date;

@Getter
@Setter
@ToString
@RequiredArgsConstructor
@Entity
@EntityListeners(AuditingEntityListener.class)
public class Test {

    @Id
    private String id;

    @CreatedBy
    private String createdBy;

    @LastModifiedBy
    private String lastModifiedBy;

    @CreatedDate
    private Date createdDate;

    @LastModifiedDate
    private Date updatedDate;

}
```

创建如下的操作员获取类

```java

@Component
public class AuditorConfig implements AuditorAware<String> {

    @Override
    public Optional<String> getCurrentAuditor() {
        
        // 这里应根据实际业务情况获取具体信息
        return Optional.of(userName);
    }

}
```

开启编辑审计功能(在启动类中加入下面的注解即可)

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class TestApplication {

    public static void main(String[] args) {
        SpringApplication.run(Test.class, args);
    }

}
```

#### 动态构建查询

首先需要在 Repository 中额外引入 `JpaSpecificationExecutor`

```java
@Repository
public interface TestRepository extends JpaRepository<Test, String>, JpaSpecificationExecutor<Test> {
}
```

然后即可在查询中进行如下操作

```java
@Service
public class Test {
    @Resource
    private TestRepository testRepository;

    public void test() {
        testRepository.findAll((root, criteriaQuery, cb) -> {
            List<Predicate> predicate = new ArrayList<>();
            // 此处可以添加条件，需要注意的是所填写的列名要和模型对象名一致
            Path<String> testPath = root.get("test");
            predicate.add(cb.like(testPath, "test"));
            Predicate[] pre = new Predicate[predicate.size()];
            criteriaQuery.where(predicate.toArray(pre));
            return criteriaQuery.getRestriction();
        });
    }
}
```

#### 表名或列名大写

在配置中填入如下内容即可：

```yaml
spring:
  jpa:
    hibernate:
      naming:
        physical-strategy: org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
```