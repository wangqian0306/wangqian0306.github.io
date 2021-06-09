---
title: 工厂模式
date: 2020-06-27 20:32:58
tags: "JAVA"
id: design-pattern-factory
no_word_count: true
no_toc: false
categories: JAVA
---

### 简单工厂模式

```java
abstract class Pizza {
    public abstract void prepare();
}

class CheesePizza extends Pizza {
    
    @Override
    public void prepare() {
        System.out.println("prepare cheese pizza");
    }
}

class GreekPizza extends Pizza {
    
    @Override
    public void prepare() {
        System.out.println("prepare greek pizza");
    }
}

public class PizzaFactory {
    
    public static Pizza createPizza(String orderType) {
        switch (orderType) {
            case "cheese":
                return new CheesePizza();
            case "greek":
                return new GreekPizza();
            default:
                System.out.println("no such type");
                return null;
        }
    }
}
```


### 工厂方法模式

```java
abstract class Pizza {
    public abstract void prepare();
}

class BJCheesePizza extends Pizza {
    
    @Override
    public void prepare() {
        System.out.println("prepare bj cheese pizza");
    }
}

class BJGreekPizza extends Pizza {
    
    @Override
    public void prepare() {
        System.out.println("prepare bj greek pizza");
    }
}

class LDCheesePizza extends Pizza {
    
    @Override
    public void prepare() {
        System.out.println("prepare ld cheese pizza");
    }
}

class LDGreekPizza extends Pizza {
    
    @Override
    public void prepare() {
        System.out.println("prepare ld greek pizza");
    }
}

abstract class OrderPizza {
    
    public abstract Pizza makePizza(String type);
}

class BJOrderPizza extends OrderPizza {
    
    @Override
    public Pizza makePizza(String type) {
        switch (type) {
            case "cheese":
                return new BJCheesePizza();
            case "greek":
                return new BJGreekPizza();
            default:
                System.out.println("no such type");
                return null;
        }
    }
}

class LDOrderPizza extends OrderPizza {
    
    @Override
    public Pizza makePizza(String type) {
        switch (type) {
            case "cheese":
                return new LDCheesePizza();
            case "greek":
                return new LDGreekPizza();
            default:
                System.out.println("no such type");
                return null;
        }
    }
}
```

### 抽象工厂模式

```java
interface Shape {
    void draw();
}

class Rectangle implements Shape {

    @Override
    public void draw() {
        System.out.println("Inside Rectangle::draw() method.");
    }
}

class Circle implements Shape {

    @Override
    public void draw() {
        System.out.println("Inside Circle::draw() method.");
    }
}

interface Color {
    void fill();
}

class Red implements Color {

    @Override
    public void fill() {
        System.out.println("Inside Red::fill() method.");
    }
}

class Blue implements Color {

    @Override
    public void fill() {
        System.out.println("Inside Blue::fill() method.");
    }
}

abstract class AbstractFactory {
    public abstract Color getColor(String color);
    public abstract Shape getShape(String shape) ;
}

class ShapeFactory extends AbstractFactory {

    @Override
    public Shape getShape(String shapeType){
        if(shapeType == null){
            return null;
        }
        if(shapeType.equalsIgnoreCase("CIRCLE")){
            return new Circle();
        } else if(shapeType.equalsIgnoreCase("RECTANGLE")){
            return new Rectangle();
        }
        return null;
    }

    @Override
    public Color getColor(String color) {
        return null;
    }
}

class ColorFactory extends AbstractFactory {

    @Override
    public Shape getShape(String shapeType){
        return null;
    }

    @Override
    public Color getColor(String color) {
        if(color == null){
            return null;
        }
        if(color.equalsIgnoreCase("RED")){
            return new Red();
        } else if(color.equalsIgnoreCase("BLUE")){
            return new Blue();
        }
        return null;
    }
}

class FactoryProducer {
    
    public static AbstractFactory getFactory(String choice){
        if(choice.equalsIgnoreCase("SHAPE")){
            return new ShapeFactory();
        } else if(choice.equalsIgnoreCase("COLOR")){
            return new ColorFactory();
        }
        return null;
    }
}

public class AbstractFactoryDemo {
    
    public static void main(String[] args) {
        AbstractFactory shapeFactory = FactoryProducer.getFactory("SHAPE");
        Shape shape = shapeFactory.getShape("CIRCLE");
        shape.draw();
        AbstractFactory colorFactory = FactoryProducer.getFactory("COLOR");
        Color color = colorFactory.getColor("RED");
        color.fill();
    }
}
```
