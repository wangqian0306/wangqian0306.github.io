---
title: 代理模式
date: 2020-07-09 22:10:58
tags: "JAVA"
id: design-pattern-proxy
no_word_count: true
no_toc: false
categories: JAVA
---

## 静态代理

```java
interface Image {
   void display();
}

class RealImage implements Image {
 
   private String fileName;
 
   public RealImage(String fileName){
      this.fileName = fileName;
      loadFromDisk(fileName);
   }
 
   @Override
   public void display() {
      System.out.println("Displaying " + fileName);
   }
 
   private void loadFromDisk(String fileName){
      System.out.println("Loading " + fileName);
   }
}

class ProxyImage implements Image{
 
   private RealImage realImage;
   private String fileName;
 
   public ProxyImage(String fileName){
      this.fileName = fileName;
   }
 
   @Override
   public void display() {
      if(realImage == null){
         realImage = new RealImage(fileName);
      }
      realImage.display();
   }
}

public class ProxyPatternDemo {
   
   public static void main(String[] args) {
      Image image = new ProxyImage("test_10mb.jpg");
      image.display();
   }
}
```

## JDK 动态代理

```java
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

interface Image {
    void display();
}

class RealImage implements Image {

    @Override
    public void display() {
        System.out.println("Displaying RealImage");
    }
}

class InvocationHandlerImpl implements InvocationHandler {

    private final Object subject;

    public InvocationHandlerImpl(Object subject) {
        this.subject = subject;
    }

    @Override
    public Object invoke(Object o, Method method, Object[] objects) throws Throwable {
        System.out.println("调用前");
        Object returnValue = method.invoke(subject, objects);
        System.out.println("调用后");
        return returnValue;
    }
}

public class ProxyPatternDemo {
    public static void main(String[] args) {
        InvocationHandlerImpl handlerImpl = new InvocationHandlerImpl(new RealImage());
        Image image = (Image) Proxy.newProxyInstance(Image.class.getClassLoader(), new Class[]{Image.class}, handlerImpl);
        image.display();
    }
}
```

## CGLIB 动态代理

可以通过如下 maven 样例引入 cglib jar:

```xml
<dependency>
    <groupId>cglib</groupId>
    <artifactId>cglib</artifactId>
    <version>3.3.0</version>
</dependency>
```

样例代码如下：

```java
import net.sf.cglib.proxy.Enhancer;
import net.sf.cglib.proxy.MethodInterceptor;
import net.sf.cglib.proxy.MethodProxy;

import java.lang.reflect.Method;

class RealImage {

    public void display() {
        System.out.println("Displaying RealImage");
    }
}

class MethodInterceptorImpl implements MethodInterceptor {

    @Override
    public Object intercept(Object obj, Method method, Object[] args, MethodProxy proxy) throws Throwable {
        System.out.println("调用前");
        Object object = proxy.invokeSuper(obj, args);
        System.out.println("调用后");
        return object;
    }
}

public class ProxyPatternDemo {
    public static void main(String[] args) {
        Enhancer enhancer = new Enhancer();
        enhancer.setClassLoader(RealImage.class.getClassLoader());
        enhancer.setSuperclass(RealImage.class);
        enhancer.setCallback(new MethodInterceptorImpl());
        RealImage image = (RealImage) enhancer.create();
        image.display();
    }
}
```