---
layout: post
title:  "查看互联网出口IP地址"
date: 2017-03-31 10:56:26 +0800
author : Mushen
categories: note
---

1.
```
$ curl ifconfig.co
60.205.210.137
```
2.
```
$ curl ifconfig.me
60.205.210.137
```
3.这个最快
```
$ dig +short myip.opendns.com @208.67.222.222 @208.67.220.220 
60.205.210.137
```

4.
```
$ curl ns1.dnspod.net:6666
60.205.210.137
```

5.
```
$ curl http://ipecho.net/plain
60.205.210.137
```
6.
```
$ curl ip.cn
^C
[toor@ali-case ~]$ curl ipinfo.io
{
  "ip": "60.205.210.137",
  "hostname": "No Hostname",
  "city": "Hangzhou",
  "region": "Zhejiang",
  "country": "CN",
  "loc": "30.2936,120.1614",
  "org": "AS37963 Hangzhou Alibaba Advertising Co.,Ltd."
}
```
