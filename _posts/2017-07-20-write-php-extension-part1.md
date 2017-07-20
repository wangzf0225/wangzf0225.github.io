---
layout: post
date: 2017-07-20 15:34:26 +0800
author : JeremyWei
categories: principle
title: "[转]PHP扩展编写第一步：PHP和Zend介绍"
tags: [tech, translate]
---

```
转发注

这是一篇转载的关于php扩展开发技术的文章，全文有三篇，这是第一篇。因为兴趣的原因，只想了解一下zend的机制，不是专业的php R&D所以不打算深入研究。这里做一个备份，以免原文链接挂掉，大家有兴趣请移步至[weizhifeng.net](http://weizhifeng.net/write-php-extension-part1.html)访问原文。
```

###  介绍

如果你在读这篇入门文章，那么你可能对写PHP扩展有点兴趣。如果不是… 好吧，那么等我们写完这篇文章，你将会发现一个之前自己完全不知道，但是非常有趣的东西。

这篇入门文章假设你对PHP语言和以及PHP的编写语言**C语言**都有一定的熟悉。

让我们以“为什么你需要写一个PHP扩展”作为开始。

* 因为PHP语言本身抽象程度有限，有一些库或者操作系统级别的调用，不能用PHP直接调用。
* 你想给PHP添加一些与众不同的行为。
* 你已经写了一些PHP代码，但是当运行的时候你知道它可以更快，更小，消耗的内存更少。
* 你有一部分程序想出售，你可以把它写成扩展，这样程序是可以执行的，但是别人却无法看到源码。

这儿有很多完美的原因，但是要想创建一个扩展，你首先要需要明白什么是扩展。

###  什么是扩展？

如果你用过PHP，那么你就用过扩展。除了一些极少的特殊情况之外，PHP语言中的每个用户空间函数都是以组的形式分布在一个或多个扩展之中。这些函数中的大部分是位于标准扩展中的 – 总共超过400个。PHP源码中包含86个扩展，平均每个扩展中有30个函数。算一下，大概有2500个函数。如果这个不够用，[PECL](http://pecl.php.net/ "PECL")仓库还提供了超过100个其他扩展，或者还可以在互联网上找到更多的扩展。

「PHP除了扩展中的这些函数之外，剩下的是什么」我听到了你的疑问「扩展是什么？PHP的核心又是什么？」

PHP的核心是由两个独立的部分组成的。在最底层是**Zend Engine (ZE)**。ZE 负责把人类可以理解的脚本解析成机器可以理解的符号（token），然后在一个进程空间内执行这些符号。ZE还负责内存管理，变量作用域，以及函数调用的调度。另一部分是**PHP**。PHP负责与**SAPI**层（Server Application Programming Interface，经常被用来与Apache, IIS, CLI, CGI等host环境进行关联）的交互以及绑定。它也为`safe_mode`和`open_basedir`检查提供了一个统一的控制层，就像streams层把文件和网络I/O与用户空间函数（例如`fopen()`，`fread()`和`fwrite()`）关联起来一样。

###  生命周期

当一个给定的SAPI启动后，以`/usr/local/apache/bin/apachectl start`的响应为例，PHP便以初始化它的核心子系统作为开始。随着SAPI启动程序的结束，PHP开始加载每个扩展的代码，然后调用它们的**模块初始化**(`MINIT`)程序。这就给每个扩展机会用来初始化内部变量，申请资源，注册资源处理器，并且用ZE注册自己的函数，这样如果一个脚本调用这些函数中的一个，ZE就知道执行哪些代码。

接下来，PHP会等待SAPI层的页面处理请求。在CGI或者CLI SAPI情况下，这个请求会立即发生并且只执行一次。在Apache, IIS, 或者其他成熟的web服务器SAPI中，请求处理会在远程用户发起请求的时候发生，并且会重复执行很多次，也可能是并发的。不管请求是怎么进来的，PHP以让ZE来建立脚本可以运行的环境作为开始，然后调用每个扩展的**请求初始化**（`RINIT`）函数。`RINIT`给了扩展一个机会，让其可以建立指定的环境变量，分配请求指定的资源，或者执行其他任务例如审计。关于`RINIT`函数调用最典型的例子是在session扩展中，如果`session.auto_start`选项是开启的，`RINIT`会自动触发用户空间的`session_start()`函数并且预先填充`$_SESSION`变量。

当请求一旦被初始化，ZE便把PHP脚本翻译成**符号**（token），最终翻译成可以进行单步调试和执行的**opcode**。如果这些opcode中的一个需要调用一个扩展函数，ZE将会给那个函数绑定参数，并且临时放弃控制权直到函数执行完成。

当一个脚本完成了执行之后，PHP将会调用每个扩展的**请求结束**(`RSHUTDOWN`)函数来执行最后的清理工作（比如保存session变量到磁盘上）。接下来，ZE执行一个清理过程（熟知的**垃圾回收**），实际上是对上次请求过程中使用的变量调用`unset()`函数。

一旦完成，PHP等待SAPI发起另一个文档请求或者一个关闭信号。在CGI和CLI SAPI的情况下，没有所谓的“下一个请求”，所以SAPI会立刻执行关闭流程。在关闭过程中，PHP又让每个扩展调用自己的**模块关闭**（`MSHUTDOWN`）函数，最后关闭自己的核心子系统。

这个过程第一次听令人有些费解，但是一旦你深入到一个扩展的开发过程中，它就会逐渐的清晰起来。

###  内存分配

为了避免写的很糟糕的扩展泄露内存，ZE以自己内部的方式来进行内存管理，通过用一个附加的标志来指明**持久化**。一个**持久化分配**的内存比单个页面请求存在的时间要长。一个**非持久化分配**的内存，相比之下，在请求结束的时候就会被释放，不管free函数是否被调用。例如用户空间变量，都是非持久化分配的内存，因为在请求结束之后这些变量都没有用了。

一个扩展理论上可以依靠ZE在每个页面请求结束后自动释放非持久化的内存，但这是不被推荐的。在请求结束的时候，分配的内存不会被立即被回收，并且会持续一段时间，所以和那块内存关联的资源将不会被恰当的关闭，这是一个很糟的做法，因为如果不能适当的清理的话，这会产生混乱。就像你即将要看见的，确定所有分配的数据被恰当的清除了是非常的简单。

让我们把常规的内存分配函数（只应该当和内部库一起工作的时候才会用到）和PHP ZE中的持久化和非持久化内存分配函数进行一个对比。


Traditional Non-Persistent Persistent
`malloc(count)` `calloc(count, num)` `emalloc(count)`
`ecalloc(count, num)` `pemalloc(count, 1)`<sup>*</sup> `pecalloc(count, num, 1)`
`strdup(str)` `strndup(str, len)` `estrdup(str)`
`estrndup(str, len)` `pestrdup(str, 1)` `pemalloc() &amp; memcpy()``free(ptr)``efree(ptr)``pefree(ptr, 1)``realloc(ptr, newsize)``erealloc(ptr, newsize)``perealloc(ptr, newsize, 1)``malloc(count * num + extr)`<sup>**</sup>`safe_emalloc(count, num, extr)``safe_pemalloc(count, num, extr)`* __The `pemalloc()` family include a ‘persistent’ flag which allows them to behave like their non-persistent counterparts.<br/>For example: `emalloc(1234)` is the same as `pemalloc(1234, 0)`__<br/>** __`safe_emalloc()` and (in PHP 5) `safe_pemalloc()` perform an additional check to avoid integer overflows__

###  建立一个开发环境

现在你已经掌握了一些关于PHP和ZE的工作原理，我估计你希望要深入进去，并且开始写些什么。无论如何在你能做之前，你需要收集一些必要的开发工具，并且建立一个满足自己目标的环境。

第一你需要PHP本身，以及构建PHP所需要的开发工具集合。如果你对于从源码编译PHP不熟悉，我建议你看看[http://www.php.net/install.unix](http://www.php.net/install.unix)。(开发windows下的PHP扩展在以后的文章会介绍)。使用适合自己发行版的PHP二进制包是很诱人的，但是这些版本总是会忽略两个重要的

	./configure

选项，这两个选项在开发过程中非常方便。第一个是`--enable-debug`。这个选项将会用附加符号信息来编译PHP所以，如果一个段错误发生，那么你将可以从PHP收集到一个核心dump信息，然后使用gdb来跟踪这个段错误是在哪里发生的，为什么会发生。另一个选项依赖于你将要进行扩展开发的PHP版本。在PHP4.3这个选项叫`--enable-experimental-zts`，在PHP5和以后的版本中叫`--enable-maintainer-zts`。这个选项将会让PHP思考在多线程环境中的行为，并且可以让你捕获常见的程序错误，这些错误在非线程环境中不会引起问题，但在多线程环境中却使你的扩展变得不可用。一旦你已经使用这些额外的选项编译好了PHP，并且已经安装在了你的开发服务器（或者工作站）上，那么你可以开始建立你的第一个扩展了。

###  Hello World

如果一门语言的入门介绍没有**Hello World**程序，那么这个介绍就是不完整的。在这种情况下，你将会建立一个扩展，这个扩展会导出一个返回”Hello World”字符串的函数。如果用PHP，你可能这么写：

	<?php
	function hello_world()
	{
	    return 'Hello World';
	}
	?>

现在你将会把这个逻辑放到一个PHP扩展中。首先让我们在你PHP源码树的**ext/**目录下创建一个名叫**hello**的目录，并进入(`chdir`)到这个目录中。这个目录实际上可以放在任何地方，PHP源码树内或者PHP源码树外，但是我希望你把它放在源码树内为了接下来的文章使用。在这你需要创建三个文件：一个包含你`hello_world`函数的**源文件**，一个**头文件**，其中包含PHP加载你扩展时候所需的引用，一个**配置文件**，它会被phpize用来准备扩展的编译环境。

###  config.m4

	PHP_ARG_ENABLE(hello, whether to enable Hello World support,
	[ --enable-hello Enable Hello World support])

	if test "$PHP_HELLO" = "yes"; then
	    AC_DEFINE(HAVE_HELLO, 1, [Whether you have Hello World])
	    PHP_NEW_EXTENSION(hello, hello.c, $ext_shared)
	fi


###  php_hello.h

	#ifndef PHP_HELLO_H
		#define PHP_HELLO_H 1
		#define PHP_HELLO_WORLD_VERSION "1.0"
		#define PHP_HELLO_WORLD_EXTNAME "hello"

		PHP_FUNCTION(hello_world);
		extern zend_module_entry hello_module_entry;
		#define phpext_hello_ptr &hello_module_entry

	#endif


###  hello.c

	#ifdef HAVE_CONFIG_H
		#include "config.h"
	#endif

	#include "php.h"
	#include "php_hello.h"

	static function_entry hello_functions[] = {
	    PHP_FE(hello_world, NULL)
	    {NULL, NULL, NULL}
	};

	zend_module_entry hello_module_entry = {
	#if ZEND_MODULE_API_NO >= 20010901
	    STANDARD_MODULE_HEADER,
	#endif
	    PHP_HELLO_WORLD_EXTNAME,
	    hello_functions,
	    NULL,
	    NULL,
	    NULL,
	    NULL,
	    NULL,
	#if ZEND_MODULE_API_NO >= 20010901
	    PHP_HELLO_WORLD_VERSION,
	#endif
	    STANDARD_MODULE_PROPERTIES
	};

	#ifdef COMPILE_DL_HELLO
		ZEND_GET_MODULE(hello)
	#endif

	PHP_FUNCTION(hello_world)
	{
	    RETURN_STRING("Hello World", 1);
	}


以上只是一个PHP扩展的大体框架，扩展中的大部分代码只是简单的把几个文件关联在了一起。只有最后四句才像你之前在PHP脚本中调用的“实际代码”。实际上这个层级的代码和我们之前看到的PHP代码非常的相似，从字面上很容易理解：

1. 声明一个名叫`hello_world`的函数
2. 让那个函数返回一个字符串：“Hello World”
3. ...额... 1? 那个1是做什么的？

回想一下ZE有一个先进的内存管理层，当脚本退出的时候确保分配的资源被释放掉。在内存管理领域，对同一块内存进行两次释放是大错特错的。这种做法叫做**double freeing**，是引起段错误的常见原因，因为它让程序去访问一个已经不属于自己的内存块。类似的，你不希望让ZE去释放一个静态字符串buffer（就像我们示例扩展中的”Hello World”），因为它是在程序空间，并不是属于任何进程的数据块。`RETURN_STRING()`假设任何传递给它的字符串都需要一个拷贝，所以它们可以在之后安全的释放掉。但是由于在一个内部函数中为字符串分配内存，动态填充，然后返回它，这是很平常，`RETURN_STRING()`允许我们来指定是否有必要对这个字符串值进行拷贝。为了更好的解释这个概念，接下来的代码片段的功能和上面的是一样的：

	PHP_FUNCTION(hello_world)
	{
	    char *str;

	    str = estrdup("Hello World");
	    RETURN_STRING(str, 0);
	}

在这个版本中，你手动为”Hello World”字符串分配了内存，最终返回给调用脚本，然后把内存“给了”`RETURN_STRING`，第二个参数值0说明不需要为这个字符串做拷贝。

###  建立你的扩展

这个练习的最后一步是把你的扩展编译成一个动态加载的模块。如果你已经正确的拷贝以上的例子，那么这个工作就是在__ext/hello/__目录下执行三个命令：

	$ phpize
	$ ./configure --enable-hello
	$ make

在运行了这些命令之后，你将会在__ext/hello/modules__目录中发现一个__hello.so__文件。现在，可以像其他PHP扩展一样，你可以把它拷贝到你的扩展目录（默认是__/usr/local/lib/php/extensions/__，检查你的__php.ini__文件确定一下）中，然后在你的__php.ini__文件中加上`extension=hello.so`这一行，让扩展可以在PHP启动的时候被加载。对于CGI/CLI SAPI来说，这个意味着下一次PHP运行的时候就会生效；对于web server SAPI比如Apache来说，这个意味着web server下次被重启的时候生效。现在让我们以命令行的形式做一个尝试：

	$ php -r 'echo hello_world();'

如果一切正常，你将会看到由这个脚本输出的**Hello World**，因为在你加载的扩展中已经定义的`hello_world()`函数会返回Hello World这个字符串，然后**echo**命令会打印出任何传递给它的东西。

其他标量也可以用类似的函数返回，用`RETURN_LONG()`返回整型值，`RETURN_DOUBLE()`返回浮点型值，`RETURN_BOOL()`返回布尔型值，`RETURN_NULL()`返回的值，你懂的，`NULL`。在__hello.c__文件中的`function_entry`结构体中加入几行`PHP_FE()`代码并且在文件最后加入几行`PHP_FUNCTION()`代码，让我们真实的看看这些函数。

	static function_entry hello_functions[] = {
	    PHP_FE(hello_world, NULL)
	    PHP_FE(hello_long, NULL)
	    PHP_FE(hello_double, NULL)
	    PHP_FE(hello_bool, NULL)
	    PHP_FE(hello_null, NULL)
	    {NULL, NULL, NULL}
	};

	PHP_FUNCTION(hello_long)
	{
	    RETURN_LONG(42);
	}

	PHP_FUNCTION(hello_double)
	{
	    RETURN_DOUBLE(3.1415926535);
	}
	
	PHP_FUNCTION(hello_bool)
	{
	    RETURN_BOOL(1);
	}

	PHP_FUNCTION(hello_null)
	{
	    RETURN_NULL();
	}

你还需要在头文件__php_hello.h__中为这些函数添加原型声明，添加在`hello_world()`函数原型旁边，这样构建程序就可以恰当的进行宏替换：

	PHP_FUNCTION(hello_world);
	PHP_FUNCTION(hello_long);
	PHP_FUNCTION(hello_double);
	PHP_FUNCTION(hello_bool);
	PHP_FUNCTION(hello_null);

如果你对__config.m4__文件没有做过更改，那么这次跳过__phpize__和__./configure__步骤，直接__make__，在技术上来说这是安全的。但是无论如何，为了能够没有问题的构建这个扩展，这次我还是想让你完整的走这三个步骤。另外，这次你应该用make clean，而不是上次用的make，从而确保所有源文件都被重新构建。其实这个还是不必要的，因为你做的修改很有限，但是安全比混乱要好。一旦模块构建好了之后，你可以把它拷贝到你的扩展目录下，替换旧的版本。

此时你可以再一次调用PHP解释器，用一个简单的脚本来测试你刚才加的函数。事实上，为什么你现在不做呢？我在这儿等你….

测试好了？很好。如果你使用`var_dump()`而不是`echo`来看每个函数的输出的话，你可能会注意到`hello_bool()`返回的是true。这是`RETURN_BOOL()`函数中1所代表的值。就像在PHP脚本中，一个整型的0等于`FALSE`，同时任何其他的整型值等于`TRUE`。扩展的作者们经常使用1来表示`TRUE`，也建议你那样做，但是不要拘泥于此。为了添加可读性，`RETURN_TRUE`和`RETURN_FALSE`宏也是可用的；下面是`hello_bool()`的重写，这次使用`RETURN_TRUE`：

	PHP_FUNCTION(hello_bool)
	{
		RETURN_TRUE;
	}

注意这没有使用括号。`RETURN_TRUE`和`RETURN_FALSE`跟其他RETURN_*()宏不一样，所以别搞错了。

你可能注意到在以上代码示例中，我们没有传递0或者1来指定是否这个值需要被拷贝。这是因为对于这些简单的标量来说，并没有额外的内存被分配或者释放。

这还有三个额外的返回类型：`RESOURCE`（`mysql_connect()`, `fsockopen()`和`ftp_connect()`等函数返回的类型），`ARRAY`（也就是`HASH`表），`OBJECT`（`new`关键字返回的）。这些类型我们将会在[第二部分](http://weizhifeng.net/write-php-extension-part2-1.html)也就是深入变量的时候来介绍。

###  INI设置

Zend引擎提供了两种管理`INI`值的方法。我们现在先看一下简单的方法，之后当你有机会使用全局变量的时候，再看一下更加完整，更加复杂的方法。

假设你想在你的扩展中声明一个__php.ini__的配置项，`hello.greeting`，这个值被你的函数`hello_world()`所使用。你需要对`hello_module_entry`做些关键的修改，同时还需要在__hello.c__和__php_hello.h__中添加些东西。在__php_hello.h__的用户区函数原型附近添加如下的函数原型：

	PHP_MINIT_FUNCTION(hello);
	PHP_MSHUTDOWN_FUNCTION(hello);
	PHP_FUNCTION(hello_world);
	PHP_FUNCTION(hello_long);
	PHP_FUNCTION(hello_double);
	PHP_FUNCTION(hello_bool);
	PHP_FUNCTION(hello_null);

现在到__hello.c__文件顶部，用以下内容替换掉`hello_module_entry`的内容：

	zend_module_entry hello_module_entry = {

	#if ZEND_MODULE_API_NO >= 20010901
	    STANDARD_MODULE_HEADER,
	#endif
	    PHP_HELLO_WORLD_EXTNAME,
	    hello_functions,
	    PHP_MINIT(hello),
	    PHP_MSHUTDOWN(hello),
	    NULL,
	    NULL,
	    NULL,
	#if ZEND_MODULE_API_NO >= 20010901
	    PHP_HELLO_WORLD_VERSION,
	#endif
	    STANDARD_MODULE_PROPERTIES
	};


	PHP_INI_BEGIN()
	PHP_INI_ENTRY("hello.greeting", "Hello World", PHP_INI_ALL, NULL)
	PHP_INI_END()

	PHP_MINIT_FUNCTION(hello)
	{
	    REGISTER_INI_ENTRIES();
	    return SUCCESS;
	}

	PHP_MSHUTDOWN_FUNCTION(hello)
	{
	    UNREGISTER_INI_ENTRIES();
	    return SUCCESS;
	}

现在，你只需要在__hello.c__文件头部的`#inlcude`代码后面添加一行，从获取对`INI`文件支持所需要的正确头文件：

	#ifdef HAVE_CONFIG_H
		#include "config.h"
	#endif

	#include "php.h"
	#include "php_ini.h"
	#include "php_hello.h"

最后，你可以修改你的`hello_world`函数来使用`INI`值：

	PHP_FUNCTION(hello_world)
	{
		RETURN_STRING(INI_STR("hello.greeting"), 1);
	}

注意，你拷贝了从`INI_STR()`返回的值。因为这是一个静态的字符串。事实上，如果你尝试去修改`INI_STR`返回的这个字符串，PHP执行环境将会变得不稳定，甚至会崩溃。

首先要修改的地方是你非常熟悉的两个函数：`MINIT`，`MSHUTDOWN`。就像前面提到的，这些函数会在SAPI层初始化启动和最后关闭的时候被调用。他们不会在请求过程中被调用。在这个例子中，你已经用这些函数在你的扩展中注册了__php.ini__的配置内容。在接下来的内容中，你将会知道如何用`MINIT`和`MSHUTDOWN`函数来注册resource，object和stream handler。

在你的`hello_world()`函数中，你用`INI_STR()`来获得了`hello.greeting`当前的值，字符串格式。在下面表格中列出了一些其他函数，这些函数可以返回long，double和Boolean类型的值，并且还有一些带有`ORIG`标识的更加原始的函数，这些函数返回__php.ini__中最初设置的值（在被__.htaccess__文件或者`ini_set()`修改之前）。

	Current Value	Original Value	Type
	INI_STR(name)	INI_ORIG_STR(name)	char * (NULL terminated)
	INI_INT(name)	INI_ORIG_INT(name)	signed long
	INI_FLT(name)	INI_ORIG_FLT(name)	signed double
	INI_BOOL(name)	INI_ORIG_BOOL(name)	zend_bool

传递给`PHP_INI_ENTRY()`的第一个参数是在__php.ini__中使用的**配置项名称**。为了避免命名空间的冲突，你应该使用跟你函数命名相同的习惯；在所有的配置项之前都加一个和你扩展名字相同的前缀，就像`hello.greeting`一样。事实上习惯就是，一个“.”把扩展名字和ini配置的名字分开。

第二个参数是__初始化值__，不管它是否是数字类型的，总是传递`char*`字符串类型。这是因为事实上__.ini__文件中的值都是原生的文本类型。你可以在你的脚本中用`INI_INT()`，`INI_FLT()`，或者`INI_BOOL()`来做类型转换。

你传递的第三个值是一个**访问模式标识**。这是一个掩码字段，用来决定在什么时候，在什么地方这个`INI`的配置项可以被修改。一些配置项，比如像`register_globals`，它就不可能在脚本中用`ini_set()`来进行修改，因为这个配置项只有在请求启动的时候才有意义，也就是脚本根本就没有机会去修改它。其他的，比如像`allow_url_fopen`，它是管理员级别的配置项，所以你不希望在共享托管环境中的用户去修改它，不管是通过`ini_set()`还是用__.htaccess__指令。这个参数常见的值可能是`PHP_INI_ALL`，表明这个配置项可以在任何地方修改。还有`PHP_INI_SYSTEM｜PHP_INI_PERDIR`，表明配置项可以在__php.ini__文件或者在__.htaccess__文件通过Apache的指令来修改，但是不能使用`ini_set()`来修改。`PHP_INI_SYSTEM`，表示这个配置项只能在__php.ini__中修改，不能在其他地方修改。

当前我们将要跳过第四个参数，只是提一下这个参数允许传递一个回调方法，这个方法会在__ini__配置被修改的时候触发，无论什么时候，比如用__ini_set()__修改。这就允许一个扩展可以在配置被修改的时候做一些更准确的控制，或者触发一个需要依赖新配置的动作。

###  全局变量

通常，一个扩展在一个特殊的请求中需要跟踪一个值，并保证这个值与同一时间其他的请求是独立开来的。在一个非线程SAPI中那很简单：在源文件中直接声明一个全局变量，在需要的时候访问它。麻烦是，自从PHP被设计成可以运行在多线程的web服务器上（像Apache2和IIS），所以需要把一个线程使用的全局变量与其他线程使用的全局变量分离开来。PHP用TSRM (Thread Safe Resource Management)抽象层，有时有也叫ZTS (Zend Thread Safety)，非常简单的解决了这个问题。

事实上，你已经用过了TSRM的一部分，只是不知道而已。（先别费劲搜索呢；你将会发现这些东西都被隐藏了。）

创建一个线程安全的全局变量的第一步，和其他全局变量都一样，先声明。由于这个例子的缘故，你必须声明一个`long`类型值为`0`的全局变量。每次调用`hello_long()`函数的时候，你将会增加这个值，然后返回它。在__php_hello.h__中的`#define PHP_HELLO_H`代码段后面加上以下的代码：

	#ifdef ZTS
		#include "TSRM.h"
	#endif

	ZEND_BEGIN_MODULE_GLOBALS(hello)
	    long counter;
	ZEND_END_MODULE_GLOBALS(hello)

	#ifdef ZTS
		#define HELLO_G(v) TSRMG(hello_globals_id, zend_hello_globals *, v)
	#else
		#define HELLO_G(v) (hello_globals.v)
	#endif

这次你还是要使用`RINIT`方法，所以你需要在头文件中声明它的原型：

	PHP_MINIT_FUNCTION(hello);
	PHP_MSHUTDOWN_FUNCTION(hello);
	PHP_RINIT_FUNCTION(hello);

现在让我们回到__hello.c__中，在你的`include`块后面加上如下内容：

	#ifdef HAVE_CONFIG_H
		#include "config.h"
	#endif

	#include "php.h"
	#include "php_ini.h"
	#include "php_hello.h"
	ZEND_DECLARE_MODULE_GLOBALS(hello)


修改`hello_module_entry`，添加`PHP_RINIT(hello)`:

	zend_module_entry hello_module_entry = {

	#if ZEND_MODULE_API_NO >= 20010901
	    STANDARD_MODULE_HEADER,
	#endif
	    PHP_HELLO_WORLD_EXTNAME,
	    hello_functions,
	    PHP_MINIT(hello),
	    PHP_MSHUTDOWN(hello),
	    PHP_RINIT(hello),
	    NULL,
	    NULL,
	#if ZEND_MODULE_API_NO >= 20010901
	    PHP_HELLO_WORLD_VERSION,
	#endif
	    STANDARD_MODULE_PROPERTIES
	};

并修改你的MINIT函数，和另一对函数一起，用来在请求开始的时候初始化：

	static void php_hello_init_globals(zend_hello_globals *hello_globals)
	{
	}

	PHP_RINIT_FUNCTION(hello)
	{
	    HELLO_G(counter) = 0;
	    return SUCCESS;
	}

	PHP_MINIT_FUNCTION(hello)
	{
	    ZEND_INIT_MODULE_GLOBALS(hello, php_hello_init_globals, NULL);
	    REGISTER_INI_ENTRIES();
	    return SUCCESS;
	}

最后，你可以修改`hello_long()`函数来使用这个值：

	PHP_FUNCTION(hello_long)
	{
		HELLO_G(counter)++;
		RETURN_LONG(HELLO_G(counter));
	}

在__php_hello.h__添加的内容中，你使用了一对宏`ZEND_BEGIN_MODULE_GLOBALS()`和`ZEND_END_MODULE_GLOBALS()` – 用来创建一个包含一个`long`类型，名为`zend_hello_globals`的结构体。然后你继续声明了`HELLO_G()`来从一个线程池中获取值，或者只是从全局空间中获取 － 如果你为一个非线程环境编译的话。

在__hello.c__中你用了`ZEND_DECLARE_MODULE_GLOBALS()`宏来真正实例化`zend_hello_globals`结构体为一个真正的全局变量（如果是以非线程安全编译的话），或者一个线程资源池的一个成员。对于一个扩展的作者来说，这个区别我们不需要担心，因为Zend Engine已经为我们处理了这个事情。最后，在`MINIT`中，你使用了`ZEND_INIT_MODULE_GLOBALS()`来分配一个线程安全的资源id – 现在不用担心这个东西是什么。

你可能注意到了那个`php_hello_init_globals()`函数实际上根本没做任何事情，我们想在其中初始化`counter`为`0`，而实际上我们是在`RINIT`中初始化的。为什么？

关键在于这两个函数什么时候被调用。`php_hello_init_globals()`只有当一个新的进程或者线程启动的时候才会被调用；而与此同时，每个进程可以处理多个请求，所以用这个函数来初始化我们的`counter`为`0`的话，那么这个初始化只会在第一个页面请求到达的时候工作。等随后到达这个相同进程的页面请求，得到的仍然是旧的`counter`值，因此也就不会从0开始计数了。为了让每个单独的页面请求都能初始化`counter`为`0`，我们实现了`RINIT`函数，就像你之前了解的那样，这个函数在每次页面请求的时候都会被调用。我们在这个时候包含了`php_hello_init_globals()`函数是因为你将会在一段时间后使用它，同时也是由于如果把一个`NULL`做为初始化函数传递给`ZEND_INIT_MODULE_GLOBALS()`将会在非线程平台上引起一个段错误。

###  INI配置项作为全局变量值

如果你回想起之前，一个用`PHP_INI_ENTRY()`声明的__php.ini__的配置项被解析成一个字符串值，并且在需要的时候可以用`INI_INT()`，`INI_FLT()`和`INI_BOOL()`转换成对应的类型。

对于一些配置项，存在很多不必要的重复工作，比如配置项的值在一个脚本执行的时候被一遍又一遍的读取。幸运的是可以让ZE以一种特殊的数据类型来存储`INI`配置项的值，并且只有值改变的时候才执行类型转换。让我们声明另一个`INI`配置的值，这次是一个`Boolean`类型，用来标示`counter`是否增加或者减少。修改__php_hello.h__文件的`MODULE_GLOBALS`块为以下内容：

	ZEND_BEGIN_MODULE_GLOBALS(hello)
	    long counter;
	    zend_bool direction;
	ZEND_ENG_MODULE_GLOBALS(hello)

接下来，修改`PHP_INI_BEGIN()`块内容从而来声明`INI`配置项的值：

	PHP_INI_BEGIN()
	    PHP_INI_ENTRY("hello.greeting", "Hello World", PHP_INI_ALL, NULL)
	    STD_PHP_INI_ENTRY("hello.direction", "1", PHP_INI_ALL, OnUpdateBool, direction, zend_hello_globals, hello_globals)
	PHP_INI_END()

现在，在`init_globals`方法中初始化配置项：

	static void php_hello_init_globals(zend_hello_globals *hello_globals)
	{
	    hello_globals->direction = 1;
	}

最后，在`hello_long()`函数中使用`INI`配置项的值来决定是否要增加或者减少`counter`：

	PHP_FUNCTION(hello_long)
	{
	    if (HELLO_G(direction)) {
	        HELLO_G(counter)++;
	    } else {
	        HELLO_G(counter)--;
	    }
	    RETURN_LONG(HELLO_G(counter));
	}

这就是全部了。在`INI_ENTRY`中指定的`OnUpdateBool`方法将会自动的转换__php.ini__，__.htaccess__文件提供的或者在脚本中通过`ini_set()`设置的值称为TRUE或者FALSE。`STD_PHP_INI_ENTRY`的最后三个参数是来告诉PHP修改哪个全局变量，我们扩展的全局变量的数据结构，以及这些全局变量被保存到的全局容器的名称。

###  稳妥的检查

到现在我们的三个文件看起来应该像下面所列的一样。（一些内容已经被移除了，并且规整到一起，只为了易读）
**config.m4**

	PHP_ARG_ENABLE(hello, whether to enable Hello World support,
	[ --enable-hello Enable Hello World support])

	if test "$PHP_HELLO" = "yes"; then
	    AC_DEFINE(HAVE_HELLO, 1, [Whether you have Hello World])
	    PHP_NEW_EXTENSION(hello, hello.c, $ext_shared)
	fi

**php_hello.h**

	#ifndef PHP_HELLO_H
		#define PHP_HELLO_H 1

		#ifdef ZTS
			#include "TSRM.h"
		#endif

		ZEND_BEGIN_MODULE_GLOBALS(hello)
		    long counter;
		    zend_bool direction;
		ZEND_END_MODULE_GLOBALS(hello)

		#ifdef ZTS
			#define HELLO_G(v) TSRMG(hello_globals_id, zend_hello_globals *, v)
		#else
			#define HELLO_G(v) (hello_globals.v)
		#endif

		#define PHP_HELLO_WORLD_VERSION "1.0"
		#define PHP_HELLO_WORLD_EXTNAME "hello"

		PHP_MINIT_FUNCTION(hello);
		PHP_MSHUTDOWN_FUNCTION(hello);
		PHP_RINIT_FUNCTION(hello);

		PHP_FUNCTION(hello_world);
		PHP_FUNCTION(hello_long);
		PHP_FUNCTION(hello_double);
		PHP_FUNCTION(hello_bool);
		PHP_FUNCTION(hello_null);

		extern zend_module_entry hello_module_entry;
		#define phpext_hello_ptr &hello_module_entry
	#endif

**hello.c**

	#ifdef HAVE_CONFIG_H
		#include "config.h"
	#endif

	#include "php.h"
	#include "php_ini.h"
	#include "php_hello.h" 

	ZEND_DECLARE_MODULE_GLOBALS(hello)

	static function_entry hello_functions[] = {
	    PHP_FE(hello_world, NULL)
	    PHP_FE(hello_long, NULL)
	    PHP_FE(hello_double, NULL)
	    PHP_FE(hello_bool, NULL)
	    PHP_FE(hello_null, NULL)
	    {NULL, NULL, NULL}
	};

	zend_module_entry hello_module_entry = {
	#if ZEND_MODULE_API_NO >= 20010901
	    STANDARD_MODULE_HEADER,
	#endif
	   PHP_HELLO_WORLD_EXTNAME,
	   hello_functions,
	   PHP_MINIT(hello),
	   PHP_MSHUTDOWN(hello),
	   PHP_RINIT(hello),
	   NULL,
	   NULL,
	#if ZEND_MODULE_API_NO >= 20010901
	   PHP_HELLO_WORLD_VERSION,
	#endif
	   STANDARD_MODULE_PROPERTIES
	};

	#ifdef COMPILE_DL_HELLO
		ZEND_GET_MODULE(hello)
	#endif

	PHP_INI_BEGIN()
	    PHP_INI_ENTRY("hello.greeting", "Hello World", PHP_INI_ALL, NULL)
		STD_PHP_INI_ENTRY("hello.direction", "1", PHP_INI_ALL, OnUpdateBool, direction, zend_hello_globals, hello_globals)
	PHP_INI_END()

	static void php_hello_init_globals(zend_hello_globals *hello_globals)
	{
	    hello_globals->direction = 1;
	}

	PHP_RINIT_FUNCTION(hello)
	{
	    HELLO_G(counter) = 0;
	    return SUCCESS;
	}

	PHP_MINIT_FUNCTION(hello)
	{
	    ZEND_INIT_MODULE_GLOBALS(hello, php_hello_init_globals, NULL);
	    REGISTER_INI_ENTRIES();
	    return SUCCESS;
	}

	PHP_MSHUTDOWN_FUNCTION(hello)
	{
	    UNREGISTER_INI_ENTRIES();
	    return SUCCESS;
	}

	PHP_FUNCTION(hello_world)
	{
	    RETURN_STRING("Hello World", 1);
	}

	PHP_FUNCTION(hello_long)
	{
	    if (HELLO_G(direction)) {
	        HELLO_G(counter)++;
	    } else {
	        HELLO_G(counter)--;
	    } 

	    RETURN_LONG(HELLO_G(counter));
	}

	PHP_FUNCTION(hello_double)
	{
	    RETURN_DOUBLE(3.1415926535);
	}

	PHP_FUNCTION(hello_bool)
	{
	    RETURN_BOOL(1);
	}

	PHP_FUNCTION(hello_null)
	{
	    RETURN_NULL();
	}

###  接下来是什么？

在这个教程中，我们探寻了一个简单PHP扩展的结构，这个扩展向用户空间增加了函数，返回了值，声明了INI配置，跟踪了一个请求过程中的内部状态。

在下一个话题中，我们将要探寻PHP变量的内部结构，看看它们在一个脚本环境中是什么怎么样被存储，跟踪，以及维护的。当一个函数被调用时候，我们将要使用`zend_parse_parameters`来接收参数，然后探寻如何返回更复杂的结果，包括这次教程中所提及的`数组`，`对象`，以及`资源`类型。
