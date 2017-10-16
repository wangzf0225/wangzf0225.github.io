---
layout: post
title:  "PHP webshell检测思路"
date: 2017-06-09 16:16:26 +0800
author: Invo
categories: original
---
# 1 基于inode的敏感文件发现方法

## inode是什么？

inode是指在许多“类Unix文件系统”中的一种数据结构。每个inode保存了文件系统中的一个文件系统对象（包括文件、目录、设备文件、socket、管道, 等等）的元信息数据，但不包括数据内容或者文件名。

 

## inotify 介绍

从文件管理器到安全工具，文件系统监控对于的许多程序来说都是必不可少的。从 Linux 2.6.13 内核开始，Linux 就推出了 inotify，允许监控程序打开一个独立文件描述符，并针对事件集监控一个或者多个文件，例如打开、关闭、移动/重命名、删除、创建或者改变属性。

 

## inotify工具

为了尽可能减少该工具对系统之外的资源的依赖，测试demo使用了inotify-tools作为目录的监听器。inotify-tools是RH发行版的一个inode事件监听工具，默认不安装，可以通过执行sudo yum install inotify-tools命令来安装，体积只有47k（Centos 6.8） 。demo使用ruby的popen函数实时获取inotifywait命令的输出，并对文件内容进行检测。

 

## 事件类型

1.如果文件属主不是momobot

2.非部署时间建立（黑客为了避人耳目经常选择非工作事件入侵）

3.不连续的inode号（正常部署的文件inode号通常是连续的）

4.文件长度过短（低于200个字符，正常业务代码文件通常至少几十行）

5.“单个”单词长度过长（正常的代码文件不会出现很多特别长的有0-9和a-Z组成的字符串，而不少木马为了躲避检测，加密后会变成超长的“单词”）

6.单个字符比例异常（正常的代码文件不同的字符分布遵循一定规律，单个字符通常不会超过20%，很多变形的木马使用符号很可能超过30%）

7.匹配到恶意的字符正则表达式

 
## 恶意字符串的正则表达式

就不告诉你……


# 基于php trace的php调用函数跟踪

待续，demo开发中

### 参考资料

                                     

* 大小马特征  http://www.freebuf.com/column/133753.html

* 一句话后门 http://www.freebuf.com/articles/web/9396.html

* php木马绕过检测方式 http://www.cnseay.com/1102/

* 统计特征识别webshell  http://www.freebuf.com/articles/4240.html

* php反射相关函数  http://php.net/manual/zh/book.reflection.php

 
