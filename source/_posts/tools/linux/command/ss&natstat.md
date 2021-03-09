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
-r, --resolve        解析主机名(把 IP 解释为域名，把端口号解释为协议名称)  
-a, --all 显示所有套接字（sockets）,对 TCP 协议来说，既包含监听的端口，也包含建立的连接  
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
ss -t -a    # 显示TCP连接
ss -s       # 显示 Sockets 摘要
ss -l       # 列出所有打开的网络连接端口
ss -pl      # 查看进程使用的socket
ss -lp | grep 3306  # 找出打开套接字/端口应用程序
ss -u -a    显示所有UDP Sockets
ss -o state established '( dport = :smtp or sport = :smtp )' # 显示所有状态为established的SMTP连接
ss -o state established '( dport = :http or sport = :http )' # 显示所有状态为Established的HTTP连接
ss -o state fin-wait-1 '( sport = :http or sport = :https )' dst 193.233.7/24  # 列举出处于 FIN-WAIT-1状态的源端口为 80或者 443，目标网络为 193.233.7/24所有 tcp套接字

# ss 和 netstat 效率对比
time netstat -at
time ss

# 匹配远程地址和端口号
# ss dst ADDRESS_PATTERN
ss dst 192.168.1.5
ss dst 192.168.119.113:http
ss dst 192.168.119.113:smtp
ss dst 192.168.119.113:443

# 匹配本地地址和端口号
# ss src ADDRESS_PATTERN
ss src 192.168.119.103
ss src 192.168.119.103:http
ss src 192.168.119.103:80
ss src 192.168.119.103:smtp
ss src 192.168.119.103:25
```

## 用TCP 状态过滤Sockets
```shell script
ss -4 state closing
# ss -4 state FILTER-NAME-HERE
# ss -6 state FILTER-NAME-HERE
# FILTER-NAME-HERE 可以代表以下任何一个：
# established、 syn-sent、 syn-recv、 fin-wait-1、 fin-wait-2、 time-wait、 closed、 close-wait、 last-ack、 listen、 closing、
# all : 所有以上状态
# connected : 除了listen and closed的所有状态
# synchronized :所有已连接的状态除了syn-sent
# bucket : 显示状态为maintained as minisockets,如：time-wait和syn-recv.
# big : 和bucket相反.
```

## dst/src dport/sport 语法

可以通过 `dst/src/dport/sprot` 语法来过滤连接的来源和目标，来源端口和目标端口。

匹配远程地址和端口号
```shell script
ss dst 192.168.1.5
ss dst 192.168.119.113:http
ss dst 192.168.119.113:443
```

匹配本地地址和端口号
```shell script
ss src 192.168.119.103
ss src 192.168.119.103:http
ss src 192.168.119.103:80
```

将本地或者远程端口和一个数比较

可以使用下面的语法做端口号的过滤：
```shell script
ss dport OP PORT
ss sport OP PORT
```
OP 可以代表以下任意一个：  

||||
|:---|:---|:---|
|<=	|le	|小于或等于某个端口号|
|\>=|ge	|大于或等于某个端口号|
|==	|eq	|等于某个端口号|
|!=	|ne	|不等于某个端口号|
|\> |gt	|大于某个端口号|
|<	|lt	|小于某个端口号|
 
 下面是一个简单的 demo(注意，需要对尖括号使用转义符)：
```shell script
ss -tunl sport lt 50
ss -tunl sport \< 50
``` 

## 通过 TCP 的状态进行过滤

ss 命令还可以通过 TCP 连接的状态对进程过滤，支持的 TCP 协议中的状态有：
> established  
syn-sent  
syn-recv  
fin-wait-1  
fin-wait-2  
time-wait  
closed  
close-wait  
last-ack  
listening  
closing  

除了上面的 TCP 状态，还可以使用下面这些状态：

|||
|:---|:---|
|all            |	列出所有的 TCP 状态。|
|connected      |	列出除了 listening 和 closing 之外的所有 TCP 状态。|
|synchronized   |	列出除了 syn-sent 之外的所有 TCP 状态。|
|bucket         |	列出 maintained 的状态，如：time-wait 和 syn-recv。|
|big            |	列出和 bucket 相反的状态。|

使用 ipv4 时的过滤语法如下：
```shell script
ss -4 state filter
```
使用 ipv6 时的过滤语法如下：
```shell script
ss -6 state filter
```
下面是一个简单的例子：
```shell script
ss -4 state listening
```

## 同时过滤 TCP 的状态和端口号

(注意下面命令中的转义符和空格，都是必须的。如果不用转义符，可以使用单引号)
下面的两种写法是等价的，要有使用 \ 转义小括号，要么使用单引号括起来：
```shell script
ss -4n state listening \( dport = :ssh \)
ss -4n state listening '( dport = :ssh )'
```

下面是一个来自 ss man page 的例子，它列举出处于 FIN-WAIT-1状态的源端口为 80 或者 443，目标网络为 193.233.7/24 所有 TCP 套接字：
```shell script
ss state fin-wait-1 '( sport = :http or sport = :https )' dst 193.233.7/24
```
