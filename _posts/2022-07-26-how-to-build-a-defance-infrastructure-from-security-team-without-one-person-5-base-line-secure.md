---
layout: post
title:  "在“没有人的安全部”构筑护网防御工事（5）——基线安全"
date: 2022-07-25 12:36:26 +0800
author : Mushen
categories: original
---

# 第五部分 

# 1 概述（what）

## 1.1 含义

笔者个人理解的基线是一个信息系统的运行环境的初始化定义，广义的基线是指任何一种可认为干预的系统初始状态的变量，例如网络的ACL；狭义的基线是指构成信息系统的各种组成部分的配置参数，安全的系统需要对这些参数进行安全的设置，这些配置参数的选择形成了系统整体的基线安全。

本章中谈到的基线具有以下几个特点：

首先是可复制性，基线存在于不同的组件中，而不同的组件的基线应该是一致的，基线是一种标准，在系统扩容时配置的新环境也默认使用相同的标准基线。

其次是可观测性，由于人为或非人为的原因可改变基线的配置设置，那么基线的标准可能就会被破坏，需要一种发现破坏基线的状态的机制，以便及时纠正。

再次是可管理型，基线除了是一种系统从状态，同时也是一种可被记录和管理的模板，其本身应该被妥善保存，并且应该像代码一样进行版本管理。

最后就是安全性，基线的配置应该具备一定的抗攻击的特性，在有些系统中，这些安全设置尤为重要。  

## 1.2 原理

基线安全应该作为系统默认的初始化策略，在任何状态都被维护和确认，在任何新的元素被引入的时候都应该被校验。说人话的表达就是，系统的基线需要在系统运行的过程中被监控，任何改变系统基线的行为都应该有能力被发现，并且应该被禁止。当系统增加新的硬件或软件，其响应的配置应该满足标准基线的要求。

## 1.3 原则

基线安全的原则比较简单，就是不要破坏基线。

# 2 目的（why）

很多时候，基线代表这合规，尽管合规水平不能代表信息系统的真实安全水平，但基线检查仍然是信息安全体系中非常重要的一个环节。在大多数信息系统中常用的组件，在行业中已经形成了比较丰富的安全最佳实践，本章节我们将摘录一些常见的基线配置选项共读者参考。

# 3 方案（how）

## 3.1 基线规则

关于基线规则，由于笔者在此做的功课不多，因此在这里只能做一下互联网搬运工。总体而言，基线检查的规则网上流传着很多版本，但核心的检查点都是相同的。通常互联网公司的基线规则不需要特别多，而金融机构因为各个层面的合规要求，他们的基线规则就非常丰富。如果感兴趣，各位读者可以自行搜搜看。这里笔者找到一份大部分以CIS标准为基准的基线规则库，内容涵盖了主机、数据库、中间件等常见软件的基线配置建议：[来自AV1080p的安全基线合集](https://github.com/AV1080p/Benchmarks)。但这个规则库没有包含容器的基线规则，这里又找到一组[来自yangrz的docker安全基线整理](https://yangrz.github.io/blog/2018/04/13/docker/)。此外，信息安全等级保护的要求也是一个不错的基线的标准蓝图，根据系统的重要性和复杂程度选择对应的级别，然后根据内容制定基线标准也是一个简单高效的办法。

最后希望大家能明白，基线规则不是越多越好，通常一个软件配置好最关键的十到二十条足矣。

## 3.2 基线流程

关于基线建立的流程，在FreeBuf有署名cihack的作者发表了一篇，内容已经介绍的比较清楚，读者可以从这里跳转阅读：[安全基线，让合规更直观](https://www.freebuf.com/articles/es/216758.html)

这篇文章罗列了建立基线的总体流程，其六个步骤分别是：

1. 建立基线配置管理规划
2. 定制基础操作系统镜像
3. 制定基线配置模板
4. 分发基线配置
5. 基线配置应用
6. 基线配置变更

但考虑到实际运营的效果以及本文的主旨目标，这篇引用的文章在原有的基础之上还应该补充日常基线配置检查的要求。因为对于已经下发的基线标准，有很多场景可以造成实际配置的变化。安全基线不但要讲标准基线下发到系统中，还要把发生变化的基线找出并纠正。这需要在每一个主机上工作的客户端程序（简单的话可以通过脚本加定时任务的方式实现。检查的结果，需要定期被收集，发现有变化的检查点需要定位变化的原因并视情况纠正。如果需要自动化收集信息，那么有能力的单位可以通过自己开发一套服务来实现，如果需要简化快速实现的，也可以将检测结果写入文件，然后通过syslog协议发送至日志服务器进行分析。


# 4 需要注意的一些问题

基线检查的主要问题，有以下几方面。一是系统中的组件多而复杂，由于缺少早期的规划和日常管理，导致使用的组件没有规律且非常庞杂，因此一方面需要系统管理员尽量收集信息并整理成有序的数据，另一方面需要筛除掉一些使用量较少的组件，以提高工作效率。二是基线配置的变更有时需要重启服务和软件，甚至重启操作系统，也会带来一定风险，因此务必做好正式变更前的测试和验证工作，同时安排好灰度策略。

