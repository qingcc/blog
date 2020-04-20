[原文链接](https://www.cnblogs.com/xiaoqi/p/docker-tls.html)
## 启用TLS
在docker服务器，生成CA私有和公共密钥
```
openssl genrsa -aes256 -out ca-key.pem 4096

openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
```

有了CA后，可以创建一个服务器密钥和证书签名请求(CSR)


```
openssl genrsa -out server-key.pem 4096

openssl req -subj "/CN=47.112.210.86" -sha256 -new -key server-key.pem -out server.csr
```
接着，用CA来签署公共密钥:

```
echo subjectAltName = DNS:47.112.210.86,IP:47.112.210.86 >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
```
生成key：

```
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf
```

创建客户端密钥和证书签名请求:


```
openssl genrsa -out key.pem 4096

openssl req -subj '/CN=client' -new -key key.pem -out client.csr
```
修改`extfile.cnf`：


```
echo extendedKeyUsage = clientAuth > extfile-client.cnf
```

生成签名私钥：

```
 openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out cert.pem -extfile extfile-client.cnf
```

将Docker服务停止，然后修改docker服务文件(/usr/lib/systemd/system/docker.service)

```
ExecStart=/opt/kube/bin/dockerd  --tlsverify --tlscacert=/root/docker/ca.pem --tlscert=/root/docker/server-cert.pem --tlskey=/root/docker/server-key.pem -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375
```
然后重启服务

```
systemctl daemon-reload
systemctl restart docker.service 
```
重启后查看服务状态：

```
systemctl status docker.service
```

使用证书连接：

复制`ca.pem`,`cert.pem`,`key.pem`三个文件到客户端

```
docker --tlsverify --tlscacert=ca.pem --tlscert=cert.pem --tlskey=key.pem -H=$HOST:2375 version
```

连接即可

