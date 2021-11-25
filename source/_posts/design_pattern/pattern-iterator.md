---
title: 迭代器模式
date: 2021-07-22 20:32:58
tags: "JAVA"
id: design-iterator-pattern
no_word_count: true
no_toc: false
categories: 设计模式
---

```java
interface Iterator {
    boolean hasNext();

    Object next();
}

interface Container {
    Iterator getIterator();
}

class NameRepository implements Container {
    public String[] names = {"Robert", "John", "Julie", "Lora"};

    @Override
    public Iterator getIterator() {
        return new NameIterator();
    }

    private class NameIterator implements Iterator {

        int index;

        @Override
        public boolean hasNext() {
            return index < names.length;
        }

        @Override
        public Object next() {
            if (this.hasNext()) {
                return names[index++];
            }
            return null;
        }
    }
}

public class IteratorPatternDemo {
    public static void main(String[] args) {
        NameRepository namesRepository = new NameRepository();
        for (Iterator iter = namesRepository.getIterator(); iter.hasNext(); ) {
            String name = (String) iter.next();
            System.out.println("Name : " + name);
        }
    }
}
```
