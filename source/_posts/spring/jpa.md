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

### 常见问题

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