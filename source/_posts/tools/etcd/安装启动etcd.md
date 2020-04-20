
### 启动

```
  makir /data/etcd
  nohup etcd --data-dir /data/etcd/test1.etcd --listen-client-urls http://127.0.0.1:7379 --advertise-client-urls http://127.0.0.1:7379 >> /data/etcd/etcd.log 2>&1 &
```

### etcd启动项信息
[config](https://github.com/etcd-io/etcd/blob/master/Documentation/op-guide/configuration.md)
[中文config](https://www.cnblogs.com/cbkj-xd/p/11934599.html)

|参数|使用说明|
|--|--|
|--name etcd0|etcd在集群中的节点名称，在同一个集群中必须是唯一的|
|--initial-advertise-peer-urls http://192.168.2.55:2380	|其他member使用，其他member通过该地址与本member交互信息。一定要保证从其他member能可访问该地址。静态配置方式下，该参数的value一定要同时在--initial-cluster参数中存在。memberID的生成受--initial-cluster-token和--initial-advertise-peer-urls影响。|
|--listen-peer-urls http://0.0.0.0:2380|本member侧使用，用于监听其他member发送信息的地址。ip为全0代表监听本member侧所有接口	|
|--listen-client-urls http://0.0.0.0:2379|本member侧使用，用于监听etcd客户发送信息的地址。ip为全0代表监听本member侧所有接口|
|--advertise-client-urls http://192.168.2.55:2379|etcd客户使用，客户通过该地址与本member交互信息。一定要保证从客户侧能访问该地址|
|--initial-cluster-token etcd-cluster-2|集群的唯一标识，用于区分不同集群。本地如有多个集群要设为不同。|
|--initial-cluster etcd0=http://192.168.2.55:2380,etcd1=http://192.168.2.54:2380,etcd2=http://192.168.2.56:2380|本member侧使用。描述集群中所有节点的信息，本member根据此信息去联系其他member。memberID的生成受--initial-cluster-token和--initial-advertise-peer-urls影响。|
|--initial-cluster-state new|用于指示本次是否为新建集群。有两个取值new和existing。如果填为existing，则该member启动时会尝试与其他member交互。集群初次建立时，要填为new，经尝试最后一个节点填existing也正常，其他节点不能填为existing。集群运行过程中，一个member故障后恢复时填为existing，经尝试填为new也正常。|
|-data-dir|指定节点的数据存储目录，这些数据包括节点ID，集群ID，集群初始化配置，Snapshot文件，若未指定-wal-dir，还会存储WAL文件；如果不指定会用缺省目录。|
|-discovery http://192.168.1.163:20003/v2/keys/discovery/78b12ad7-2c1d-40db-9416-3727baf686cb|用于自发现模式下，指定第三方etcd上key地址，要建立的集群各member都会向其注册自己的地址。|

### 测试是否成功启动
```
etcdctl --endpoints=127.0.0.1:7379 put key1 "Hello world"
etcdctl --endpoints=127.0.0.1:7379 get key1
```

# docker 镜像启动

```
#!/bin/bash
docker run \
  -it -d \
  -p 7379:2379 \
  -p 7380:2380 \
  -v /root/docker/etcd/etcd-data:/etcd-data \
  --name etcd \
  --env ETCDCTL_API=3 \
  quay.io/coreos/etcd \
  /usr/local/bin/etcd \
  --name s1 \
  --data-dir /etcd-data \
  --listen-client-urls http://0.0.0.0:2379 \
  --advertise-client-urls http://47.112.210.86:7379 \
  --listen-peer-urls http://0.0.0.0:2380 \
  --initial-advertise-peer-urls http://47.112.210.86:7380 \
  --initial-cluster s1=http://47.112.210.86:7380 \
  --initial-cluster-token etcd-cluster \
  --initial-cluster-state new

#docker run \
#  -it -d \
#  -p 8379:2379 \
#  -p 8380:2380 \
#  --mount type=bind,source=/tmp/etcd-data.tmp,destination=/etcd-data \
#  --name etcd-gcr \
#  quay.io/coreos/etcd \
#  /usr/local/bin/etcd \
#  --name s1 \
#  --data-dir /etcd-data \
#  --listen-client-urls http://0.0.0.0:2379 \
#  --advertise-client-urls http://47.112.210.86:8379 \
#  --listen-peer-urls http://0.0.0.0:2380 \
#  --initial-advertise-peer-urls http://47.112.210.86:8380 \
#  --initial-cluster s1=http://47.112.210.86:8380 \
#  --initial-cluster-token etcd-cluster \
#  --initial-cluster-state new
```
