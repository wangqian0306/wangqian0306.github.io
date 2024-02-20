---
title: Github Copilot 技巧梳理
date: 2023-04-11 22:26:13
tags:
- "Github Copilot"
- "AI"
id: copilot
no_word_count: true
no_toc: false
---

## Github Copilot 技巧梳理

### 简介

GitHub Copilot 是一款编码辅助工具。

### 小技巧

- 问答模式

```python
# q: How to write bubble sort?
# a: https://stackoverflow.com/questions/18262306/quicksort-with-python
```

- 根据函数名生成代码

```python
import time

def getUnixTimeStamp():
    return int(time.time())
```

- 生成测试用例

```python
import os


def get_file_content(filename):
    if not os.path.exists(filename):
        raise Exception("File does not exist: " + filename)
    with open(filename) as f:
        return f.read()


if __name__ == '__main__':
    # test get_file_content
    print(get_file_content("test.py"))
```

- 使用 JSON 生成类

```python
# create User class from json {"code": 200, "username":"test", "email":"123@asd.com", "date":"2022-04-17"}
class User:
    def __init__(self, code, username, email, date):
        self.code = code
        self.username = username
        self.email = email
        self.date = date

    def __repr__(self):
        return f"User(code={self.code}, username={self.username}, email={self.email}, date={self.date})"

    def __eq__(self, other):
        return self.code == other.code and self.username == other.username and self.email == other.email and self.date == other.date

    def __hash__(self):
        return hash((self.code, self.username, self.email, self.date))

    def to_dict(self):
        return {"code": self.code, "username": self.username, "email": self.email, "date": self.date}

    @staticmethod
    def from_dict(obj):
        assert isinstance(obj, dict)
        code = obj.get("code")
        username = obj.get("username")
        email = obj.get("email")
        date = obj.get("date")
        return User(code, username, email, date)

    def to_json(self):
        return json.dumps(self.to_dict(), indent=2)

    @staticmethod
    def from_json(json_str):
        return User.from_dict(json.loads(json_str))
```

- 使用建表语句生成代码

```python
# create User class from sql
# CREATE TABLE User( `id` INT UNSIGNED AUTO_INCREMENT KEY,`username` VARCHAR(20) NOT NULL UNIQUE, `password` CHAR(32) NOT NULL,`email` VARCHAR(50) NOT NULL) CHARSET=UTF8;
class User:
    def __init__(self, id, username, password, email):
        self.id = id
        self.username = username
        self.password = password
        self.email = email

    def __repr__(self):
        return '<User %r>' % self.username
```

### Copilot Chat

Copilot Chat 是 Copilot X 当中的一个子功能，类似于 ChatGPT。目前可以使用 VS Code 访问此功能。

### 参考资料

[官方文档](https://docs.github.com/en/copilot/getting-started-with-github-copilot)

[Github Copilot 使用技巧](https://www.jianshu.com/p/35359b1d0636)

[Using GitHub Copilot to Automate Tests](https://applitools.com/blog/using-github-copilot-to-automate-tests/)

[Github Copilot X](https://github.com/features/preview/copilot-x)
