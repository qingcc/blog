# [ssh教程](https://wangdoc.com/ssh/key.html)

SSH（Secure Shell 的缩写）是一种网络协议，用于加密两台计算机之间的通信，并且支持各种身份验证机制。

实务中，它主要用于保证远程登录和远程通信的安全，任何网络服务都可以用这个协议来加密。


# 常用的参数

-L

-L参数设置本地端口转发
```shell script
ssh  -L 9999:targetServer:80 user@remoteserver
```

上面命令中，所有发向本地9999端口的请求，都会经过remoteserver发往 targetServer 的 80 端口， 可以将 remoteserver作为跳板连接targetServer

-N

-N参数用于端口转发，表示建立的 SSH 只用于端口转发，不能执行远程命令，这样可以提供安全性

-v

-v参数显示详细信息。

$ ssh -v server.example.com
-v可以重复多次，表示信息的详细程度，比如-vv和-vvv。

```shell script
$ ssh -vvv server.example.com
# 或者
$ ssh -v -v -v server.example.com
```
上面命令会输出最详细的连接信息。



