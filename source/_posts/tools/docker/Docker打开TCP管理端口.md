[原文链接](https://blog.csdn.net/onlyshenmin/article/details/81069047)

[TOC]

# 1.开启TCP管理端口
## 1.1创建目录/etc/systemd/system/docker.service.d

```
mkdir /etc/systemd/system/docker.service.d
```
## 1.2在这个目录下创建tcp.conf文件,增加以下内容

### ubuntu专用版

```
cat > /etc/systemd/system/docker.service.d/tcp.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
EOF
```
### ubuntu/centos7通用版

```
cat > /etc/systemd/system/docker.service.d/tcp.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375
EOF
```
上面两个版本的区别在于用何种方式指定Docker守护进程本地套接字监听


```
-H fd://                                    仅Ubuntu可用
-H unix:///var/run/docker.sock              CentOS和Ubuntu通用
```

## 1.3Daemon重新reload ，并重启docker

```
systemctl daemon-reload
systemctl restart docker
```

## 1.4查看端口是否打开

```
ps aux |grep dockerd
// or
netstat -an | grep 2375
```

## 1.5CentOS7其他方法
CentOS7还可以通过修改/etc/sysconfig/docker文件中的 OPTIONS来达到同样的目的

```
OPTIONS='--selinux-enabled -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375'
```

## 2.关闭TCP管理端口

```
rm  /etc/systemd/system/docker.service.d/tcp.conf -rf
systemctl daemon-reload
systemctl restart docker
ps aux |grep dockerd
```

