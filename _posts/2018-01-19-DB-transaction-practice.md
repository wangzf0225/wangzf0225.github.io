---
layout: post
title:  "数据库事务实验"
date: 2018-01-19 11:06:26 +0800
author : Mushen
categories: original
---

几周前研究生班数据库老师布置了一道作业题：通过写事务理解DBMS的事务的概念、并发控制机制、数据恢复机制等，可基于当前主流的DBMS产品（SQL Server 2005/2008，Oracle，DB2，MySQL等均可）。

以前学习数据库，只接触过最简单的一些查询和写入，没有深入研究过其他高级特效（其实可能也不算很高级）。这次为了完成这次作业，做了一些实验和测试，发现还是挺有意思的。这里把实验报告贴出来，权当做个记录，希望大家指正。

以下两段文字为引用，解释了数据库事务的概念。

> 一个数据库事务通常包含对数据库进行读或写的一个操作序列。它的存在包含有以下两个目的： 
> 1. 为数据库操作提供了一个从失败中恢复到正常状态的方法，同时提供了数据库即使在异常状态下仍能保持一致性的方法。 
> 2. 当多个应用程序在并发访问数据库时，可以在这些应用程序之间提供一个隔离方法，以防止彼此的操作互相干扰。 
> 
> 当一个事务被提交给了DBMS（数据库管理系统），则DBMS需要确保该事务中的所有操作都成功完成且其结果被永久保存在数据库中，如果事务中有的操作没有成功完成，则事务中的所有操作都需要被回滚，回到事务执行前的状态（要么全执行，要么全都不执行）;同时，该事务对数据库或者其他事务的执行无影响，所有的事务都好像在独立的运行。


实验代码如下，实现的一个功能是从id为1的账户向id为2的账户转账1000元，数据库操作过程通过数据库事务实现。(代码来源于网络，有改动。)

{% highlight php %}
/*php+Mysqli利用事务处理转账问题实例
 * version 1
 */
header("Content-type:text/html; charset=utf-8");

$mysqli = new mysqli("localhost", "root", "", "test");
$mysqli->set_charset("utf8");

if($mysqli->connect_errno) {
	die('数据库连接失败'.$mysqli->connect_error);
}

$mysqli->autocommit(false); //自动提交模式设为false 
$flag = true; //事务是否成功执行的标志 

$query = "update account set balance=balance-1000 where id=1";
$result = $mysqli->query($query);
$affected_count = $mysqli->affected_rows;
if(!result || $affected_count == 0) {  //失败 
	$flag = false;
}

#锚定1
#$query = "select balance from account where id=1";
#$result = $mysqli->query($query);
#while ($row = mysqli_fetch_row($result)) {
#      var_dump($row[0]);
#}

#锚定2
#var_dump($flag);

$query = "update account set balance=balance+1000 where id=2";
$result = $mysqli->query($query);
$affected_count = $mysqli->affected_rows;
if(!$result || $affected_count == 0) {
	$flag = false;
}

#锚定3
#var_dump($flag);

if($flag) {
	$mysqli->commit();
	echo '转账成功';
} else {
	$mysqli->rollback();
	echo '转账失败';
}

$mysqli->autocommit(true); //重新设置事务为自动提交 
$mysqli->close();
>

{% endhighlight %}

基础数据如下：

```
MariaDB [test]> select * from account;
+----+------+---------+------+
| id | name | balance | flag |
+----+------+---------+------+
|  1 | Tom  | 3000.00 | NULL |
|  2 | Bob  | 2000.00 | NULL |
+----+------+---------+------+
2 rows in set (0.00 sec)

```

### 第一步，正常情况
执行以上代码，就可以完成一次转账。
[toor@vm-centos001 ~]$ php DBTransaction.php 
转账成功
查看数据库，看到Tom的账上少了1000块，而Bob的账上多了1000块。
```
MariaDB [test]> select * from account;
+----+------+---------+------+
| id | name | balance | flag |
+----+------+---------+------+
|  1 | Tom  | 2000.00 | NULL |
|  2 | Bob  | 3000.00 | NULL |
+----+------+---------+------+
2 rows in set (0.00 sec)

```

### 第二步，验证数据恢复机制。

强制操作出错，验证数据库事务操作的数据恢复功能。 
修改代码，将第2条sql语句的id改为200，这样第一条sql可以执行，而第二条会出错。如果没有事务的场景下，Tom的账户会被扣掉1000。
我们在锚定点1加入查询Tom账户余额的代码，在锚定点2和3观测sql语句执行的结果。
```
[toor@vm-centos001 ~]$ php DBTransaction.php 
string(7) "1000.00"
bool(true)
bool(false)
转账失败
```
从上图看出第一条语句执行成功，第二天执行失败。从代码中的查询语句看，Tom的账户被扣掉1000，只剩下1000.
然而查看数据库的值，发现数据是正常的，数据被恢复。
```
MariaDB [test]> select * from account;
+----+------+---------+------+
| id | name | balance | flag |
+----+------+---------+------+
|  1 | Tom  | 2000.00 | NULL |
|  2 | Bob  | 3000.00 | NULL |
+----+------+---------+------+
2 rows in set (0.00 sec)

```
### 第三步，验证并发控制机制。

将第二条sql语句的id改回2，在锚定点2后面加入一句sleep(1000);强行制造并发的情况。
执行php代码，进入等待。
````
[toor@vm-centos001 ~]$ php DBTransaction.php 
string(7) "3000.00"
```

此时操作数据库，发现被阻塞。经过一段时间后，出现等待超时的提示，说明并发操作被隔离，证明数据得到保护。
```
MariaDB [test]> update account set balance=balance+1 where id = 1;
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction

```

