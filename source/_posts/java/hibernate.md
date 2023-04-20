---
title: Hibernate 常用功能记录
date: 2023-04-20 23:09:32
tags:
- "JAVA"
id: hibernate
no_word_count: true
no_toc: false
categories: JAVA
---

## Hibernate 常用功能记录

### 简介

Hibernate 是一个开源的对象关系映射框架，它对 JDBC 的操作数据库的过程进行封装，使得开发者只需要关注业务逻辑，而不需要关注底层的数据库操作。Hibernate 有着良好的性能，支持多种数据库，同时也支持多种编程语言。

### 常用功能

#### 关联(Associations)

##### `@ManyToOne`

用户类

```java
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity(name = "Person")
public class Person {

    @Id
    @GeneratedValue
    private Long id;

}
```

联系方式类

```java
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity(name = "Phone")
public class Phone {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String number;

    @ManyToOne(optional = false)
    @JoinColumn(name = "person_id", nullable = false, foreignKey = @ForeignKey(name = "PERSON_ID_FK"))
    private Person person;

}
```

##### `@OneToMany`

用户类

```java
@Entity(name = "Person")
public class Person {

    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY)
    private Long id;

    @OneToMany(mappedBy = "person",cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Phone> phones = new ArrayList<>();

}
```

```java
@Entity(name = "Phone")
public static class Phone {

    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY)
    private Long id;

    private String number;

    @ManyToOne
    private Person person;

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        Phone phone = (Phone) o;
        return Objects.equals(number, phone.number);
    }

    @Override
    public int hashCode() {
        return Objects.hash(number);
    }

}
```

##### `@OneToOne`

联系方式表：

```java
@Entity(name = "Phone")
public class Phone {

    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY)
    private Long id;

    @Column(name = "number")
    private String number;

    @OneToOne
    @JoinColumn(name = "details_id")
    private PhoneDetails details;

}
```

联系方式详情表：

```java
@Entity(name = "PhoneDetails")
public class PhoneDetails {

    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY)
    private Long id;

    private String provider;

    private String technology;

}
```

##### `@ManyToMany`

用户表：

```java
@Entity(name = "Person")
public class Person {

    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY)
    private Long id;

    @NaturalId
    private String registrationNumber;

    @ManyToMany(cascade = {CascadeType.PERSIST, CascadeType.MERGE})
    private List<Address> addresses = new ArrayList<>();
    
    public void addAddress(Address address) {
        addresses.add(address);
        address.getOwners().add(this);
    }

    public void removeAddress(Address address) {
        addresses.remove(address);
        address.getOwners().remove(this);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        Person person = (Person) o;
        return Objects.equals(registrationNumber, person.registrationNumber);
    }

    @Override
    public int hashCode() {
        return Objects.hash(registrationNumber);
    }
    
}
```

地址表：

```java
@Entity(name = "Address")
public class Address {

    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY)
    private Long id;

    private String street;

    private String number;

    private String postalCode;

    @ManyToMany(mappedBy = "addresses")
    private List<Person> owners = new ArrayList<>();

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        Address address = (Address) o;
        return Objects.equals(street, address.street) &&
                Objects.equals(number, address.number) &&
                Objects.equals(postalCode, address.postalCode);
    }

    @Override
    public int hashCode() {
        return Objects.hash(street, number, postalCode);
    }

}
```

##### `@NotFound`

```java

```

##### `@Any`

```java

```

##### `@JoinFormula`

```java

```

##### `@JoinColumnOrFormula`

```java

```

##### 

### 参考资料

[官方文档](https://docs.jboss.org/hibernate/orm/6.2/userguide/html_single/Hibernate_User_Guide.html)
