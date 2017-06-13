---
layout: post
title:  "账号安全的异常检测"
date: 2016-04-14 16:06:26 +0800
categories: 原创
---

## 摘要

这篇文章收集了一些学术界和著名的社交网络公司在针对异常账号的识别和检测的研究成果，总结了常见的几种算法，并对比其优劣。希望能在这篇文章的基础上，针对陌陌的实际情况，和大家共同探讨出一套可行的工程实践方案，解决账号安全这个“老大难”问题。

## 0x00 引言

在线社交网络（Online Social Networks, OSN）也称为社会媒体网络（Social Media Networks，SMN）或社交网站（Social Network Sites，SNS），它是Web2.0时代的产物。社交网络出现，给人们的生活增添了许多新的方式。社交网络具有用户规模大、响应速度快的特点，而这些社交网络与生俱来的优势，也成为不法分子谋取利益的温床：他们会通过注册僵尸账号，或者盗用正常用户的帐号，在社交网站中发布广告、色情、钓鱼等恶意信息 ，通过不法交易或者诈骗等行为获得经济利益；也有一部分极端分子，利用社交网络扩散虚假、煽动性甚至恐怖信息。这些因素都会对在线社交网络的信誉评价体系以及用户的信任关系产生严重危害。


总体而言，异常帐号检测主要涉及3方面的内容：

（1）异常帐号的表现。


（2）检测方案的设计。


（3）检测方案的验证。


## 0x01 异常账号的表现

社交网络是近些年非常热门的一类互联网应用，它具有用户规模大、产品形态丰富的特点，因此，不同的类型的社交产品账号具有形态各异的表现。此外，帐号的表现是一个变化的过程，在用户使用账号的不同阶段，其表现会有差异。账号异常检测的目标，就是选取合适的维度，将正常的账号和异常账号的表现区分开。

在过去的实践中，我们往往通过观察正常账号和异常账号的行为特征的差异来区分这两者。例如，正常账号通常来自一个IP地址，而这个IP地址也只能登录一个或者极少数几个账号，但是对于异常账号的控制者而言，他们会用一个IP去登录很多账号；再比如，一个正常用户的账号访问服务器的时间分布是随机的，并且平均频率低于1次/秒，但是异常账号会在一秒内发出多次请求，对于某些特定的应用接口，访问的时间间隔高度接近。通过对这些规律的总结和归纳，我们可以开发出一些方法对攻击者进行防御，但是越是明显的特征往往也越容易被绕过——也就是说，这样的方法的鲁棒性较弱。

今年来，不少学术界和工业界的科学家和工程师运用数据科学的知识探索出一些新的方法，这些方法利用数据挖掘算法将数据中一些隐蔽的规律特征——甚至是无法用语言描述的特征——发现出来。在这个方向上，对于异常账号检测的方法论正在逐渐形成。

其实，账号异常检测会运用到许多领域的研究成果，例如异常检测、基于图的异常检测、垃圾信息检测等。一些文章将检测方案归纳为为基于行为特征、基于内容、基于图以及无监督学习。由于涉及的技术多样切复杂，我们这里不对所有的方案进行讨论。

## 0x02 异常账号的分类

异常账号是描述一类行为异常的账号的统称。实际上，异常账号这个概念在不同的角度会有不同的表述。按照异常账号表现形式的不同，我们可以将其划分为以下几个类别：


(1） 僵尸帐号(Social Bot），即由攻击者通过自动化工具创建的虚假帐号，能够模拟正常用户的操作如发布消息、添加好友等。

(2） Sybil/Spam 帐号，指攻击者创建的用于隐蔽攻击的虚假身份账号。帐号主要用来发布广告、钓鱼、色情等信息，或用来恶意改变社交网络中的信誉，如恶意互粉、添加好友、点赞等行为。Spam账号是Sybil账号在应用阶段的统称。

(3） Compromised帐号，即被劫持帐号。这些帐号原本是正常帐号，但被攻击者劫持来执行恶意行为。

不同类别的账号所应用的检测方法也有差别，例如针对Spam帐号的检测主要侧重于恶意行为和恶意内容的特征，而针对 Compromised 帐号的检测主要利用帐号行为的突变来进行。基于这个原因，我们必须提一下Spam Campaign这种类型，它操纵大量虚假帐号以及盗用的Compromised帐号在集中时间段来传播恶意信息或执行其他恶意行为，称其为 SpamCampaign，这种类型的账号 可能包含僵尸账号、spam账号以及被劫持的账号等。针对这一类账号的检测主要通过这些帐号在同一时间段内的群体行为，如同时发布相同消息或者同时点赞某个页面等。

这几类帐号的分类不是绝对的也不是互相排斥的，只是为了更好的标识异常帐号在不同阶段的不同表现。

## 0x03 检测方法的分类

这些年针对在线社交网络异常账号检测在学术界和工业界提出了大量的方案。根据国内研究者的总结，这些方法大概可以被归纳为4个类型：

* 基于行为特征
* 基于内容
* 基于图
* 无监督学习


|分类|思想|特征|方法|
|:--:|:--:|:--|:--|
|基于行为特征| 分类	|用户行为特征|有监督|
|基于内容	|分类|消息内容|有监督|
|基于图 	|图中的异常检测|图结构|无监督|
|无监督学习| 	聚类/模型|multi|无监督|


##### 1.基于行为特征

异常账号的目的是通过恶意行为获得经济利益，为了追求更高的回报，总会设法提高各类恶意操作的频率。异常账号的某些行为特征与正常的账号之间必然会有分别。基于行为特征的检测方案，可以看做数据挖掘中的分类问题——也就是说，检测者需要收集各种各样的行为特征，这些特征具备区分正常用户和异常用户的属性，通过选择某一特定的特征，将这个特征下采集到的数据样本分类，从而筛选出异常的账号。有时候一个特征就可以满足这个需求，而有时候需要多个特征结合起来才能形成区分度。

前面提到过，选取不同的特征可以检测不同类型的异常账号。比如提提取账号注册的时间、ip分布、注册时的手机号可以检测僵尸账号，利用消息发布的频率、评论数、相似度等可以用来检测spam账号。下表引用了张玉清教授等人总结的特征的类型。

|类别 |特征|
|:---:|:--|
|用户个人信息 |用户名长度、用户简介长度、帐号注册时间、用户名命名规则、被访问次数|
|用户行为 |消息发布时间间隔、评论回复时间、帐号注册流程、帐号点击顺序、点赞数|
|好友关系 |好友数、粉丝数、关注数、好友请求/好友数、关注数/粉丝数、好友网络聚类系数、二阶好友数、二阶好友消息数|
|消息内容 |消息中 URL 比率、#比率、@比率、消息相似度、消息单词数、消息字符数、评论数、Spam 关键词数、消息来源、消息数量、消息转发次数|


根据相关研究的统计结论，基于行为特征的检测方法，选取特征的重要性比选择算法更重要。不同的特征对检测结果的贡献度有所不同。另外，行为特征的选取，除特征的有效性（贡献度）要高以外，鲁棒性也应当尽可能强。攻击者通过辨别防御者的策略会及时更改绕过策略，而鲁棒性强特征使攻击者不易发现。另外，通过采用在线学习的办法可以及时更新模型，即使攻击者改变行为方式也能实时自动化训练模型。

##### 2.基于内容的检测

异常账号发布的消息异于常人，否则与正常账号没有分别。根据工作实践的观察，我们遇到的最常见的是通过招呼、留言等方式发送招嫖信息给男性用户。那么检测消息中是否含有恶意内容，就可以发现这部分异常账号。

通过检测消息内容中被标记为恶意URL来识别实施钓鱼攻击的恶意账户，通过消息特征的突变来检测通过撞库等手段劫持的账号：通过时间、消息来源、消息语言、消息主题、消息中的链接、直接用户交互、邻近行等7个维度来建模，然后判断某一时间点之后的的消息是否与这个模型有所偏离来判定被盗的概率。

此外，攻击者会扩大消息的传播范围以扩大收益，而这些消息往往具有极高的相似性。一项针对Twitter的统计表明，约63%的消息是基于模板产生。他们根据这一特性设计了Tangram，将已知的恶意消息分割来生成匹配模板，然后用模板去检测更多的恶意消息。另一条可行的思路是将用户发送的消息进行聚类，找到发布大量相似消息的群组，如果这些消息被判定为恶意消息，则认为发布消息的账号属于恶意账户。这种方法已经在Facebook和Twitter得到运用。

然而，基于内容的检测与基于行为特征的检测一样，是有监督学习的方法。攻击者可以通过反复变化消息内容以达到绕过检测框架的目的。

##### 3.基于图的检测

在一个社交网络中，异常账号的社交关系——即它与其他账号的连接形态和结构——会与正常账号有所不同，这是因为异常账号的关系网络往往服务于牟利的目的，它的分布有异于正常用户关系网随机分散的特点。如果想模仿正常用户构建异常用户的关系网络，那么攻击者就必须花费大量成本。基于图的检测方案的本质是异常帐号与正常帐号在组成的图中具有不同的结构或者连接方式，因此基于图的检测方案关键是构造一个图，在图中异常帐号与正常帐号具有不同的结构或者连接方式，然后利用图挖掘的相关算法找到图中具体的异常结构或者异常节点。

在社交网络图中，正常账号和异常账号分别形成较密集的结构，而正常账号和异常账号之间存在稀疏的连接。目前利用图计算的异常挖掘检测方案主要有随机游走、社区发现以及其他特定业务场景下设计的方案。利用随机游走算法，通过计算节点与已知的正常节点之间的关系来判断帐号是否为异常，例如，通过随机游走算法选取一部分节点作为根节点，然后进行广度优先搜索，如果一个节点被搜索到的次数大于一个阈值，那么就判定为正常节点，否则为Sybil/Spam 节点。一些研究者认为基于随机游走算法的Sybil/Spam检测方案对于网络结构和攻击模型的假设在现实网络中并不成立。现实网络结构中正常节点并不是快速融合的而是形成多个社区结构，社区内是紧密联系而社区间存在稀疏的割边，而且攻击者创建的Sybil/Spam节点能够与其他正常节点建立大量的连接，因此利用随机游走算法的方案存在较大的误检率。因此将随机游走检测方案改进，由区分正常节点与 Sybil节点转变为判断正常节点所在社区内其他节点的正常概率，实验表明这种方案更有优势。

此外，社交网络中除了显性的好友关系图，还存在大量利用其他关系（如好友请求、点赞、分享和转发等关系）组成的隐性关系图。一些工作利用隐性关系组成的图来检测异常帐号。

##### 4.无监督学习的检测

基于行为特征和基于内容的检测方案都是有监督学习的方案，对分类器的训练需要提前对帐号状态进行标记，样本的数量与质量对于检测结果有较大的影响；基于图的检测方案尽管是无监督学习的，但是需要构建图结构。无监督学习的检测方案不需要提前对数据进行标记，因此能够更快的形成检测系统。根据具体的算法我们将方案分为两类：基于聚类和基于模型。

基于聚类的方案本质上也是一个数据挖掘的聚类问题。通过对帐号的某些特征进行聚类，将正常或者异常的账号聚位一类或几类，然后抽样检验，如果发现一类中正常或异常的比例超过某一阈值，就判定该类为非一个正常或者异常集。基于聚类的检测方案的关键是选择合适的特征对帐号进行聚类。一项针对twitter的研究使用了用户个人信息和消息内容进行聚类，而另一项试验使用了http请求的时间序列特征进行了聚类。这里需要提到一点，基于聚类的方法和前文所述的基于特征的检测方法是有差别的，因为基于特征的方法是一个分类问题，而分类问题需要事先对数据进行标记，然后选择不同的分类算法对数据进行分类。而聚类方法，只选择一些特征（维度），从中挖掘数据之间的共性和差异，以此将数据划分为若干个集合。

基于模型的方案的前提条件是认为正常用户的行为符合某种模型。因此，基于模型的特征要求使用大量正常账号进行训练形成模型，然后使用模型去识别异常的账号。腾讯的工程师在这个方向上的研究工作归纳出定义异常行为的两个指标：（1）同步值，即社交网络中异常帐号经常具有相同的行为；（2）异常值，即这些帐号的行为与大部分其他帐号的行为不同。通过计算这两个值，对于低于阈值的帐号判断为异常帐号。无监督学习的检测方案是目前异常帐号检测的新方向。无监督学习方案不需要提前对样本进行标识，因此能够检测到未知的恶意行为。


分类，是按照一些标准和规则，将样本打对应的标签，根据标签分类。聚类，是开始时没有标签，只能通过某种共性，找出对象之间存在的共性。聚类前不知道要划分成几个组，什么组，也不知道根据哪些规则来定义组。


## 0x04 小结

基于行为特征和基于内容的检测方案是有监督学习方案，优点是只要训练形成了分类器，就能够对异常帐号进行检测而且能够区分不同类别的异常帐号，检测准确率较高，但需要提前对样本数据进行标记，只能够检测已知的攻击类型，容易被攻击者绕过。基于内容的检测方案能够做到对异常帐号实时检测，但是只能够检测发布恶意消息的异常帐号。基于行为特征和基于内容的检测方案目前比较成熟，不单有理论的研究还有现实中大规模的部署。基于图的检测方案利用了图结构特征，抗扰动能力强，但是需要建立相应的图结构，检测的精度也较低，目前处于理论研究阶段，还没有形成大规模部署的经验。无监督学习方案不需要提前对样本数据进行标记，能够较快形成检测系统，同时能够检测未知的攻击行为，且不易被攻击者绕过，但是这种检测方案不容易区分不同类型的异常帐号，而且需要对大量数据进行学习。因此可以结合多种不同的检测方案，从不同的层次对异常帐号进行检测，如可以先采用无监督学习的方案检测未知的攻击行为，然后对攻击行为抽取特征，再利用有监督学习的方案进行检测。

