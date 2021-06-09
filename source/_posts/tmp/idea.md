---
title: IDEA 常用內容整理
date: 2020-06-06 21:41:32
tags: "JetBrains"
id: idea
no_word_count: true
no_toc: false
categories: JetBrains
---

## 快捷键

### 全局可用

|快捷键|说明|
|:---:|:---:|
|`ctrl`+`shift`+`f12`|全屏 Editor|
|`alt`+`home`|展开当前目录|
|`ctrl`+`t`|拉取代码(git)|
|`alt`+`~`|版本控制|
|`alt`+`1`|打开或者关闭 Project 选项卡|
|`shift`+`esc`|关闭小窗|
|双击`shift`|全局文件检索|
|`ctrl`+`e`|打开最近编辑的文件|
|`ctrl`+`n`|文件查找|
|`ctrl`+`w`|扩大选中区域|
|`ctrl`+`shift`+`f`|全局内容查找|
|`ctrl`+`shift`+`r`|全局内容替换|

### Project 部分

|快捷键|说明|
|:---:|:---:|
|`←`|关闭文件夹|
|`→`|打开单个文件夹|
|`*`|打开选中目录下的所有文件夹|
|`alt`+`←/→`|切换视图种类|
|`alt`+`insert`|在选中目录下新建文件或者文件夹|

### Editor 部分

|快捷键|说明|
|:---:|:---:|
|`ctrl`+`tab`|切换已打开的文件|
|`alt`+`←/→`|切换编辑器内的文件|
|`alt`+`↑/↓`|跳转至下一个方法/目录|
|`ctrl`+`f12`|展示文件结构|
|`ctrl`+`h`|显示类结构图|
|`ctrl`+`+`|展开代码|
|`ctrl`+`-`|折叠代码|
|`ctrl`+`shift`+`+`|展开全部代码|
|`ctrl`+`shift`+`-`|折叠全部代码|
|`ctrl`+`[`|移动至括号开始位置|
|`ctrl`+`]`|移动至括号结束位置|
|`ctrl`+`f1`|错误提示说明|
|`f2`|跳转至下一处错误或者警告|
|`shift`+`f2`|跳转至上一处警告|
|`ctrl`+`f3`|跳转至选中元素的下一处引用|
|`alt`+`insert`|快速生成|
|`ctrl`+`shift`+`space`|信息提示|
|`alt`+`enter`|自动修复/提示|
|`ctrl`+`p`|提示方法参数|
|`ctrl`+`alt`+`←/→`|最近编辑位置跳转|
|`ctrl`+`f`|文件内搜索|
|`ctrl`+`r`|文件内替换|
|`ctrl`+`b`|查看类/接口/方法的调用|
|`ctrl`+`alt`+`b`|查看实现方法|
|`ctrl`+`q`|查看文档|
|`ctrl`+`shift`+`i`|查看方法或者类的定义|
|`shift`+`↑/↓`|选择行|
|`ctrl`+`/`|单行注释|
|`ctrl`+`d`|复制行|
|`ctrl`+`x`|删除行|
|`ctrl`+`shift`+`/`|多行注释|
|`alt`+`shift`+`↑/↓`|调整代码位置|
|`ctrl`+`shift`+`↑/↓`|调整方法位置|
|`ctrl`+`alt`+`i`|格式化缩进|
|`ctrl`+`alt`+`o`|格式化引入|
|`ctrl`+`alt`+`l`|格式化代码|
|`ctrl`+`shift`+`t`|生成/跳转至测试类|
|`ctrl`+`f4`|关闭当前编辑文件|

### 终端部分

|快捷键|说明|
|:---:|:---:|
|`alt`+`f12`|切换至终端|

### TODO 部分

|快捷键|说明|
|:---:|:---:|
|`alt`+`6`|切换至 TODO 窗口|

### 调试与运行

|缩写|说明|
|:---:|:---:|
|双击`ctrl`|运行命令或者程序|
|`ctrl`+`f9`|编译项目|
|`ctrl`+`shift`+`f9`|以 Debug 模式运行 Editor 当前打开的代码|
|`ctrl`+`shift`+`f10`|运行 Editor 当前打开的代码|
|`shift`+`f9`|以 Debug 模式运行项目(目前的 debug/run configuration)|
|`shift`+`f10`|运行项目(目前的 debug/run configuration)|
|`ctrl`+`f5`|重新启动程序|
|`ctrl`+`f2`|终止程序运行|
|`alt`+`f10`|显示断点|
|`f8`|进入下一步|
|`f9`|进入代码|

### 代码缩写

|缩写|说明|
|:---:|:---:|
|`psvm`|public static void main|
|`psf`|public static final|
|`prsf`|private static final|
|`sout`|System.out.println|
|`serr`|System.err.println|

## 常见问题

### 在 Linux 环境中无法输入中文

- 点击菜单 `Help | Edit Custom VM options...`
- 添加如下内容
```text
-Drecreate.x11.input.method=true 
```
- 重启IDEA
