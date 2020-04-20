拉取镜像
```
docker pull percona/percona-xtradb-cluster
```
## 创建Docker 网络
### Docker网段命令
```
#创建网段、取名为：net1
docker network create net1
#查看指定网段详细信息
docker network inspect net1
#删除指定网段
docker network rm net1
```
### 创建网段
```
docker network create --subnet=172.18.0.0/24 net1
```
## 创建Volume
### Docke Volume卷命令
```
#创建网段、取名为：v1
docker volume create v1
#查看指定卷详细信息
docker volume inspect v1
#删除指定卷
docker volume rm v1
#查看卷信息
docker volume ls
```
### 创建卷
因为要搭建5个数据库的集群、所以创建5个卷
```
docker volume create v1
docker volume create v2
docker volume create v3
docker volume create v4
docker volume create v5
```
## 创建MySQL PXC容器
### 创建Master数据库
mysql的默认帐号是: root
```
docker run -d -p 3306:3306 \
  -v v1:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=root123456 \
  -e CLUSTER_NAME=PXC \
  -e XTRABACKUP_PASSWORD=root123456 \
  --privileged \
  --name=my1 \
  --net=net1 \
  --ip 172.18.0.2 \
  percona/percona-xtradb-cluster 
```
参数说明：
> -d：后端启动容器
> 
> -p:宿主机端口:容器端口，把容器中的端口映射到宿主机的端口上，访问宿主机端口就是直接访问容器
> 
> -v:卷:容器目录，把卷挂载在容器里面
> 
> -e:启动参数 
>
>>   MYSQL_ROOT_PASSWORD:mysql的密码(自定义) 
>>    
>>   CLUSTER_NAME:集群名字(自定义) 
>>
>>   XTRABACKUP_PASSWORD:数据库节点间数据同步的密码(自定义)
>
> –privileged:授予权限
> 
> –name:容器命名
> 
> –net:绑定网段
> 
> –ip:绑定ip,ip地址为绑定网段内ip percona-xtradb-cluster:latest:运行的镜像

## 创建备库
说明
加四个从数据库
特别注意：创建备库的时候、必须要等主库可以成功连接上了、才可以创建、不然会出现容器闪退的问题。原因是容器启动快、但是容器里服务启动慢。
### 注意事项
- 1. 修改挂载的卷
- 2. 修改宿主机端口，端口唯一
- 3. 添加指定的群名,-e CLUSTER_JOIN=my1
- 4. 修改容器名
- 5. 修改ip
- 6. 必须等第一个容器服务创建成功才能创建第二个、通过客户端工具验证，不然会出现闪退情况
my2:
```
docker run -d -p 3307:3306 
-v v2:/var/lib/mysql 
-e MYSQL_ROOT_PASSWORD=root123456 
-e CLUSTER_NAME=PXC 
-e XTRABACKUP_PASSWORD=root123456 
-e CLUSTER_JOIN=my1 
--privileged 
--name=my2
--net=net1 
--ip 172.18.0.3
  percona/percona-xtradb-cluster 
```
参数说明： CLUSTER_JOIN：需要加入到主集群中、主mysql名字,跟主数据数据同步
my3:
```
docker run -d -p 6308:3306 \
-v v3:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=root123456 \
-e CLUSTER_NAME=PXC \
-e XTRABACKUP_PASSWORD=root123456 \
-e CLUSTER_JOIN=my1 \
--privileged \
--name=my3 \
--net=net1 \
--ip 172.18.0.4 \
  percona/percona-xtradb-cluster 
```
my4:
```
 docker run -d -p 6309:3306 \
-v v4:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=root123456 \
-e CLUSTER_NAME=PXC \
-e XTRABACKUP_PASSWORD=root123456 \
-e CLUSTER_JOIN=my1 \
--privileged \
--name=my4 \
--net=net1 \
--ip 172.18.0.5 \
  percona/percona-xtradb-cluster 
```
my5:
```
 docker run -d -p 6310:3306 \
-v v5:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=root123456 \
-e CLUSTER_NAME=PXC \
-e XTRABACKUP_PASSWORD=root123456 \
-e CLUSTER_JOIN=my1 \
--privileged \
--name=my5 \
--net=net1 \
--ip 172.18.0.6 \
  percona/percona-xtradb-cluster 
```
连接效果
注意事项：连接的是宿主机的ip和port、并不是容器内部地址
...


链接：http://liujilu.com/2019/05/17/docker-percona-xtradb-cluster/