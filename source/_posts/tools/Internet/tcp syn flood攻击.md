[原文链接](https://blog.csdn.net/hengyunabc/article/details/24934529)

[TOC]

# 简介
TCP协议要经过三次握手才能建立连接

于是出现了对于握手过程进行的攻击。攻击者发送大量的 `SYN` 包，服务器回应( `SYN+ACK` )包，但是攻击者不回应 `ACK` 包，这样的话，服务器不知道( `SYN+ACK` )是否发送成功，默认情况下会重试 `5` 次（ `tcp_syn_retries` ）。这样的话，对于服务器的内存，带宽都有很大的消耗。攻击者如果处于公网，可以伪造 `IP` 的话，对于服务器就很难根据 `IP` 来判断攻击者，给防护带来很大的困难。

# 攻与防

## 攻击者角度

从攻击者的角度来看，有两个地方可以提高服务器防御的难度的：

- 变换端口  
- 伪造 `IP` 

变换端口很容易做到，攻击者可以使用任意端口。

攻击者如果是只有内网 `IP` ，是没办法伪造 `IP` 的，因为伪造的 `SYN` 包会被路由抛弃。攻击者如果是有公网 `IP` ，则有可能伪造 `IP` ，发出 `SYN` 包。（TODO，待更多验证）

## hping3

`hping3` 是一个很有名的网络安全工具，使用它可以很容易构造各种协议包。

用下面的命令可以很容易就发起 `SYN` 攻击：


```
sudo hping3 --flood -S -p 9999  x.x.x.x
#random source address
sudo hping3 --flood -S --rand-source -p 9999  x.x.x.x
```

> --flood 是不间断发包的意思  
-S   是SYN包的意思  

更多的选项，可以 `man hping3` 查看文档，有详细的说明。

如果是条件允许，可以伪造 `IP` 地址的话，可以用 `--rand-source` 参数来伪造。

我在实际测试的过程中，可以伪造 `IP` ，也可以发送出去，但是服务器没有回应，从本地路由器的统计数据可以看出是路由器把包给丢弃掉了。

我用两个美国的主机来测试，使用

```
sudo hping3 --flood -S  -p 9999  x.x.x.x
```

发现，实际上攻击效果有限，只有网络使用上涨了，服务器的 `cpu` ，内存使用都没有什么变化：

![Image](https://img-blog.csdn.net/20140512025751562)

为什么会这样呢？下面再解析。

## 防御者角度

从防御者的角度来看，主要有以下的措施：

- 内核参数的调优  
- 防火墙禁止掉部分 `IP`  

linux内核参数调优主要有下面三个：

- 增大 `tcp_max_syn_backlog`  
- 减小 `tcp_synack_retries`  
- 启用 `tcp_syncookies`  

### tcp_max_syn_backlog

从字面上就可以推断出是什么意思。在内核里有个队列用来存放还没有确认 `ACK` 的客户端请求，当等待的请求数大于 `tcp_max_syn_backlog` 时，后面的会被丢弃。

所以，适当增大这个值，可以在压力大的时候提高握手的成功率。手册里推荐大于 `1024` 。

### tcp_synack_retries

这个是三次握手中，服务器回应 `ACK` 给客户端里，重试的次数。默认是 `5` 。显然攻击者是不会完成整个三次握手的，因此服务器在发出的 `ACK` 包在没有回应的情况下，会重试发送。当发送者是伪造 `IP` 时，服务器的 `ACK` 回应自然是无效的。

为了防止服务器做这种无用功，可以把 `tcp_synack_retries` 设置为 `0` 或者 `1` 。因为对于正常的客户端，如果它接收不到服务器回应的 `ACK` 包，它会再次发送 `SYN` 包，客户端还是能正常连接的，只是可能在某些情况下建立连接的速度变慢了一点。

### tcp_syncookies

根据 `man tcp` 手册， `tcp_syncookies` 是这样解析的：

> tcp_syncookies (Boolean; since Linux 2.2)  
        Enable TCP syncookies. The kernel must be compiled with CONFIG_SYN_COOKIES. Send out syncookies when the syn backlog queue of a socket overflows. The syncookies feature attempts to protect a socket from a SYN flood attack. This should be used as a last resort, if at all. This is a violation of the TCP protocol, and conflicts with other areas of TCP such as TCP extensions. It can cause problems for clients and relays. It is not recommended as a tuning mechanism for heavily loaded servers to help with overloaded or misconfig‐ured conditions.For recommended alternatives see tcp_max_syn_backlog, tcp_synack_retries, and tcp_abort_on_overflow.

当半连接的请求数量超过了 `tcp_max_syn_backlog` 时，内核就会启用 `SYN cookie` 机制，不再把半连接请求放到队列里，而是用 `SYN cookie` 来检验。

手册上只给出了模糊的说明，具体的实现没有提到。

## linux下SYN cookie的实现

`SYN cookie` 是非常巧妙地利用了 `TCP` 规范来绕过了 `TCP` 连接建立过程的验证过程，从而让服务器的负载可以大大降低。

在三次握手中，当服务器回应（ `SYN + ACK` ）包后，客户端要回应一个 `n + 1` 的 `ACK` 到服务器。其中n是服务器自己指定的。当启用 `tcp_syncookies` 时， `linux` 内核生成一个特定的 `n` 值，而不并把客户的连接放到半连接的队列里（即没有存储任何关于这个连接的信息）。当客户端提交第三次握手的 `ACK` 包时， `linux` 内核取出 `n` 值，进行校验，如果通过，则认为这个是一个合法的连接。

`n` 即 `ISN` （ `initial sequence number` ），是一个无符号的32位整数，那么 `linux` 内核是如何把信息记录到这有限的 `32` 位里，并完成校验的？

首先，`TCP` 连接建立时，双方要协商好 `MSS` （ `Maximum segment size` ），服务器要把客户端在 `ACK` 包里发过来的 `MSS` 值记录下来。

另外，因为服务器没有记录 `ACK` 包的任何信息，实际上是绕过了正常的 `TCP` 握手的过程，服务器只能靠客户端的第三次握手发过来的 `ACK` 包来验证，所以必须要有一个可靠的校验算法，防止攻击者伪造 `ACK` ，劫持会话。

### linux是这样实现的：

1. 在服务器上有一个 `60` 秒的计时器，即每隔 `60` 秒，`count` 加一；

2. `MSS` 是这样子保存起来的，用一个硬编码的数组，保存起一些 `MSS` 值：

```
static __u16 const msstab[] = {
	536,
	1300,
	1440,	/* 1440, 1452: PPPoE */
	1460,
};
```

比较客户发过来的 `mms` ，取一个比客户发过来的值还要小的 `mms` 

...(省略中间的c代码实现)

可以看到 `SYN cookie` 机制十分巧妙地不用任何存储，以略消耗 `CPU` 实现了对第三次握手的校验。

但是有得必有失，`ISN` 里只存储了 `MSS` 值，因此，其它的 `TCP Option` 都不会生效，这就是为什么 `SNMP` 协议会误报的原因了。

### 更强大的攻击者

`SYN cookie` 虽然十分巧妙，但是也给攻击者带了新的攻击思路。

因为 `SYN cookie` 机制不是正常的 `TCP` 三次握手。因此攻击者可以构造一个第三次握手的 `ACK` 包，从而劫持会话。

攻击者的思路很简单，通过暴力发送大量的伪造的第三次握手的 `ACK` 包，因为 `ISN` 只有 `32` 位，攻击者只要发送全部的 `ISN` 数据 `ACK` 包，总会有一个可以通过服务器端的校验。

有的人就会问了，即使攻击者成功通过了服务器的检验，它还是没有办法和服务器正常通讯啊，因为服务器回应的包都不会发给攻击者。

刚开始时，我也有这个疑问，但是 `TCP` 允许在第三次握手的 `ACK` 包里带上后面请求的数据，这样可以加快数据的传输。所以，比如一个 `http` 服务器，攻击者可以通过在第三次握手的 `ACK` 包里带上 `http get/post `请求，从而完成攻击。

所以对于服务器而言，不能只是依靠 `IP` 来校验合法的请求，还要通过其它的一些方法来加强校验。比如 `CSRF` 等。

 **值得提醒的是即使是正常的 `TCP` 三次握手过程，攻击者还是可以进行会话劫持的，只是概率比 `SYN cookie `的情况下要小很多。** 

[详细的攻击说明](http://www.91ri.org/7075.html)

# 总结

对于 `SYN flood` 攻击，调整下面三个参数就可以防范绝大部分的攻击了。

- 增大 `tcp_max_syn_backlog`  
- 减小 `tcp_synack_retries`  
- 启用 `tcp_syncookies`  

貌似现在的内核默认都是开启 `tcp_syncookies` 的。

 