---
layout: post
title:  "mac下全盘安全擦除数据的方法"
date: 2016-03-22 18:06:26 +0800
author : Mushen
categories: original
---

1.使用启动U盘重启电脑

2.确定磁盘名，使用磁盘工具或diskutil list命令,找到最大的一个盘，一般是disk0s2

3.启动命令行，卸载磁盘

```
umount disk0s2
```

4.安全擦除数据

擦除具体办法是执行dd命令向磁盘写入全零数据，覆盖数据三次即符合美国能源部关于安全抹掉磁性介质的标准。

注：设置bs参数的不同取值会极大的影响擦除速率。经过测试，bs=16384为擦除相对较快时的取值。

```
i=0
while (($i<3))
      do
            dd if=/dev/zero bs=16384 of=/dev/disk0s2
            i=$[i+1]
done
```
或者直接执行三次

```
dd if=/dev/zero bs=16384 of=/dev/disk0s2;dd if=/dev/zero bs=16384 of=/dev/disk0s2;dd if=/dev/zero bs=16384 of=/dev/disk0s2
```
* 注意，在擦除过程中，电脑不能黑屏

5.擦除后磁盘变成控盘，此时需要通过磁盘工具，使用抹掉功能格式化磁盘（默认磁盘名可设为Macintosh HD）。

6.安装操作系统
