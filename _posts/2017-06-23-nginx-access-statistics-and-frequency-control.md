---
layout: post
title:  "[转]Nginx访问计数和频率控制"
date: 2017-06-23 16:06:26 +0800
author : liulantao
categories: note
---
From:[Nginx访问计数和频率控制](http://blog.liulantao.com/blog/2016/2016-12-20-nginx-counter-and-ratelimit-with-lua-redis.html)

在使用了负载均衡设施的网站中，对 HTTP 请求做访问控制（频率控制）是个经常遇到的需求。

频率控制的主要目的，传统应用场景中要**_保护后端系统_**。

在多租户的云服务上，通过频率控制**对不同租户的资源使用量进行有效分配**，从而避免相互影响访问质量。

### Nginx 的频率控制

`Nginx` 是现在最常见的负载均衡软件，比较早的版本即有频率控制功能。

Nginx 中通常采用模块的形式提供各种功能，频率控制方面常用的有两个模块：

*   [ngx_http_limit_req_module](http://nginx.org/en/docs/http/ngx_http_limit_req_module.html)

针对指定的 key，限制`请求处理频率`。

*   [ngx_http_limit_conn_module](http://nginx.org/en/docs/http/ngx_http_limit_conn_module.html)

针对指定的 key，限制`同时连接数`。

这两个模块是按秒或分的时间精度来限制，使用 `10r/s` 或 `1r/m` 这种方式能够比较容易配置。 `Tengine` 改进了频率控制相关功能，但是仍然简单粗暴，支持的策略比较少，难以满足个性化的时间窗口需要。。

另外，以上2个模块针对进程级别做控制，多个 Nginx 部署之间不共享数据。

实际部署中，`Nginx` 作为负载均衡设施，一般会部署多台组成集群。 这时的目的是对这个集群进行保护，不是对单个server的访问限制，所以基于单机的限制有了明显的局限性。

### 频率控制系统的设计目标

这样一个频率控制系统，我们有以下设计目标：

1.  状态数据共享

    从单机限制到集群化整体限制，需要有统一维护状态的存储

2.  简化配置

    数据metrics可定制key，尽量减少（各种判断）逻辑

3.  资源消耗低

    高效的字符串操作

    网络流量低，使用长连接

4.  实时反馈

    可允许边缘情况限制部准确，但是不能有延时。

    这也决定了基于日志分析的方案不能达到。

5.  数据持久化

    历史数据保存，可追溯

6.  失败保护

    作为辅助系统，内部失败时应该能使对外服务正常进行。

根据实际业务需求协商确定出公认的目标，是实现的关键步骤。

### 架构设计

在设计目标指引下，选择使用稳定高效的开源软件来实现。 最终形成了 `Nginx` + `Lua` + `Redis` 的方案。

基于负载均衡层的流控系统，可以串联部署在负载均衡后端，作为应用层的代理，也可以并联部署在负载均衡后端旁路。 我们采用了旁路的方式来部署。

架构图：

![Loadbalancer Ratelimit](/images/diagram/loadbalancer-ratelimit-architecture.png)

#### 组件失败保护：

*   Nginx 作为基础服务，有前端 keepalived 提供故障转移
*   Lua 作为配置的一部分，上线前经过测试环境的单元测试验证
*   Redis 出现宕机导致失败后，可以选择直接跳出控制逻辑，根据实际情况默认返回允许或拒绝。

### 关键配置

#### 1\. 规范化频率控制的键

针对每个请求URL，使用 `nginx` 的 `map` 功能或 `location regex` 进行提取，并规范化为限制规则使用的键名。

<figure class="highlight">

```
location ~* ^/(?P<org_name>[0-9a-zA-Z-_]+)/(?P<app_name>[0-9a-zA-Z-]+)/users$
{
    set $ratelimit_metric "$org_name#$app_name#users"

	proxy_pass http://backend_rest_servers;
}
```

</figure>

我们将 URL 中提取的信息使用 `set` 语法拼接，将它保存在 `$ratelimit_metric` 变量作为频率控制的键，

#### 2\. 加载 lua

lua 基础功能需要在 nginx 编译阶段指定选项。如果当前版本不支持 lua 功能，需要重新编译，并在编译时至指定 `--with-lua` 选项。

<div class="highlighter-rouge">

```
./configure --with-lua

```

</div>

实现逻辑时需要访问 `redis`，因此还需要加载 lua 的 redis 库：[lua-resty-redis](https://github.com/openresty/lua-resty-redis)。

在配置文件的 `http` 上下文部分加一行配置：

<div class="highlighter-rouge">

```
lua_package_path "lua/lua-resty-redis/lib/?.lua;;";

```

</div>

然后加载我们实现逻辑的 lua 脚本，之后的所有逻辑操作都在这个文件中完成。

<div class="highlighter-rouge">

```
access_by_lua_file 'ratelimit-with-redis.lua';

```

</div>

#### 3\. 初始化 redis 连接

首先加载 lua 的 redis 库，设置合理的超时时间。 当连接失败时，则直接从限流逻辑中跳出。

<figure class="highlight">

```
local cjson = require "cjson"
local redis = require "resty.redis"
local red = redis:new()

red:set_timeout(1000)

local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
	-- ngx.say("failed to connect: ", err)
	return
end
```

</figure>

#### 4\. counter incr 操作

对于每一次客户请求，都需要去更新指定的 key。

<figure class="highlight">

```
local counter_key = ngx.var.ratelimit_metric
-- ngx.say("counter key: ", counter_key)

count, err = red:incr(counter_key)
if not count then
	-- ngx.say("failed to incr: ", err)
	return
end
```

</figure>

#### 5\. 根据键值控制访问

假定默认限制超过 100 次后，对后续访问进行限制，返回状态码 429。

<figure class="highlight">

```
if count > 100 then
	ngx.status = 429
	--ngx.say("fooc: ", ok)
	ngx.say("rate limit: ", count, " > ", 100)
	ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end
```

</figure>

#### 6\. 与 Redis 保持长连接

<figure class="highlight">

```
local ok, err = red:set_keepalive(100000, 20)
if not ok then
	-- ngx.say("failed to set keepalive: ", err)
	return
end
```

</figure>

#### 7\. 时间维度限制

前面示例所做的限制没有考虑时间维度，即超出限制被禁后，不会随时间清零。 现在我们改造一下 key 的格式，使得 counter 只在一个时间周期内有效。

修改 counter_key 的定义：

<figure class="highlight">

```
local counter_key = time()/60 .. ":" .. ngx.var.ratelimit_metric
```

</figure>

#### 8\. 读取 limit 上限设置

<figure class="highlight">

```
limit, err = red:get("limit:" .. ngx.var.ratelimit_metric)
if not limit then
	-- ngx.say("use default limit: ", 100)
	limit = 100
end
```

</figure>

限制默认为 100

#### 9\. 利用 [Redis Pipelining](http://redis.io/topics/pipelining)

同一次请求会产生多个 redis 操作，没有前后依赖关系，使用 redis 的 batch 方式减少交互

red:init_pipeline

local results, err = red:commit_pipeline() if not results then ngx.say(“failed to commit the pipelined requests: “, err) return end print(cjson.encode(results))

for i, res in ipairs(results) do if type(res) == “table” then if not res[1] then ngx.say(“failed to run command “, i, “: “, res[2]) else – process the table value end else – process the scalar value end end

### 效果、功能与性能评估关键点

*   nginx `响应时间`的对比（proxy and static）
*   redis `连接数`
*   nginx 和 redis 的 `cpu 利用率`
*   redis `failover`
*   边缘情况测试

可以使用 `ab (apache benchmarking)` 进行测试。

### 思路总结

最终方案中，各部分功能都采用了成熟的开源方案，有一些综合的优势：

*   需要的代码量比较小
*   在性能和稳定性方面能够满足较长时间的需求
*   Redis 容量可以通过 codis 等工具进一步扩展

但是在使用场景方面有局限性，针对 HTTP 数据都分析则不适合。 如果遇到与业务深度分析的场景时，Nginx 端实现则会有比较大的代价，既包括人工付出，也可能有一些性能方面的退化。 比如针对 API 请求中的 JSON 数据做有效性校验，使用 lua 去处理业务逻辑，以及容错方面的代码量将显著增加。 从开发成本来看这不是一个好的选择，对 Nginx 维护人员的能力也是挑战。

### 展望

可以进一步优化为使用 redis scripting(也是 lua 脚本)，将所有逻辑放到 redis 中实现。 既能够达到现有方案使用 [Redis Pipelining] 的降低延时效果，还能进一步减少 nginx <-> redis 之间的读写操作次数，从而进一步降低延时。


