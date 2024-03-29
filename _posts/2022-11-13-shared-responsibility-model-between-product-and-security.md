---
layout: post
title:  "业务与安全的责任共担模型"
date: 2022-11-13 02:54:25 +0800
author : Mushen
categories: original
---

# 1 业务安全的责任主体与职责划分

云计算行业共同认可并实践“安全责任共担模型”，在全链路云服务中，云运营商只负责维护和监控基础设施的安全，而基于云计算建立的业务的安全应由客户自己负责。“安全责任共担模型”给了客户一个提醒，安全不能完全依赖云服务商，还要不断提升自身在应用层面的安全保障措施，毕竟应用层的管理权限完全在用户自己手中。
在云服务的内部，业务团队与安全团队之间也存在类似的责任共担模型。安全团队基于自身的专业能力提供相关的方法、工具等能力支持，但最终需要产品团队完成落地实践。没有良好的执行，所有的策略都将停留在纸面。

## 1.1 安全责任主体

业务团队是云计算信息安全责任的主体和第一安全责任人。从现代的信息安全治理方法论的角度看，信息安全和整个软件开发生命周期紧密相关，它不仅仅是一种能力，更是一种理念和方法。单独依靠某一个孤立的系统无法解决一项业务或一个组织整体的安全问题，因为安全问题可能出现在生产环节的方方面面。而就如云计算服务运营商于客户的关系一样，业务团队团队拥有对产品自身的管理权，因此解决风险和实现安全价值除了安全团队在与明处的入侵和攻击行为对抗以外，更多的是依赖业务团队团队将责任扎实落实。这种关系好比病人与医生、或者驾驶员与交警。无论医生和交警有多么强大的能力与特权，但是否认真配合治疗，是否遵守交通规则，是病人或驾驶员自身无法让别人替代的。

然而，这并不意味着安全团队不会承担任何责任。安全团队需要向对外提供的产品能力和服务负责，这既包括云计算安全防护基础设置的产品（包含运行于其上的各类规则）、各种内部安全工具和相关文档等有形的内容，也包括安全团队参与的产品架构和功能设计的安全属性和安全元素（如产品的身份认证、网络访问控制、加密与数据保护等）、各种内部DevOps工具平台的安全管控能力的设计、各种安全规范和最佳实践等无形的能力输出。安全团队在必要的场合需要获得某些特权，以确保安全策略在全局范围严谨地落地，例如配置全局统一的网络访问控制策略，或者在产品遭到入侵后登录到主机进行调查溯源，这些行为都需要很好的管理权限，安全团队同样也为此承担责任。总的来说，安全团队的职责有时处在一种略微妙的状态下，安全团队必须同时承担教练员和守门员的角色，这其中的尺度取决于组织的管理者对安全团队的定位。但无论如何，安全团队需要责权对等。

## 1.2 安全责任的识别与划分

业务团队与安全团队的责任划分可以用一个原则概括，即：谁管理谁负责，这也符合责权对等的管理理念。安全责任的识别有很多角度，根据工作程序，我们参考微软的的SDL安全开发生命周期模型设计安全责任识别的框架。

![微软SDL安全活动图](/assets/img/MS-sdl.png) 

根据SDL安全开发生命周期流程，软件的安全实施分为1.训练 2.需求 3.设计 4.执行 5.验证 6.发布 7.响应 共七个阶段。每个阶段的安全责任划分对应到业务和安全两个部门的情况如下表（少数情况下需要双方共同负责）。

|SDL阶段	|产品团队|安全团队 |双方共同|
|  :----:  | ----  |----  |----  |
|训练	|参加安全编码和安全规范的学习并通过考核。	|设计安全编码规约和安全规范，对产品开发人员进行培训和考核。||
|需求	|对产品的使用场景进行抽象，整理出产品的功能需求列表，并明确需要使用的用户数据和数据内容的类型，整理出产品的数据需求。|	根据产品的功能需求分析可能存在的交互风险，根据数据需求分析可能存在的数据泄露和隐私保护风险点，并依据这些风险点整理产品的安全需求列表。||
|设计	|依据相关的设计规约和最佳实践，按照产品需求（包括功能需求）完成产品的功能、交互、架构方案设计。	|根据产品的设计方案，评估其中的风险点，并提出安全方案（或改进建议）。||
|执行	|完成产品的编码开发工作。	|提供安全编码的最佳实践和自助工具，协助研发完成代码安全检查。|代码评阅和审计。|
|验证	|修复验证过程中发现的产品安全缺陷。	|对照产品的安全需求和安全方案（或改进建议）中的所有安全要求对产品进行黑白盒验证，同时根据安全工程师的经验对产品的编码实现和其他非常规使用场景的风险点进行挖掘。|常规验证过程由安全团队完成，个别场景需要产品研发配合共同完成。|
|发布	|发起产品的发布流程，并完成安全反馈意见的整改和确认。	|制定应急响应计划，并对产品最终状态进行安全检测和确认，完成审批流程。||
|响应	|协助安全工程师进行应急响应阶段的必要工作，执行业务连续性计划保障产品运行的稳定性。	|对安全实践执行应急响应。||

  <br>
  <br>


# 2 SDL落地实践


安全团队从SDL视角提供配套工具和能力，同时从攻防视角提供安全防护基础设施及其运营能力（在安全团队内部会有不同分工，相关说明将在后文中标注）。本章节介绍安全团队提供的产品和服务（可能重复的内容仅选择相关性较高的标题下介绍）。

## 2.1 架构安全

|  能力项   | 内容说明 |
|  :----  | ----  |
|产品架构评审 & 威胁建模	|以安全左移视角，在设计初期定义产品安全架构，零成本消除架构层面潜在安全风险。|
|安全架构技术方案设计	|针对产品自身的内部设计提出安全需求；结合产品应用场景，面向用户设计产品安全能力和实现方法。|
|定制化安全架构需求，设计解决方案  |根据业务诉求，依据场景定制产品安全架构，包括网络架构、软件架构、数据交互模型等。|
  
  <br>

## 2.2 风险识别与治理

|  能力项   | 内容说明 |
|  :----  | ----  |
|漏洞运营平台	|提供漏洞从通知到修复的管理链路|
|产品配置基线扫描平台	|检查某个产品依赖的内外产品、组件的配置是否满足安全规范|
|黑盒漏洞扫描平台	|检查产品系统、网络、应用、中间件等不同层面安全漏洞|
|白盒扫描平台	|自动化代码审计工具|
|供应链扫描平台	|扫描产品依赖的二三方组件的已知安全风险|
|敏感信息扫描平台	|自动化代码敏感信息扫描，发现AK、密码或其他不宜在代码中出现的敏感信息|
|SRC应急响应中心|收集外部报告的安全漏洞，从真实的对抗角度提示关键风险|
|SDL流程管理闭环	|在整个SDL链路中，将一个个具体问题抽象成事件，在统一的管理平台解决事件的全生命周期管理，例如流程的跟踪、事务审批、工单下发等。|
|核心管控系统安全监测	|针对核心管控系统进行渗透测试，发现自动化工具难以覆盖的真实安全风险。|
|外部漏洞收集与响应 |专项预算支产品外部漏洞收集，对有价值的漏洞进行复现，设计修复方案，并跟踪修复过程。|
  
<br>
  
## 2.3 产品安全设计与最佳实践

|  能力项   | 内容说明 |
|  :----  | ----  |
|产品安全能力设计方案	|从用户视角出发，提供产品应用场景下的安全功能和特性，提升安全维度的产品竞争力，满足用户侧安全功能需求，提升用户使用产品的安全感。|
|产品安全最佳实践	 |基于产品安全功能和特性，提供产品安全最佳实践文档。|
|产品安全测评支持	 |针对国内外主流咨询公司的产品测评，支持产品进行安全领域专业测评。|
  
  <br>

## 2.4 安全基础设施

|  能力项   | 内容说明 |
|  :----  | ----  |
|SOC运营平台	|产品发布审核管理平台|
|资产管理平台 |资产管理平台，包括域名、IP、账号等|
|云WAF	|在产品边界Web层抵御已知和未知风险|
|云防火墙	|在产品边界网络层抵御已知和未知风险|
|SIEM	|事件管理|
|安骑士	|主机层面入侵监测工具|
|灰盒扫描平台 |代码层运行态入侵监测工具|
  
  <br>

## 2.5 事件响应

|  能力项   | 内容说明 |
|  :----  | ----  |
|入侵检测	|基于安全威胁检测能力，提供面向产品的威胁告警。|
|应急响应	|发现入侵事件后，快速止血响应|
|黑灰产情报|监控黑灰产情报，打击犯罪团伙。|
|内容安全&风控	|识别涉黄涉政等内容安全风险、账号安全管控|
|漏洞应急响应服务	|处理内外发现的漏洞和应急事件，管理漏洞生命周期，确保漏洞如期修复。|
  
  <br>

## 2.6 攻防演练

|  能力项   | 内容说明 |
|  :----  | ----  |
|内部攻防演练	|以攻击者视角模拟真实入侵行为，挖掘产品和产线 内部应用的安全弱点，并在演练后提供整改建议。|
|国家、区域、行业攻防演练支持	|面对护网等重要场合，开启重保模式，全方位护航产品安全。护网相关事项全包，包括护网前安全建设和加固、护网过程的值班和响应、护网后的沙盘推演。|
  
  <br>

# 3 安全管理
业务团队团队是落实信息安全责任的主体，安全团队从安全管理的角度出发，设计安全管理流程，提供安全管理工具，与业务团队共同将安全责任落到实处。

## 3.1 安全规范

|  能力项   | 内容说明 |
|  :----  | ----  |
|代码编码安全开发指引	|代码编码的安全规约，帮助研发人员减少在编码阶段引入安全风险|
|安全规范与制度红线	|制定安全规范要求，定义违规行为和处罚原则，降低内部操作风险。|
|培训与考核	|安全红线、安全规范和安全意识培训和考试。|
 
  <br>

## 3.2 数据安全

|  能力项   | 内容说明 |
|  :----  | ----  |
|数据链路监控	|监控内部员工、外包的数据访问异常情况。|
|数据泄漏应急排查	|发生数据泄漏事件时，协同进行排查，快速定位泄漏源。|
  
  <br>

## 3.3 合规应答

|  能力项   | 内容说明 |
|  :----  | ----  |
|应审与应答	|针对外部监管机构的合规要求，提供合规证明材料，对需要整改的项目制定整改方案，支持业务方完成整改落地。|
  
<br>

# 4 小结

在建立安全运营体系的过程中，业务团队团队和安全团队必须相互依赖相互支持，而业务方必须要经历的重大思想转变，就是业务是安全的第一责任人。许多公司的管理团队要求安全团队为安全的最终效果兜底，实际上这样的制度设计很不科学。俗话说羊毛出在羊身上，那拔羊毛也要去羊身上拔，剃毛推子不长毛。本文从SDL的角度出发，借助“责任共担模型”的思路，尝试建立一个安全运营责任的全景图，并明确业务团队与安全团队的角色。从职责角度看，建立清晰的责任边界并定义共建区域，可以帮助双方理解各种职责和需要负责的结果。很多企业团队在建立这样的职责框架的过程中产生过不少摩擦、争执，也属于业务成长期的艰难探索，希望这篇文章介绍的思路能够帮助一些企业建立合理的责任和分工体系。

*Reference*


——————————

https://zhuanlan.zhihu.com/p/29822421  周璞  如何实现“默认安全”？这是云服务商的下一道考题
