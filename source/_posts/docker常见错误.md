# docker常见错误

## 启动就退出
1. 未加 `-d` 参数，未后台运行
2. 加 `-it` docker容器运行必须有一个前台进程， 如果没有前台进程执行，容器认为空闲，就会自行退出(网上搜索到的)

<!-- more -->
## docker命令报permission denied错误的处理方法
在安装docker时，已经创建了一个名为docker的用户组，守护进程启动的时候，会默认赋予用户组docker读写Unix socket的权限，因此只要将当前用户加入到docker用户组中，那当前用户就有权限访问Unix socket了，进而也就可以执行docker相关命令

```
#将登陆用户加入到docker用户组中
sudo gpasswd -a $USER docker

#更新用户组
newgrp docker

#测试docker命令是否可以使用sudo正常使用
docker ps -a
```