[TOC]

[原文链接](https://www.cnblogs.com/peida/archive/2013/03/11/2953420.html)  
[参考文章](https://wangchujiang.com/linux-command/c/ss.html)  
[参考文章](https://www.cnblogs.com/machangwei-8/p/10352986.html)

ss是Socket Statistics的缩写。顾名思义，ss命令可以用来<font color="#dd0000">获取socket统计信息</font>，它可以显示和netstat类似的内容。但<font color="#dd0000">ss的优势在于它能够显示更多更详细的有关TCP和连接状态的信息</font>，而且比netstat更快速更高效。

> 1. 当服务器的socket连接数量变得非常大时，无论是使用netstat命令还是直接cat /proc/net/tcp，执行速度都会很慢。特别是当服务器维持的连接达到上万个的时候，差别非常明显。    
> 2. 而ss快的秘诀在于它利用到了TCP协议栈中tcp_diag。tcp_diag是一个用于分析统计的模块，可以获得Linux内核中第一手的信息，这就确保了ss的快捷高效。当然，如果你的系统中没有tcp_diag，ss也可以正常运行，只是效率会变得稍慢（但仍然比 netstat要快）

推荐直接使用 `ss` 代替 `netstat`

> 几乎所有的Linux系统都会默认包含netstat命令，但并非所有系统都会默认包含ss命令。
netstat命令是net-tools工具集中的一员，这个工具一般linux系统会默认安装的；ss命令是iproute工具集中的一员；  
net-tools是一套标准的Unix网络工具，用于配置网络接口、设置路由表信息、管理ARP表、显示和统计各类网络信息等等，但是遗憾的是，这个工具自2001年起便不再更新和维护了。
iproute，这是一套可以支持IPv4/IPv6网络的用于管理TCP/UDP/IP网络的工具集

如果没有ss命令，可以如下安装：

```
 yum install iproute iproute-doc
```

1. 命令格式:

```
ss [参数]
ss [参数] [过滤]
```

2. 命令功能：

ss(Socket Statistics的缩写)命令可以用来获取 socket统计信息，此命令输出的结果类似于 netstat输出的内容，但它能显示更多更详细的 TCP连接状态的信息，且比 netstat 更快速高效。它使用了 TCP协议栈中 tcp_diag（是一个用于分析统计的模块），能直接从获得第一手内核信息，这就使得 ss命令快捷高效。在没有 tcp_diag，ss也可以正常运行。

3. 命令参数：

> 
-h, --help 帮助信息  
-V, --version 程序版本信息  
-n, --numeric 不解析服务名称  
-r, --resolve        解析主机名  
-a, --all 显示所有套接字（sockets）  
-l, --listening 显示监听状态的套接字（sockets）  
-o, --options        显示计时器信息  
-e, --extended       显示详细的套接字（sockets）信息  
-m, --memory         显示套接字（socket）的内存使用情况  
-p, --processes 显示使用套接字（socket）的进程  
-i, --info 显示 TCP内部信息  
-s, --summary 显示套接字（socket）使用概况  
-4, --ipv4           仅显示IPv4的套接字（sockets）  
-6, --ipv6           仅显示IPv6的套接字（sockets）  
-0, --packet         显示 PACKET 套接字（socket）  
-t, --tcp 仅显示 TCP套接字（sockets）  
-u, --udp 仅显示 UCP套接字（sockets）  
-d, --dccp 仅显示 DCCP套接字（sockets）  
-w, --raw 仅显示 RAW套接字（sockets）  
-x, --unix 仅显示 Unix套接字（sockets）  
-f, --family=FAMILY  显示 FAMILY类型的套接字（sockets），FAMILY可选，支持  unix, inet, inet6, link, netlink  
-A, --query=QUERY, --socket=QUERY
> > QUERY := {all|inet|tcp|udp|raw|unix|packet|netlink}[,QUERY]
-D, --diag=FILE     将原始TCP套接字（sockets）信息转储到文件  
 -F, --filter=FILE   从文件中都去过滤器信息
> >       FILTER := [ state TCP-STATE ] [ EXPRESSION ]

4. 使用实例：

实例1：显示TCP连接

命令：

```
ss -t -a
```
