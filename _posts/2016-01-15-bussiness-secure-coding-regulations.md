---
layout: post
title:  "业务安全编码规范"
date: 2016-01-15 11:06:26 +0800
author : Invo
categories: original
---

说明：这套编码规范是以在MOMO长期测试发现的漏洞为基础，结合OWASP编码规范提炼的一个业务层的安全要点规范。看起来有点low，也没有很强的可移植性，但是就MOMO本身的业务而已，这套规范完全覆盖了线上业务70%到80%的安全漏洞，因此，这个规范也可以看做是一个业务层场景下的安全基线。由于能力有限，其中的错误不可避免，欢迎大家指出，如果有其他的不全面的地方，也欢迎大家补充。



### 1.会话

|序号	|内容	|细节&目的|
|:---:|:---|:---|
|1|	仅在服务器上创建会话标识符(sessionID)	|使用基类代码统一对每一个用户创建sessionID，sessionID具有统一的格式<br>目的：<br>1.避免会话丢失<br>2.降低会话被劫持的风险|
|2|	sessionID应有效抗碰撞	|sessionID的值尽可能随机，不易被预测（尽量不要携带与用户身份相关联的公开信息）<br>目的：<br>1.避免sessionID被猜测到<br>2.避免会话管理混乱（多个用户对应一个sessionID）|
|3|	仅在Cookie中保存sessionID	|使用Cookie作为固定的sessionID传输载体，如果是web应用，在set-cookie时设定最小使用范围的domain和path<br>目的：<br>1.避免web sever在日志中记录sessionID信息<br>2.防止被XSS跨域攻击|
|4|	一个用户同一时间只维持一个会话有效	|一个用户在生成新的会话的时候，应该终止同一用户上一个会话的生命周期。<br>目的：<br>1.降低会话被劫持的风险|
|5|	注销功能应当完全终⽌止相关的会话或连接	|目的：1.降低会话被劫持的风险|



### 2.支付

|序号	|内容	|细节&目的|
|:---:|:---|:---|
|6|	关键参数在服务器端签名（订单号、商品ID、⾦额、数量）|	将所有交易参数发送给服务器端生成一个校验和，并回传给客户端<br>目的：<br>1.防止调用支付功能时交易参数被篡改|
|7|	签名算法不可被猜测到|	服务器端的签名算法的设计应该尽可能复杂，避免被破解<br>目的：<br>防止客户端篡改参数和校验和|
|8|	以订单号为索引记录对应所有商品信息|	如果遇到比较复杂的交易逻辑，如他人代付或礼品赠送，每一笔交易支付后的回调或接口通信中传递参数，尽可能在生成订单时记录交易的商品ID、金额、数量<br>目的：<br>1.避免客户端篡改参数|
|9|	订单号应当在服务器端生成并且不可重复|	对每一笔交易在服务器端生成唯一的订单号，不接受用户指定的订单号。<br>目的：<br>1.避免逻辑错误|
|10|	已经完成交易的订单号不可重复使⽤|	"支付回调时核准订单号，对于已经完成过的订单号不可重复使用<br>目的：<br>1.防止支付成功的订单被多次使用（例如多次发放商品等）|



### 3.上传

|序号	|内容	|细节&目的|
|:---:|:---|:---|
|11|	限定上传文档类型	|只允许上传业务需要的文件类型<br>目的：<br>1.防止含有恶意脚本的文件被上传|
|12|	在服务器端校验⽂文件类型	|所有在客户端做的文件类型检测不能作为文件类型检测的依据，只能用来改善用户体验，文件类型检测要在服务器上执行。<br>目的： <br>1.防止文件类型检测被绕过|
|13|	保存在webroot以外的目录,并去掉执⾏权限	|主要业务的上传文件应当存储在专门的文件服务器上，或者存放在web应用服务器非web目录中。存放文件的目录要去掉可执行权限。<br>目的：<br>1.控制上传文件的权限，避免被执行。|
|14|	多媒体文件可执⾏一次压缩或格式变换后再存储	|对于多媒体文件，可使用压缩和转码函数对数据进行转换。<br>目的：<br>1.破坏上传文件中的恶意代码"|
|15|	在预先设置路径列表中索引文件目录路径	|将使用到的目录路径，用常量的方式写死在代码中，不能使用用户传递上来的文件路径。<br>目的：<br>1.用户输入不可信，避免攻击者拼接路径越权访问操作系统上的文件。|



### 4.验证码

|序号	|内容	|细节&目的|
|:---:|:---|:---|
|16|	验证码验证成功后再执⾏行其他操作|	在执行所有功能性操作之前，首先检查验证码。如果验证码错误，不执行其他操作。<br>1.避免验证码被绕过<br>2.避免验证码未被绕过，但是泄露敏感信息|
|17|	验证码应在一段时间后过期|	验证码应设置合理的过期时间，尤其对于纯数字的验证码。<br>目的：<br>1.防止暴力破解。|
|18|	验证码应当在使⽤用一次后过期|	图形验证码：验证码应当在提交一次以后过期（以收到的verify_code为依据）<br>手机验证码：在正确提交一次以后过期，提交接口应具备一定的时间和频率限制<br>目的：<br>1.防止被暴力破解|
|19|	图形验证码在不应以文本形式传递到客户端|	"图形验证码的明文不能以任何方式传递到客户端，一些开发会把验证码发到客户端在前端做验证，这种做法是错误的。<br>目的：<br>1.防止图形验证码被绕过|



### 5.输入验证和输出编码

|序号	|内容	|细节&目的|
|:---:|:---|:---|
|20|	在服务器上执行所有的输入输出编码|	在服务器上执行所有的输入输出编码。|
|21|	将数据源分为可信和不可信，所有不可信数据都要进行输入验证和输出编码。|	不信任所有的用户输入，分别为输入输出的数据，制定统一的编码规则，对输入前的数据进行验证，对输出前的数据进行编码。<br>目的：<br>1.概括的说，防止数据被当做代码被执行。|
|22|	对进行了编码的数据在字符解码后进行输入数据的验证|	首先应该保证解码后的数据只包含ASCII字符，其次应该在解码后进行验证。<br>目的：<br>1.防止一些因编码引起的验证和转义的绕过|
|23|	不信任用户输入|	一切用户的输入都不可信任，包括所有参数、URL、HTTP 头信息(比如:cookie 名字和数据值)|
|24|	验证正确的数据类型、数据范围、数据长度|	对用户输入的数据进行限定，可以防止很大一部分恶意输入。<br>目的：<br>1.限制恶意用户构造恶意的脚本或数据。|
|25|	部分需要编码的字符|	1.常规的< > " ' % ( ) & + \ \' \" <br>2.验证%0d, %0a, \r, \n<br>3.验证路径替代字符“点-点-斜杠”(../或 ..\)，如果支持 UTF-8 扩展字符集编码,验证替 代字符: %c0%ae%c0%ae|



### 6.其他

|序号	|内容	|细节&目的|
|:---:|:---|:---|
|26|	验证数据的属主以防⽌平⾏权限问题|	对用户的数据进行写操作时，应当判断当前用户是否对这项数据拥有权限，仅当确认用户具有这项权限时才能进行操作。<br>目的：<br>1.避免越权修改和删除他人数据。|
|27|	多级步骤操作对每一步结果验证|	某些应用的功能，需要用户在多个步骤上提交数据，甚至根据不同的状态走入不同的流程分支。后端程序应该在用户执行的每一个步骤记录一个状态，每开始新的一步操作，都应该检查上一步状态是否符合预期。对于不存在或异常的状态，应该及时中断或跳出。<br>目的：<br>1.避免攻击者绕过前面的逻辑判断，直接执行最终的结果。|
|28|	对参数进⾏行非空校验|	由于一些逻辑上的疏漏，以及后端的底层应用（数据库、中间件或编程语言）上的特性，空字符串在进行处理的时候可能会出现预期外的结果。应该尽力保证用户传入的参数是符合预期的。<br>目的：<br>1.检查是否存在用户没有传输的参数或内容为空的参数。|
|29|	获取陌陌ID应当⽤cookie查询|	应该严格的，使用sessionID这类会话标识符作为身份判断的依据，不应该接受用户上传的momoid。<br>目的：<br>1.防止用户上传momoid引起的越权操作|