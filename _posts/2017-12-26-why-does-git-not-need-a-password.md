---
layout: post
title:  "为什么git push不用密码"
date: 2017-12-26 18:51:26 +0800
author : Invo
categories: original
---

好久没写东西，马上就要结束的2017，也是我来阿里一个月的时间，这边工作的节奏还是非常紧凑的，我都差点忘了还有这个博客。今天使用git的时候发现一个问题，决定用这个主题来水一篇。

事情的过程是这样的，在公司发的新mac上，打算给自己的博客修改一个东西，于是使用git clone命令把仓库下载到本地。在修改完成后，通过git add、git commit直到git push，但是发现提交不上去。上网查了下，配置了user.name和user.email，再次push，成功。

然而我突然意识到，终端并没有提示让我输入用户名和密码。过去在电脑中是使用ssh的方式连接github，而这次使用了一台新电脑，从来没有配置过ssh-key，也没有在git中配置过github的用户名和密码。后来我在我的虚拟机中用同样的方式提交git，发现kali下面则是必须要输入用户名和密码的，这让我很奇怪。后来在知乎上搜到一篇帖子，作者说是因为操作系统的钥匙链的原因，具体原理没有详细解释。顺着这个关键词，我搜索了钥匙链、git，没有结果，尝试google搜索key chain、git，发现果然是这个原因。具体可以看这篇文章[Caching your GitHub password in Git](https://help.github.com/articles/caching-your-github-password-in-git/)。文中提到：
```
If you're running Mac OS X 10.7 and above and you installed Git through Apple's Xcode Command Line Tools, then osxkeychain helper is automatically included in your Git installation.
```
刚好符合我的情况：在第一次使用git的时候，操作系统提示安装Xcode，顺理成章地在安装以后就添加了密码缓存。