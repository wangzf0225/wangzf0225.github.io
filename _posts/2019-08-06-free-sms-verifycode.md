---
layout: post
title:  "不需要图形验证码的短信验证码接口（免费）"
date: 2019-08-06 18:33:26 +0800
author : Invo
categories: original
---

今日收集了几个不需要图形验证码的短信验证码接口，其中有几个在使用了一段时间以后发现被加了图形验证码，还有两个链接可以保留，但是要注意的是短信内容不能定制，只能作为不带内容提示的alert。

另外发现学而思和自如的app上可以通过手机获得验证码，也不需要图形验证码，但是没有转。

下面给出现在还能用的两个接口的请求地址。

```
curl 'https://healthyhappy.heidianer.com/api/customers/send_code/' -H 'Origin: https://healthyhappy.heidianer.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36' -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' -H 'Referer: https://healthyhappy.heidianer.com/account/login?grant_type=code&next=' -H 'Cookie: _hs_front_session=1431542975436636; wx_config=%7B%22appId%22%3A%22wx3b0f9bf95fc3ab10%22%2C%22timestamp%22%3A%221542975436%22%2C%22nonceStr%22%3A%22cpbkqxfc1fc7gta%22%2C%22signature%22%3A%22b1ef4c81cfb5de7bdad4130b8fef710f85a17acc%22%2C%22jsApiList%22%3A%5B%22onMenuShareTimeline%22%2C%22onMenuShareAppMessage%22%5D%7D; ajs_user_id--heyshop_customer=null; ajs_group_id--heyshop_customer=null; ajs_anonymous_id--heyshop_customer=%2279bdacf4-95de-4952-a449-f7ea0b1cd291%22; _ga=GA1.2.229316599.1542975438; _gid=GA1.2.1546271902.1542975438' -H 'Connection: keep-alive' --data-binary '{"mobile":"$你的手机号码"}' --compressed
```

```
curl 'https://www.offcurrent.com/api/customers/send_code/' -H 'Origin: https://www.offcurrent.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36' -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' -H 'Referer: https://www.offcurrent.com/account/login?grant_type=code' -H 'Cookie: _hs_front_session=8071542975921511; wx_config=%7B%22appId%22%3A%22wx3b0f9bf95fc3ab10%22%2C%22timestamp%22%3A%221542975921%22%2C%22nonceStr%22%3A%22ptuu3xvakygu8uu%22%2C%22signature%22%3A%22fc597964a6bc5ab8ee734675757804637a80886d%22%2C%22jsApiList%22%3A%5B%22onMenuShareTimeline%22%2C%22onMenuShareAppMessage%22%5D%7D; ajs_user_id--heyshop_customer=null; ajs_group_id--heyshop_customer=null; ajs_anonymous_id--heyshop_customer=%226b6940a9-c24d-40d3-b02c-4a24fd284ea9%22; _ga=GA1.2.1723923137.1542975922; _gid=GA1.2.545666786.1542975922; _gat=1' -H 'Connection: keep-alive' --data-binary '{"mobile":"$你的手机号码"}' --compressed
```
