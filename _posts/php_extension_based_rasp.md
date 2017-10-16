基于php Extension的RASP防御机制

1 RASP

php是一门相当灵活的编程语言，对于攻击者而言，这无异于大开方便之门。一个函数，既可以直接调用，又可以以字符串方式调用，甚至将字符串通过复杂的变换进行调用。那么常用的通过对web目录的监控的做法，如果检测的静态规则一旦被摸清，那么攻击者几乎就有无数种方式突破防御了。

RASP（Runtime Application Self Protection）技术作为未来攻防场景下的防御机制的发展趋势，核心的特点是在cgi程序执行的过程中，在应用程序的执行环境内部对应用的行为进行实时的观测和记录，即便是遇到非常复杂高明的绕过手段，只要其行为符合某些特征（通常即调用某些关键的函数或或执行某些命令），我们就可以做出报警，甚至按照我们预设的逻辑进行操作。

在PHP中，虽然它灵活的机制让攻击方式十分多变，但无论如何，在语言的解释器中，所有的动作都难逃法眼。例如对文件进行读写，或者执行系统命令，只要我们能发现这些行为，就能非常精确的阻断攻击者的进攻。

2 PHP底层原理

在介绍真正的防御方案之前，先简单介绍PHP内核的工作原理。其实如果要非常具体的说清楚PHP的工作原理，恐怕一本书的容量应该差不多，再加上笔者没有真正深入的研究过PHP，这个问题恐怕答不上来。不过，要想更深刻的理解基于PHP Extension的防御机制，那么了解PHP解释器大概的工作流程是有必要的。

PHP脚本要执行有很多种方式，通过Web服务器，或者直接在命令行下，也可以嵌入在其他程序中。不同的执行方式通过一个叫做SAPI(Server Application Programming Interface)的接口引入到同一个引擎中。

1.Scanning(Lexing) ,将PHP代码转换为语言片段(Tokens) 2.Parsing, 将Tokens转换成简单而有意义的表达式 3.Compilation, 将表达式编译成Opocdes 4.Execution, 顺次执行Opcodes，每次一条，从而实现PHP脚本的功能。 题外话:现在有的Cache比如APC,可以使得PHP缓存住Opcodes，这样，每次有请求来临的时候，就不需要重复执行前面3步，从而能大幅的提高PHP的执行速度。

php执行过程的流程图

http://www.fullstackdevel.com/wp-content/uploads/2016/07/php-life-cycle-without-opcode-cache.png

php 的生命周期 http://www.cunmou.com/phpbook/1.3.md


3 构建一个PHP Extension

4 通过HOOK方式检测危险的php内建函数

referrer
http://www.php-internals.com/book/?p=chapt02/02-01-php-life-cycle-and-zend-engine
