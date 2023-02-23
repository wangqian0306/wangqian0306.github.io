---
title: Git 麻瓜操作
date: 2023-02-22 21:57:04
tags: "随笔"
id: self-git
no_word_count: true
no_toc: true
---

## Git 麻瓜操作

### 简介

不小心把本地文件推送到 Github 了，还好遇到好心人提醒。以此文铭记自己的麻瓜操作。

### 删除某次错误的提交

首先需要使用如下命令，定位到错误的 commit-id 和上一次正确的 commit-id:

```bash
git log
```

然后使用如下命令切换到正确的 commit-id ：

```bash
git rebase -i <correct_commit_id>
```

在新开的文本中应该可以看到之后的 commit log 清单，将错误的 commit 前的 `pick` 改为 `drop` 然后保存退出即可。

还可以使用如下命令强制推送到服务器：

```bash
git push origin HEAD --force
```

### 参考资料

[git删除某个提交commit记录](https://juejin.cn/post/6981769872338321416)
