---
title: TypeScript
date: 2023-11-09 21:41:32
tags:
- "nodejs"
- "TypeScript"
id: typescript
no_word_count: true
no_toc: false
categories: 前端
---

## TypeScript

### 简介

TypeScript 是由微软进行开发和维护的一种开源的编程语言。 TypeScript 是 JavaScript 的严格语法超集，提供了可选的静态类型检查。

### 基本写法

#### 读取特定 key 

```typescript
const myObject = {
    a: 'apple',
    b: 'banana',
    c: 'cherry'
};

function getValueFromKey(key: string): string | null {
    if (key in myObject) {
        const value = myObject[<keyof typeof myObject>key];
        console.log(value);
        return value;
    } else {
        console.log("Key not found");
        return null;
    }
}

console.log(getValueFromKey('a')); // Output: 'apple'
console.log(getValueFromKey('b')); // Output: 'banana'
console.log(getValueFromKey('c')); // Output: 'cherry'
console.log(getValueFromKey('d')); // Output: "Key not found"
```

### 参考资料

[维基百科](https://zh.wikipedia.org/wiki/TypeScript)

[官方项目](https://github.com/microsoft/TypeScript)

[官方文档](https://www.typescriptlang.org/)
