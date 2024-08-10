---
title: Chrome 启动主页被拦截
date: 2024-08-10 20:41:32
tags:
- "Windows"
id: chrome-homepage
no_word_count: true
no_toc: false
categories: Windows
---

## Chrome 启动主页被拦截

### 简介

今天突然发现打开 Chrome 后自动访问了广告页面，先对此问题进行记录。

### 解决方式

按下 `win` + `R` 打开运行工具，然后输入下面的内容进入注册表编辑器

```text
regedit
```

然后检索如下位置：

```text
HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
```

之后就可以在注册表中看到如下项目：

```text
<user> cmd.exe /c start http://xxx.xxx.xxx
```

删除完成后还需要重新打开运行工具，然后输入下面的内容进入任务计划程序：

```text
taskschd.msc
```

在计划程序中也会出现自己用户名对应的内容，将其删除即可。

### 参考资料

[开机cmd窗口自动打开dinoklafbzor的解决方法](https://blog.csdn.net/hfhbutn/article/details/124913211)

[(Solved) How to Remove dinoklafbzor.org Virus Pop-up?](https://easysolvemalware.com/solved-how-to-remove-dinoklafbzor-org-virus-pop-up/)
