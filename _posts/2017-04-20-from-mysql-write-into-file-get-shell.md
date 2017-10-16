---
layout: post
title:  "通过mysql写入文件功能获取mysql server ssh登录Linux"
date: 2017-04-20 17:06:26 +0800
author : Invo
categories: original
---

在利用redis未授权访问的漏洞中，可以利用redis将用户的authorized_key覆盖，写上自己生成的公钥。在mysql中，同样有机会利用类似的思路得到shell。

要点：

1.思路：通过mysql将生成的公钥写入服务器mysql启动用户的.ssh/authorized_keys文件，然后用对应的私钥登录服务器。

2.条件：

+ a 服务器用一个实体账号启动mysql，在passwd中可以看到这个用户的shell是bash或者其他，不是false或者nologin

+ b 要满足mysql可以写入这个大前提。如果是通过select * from table_name into outfile '/tmp/filename';这样的语句来执行写入，那么首先在该账户的home目录下一定要存在.ssh目录；目录中没有authorized_keys文件，如果已经存在这个文件，那么mysql是无法追加写入或者覆盖掉的。

+ c 如果被攻击的victim server使用的是比较低版本的openssl（网上的说法是第二版，但是实测当中有些第二版并不能成功），那么可以尝试写入authorized_keys2，有一定几率成功

+ d 参数secure-file-priv=""，同时关闭seLinux模块，可以说条件还是蛮苛刻的


站在现实的角度上考虑，要达成上述所有条件并不容易，而且如果管理员松懈成这个样子，那么他的server通过其他方式被入侵的可能性应该更大。在研究mysql向操作系统写入文件的过程中，发现了另一种办法：pager。如果mysql的版本允许pager，--no-pager配置为false，那么可以通过再mysql的命令行执行以下命令将公钥写入authorized_keys文件。

```
pager cat|grepo -o ssh.*[^|]>> /home/mysql/.ssh/authorized_keysl;
```

看到这个文章让我觉得自己发现了新大陆。然而在实际测试的过程中发现并不顺利。

例如：

```
PAGER set to 'cat |grep -o ssh.* >> /home/mysqldb/.ssh/authorized_keys'
mysql> select * from table_name;
sh: /home/mysqldb/.ssh/authorized_keys: 没有那个文件或目录
1 row in set (0.00 sec)
```

明明文件是存在的，但是始终提示没有那个文件或目录。突然小伙伴的一句话提醒了我，是不是pager没有在mysql的server端执行，我赶紧看了下本地的文件，确实没有authorized_kys这个文件。这时我才恍然大悟，原来pager命令只能在client端执行，同时转念一想，如果在服务器端能任意的执行命令（pager是一个在mysql的终端执行shell命令的命令），那么入侵的方式就不可计数了吧。

于是，花了很长时间从一个坑里爬上来。验证了一个错误，恐怕才是这篇博客最大的用处吧。
