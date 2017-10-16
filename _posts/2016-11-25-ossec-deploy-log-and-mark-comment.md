---
layout: post
title:  "ossec部署日志及备注"
date: 2016-11-25 15:06:26 +0800
categories: note
---
# 设计目标

1.日志收集
2.报警配置设置
3.web管理
4.报警数据可视化
5.系统健康检查

# 安装过程的要点

1.根据官方提供的下载命令安装即可，注意直接下载，会被劫持，需要使用海外的代理下载然后传到本地服务器上安装

2.安装过程需要依赖mysql的相关库才能编译

# 配置要点

1. 远程syslog配置

* 使用syslog、rsyslog、syslog-ng都可以，本次配置使用了syslog-ng，配置文件中添加

```
destination security_loghost { udp("172.30.1.103" port(514)); };
```

* 调试（重点在于监听udp端口，也可以使用tcp端口）

说明：如果ossec服务器端已经启动，则无法使用nc命令，只能用tcpdump进行监听

```
tcpdump -vv -X -i eth0 'host sorce_syslog_host'
nc -ul -vv 514
netstat -uan
```

2.ossec server端配置

* 配置监听514（syslog）端口

```
  <remote>
    <connection>syslog</connection>
    <port>514</port>
    <protocol>udp</protocol>
    <allowed-ips>172.30.3.0</allowed-ips>
    <local_ip>172.30.1.103</local_ip>
  </remote>
```

connection标签中可以使用syslog和secure，暂时没有测试两种方案的区别。配置成功后会在安装目录下的logs/alert/alert.log看到所有报警的日志。配置方案参考http://ossec.github.io/docs/syntax/head_ossec_config.remote.html#ossec-config-remote

说明：syslog-output不是接受syslog，而是将报警发给其他syslog服务的server端。

3.ossec规则配置

ossec支持自定义的报警规则，处理的流程是这样的：

```
1.通过本地文件或者syslog读入一条日志
2.启动pre-decode分析这条日志的基本信息，分别是fullevent，hostname，program_name，log
3.根据pre-decode分析的结果的数据，按照docoder.xml（etc目录下）中的配置，按照一定规则分析该条日志的更多信息，并格式化，以便后面利用这里的数据进行报警规则的匹配
4.报警（待续）
```

对于报警规则的设置，ossec开发了一个ossec-test配置测试工具（bin/ossec-test）

官方文档：http://ossec-docs.readthedocs.io/en/latest/manual/rules-decoders/create-custom.html

中文文档：http://www.freebuf.com/articles/network/36484.html

官方示例：

运行ossec-logtest -，会将一条日志的分析过程显示出来。当前我们是用一条程序测试的日志，这条日志不是产生于操作系统，ossec并没有找到关于这条日志的配置规则。
```
# /var/ossec/bin/ossec-logtest
2013/11/01 10:39:07 ossec-testrule: INFO: Reading local decoder file.
2013/11/01 10:39:07 ossec-testrule: INFO: Started (pid: 32109).
ossec-testrule: Type one log per line.

2013-11-01T10:01:04.600374-04:00 arrakis ossec-exampled[9123]: test connection from 192.168.1.1 via test-protocol1


**Phase 1: Completed pre-decoding.
       full event: '2013-11-01T10:01:04.600374-04:00 arrakis ossec-exampled[9123]: test connection from 192.168.1.1 via test-protocol1'
       hostname: 'arrakis'
       program_name: 'ossec-exampled'
       log: 'test connection from 192.168.1.1 via test-protocol1'

**Phase 2: Completed decoding.
       No decoder matched.
```

下面考虑在decoder.xml文件中为这类日志添加一条规则

```
<decoder name="ossec-exampled">
  <program_name>ossec-exampled</program_name>
</decoder>

```

[可选]执行ossec-logtest -t测试配置文件。

再次执行ossec-logtest -v

```
# /var/ossec/bin/ossec-logtest
2013/11/01 10:52:09 ossec-testrule: INFO: Reading local decoder file.
2013/11/01 10:52:09 ossec-testrule: INFO: Started (pid: 25151).
ossec-testrule: Type one log per line.

2013-11-01T10:01:04.600374-04:00 arrakis ossec-exampled[9123]: test connection from 192.168.1.1 via test-protocol1


**Phase 1: Completed pre-decoding.
       full event: '2013-11-01T10:01:04.600374-04:00 arrakis ossec-exampled[9123]: test connection from 192.168.1.1 via test-protocol1'
       hostname: 'arrakis'
       program_name: 'ossec-exampled'
       log: 'test connection from 192.168.1.1 via test-protocol1'

**Phase 2: Completed decoding.
       decoder: 'ossec-exampled'
```

可以看到在**Phase 2的部分，已经可以识别出ossec-exampled的名称。


#######
*costom rule跨优先级报警的一个例子
[http://linuxbsdos.com/2015/02/26/configure-ossec-to-not-email-alerts-on-iptables-denied-messages/]:http://linuxbsdos.com/2015/02/26/configure-ossec-to-not-email-alerts-on-iptables-denied-messages/
