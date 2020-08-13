## 常用命令
删除本地无用的镜像

```
docker  images|grep  none|awk  '{print  $3  }'|xargs  docker  rmi
```

服务器磁盘满了，查看思路之一（主要针对docker容器日志文件过大）：

1. `df -h`查看磁盘占用情况
2. 查看docker占用磁盘大小（最大可能是docker占用磁盘过大）
3. 查看 `/var/lib/docker/containers/`下容器是否占用磁盘过大（容器的日志文件可能会很大，如果没有限制容器日志文件大小），使用`ls | du sh`命令查看各个容器占用磁盘的大小
4. 使用`docker instect container`来查看占用磁盘较大的容器（主要查看对应的日志文件路径，并使用`du sh`命令来查看该日志文件的大小

1.2 在 `linux` 上容器日志一般存放在 `/var/lib/docker/containers/container_id/` 下面，以 `json.log` 结尾的文件(业务日志)很大：

```
du -h --max-depth=1 * //可以查看当前目录下各文件、文件夹的大小。
du -h --max-depth=0 *  //可以只显示直接子目录文件及文件夹大小统计值。
du –sh //查看指定目录的总大小。
 ```

查看服务器docker容器日志大小脚本：
```
#!/bin/sh 
echo "======== docker containers logs file size ========"  

logs=$(find /var/lib/docker/containers/ -name *-json.log)  

for log in $logs  
        do  
             ls -lh $log   
        done
```

二、清理 `Docker` 容器（治标）

2.1 这里需要用 `cat /dev/null >` 进行清空，而不是 `rm` ：

```
cat /dev/null > /var/lib/docker/containers/容器id/容器id-json.log
```

三、设置Docker容器日志大小（治本）

3.1 设置一个容器服务的日志大小上限

通过配置容器docker-compose.yml的max-size选项来实现:
```
nginx: 
  image: nginx:1.12.1 
  restart: always 
  logging: 
    driver: "json-file"
    options: 
      max-size: "5g"
```
docker 命令参数：
```
--log-opt max-size=1m --log-opt max-file=3
```
 

3.2 全局设置

新建 `/etc/docker/daemon.json` ，若有就不用新建了

```
# vim /etc/docker/daemon.json

{
  "registry-mirrors": ["http://f613ce8f.m.daocloud.io"],
  "log-driver":"json-file",
  "log-opts": {"max-size":"500m", "max-file":"3"}
}
```

`max-size=500m` ，意味着一个容器日志大小上限是500M，

`max-file=3` ，意味着一个容器有三个日志，分别是id+.json、id+1.json、id+2.json

注：设置后只对新添加的容器有效。

 

重启docker守护进程

```
systemctl daemon-reload
systemctl restart docker
```