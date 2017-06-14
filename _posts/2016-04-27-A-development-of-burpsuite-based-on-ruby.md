---
layout: post
title:  "基于Ruby的Burpsuite插件开发"
date: 2016-04-27 14:30:26 +0800
categories: original
---

# 0x00 前言

BurpSuite是久负盛名的web应用安全测试工具，在安全圈子中被誉为“神器”。它的核心功能是http代理，并在此基础上提供了丰富的自定义配置选项，协助使用者设计不同的方案进行渗透或者安全监测。此外，除了工具本身提供的功能以外，burpsuite神器提供了一组java编写的应用接口，通过java或基于java的Jython、Jruby，可以实现许多自定义的功能插件。在工作中，笔者尝试使用Ruby进行BurpSuite Extention的插件开发，这个过程有一些坑需要同特定的方式解决，希望能和大家分享这点经验。在这里，不针对具体业务，不讨论编程语言优劣，只希望能够丰富这个生态系统，让Burp的爱好者们多一种选择。

# 0x01开发环境

1 软件配置

```
Macbook pro OSX 10.10.5
Burpsuite free edit 1.6.03
Jruby 1.7.19
rvm 1.26.10
gem 2.0.14
```

2 安装

在Unix/Linux环境下安装Ruby编程语言，很可能会遇到多个版本共存的情况。RVM（Ruby Version Manager）这个小工具很好的解决了这个问题，使用这个工具可以方便的安装和管理操作系统上复杂的Ruby版本，强烈推荐新手使用。

## 2.1 安装RVM

RVM的安装步骤非常简单，通过使用curl命令下载一个脚本，同时使用‘bash -s’执行，最后重新载入profile文件即可。官方的安装说明：https://rvm.io/rvm/install

```
$ curl -sSL https://get.rvm.io|bash -s
```

正确安装后会有如下提示

```
In case of problems: http://rvm.io/help and https://twitter.com/rvm_io

  * WARNING: You have '~/.profile' file, you might want to load it,
    to do that add the following line to '/home/wang.zhaofeng/.bash_profile':

      source ~/.profile
```

此时在命令行下执行

```
$ source ~/.profile 
```

执行如下命令测试安装是否成功，如果显示版本说明，则安装成功。

```
$ rvm -v
```

## 2.2 安装Jruby

Burpsuite使用Java开发，因此无论使用python还是ruby进行插件开发，都必须有java实现的解释器（即Jython和Jruby）。

安装jruby并创建针对burpsuite的环境变量。

```
$ rvm install jruby
$ rvm --ruby-version use jruby@burp --create
```

执行‘rvm list’ 查看是否安装成功。

```
$ rvm list
```

当看到如下显示说明安装成功。

```
rvm rubies

=> jruby-1.7.19 [ x86_64 ]

# Default ruby not set. Try 'rvm alias create default <ruby>'.

# => - current
# =* - current && default
#  * - default
```

为了稳定和向下兼容，我使用了比较陈旧的1.7版，经测试，最新的9.x版也是没有问题的。（不知道这个版本是怎么命名的。）

### 2.3 BurpSuite插件环境配置

软件安装成功后，你可以在个人目录的.rvm/rubies/jruby-1.7.19目录下找到你的Jruby目录，在这个目录下，会有一个Jruby.jar的文件，记住它的位置。

如果不能手动找到，可以尝试执行以下命令：

```
$ rvm env|grep MY_RUBY_HOME
```

MY_RUBY_HOME将作为这个jar文件路径的环境变量名。

```
export MY_RUBY_HOME='/Users/myname/.rvm/rubies/jruby-1.7.19'
```

单引号中的路径，就是jruby.jar的存放路径。

执行以下命令

```
rvm use jruby
```

让jruby变成当前的操作环境，就可以找到对应的环境变量。

* 下面是非常重要的一步! *

* 下面是非常重要的一步! *

* 下面是非常重要的一步! *

打开命令行，输入以下命令：

```
JRUBY_HOME=/Users/myname/.rvm/rubies/jruby-1.7.19 java -XX:MaxPermSize=1G -Xmx1g -Xms1g -jar YOUR_BURP_PATH/burpsuite_free_v1.6.xx.jar
```

通过命令行启动BurpSuite，而不是双击图标，这一步非常重要，否则在代码中require库文件，就会出现无法加载库文件的情况。

打开Burp，在Extender-->Options选项卡最下方的Ruby Environment部门导入你的Jruby.jar文件，没如果没有报错，则说说明加载成功。

![a_development_of_burpsuite_based_on_ruby_01.jpg](/assset/img/cc710e80636d254de260ea125125547e187e2d8e.jpg)

## 2.4 测试

Burpsuite官方网站提供了一个测试文件（点这里下载）

解压缩后可以在名为ruby的目录下面看到一个HelloWorld.rb文件，这个就是要载入的插件代码。

点击Extentders标签下的Extention选项卡，在上半部分左侧点击“Add"
