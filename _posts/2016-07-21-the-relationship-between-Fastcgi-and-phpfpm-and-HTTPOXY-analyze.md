---
layout: post
title:  "HTTPOXY漏洞分析及Fastcgi与phpfpm之间的关系"
date: 2016-07-21 17:46:26 +0800
categories: original
---
落笔前两三天红帽官网报出一个http协议实现的漏洞，影响到绝大部分主流的cgi模式的http server端程序。简单的说，在http header中设置一个"proxy: 1.2.3.4"这样的请求头，就可以控制cgi模式下的环境变量HTTP_PROXY。

然而，由于对cgi模式不了解，对php的运行的原理也不熟悉，直到按照文档的说明排查了公司代码，都对这个漏洞处于半懵逼状态。今天有空把鸟哥的文章研究了一下，顺便把cgi也搞懂了，简单留个笔记。

首先，祭出鸟哥的文章：

 
[HTTPOXY漏洞说明]: http://www.laruence.com/2016/07/19/3101.html

[HTTPOXY漏洞说明] 

在这篇文章中，鸟哥解释了为什么会在协议实现的过程中留下这类问题。当然，是否属实都只是猜测，无法证实。

为了测试，我部署了一个php环境，并写了测试代码，用nginx假设了正向代理：


{% highlight php%}
<?php

var_dump(getenv("HTTP_PROXY"));

?>
{% endhighlight %}
 

 

对于鸟哥给出的例子，我不理解。因为在部署了测试代码以后，我发现当我执行了一下命令以后，无法用getenv("HTTP_PROXY")在服务器端获取到http_proxy这个变量的值。

```
http_proxy=127.0.0.1:8088 wget http://localhost/ff.php
```

 

而，当我使用curl命令，并在请求头部加上proxy字段的时候，就能获取。这是必须的。

 

```
curl -x 127.0.0.1:8088 http://localhost/ff.php -H 'proxy: test string'
```

这里使用代理，是为了在懵逼状态下测试getenv函数取到的代理地址是否是我使用的代理地址。（实际上在测试中我使用了私网地址。）

于是我发现，只有http header中的proxy字段可以影响getenv这个函数获取的变量，其他，无论wget命令前进行的环境变量设置，还是使用http代理匀不会产生影响。

 

那么wget命令前设置的环境变量，和getenv取得的环境变量，究竟是什么？

 

为了验证这个问题，我对wget发出的请求进行了抓包（sudo tcpdump -A  -i lo），抓包发现，wget设置的变量（如我猜测）是真实的代理，这个请求首先通过连接到代理服务器（端口）的socket连接发给代理服务器，然后再转发给服务器。那么这个设置就是本地的代理环境变量。

 

于是，百思不得其解。

 

突然，一个念头蹦出来，是不是getenv获取到的变量，也像wget使用的这个变量。好吧，如果你已经猜到了结果，那么确实是这样的。

我们还是来验证一下。还是使用刚才那段php代码（server端的），然后执行命令：

```
[root@vm-bl001.vm.momo.com html]# HTTP_PROXY='1231412' php ff.php

string(7) "1231412"

```

果然是这样。有些文档称造成这个漏洞的原因是命名空间冲突。其实除了这个原因，cgi对proxy这个字符串做过处理，是造成这个问题的最主要原因。如果开发同学本来想使用系统的环境变量来为自己的代码设置http请求代理，那么攻击者就有可能利用这里的逻辑去劫持和篡改请求。至于为什么不在代码中设置环境变量，我只能说研发同学的心思实在摸不透……

 

另附sg上关于cgi的说明一篇，终于讲明白了。

 

[搞不清FastCgi与PHP-fpm之间是个什么样的关系]:https://segmentfault.com/q/1010000000256516

FROM:[搞不清FastCgi与PHP-fpm之间是个什么样的关系]
