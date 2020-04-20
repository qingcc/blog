# docker容器常用命令
```
1. docker version   //显示docker版本信息

2. docker info //显示docker系统信息, 包括镜像和容器数

3. docker search images-name //从 docker hub 中搜索符合条件的镜像
    --automated 只列出 automated build  类型的镜像；
    --no-trunc 可显示完整的镜像描述；
    -s 40 列出收藏数不小于40的镜像。

4. docker pull images-name 拉取镜像

5. docker login
root@moon:~# docker login
Username: username
Password: ****
Email: user@domain.com
Login Succeeded
按步骤输入在 Docker Hub 注册的用户名、密码和邮箱即可完成登录。

6. docker logout  从服务器登出, 默认为官方服务器

7. docker images 列出本地镜像
    -a 列出所有镜像（含过程镜像）；
    
    -f 过滤镜像，如：
    -f ['dangling=true'] 只列出满足dangling=true 条件的镜像；
    --no-trunc 可显示完整的镜像ID；
    -q 仅列出镜像ID。
    --tree 以树状结构列出镜像的所有提交历史。
8. docker ps 列出所有运行中的容器
    -a 列出所有容器（含沉睡镜像）；
    --before="nginx" 列出在某一容器之前创建的容器，接受容器名称和ID作为参数；
    --since="nginx" 列出在某一容器之后创建的容器，接受容器名称和ID作为参数；
    -f [exited=<int>] 列出满足exited=<int> 条件的容器；
    -l 仅列出最新创建的一个容器；
    --no-trunc 显示完整的容器ID；
    -n=4 列出最近创建的4个容器；
    -q 仅列出容器ID；
    -s 显示容器大小。
9. docker rmi
    docker rmi [options "o">] <image>  "o">[image...]
    docker rmi nginx:latest postgres:latest python:latest
    从本地移除一个或多个指定的镜像。
    -f 强行移除该镜像，即使其正被使用；
    --no-prune 不移除该镜像的过程镜像，默认移除。    
10. docker rm
    docker rm [options "o">] <container>  "o">[container...]
    docker rm nginx-01 nginx-02 db-01 db-02
    sudo docker rm -l /webapp/redis
    -f 强行移除该容器，即使其正在运行；
    -l 移除容器间的网络连接，而非容器本身；
    -v 移除与容器关联的空间。
11. docker history
    docker history  "o">[options] <image>
    查看指定镜像的创建历史。
12. docker start|stop|restart
    docker start|stop "p">|restart [options "o">] <container>  "o">[container...]
    启动、停止和重启一个或多个指定容器。
    -a 待完成
    -i 启动一个容器并进入交互模式；
    -t 10 停止或者重启容器的超时时间（秒），超时后系统将杀死进程。
13. docker kill
    docker kill  "o">[options "o">] <container>  "o">[container...]
    杀死一个或多个指定容器进程。
    -s "KILL" 自定义发送至容器的信号。
17. docker export
    docker export <container>
    docker export nginx-01 > export.tar
    将指定的容器保存成 tar 归档文件， docker import 的逆操作。导出后导入（exported-imported)）的容器会丢失所有的提交历史，无法回滚。
18. docker impor
    docker import url|-  "o">[repository[:tag "o">]]
    cat export.tar  "p">| docker import - imported-nginx:latest
    docker import http://example.com/export.tar
    从归档文件（支持远程文件）创建一个镜像， export 的逆操作，可为导入镜像打上标签。导出后导入（exported-imported)）的容器会丢失所有的提交历史，无法回滚。    
20. docker inspect
    docker instpect nginx:latest
    docker inspect nginx-container
    检查镜像或者容器的参数，默认返回 JSON 格式。    
    -f 指定返回值的模板文件。    
21. docker pause
    暂停某一容器的所有进程。
22. docker unpause
    docker unpause <container>
    恢复某一容器的所有进程。
23. docker tag
    docker tag [options "o">] <image>[:tag "o">] [repository/ "o">][username/]name "o">[:tag]
    标记本地镜像，将其归入某一仓库。 
    -f 覆盖已有标记。
24. docker push
    docker push name[:tag "o">]
    docker push laozhu/nginx:latest
    将镜像推送至远程仓库，默认为 Docker Hub 。
25. docker logs
    docker logs [options "o">] <container>
    docker logs -f -t --tail= "s2">"10" insane_babbage
    获取容器运行时的输出日志。
    -f 跟踪容器日志的最近更新；
    -t 显示容器日志的时间戳；
    --tail="10" 仅列出最新10条容器日志。
26. docker run
    docker run [options "o">] <image> [ "nb">command]  "o">[arg...]
    启动一个容器，在其中运行指定命令。
    -a stdin 指定标准输入输出内容类型，可选 STDIN/STDOUT / STDERR 三项；
    -d 后台运行容器，并返回容器ID；
    -i 以交互模式运行容器，通常与 -t 同时使用；
    -t 为容器重新分配一个伪输入终端，通常与 -i 同时使用；
    --name="nginx-lb" 为容器指定一个名称；
    --dns 8.8.8.8 指定容器使用的DNS服务器，默认和宿主一致；
    --dns-search example.com 指定容器DNS搜索域名，默认和宿主一致；
    -h "mars" 指定容器的hostname；
    -e username="ritchie" 设置环境变量；
    --env-file=[] 从指定文件读入环境变量；
    --cpuset="0-2" or --cpuset="0,1,2"  绑定容器到指定CPU运行；
    -c 待完成
    -m 待完成
    --net="bridge" 指定容器的网络连接类型，支持 bridge /host / nonecontainer:<name|id> 四种类型；
    --link=[] 待完成
    --expose=[] 待完成        
```

docker 常用命令 [链接](https://www.runoob.com/docker/docker-command-manual.html)

## docker关于容器的基本命令

1. 创建
```
docker run --name container-name -p 8081:80 -d nginx
--name container-name 容器名称
-p 8081:80 端口进行映射，将本地 8081 端口映射到容器内部的 80 端口。
-d 设置容器在在后台一直运行
nginx 使用镜像
```

2. 查看
```
docker ps     // 查看当前运行的容器
docker ps -a  //查看所有容器，包括停止的。
docker ps -l  //查看最新创建的容器，只列出最后创建的。
docker ps -n=2 //-n=x选项，会列出最后创建的x个容器。
```

3. 启动
```
通过docker start来启动之前已经停止的docker_run镜像。
容器名：docker start docker_run，或者ID：docker start 43e3fef2266c。
–restart(自动重启)：默认情况下容器是不重启的，–restart标志会检查容器的退出码来决定容器是否重启容器。 
docker run --restart=always --name docker_restart -d centos /bin/sh -c "while true;do echo hello world; sleep;done":
--restart=always:不管容器的返回码是什么，都会重启容器。
--restart=on-failure:5:当容器的返回值是非0时才会重启容器。5是可选的重启次数。
```

4. 终止
```
docker stop [NAME]/[CONTAINER ID]:将容器退出。
docker kill [NAME]/[CONTAINER ID]:强制停止一个容器。
```

5. 删除
```
容器终止后，在需要的时候可以重新启动，确定不需要了，可以进行删除操作。
docker rm [NAME]/[CONTAINER ID]:不能够删除一个正在运行的容器，会报错。需要先停止容器。
一次性删除：docker本身没有提供一次性删除操作，但是可以使用如下命令实现：
docker rm $(docker ps -a -q)：-a标志列出所有容器，-q标志只列出容器的ID，然后传递给rm命令，依次删除容器。
```

6. 查看日志
```
tail -f /var/log/messages
```