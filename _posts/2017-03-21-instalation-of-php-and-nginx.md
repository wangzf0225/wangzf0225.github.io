---
layout: post
title:  "nginx+php+php-fpm安装手札"
date: 2017-03-21 17:06:26 +0800
author : Invo
categories: origin
---
十年九不遇装一次php，以前装过隔很久以后就会忘了操作，担心下次再忘，做下要点笔记。

1.php及nginx安装

```
rpm -Uvh http://mirror.webtatic.com/yum/el6/latest.rpm

#确认webstatic是否安装
rpm -qa | grep webstatic 

#或者php其他版本，比如：yum install php56w
yum install php70w.x86_64 

#测试安装结果
php -v 

yum install php70w-fpm

#测试安装结果
php-fpm -v 

```
nginx的安装就不说了

2.php-fpm的启动

php-fpm默认启动就可以，可以参考https://segmentfault.com/a/1190000003067656
启动成功后看下9000端口是否on

```
netstat -ant|grep :9000
```

3.nginx配置和启动

找到nginx.conf.default这个默认配置文件的备份，复制一份出来转成一个单独的配置文件。
关于php的部分的配置,需要先把一下部分的注释去掉，保存退出。

```
        location ~ \.php$ {
        #    root           html;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
```
使用以下命令启动nginx
```
nginx -c /usr/share/nginx/test.conf

```
如果nginx启动起来，可以用-s reload参数在不重启的情况下载入配置文件。

*注意，配置文件的'fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;'要改成'fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;'，不然访问网页会提示找不到文件（404错误）



