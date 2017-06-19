---
layout: post
title:  "PAM要点笔记"
date: 2016-08-10 19:06:26 +0800
categories: note
---
PAM是类Unix系统中使用的一个用于用户身份认证的模块。最早的操作系统只能满足用户登录的需要，但是对于很多程序和进程，要单独在程序中编写关于身份认证的代码。这就使得程序非常臃肿和复杂。为了解决这个问题，solaris公司开发了Pluggable Authentication Module--PAM，通过独立的认证模块和可调用的API接口来解决这个问题。下面引用一张图片。

![note-about-pam-01.png](/assets/img/note-about-pam-01.png)

PAM 的API起着承上启下的作用，它是应用程序和认证鉴别模块之间联系的纽带和桥梁：当应用程序调用PAM API 时，应用接口层按照PAM配置文件的定义来加载相应的认证鉴别模块。然后把请求（即从应用程序那里得到的参数）传递给底层的认证鉴别模块，这时认证鉴别模块就可以根据要求执行具体的认证鉴别操作了。当认证鉴别模块执行完相应的操作后，再将结果返回给应用接口层，然后由接口层根据配置的具体情况将来自认证鉴别模块的应答返回给应用程序。

PAM配置文件的解读

![http://www.infoq.com/cn/articles/linux-pam-one](http://www.infoq.com/cn/articles/linux-pam-one)

PAM各种详细使用案例

![http://www.infoq.com/cn/articles/linux-pam-two](http://www.infoq.com/cn/articles/linux-pam-one)
